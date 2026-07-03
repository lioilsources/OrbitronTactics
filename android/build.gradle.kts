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
fun backfillNamespace(project: Project) {
    val ext = project.extensions
        .findByType(com.android.build.gradle.LibraryExtension::class.java)
        ?: return
    if (ext.namespace != null) return
    val manifest = project.file("src/main/AndroidManifest.xml")
    if (!manifest.exists()) return
    Regex("package=\"([^\"]+)\"")
        .find(manifest.readText())
        ?.groupValues
        ?.get(1)
        ?.let { ext.namespace = it }
}

subprojects {
    // evaluationDependsOn(":app") above may have evaluated this project
    // already, in which case afterEvaluate would throw.
    if (state.executed) {
        backfillNamespace(this)
    } else {
        afterEvaluate { backfillNamespace(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
