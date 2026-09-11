"""Fleet art definitions for OrbitronTactics battle ships.

Ten fleets x six unit types x two colours. The white ship is generated with
FLUX.1-dev; the black ship is the same render repainted with FLUX Kontext, so
both sides of a fleet share one design.
"""

# Every role names where the bow is: without it the pilot king came out as a
# wedge pointing down with its bridge tower at the top.
UNITS = {
    "pawn": "a small nimble light fighter with twin rapid-fire cannons, a compact "
            "simple hull with a pointed nose, the smallest ship of the fleet",
    "knight": "an agile interceptor with swept-forward wings and a single nose cannon, "
              "sleek and fast",
    "bishop": "a slender long-range sniper frigate with one very long railgun barrel "
              "running along its centerline and reaching past its bow",
    "rook": "a heavily armored blocky gunship with a blunt armored bow, thick layered "
            "armor plates, a squared fortress-like silhouette and one heavy cannon turret",
    # "Graceful sweeping wings" drew forward-pointing horns over a spear-like
    # tail, which reads as a ship flying down (Neon Runners, Solar Crusade).
    "queen": "a large elegant battlecruiser shaped like a long arrowhead, its sharp bow at "
             "the top and its wide wings swept back toward the engines at the bottom, with "
             "several heavy cannon turrets, powerful and regal",
    # Kings kept coming out as a sword: a cross-shaped bridge section at the
    # top over a long blade tapering to the bottom, which reads as flying down.
    "king": "a massive flagship dreadnought whose broad heavy hull is widest at the bottom, "
            "where its engines are, and narrows steadily to a sharp bow at the top, with a "
            "command tower on its rear half and rows of heavy cannon batteries, the largest "
            "and most imposing ship of the fleet",
}

# slug, name, design language, white hull, black hull, accents
FLEETS = [
    ("vanguard", "Orbitron Vanguard",
     "clean hard-surface science fiction design, smooth curved panels and fine panel lines",
     "glossy white and pale silver hull", "matte black and dark gunmetal hull",
     "glowing cyan light strips and cyan engine exhaust"),
    ("solar_crusade", "Solar Crusade",
     "ornate knightly design with gilded filigree, heraldic crest shapes and sunburst motifs",
     "polished ivory white hull", "blackened steel hull",
     "gold trim and warm golden engine glow"),
    ("void_hive", "Void Hive",
     "organic biomechanical insectoid design, segmented chitin carapace plates and claw-like prongs",
     "bone-white chitin carapace", "glossy obsidian-black chitin carapace",
     "acid green bioluminescent veins and green engine glow"),
    ("neon_runners", "Neon Runners",
     "synthwave design with sharp angular wedge shapes and glossy surfaces",
     "glossy pearl white hull", "glossy jet black hull",
     "hot magenta and electric cyan neon edge lights"),
    ("iron_armada", "Iron Armada",
     "dieselpunk industrial warship design with riveted armor plates, exhaust stacks and bolted turrets",
     "off-white painted steel hull", "soot-black painted steel hull",
     "orange hazard stripes and fiery orange exhaust"),
    ("crystal_choir", "Crystal Choir",
     "faceted crystalline design with sharp geometric gemstone facets and prismatic refractions",
     "clear white quartz crystal hull", "black obsidian crystal hull",
     "violet and aqua light glowing through the facets"),
    ("ronin_blades", "Ronin Blades",
     "Japanese-inspired design with blade-like katana-edge wings, lacquered panels and elegant curves",
     "white lacquered hull", "black lacquered hull",
     "crimson lacquer accents and red engine glow"),
    ("atomic_age", "Atomic Age",
     "1950s retro-futurist rocket design with tail fins, round portholes and polished chrome details",
     "white enamel hull with chrome trim", "black enamel hull with dark chrome trim",
     "teal and cherry red stripes and a warm rocket flame"),
    ("abyssal_tide", "Abyssal Tide",
     "aquatic design inspired by manta rays and nautilus shells with flowing fin shapes",
     "pearlescent white hull", "deep glossy black hull",
     "teal bioluminescent patterns and soft blue engine glow"),
    ("star_nomads", "Star Nomads",
     "scavenger patchwork design with mismatched hull plates, small solar sails and welded makeshift parts",
     "sun-bleached white hull plates", "charred black hull plates",
     "rust orange patches and turquoise engine glow"),
]

# Ships FLUX drew bow-down despite the bow wording: a command tower at the top
# over a hull tapering to a sharp point at the bottom. Contact sheets and the
# export mirror them top to bottom, both colors, so the point leads.
BOW_DOWN = {"solar_crusade/king", "ronin_blades/king"}


def white_prompt(fleet, unit):
    _, name, design, white_hull, _, accents = fleet
    return (
        f"Game sprite of {UNITS[unit]}, one ship of the \"{name}\" space fleet.\n"
        "Viewed from DIRECTLY OVERHEAD: strict 90-degree top-down orthographic view with zero "
        "perspective and zero tilt. The ship flies straight up the image: its bow is at the "
        "TOP edge and its engine exhausts glow at the BOTTOM edge.\n"
        "One single ship, drawn large and highly detailed, centered, filling most of the frame "
        "with a small even margin on every side.\n"
        f"Design: {design}. Colors: {white_hull} with {accents}.\n"
        "Bold readable silhouette that stays recognizable at small size, symmetrical from left "
        "to right, polished digital painting with crisp clean edges.\n"
        "The ship floats in empty air, evenly lit from every side. "
        "The background is one flat solid neutral mid-gray color, completely plain and empty."
    )


def black_prompt(fleet, unit, attempt=0):
    _, _, _, _, black_hull, accents = fleet
    prompt = (
        f"Repaint the spaceship so its hull becomes a {black_hull}, while keeping the {accents}. "
        "Keep the exact same ship design, shape, size, position and top-down view, and keep the "
        "flat neutral gray background."
    )
    if attempt:
        # A retry after the darkness gate found the repaint too pale.
        prompt += (" The hull must end up very dark, close to pitch black, far darker than "
                   "the original white paint.")
    return prompt


def seed_for(slug, unit):
    """Stable seed per ship, so a re-run reproduces the same design."""
    h = 2166136261
    for ch in f"{slug}/{unit}":
        h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return h
