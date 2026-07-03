allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Legacy plugins (e.g. flutter_nearby_connections) predate AGP 7 and declare
// no `namespace`, which AGP 8+ requires. Backfill it from the plugin's
// manifest `package=` attribute so they still build.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { ext ->
            if (ext.namespace == null) {
                val manifest = file("${projectDir}/src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("package=\"([^\"]+)\"")
                        .find(manifest.readText())
                        ?.groupValues
                        ?.get(1)
                    if (pkg != null) {
                        ext.namespace = pkg
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
