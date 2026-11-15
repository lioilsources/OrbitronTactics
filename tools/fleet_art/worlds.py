"""World art pilot for plan 12, step 1A: other worlds than space.

A world puts two factions of one lore against each other. What it costs is
set by the view its units can be drawn in:

  top   — seen from directly overhead, head or bow up, like today's ships;
          goes through the arena unchanged and keeps the mirror gate.
  side  — a painted tabletop miniature on a round base in strict profile,
          facing right; needs the side arena. No mirror gate: one figure,
          fully in frame, and the dark side clearly darker.

The brief behind the worlds, as Olin gave it: "bájná zvířata, golemové,
římská a egyptská armáda, lodní bitvy" (mythical beasts, golems, the Roman
and the Egyptian army, naval battles), both factions from the same lore.
"""

# Pilot set: the smallest and the largest role of every faction.
PILOT_UNITS = ("pawn", "king")

# The piece drawn before anything else.
FIRST_PIECE = ("golems", "marble", "rook")

TOP_DIRECTION = ("{subject} heads straight up the image: its head or bow is at the "
                 "TOP edge and its tail or stern at the BOTTOM edge.")

WORLDS = {
    "golems": {
        "name": "Golems",
        "lore": "golems, chess pieces brought to life: guilds of animated statues, each "
                "guild carved from its own material",
        "view": "side",
        "factions": {
            "marble": ("Marble Guild", "carved from polished white marble with fine grey "
                       "veins, gilded joints"),
            "obsidian": ("Obsidian Guild", "carved from glossy black obsidian with sharp "
                         "faceted edges, glowing violet cracks"),
            "lava": ("Lava Guild", "made of dark basalt rock with glowing orange molten "
                     "lava seams"),
            "ice": ("Ice Guild", "made of translucent pale blue glacier ice with frosted "
                    "edges and white snow crust"),
        },
        "units": {
            "pawn": "a small stocky clay-like golem soldier with a round head and a short "
                    "stone club, the smallest figure of the army",
            "knight": "a stone war horse golem rearing on its hind legs, with a heavy "
                      "carved mane",
            "bishop": "a tall narrow obelisk golem with glowing runes and one slender arm "
                      "raised to cast",
            "rook": "a walking stone tower golem: a massive round castle tower with "
                    "battlements on top, two thick stone legs and two short heavy arms",
            "queen": "a crowned statue sorceress golem in a long carved robe, holding a "
                     "staff",
            "king": "a huge crowned colossus golem with broad shoulders and a carved stone "
                    "cape, the largest and most imposing figure of the army",
        },
    },
    "sky_beasts": {
        "name": "Sky Beasts",
        "lore": "mythical beasts: flying armies of dragons and griffins",
        "view": "top",
        "factions": {
            "dragons": ("Dragon Brood", "scaled dragons with leathery bat wings, crimson "
                        "and bronze scales"),
            "griffins": ("Griffin Eyrie", "griffins with feathered eagle wings and lion "
                         "bodies, golden and white plumage"),
        },
        "units": {
            "pawn": "a small young flying beast with wings spread wide, the smallest of "
                    "the flock",
            "knight": "a swift wyvern-like flyer with long swept wings",
            "bishop": "a long-necked flyer that spits lightning, its neck stretched far "
                      "forward",
            "rook": "a heavy armored flyer with a broad plated back like a turtle shell",
            "queen": "a slender elegant long-bodied flyer with long graceful wings",
            "king": "an ancient enormous flying beast with vast wings spread wide, the "
                    "largest and most imposing of the flock",
        },
    },
    "actium": {
        "name": "Actium",
        "lore": "naval battles: the Roman fleet against the fleet of Cleopatra's Egypt, "
                "ancient oared war galleys",
        "view": "top",
        "factions": {
            "rome": ("Roman Fleet", "dark oak hulls with red sails, bronze ram and a "
                     "golden eagle standard"),
            "egypt": ("Egyptian Fleet", "papyrus-gold painted hulls with white and blue "
                      "striped sails and an eye of Horus on the bow"),
        },
        "units": {
            "pawn": "a small light liburna galley with one row of oars, the smallest ship "
                    "of the fleet",
            "knight": "a fast bireme war galley with two rows of oars",
            "bishop": "a galley carrying a long ballista mounted along its centerline",
            "rook": "a heavy quinquereme war galley with a wooden siege tower on its deck",
            "queen": "a grand flagship galley with a richly decorated deck and canopy",
            "king": "a massive royal galley with many rows of oars, the largest and most "
                    "imposing ship of the fleet",
        },
    },
    "rome_egypt": {
        "name": "Rome and Egypt",
        "lore": "the Roman army and the Egyptian army, with their myths: legionaries and "
                "eagles of the legion against the pharaoh's warriors, Anubis guards and "
                "sphinxes",
        "view": "side",
        "factions": {
            "legion": ("Roman Legion", "red tunics, polished steel and bronze armor, red "
                       "crests and rectangular shields"),
            "pharaoh": ("Pharaoh's Host", "white linen, gold and lapis lazuli jewelry, "
                        "striped nemes headdresses"),
        },
        "units": {
            "pawn": "a young foot soldier with a spear and a shield, the smallest figure "
                    "of the army",
            "knight": "a mounted warrior on a horse",
            "bishop": "an archer priest drawing a long bow",
            "rook": "a giant guardian statue warrior holding a tower shield",
            "queen": "a commanding priestess with a staff",
            "king": "the crowned ruler in full ceremonial armor on a small war chariot, "
                    "the largest and most imposing figure of the army",
        },
    },
}


def white_prompt(world_id, faction_id, unit):
    world = WORLDS[world_id]
    faction_name, look = world["factions"][faction_id]
    role = world["units"][unit]
    intro = (f"Game sprite of {role}, one unit of the \"{faction_name}\" from a world of "
             f"{world['lore']}.\n")
    if world["view"] == "top":
        return intro + (
            "Viewed from DIRECTLY OVERHEAD: strict 90-degree top-down orthographic view "
            "with zero perspective and zero tilt. "
            + TOP_DIRECTION.format(subject="It") + "\n"
            "One single subject, drawn large and highly detailed, centered, filling most of "
            "the frame with a small even margin on every side.\n"
            f"Look: {look}.\n"
            "Bold readable silhouette that stays recognizable at small size, symmetrical "
            "from left to right, polished digital painting with crisp clean edges.\n"
            "It floats in empty air, evenly lit from every side. "
            "The background is one flat solid neutral mid-gray color, completely plain "
            "and empty."
        )
    return intro + (
        "A painted tabletop wargame miniature standing on a small round base, shown in "
        "STRICT SIDE PROFILE, facing RIGHT, orthographic with no perspective.\n"
        "The whole figure from the top of its head to its base is in the frame, drawn "
        "large and highly detailed, centered, with a small even margin on every side.\n"
        f"Look: {look}.\n"
        "Bold readable silhouette that stays recognizable at small size, a static heroic "
        "pose, polished digital painting with crisp clean edges.\n"
        "Evenly lit from every side, no cast shadow. "
        "The background is one flat solid neutral mid-gray color, completely plain and "
        "empty."
    )


def black_prompt(world_id, faction_id, unit, attempt=0):
    world = WORLDS[world_id]
    _, look = world["factions"][faction_id]
    noun = "figure" if world["view"] == "side" else "unit"
    prompt = (f"Repaint the {noun} in a dark version of its colors: the same materials ({look}) "
              "but deep, shadowed and near black, keeping any glowing accents bright. Keep "
              f"the exact same design, shape, size, position and view, and keep the flat "
              "neutral gray background.")
    if attempt:
        prompt += " It must end up very dark, far darker than the original."
    return prompt


def seed_for(world_id, faction_id, unit):
    """Stable seed per unit, so a re-run reproduces the same design."""
    h = 2166136261
    for ch in f"{world_id}/{faction_id}/{unit}":
        h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return h
