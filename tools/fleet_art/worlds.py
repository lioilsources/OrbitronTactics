"""World art pilot for plan 12, step 1A: other worlds than space.

Every world sets good against evil, as Olin set it: "Jedni budou hrát za
světlo, slunce. Druzí za peklo a démony. Armády nemusí být symetrické."
(One side plays for the light, the sun; the other for hell and demons. The
armies need not be symmetric.) And: "dobro proti zlu bude i v jinych
lorech: Rim vs Kartago tj Kone verzus Sloni..., Egypt vs Asyrane; Knight vs
Orkove; Elfove proti skretum, Cerni wizardi vs. White carodejove" (good
against evil in other lores too: Rome vs Carthage, i.e. horses vs
elephants; Egypt vs Assyrians; knights vs orcs; elves vs goblins; black vs
white wizards). Also "Víc figurek, víc magických zvířátek" (more pieces,
more magical creatures). So each side has its own designs: no dark repaint
of the good army ("Černé figurky jsou černé. To nechceme." - black pieces
come out just black, we don't want that). The good side plays white and the
evil side plays black; file names keep `_white` / `_black`.

What a world costs is set by the view its units are drawn in:

  top   — seen from directly overhead, head or bow up, like today's ships;
          goes through the arena unchanged.
  side  — a painted tabletop miniature on a round base in strict profile,
          facing right; needs the side arena.

The brief behind the worlds: "bájná zvířata, golemové, římská a egyptská
armáda, lodní bitvy" (mythical beasts, golems, the Roman and the Egyptian
army, naval battles).
"""

# Pilot set: the smallest and the largest role of every side. A world that
# describes all six roles can render the whole army (`--units all`).
PILOT_UNITS = ("pawn", "king")
ALL_UNITS = ("pawn", "knight", "bishop", "rook", "queen", "king")

# Which side plays which color.
SIDE_OF_COLOR = {"white": "good", "black": "evil"}

TOP_DIRECTION = ("{subject} heads straight up the image: its head or bow is at the "
                 "TOP edge and its tail or stern at the BOTTOM edge.")

WORLDS = {
    "golems": {
        "name": "Golems",
        "lore": "golems, chess pieces brought to life as animated statues",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Sunforged Host",
                "look": "carved from warm white marble and sun-gold, with radiant golden "
                        "sun discs set into the chest and glowing warm light in the eyes",
                "units": {
                    "pawn": "a small stocky marble golem soldier with a round head and a "
                            "small sun-disc shield, the smallest figure of the army",
                    "king": "a huge colossus golem crowned with a ring of golden sun rays, "
                            "broad shoulders, the largest and most imposing figure of the "
                            "army",
                },
            },
            "evil": {
                "name": "Brimstone Legion",
                "look": "made of cracked black basalt and brimstone with glowing red-orange "
                        "magma seams, curved horns and burning ember eyes",
                "units": {
                    "pawn": "a small hunched imp golem of rough rock with stubby horns and "
                            "claws, the smallest figure of the army",
                    "king": "a huge horned demon colossus of molten rock with burning "
                            "cracks and a crown of jagged obsidian spikes, the largest and "
                            "most imposing figure of the army",
                },
            },
        },
    },
    "sky_beasts": {
        "name": "Sky Beasts",
        "lore": "mythical beasts: flying armies of the sun against flying demons of hell",
        "view": "top",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Sun Flight",
                "look": "golden and white feathers lit by warm sunlight, glowing sun-gold "
                        "wing tips",
                "units": {
                    "pawn": "a small young griffin with feathered eagle wings spread wide, "
                            "the smallest of the flock",
                    "king": "a vast radiant phoenix with enormous flaming golden wings "
                            "spread wide, the largest and most imposing of the flock",
                },
            },
            "evil": {
                "name": "Infernal Swarm",
                "look": "dark crimson and charcoal leathery skin with glowing red-orange "
                        "veins, horns and hellfire",
                "units": {
                    "pawn": "a small winged imp demon with bat wings spread wide, the "
                            "smallest of the swarm",
                    "king": "an enormous horned demon dragon with vast tattered bat wings "
                            "spread wide and burning eyes, the largest and most imposing "
                            "of the swarm",
                },
            },
        },
    },
    "actium": {
        "name": "Actium",
        "lore": "naval battles of ancient oared war galleys: the fleet of the sun against "
                "the fleet of hell",
        "view": "top",
        "mirror": True,
        "sides": {
            "good": {
                "name": "Sun Fleet",
                "look": "pale oak hulls trimmed in gold, white and golden sails with a "
                        "radiant sun emblem, gilded bronze ram",
                "units": {
                    "pawn": "a small light galley with one row of oars, the smallest ship of "
                            "the fleet",
                    "king": "a massive royal galley with many rows of oars and a golden sun "
                            "disc on its deck, the largest and most imposing ship of the "
                            "fleet",
                },
            },
            "evil": {
                "name": "Hell Fleet",
                "look": "charred black hulls with glowing red cracks, blood-red sails, "
                        "bone spikes and a horned demon skull ram",
                "units": {
                    "pawn": "a small fast raider galley with one row of oars, the smallest "
                            "ship of the fleet",
                    "king": "a massive demonic war galley with many rows of oars and a "
                            "burning brazier on its deck, the largest and most imposing "
                            "ship of the fleet",
                },
            },
        },
    },
    "fable": {
        "name": "Fable",
        "lore": "magical creatures of a fairy tale, good against evil: the creatures of "
                "light and the sun against the beasts of hell",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Court of the Sun",
                "look": "white, cream and gold fur, feathers and scales, softly glowing "
                        "golden sun runes and warm radiant light",
                "units": {
                    "pawn": "a small brave winged fox kit with a tiny golden sun charm, the "
                            "smallest creature of the army",
                    "knight": "a white unicorn rearing on its hind legs with a spiral "
                              "golden horn",
                    "bishop": "a wise snowy owl sage with a sun-gold staff in its talons",
                    "rook": "a huge kind stone-bark tree ent with a golden glowing heart",
                    "queen": "a radiant phoenix with flaming golden wings raised high",
                    "king": "a majestic winged sun lion with a golden mane of light and a "
                            "crown, the largest and most imposing creature of the army",
                },
            },
            "evil": {
                "name": "Brood of the Abyss",
                "look": "black, charcoal and deep crimson fur, scales and leathery skin, "
                        "glowing red-orange eyes, horns and smouldering embers",
                "units": {
                    "pawn": "a small grinning horned imp with bat wings and a pitchfork, the "
                            "smallest creature of the army",
                    "knight": "a nightmare horse of black smoke with a burning mane and "
                              "flaming hooves",
                    "bishop": "a hooded goat-headed warlock demon holding a skull staff "
                              "with green hellfire",
                    "rook": "a hulking stone gargoyle with folded wings and cracked "
                            "glowing veins",
                    "queen": "a serpent-bodied demon sorceress with six arms and a crown of "
                             "horns",
                    "king": "a three-headed hellhound with burning eyes and a collar of "
                            "spiked iron, the largest and most imposing creature of the "
                            "army",
                },
            },
        },
    },
    "rome_carthage": {
        "name": "Rome and Carthage",
        "lore": "the Punic Wars told as a legend of good against evil: the sunlit legions "
                "of Rome with their horses against the dark host of Carthage with its war "
                "elephants",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Sunlit Legions of Rome",
                "look": "polished steel and gold armor, white and red cloth, red crests, "
                        "golden eagle and sun emblems, bright daylight colors",
                "units": {
                    "pawn": "a young legionary with a short sword and a tall rectangular "
                            "shield, the smallest figure of the army",
                    "knight": "a Roman cavalryman on a white war horse rearing up",
                    "bishop": "an augur priest in a white toga raising a golden eagle staff",
                    "rook": "a heavy wooden siege tower on wheels crewed by legionaries",
                    "queen": "a Vestal priestess in white robes holding a sacred flame",
                    "king": "a triumphant general in gold armor and a laurel wreath "
                            "standing in a gilded chariot drawn by two white horses, the "
                            "largest and most imposing figure of the army",
                },
            },
            "evil": {
                "name": "Shadow Host of Carthage",
                "look": "dark bronze and black iron armor, deep purple and blood-red cloth, "
                        "horned helmets, glowing ember-red eyes and dusk colors",
                "units": {
                    "pawn": "a Numidian skirmisher with javelins and a small round shield, "
                            "the smallest figure of the army",
                    "knight": "a war elephant in dark armor with a small tower on its back "
                              "and iron-capped tusks",
                    "bishop": "a priest of Baal Hammon in a dark hooded robe holding a "
                              "brazier of red fire",
                    "rook": "a huge armored war elephant with a fortified tower full of "
                            "spearmen on its back",
                    "queen": "a dark sorceress queen in purple robes with a serpent crown",
                    "king": "a fearsome warlord general riding a gigantic black war elephant "
                            "with spiked armor, the largest and most imposing figure of the "
                            "army",
                },
            },
        },
    },
    "egypt_assyria": {
        "name": "Egypt and Assyria",
        "lore": "an ancient myth of good against evil: the radiant army of the sun god Ra "
                "against the cruel winged-bull empire of Assyria",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Host of Ra",
                "look": "white linen, polished gold and lapis lazuli, sun-disc emblems, "
                        "warm radiant light",
                "units": {
                    "pawn": "a young Egyptian spearman with a gold-rimmed shield bearing a "
                            "sun disc, the smallest figure of the army",
                    "knight": "an Egyptian war chariot pulled by a golden horse with a "
                              "charioteer archer",
                    "bishop": "a falcon-headed priest of Horus raising a glowing ankh",
                    "rook": "a great sphinx guardian with a lion body and a pharaoh head",
                    "queen": "a queen with a vulture-feather crown and a golden sun disc "
                             "between cow horns, holding a lotus scepter",
                    "king": "a pharaoh crowned with a golden sun disc, holding a crook and "
                            "flail, standing tall in gold armor, the largest and most "
                            "imposing figure of the army",
                },
            },
            "evil": {
                "name": "Iron Empire of Assyria",
                "look": "dark iron scale armor, black and crimson cloth, long braided "
                        "black beards, bronze and obsidian ornaments, smouldering torchlight",
                "units": {
                    "pawn": "an Assyrian spearman with a conical iron helmet and a wicker "
                            "shield, the smallest figure of the army",
                    "knight": "an Assyrian horse archer on a black horse",
                    "bishop": "a sinister priest with a fish-skin cloak and a dark incense "
                              "censer",
                    "rook": "a battering ram siege engine shaped like a horned beast",
                    "queen": "a dark sorceress queen with a tall horned crown and a "
                             "scorpion-headed staff",
                    "king": "a stern god-king on a throne carried by a huge winged human-"
                            "headed bull lamassu, the largest and most imposing figure of the "
                            "army",
                },
            },
        },
    },
    "knights_orcs": {
        "name": "Knights and Orcs",
        "lore": "high fantasy: shining knights of a sunlit kingdom against a horde of orcs",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Kingdom of Dawn",
                "look": "shining silver plate armor, white and gold heraldry with a rising "
                        "sun, blue cloaks",
                "units": {
                    "pawn": "a young squire footman with a spear and a kite shield, the "
                            "smallest figure of the army",
                    "knight": "a knight in full plate on a barded white destrier with a "
                              "lance",
                    "bishop": "a paladin cleric raising a glowing warhammer",
                    "rook": "a walking castle tower with a portcullis and banners",
                    "queen": "a queen in silver armor with a radiant sword and a white cape",
                    "king": "a crowned king in gold-trimmed plate with a great sword and a "
                            "sun shield, the largest and most imposing figure of the army",
                },
            },
            "evil": {
                "name": "Bloodtusk Horde",
                "look": "green and grey skin, crude black iron and bone armor, red war "
                        "paint, ragged hides and tusks",
                "units": {
                    "pawn": "a small scrawny orc grunt with a jagged cleaver, the smallest "
                            "figure of the army",
                    "knight": "an orc raider riding a huge snarling wolf",
                    "bishop": "an orc shaman with a skull totem staff and green fire",
                    "rook": "a hulking troll carrying a tree-trunk club",
                    "queen": "an orc warchief matriarch with twin axes and a bone crown",
                    "king": "a massive orc warlord in spiked black armor with a giant war "
                            "axe, the largest and most imposing figure of the army",
                },
            },
        },
    },
    "elves_goblins": {
        "name": "Elves and Goblins",
        "lore": "a fairy forest: graceful elves of the sunlit woods against goblins of the "
                "dark caves",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Sunwood Elves",
                "look": "leaf-green and gold armor, white and silver cloth, flowing hair, "
                        "glowing golden leaf motifs",
                "units": {
                    "pawn": "a young elf archer with a longbow, the smallest figure of the "
                            "army",
                    "knight": "an elf rider on a white stag with golden antlers",
                    "bishop": "an elf druid with a staff of living branches and glowing "
                              "fireflies",
                    "rook": "a great tree guardian with a kind face in its bark",
                    "queen": "an elf queen with a crown of golden leaves and a glowing wand",
                    "king": "a tall elf king in gleaming leaf armor with an antler crown and "
                            "a sun-bright sword, the largest and most imposing figure of the "
                            "army",
                },
            },
            "evil": {
                "name": "Cavern Goblins",
                "look": "green-grey warty skin, scrap iron armor, patched dark rags, big "
                        "ears and glowing yellow eyes",
                "units": {
                    "pawn": "a tiny sneaky goblin with a rusty dagger, the smallest figure of "
                            "the army",
                    "knight": "a goblin rider on a giant cave spider",
                    "bishop": "a goblin hexer with a bubbling cauldron on its back and a "
                              "crooked staff",
                    "rook": "a goblin clockwork siege machine on rickety wheels",
                    "queen": "a goblin witch queen in a crown of mushrooms",
                    "king": "a fat goblin king on a throne carried by a cave ogre, the "
                            "largest and most imposing figure of the army",
                },
            },
        },
    },
    "olympus_titans": {
        "name": "Olympus and Titans",
        "lore": "Greek myth: the shining gods of Olympus against the monstrous Titans",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Gods of Olympus",
                "look": "white marble skin tones, white chitons, gold laurel and armor, "
                        "glowing lightning and sunlight",
                "units": {
                    "pawn": "a young hoplite with a round bronze shield and a spear, the "
                            "smallest figure of the army",
                    "knight": "a hero riding the winged horse Pegasus",
                    "bishop": "Apollo with a golden lyre and a sun-ray crown",
                    "rook": "a bronze giant automaton guardian like Talos",
                    "queen": "Athena with a crested helmet, an owl and a golden spear",
                    "king": "Zeus with a flowing beard holding a crackling thunderbolt, the "
                            "largest and most imposing figure of the army",
                },
            },
            "evil": {
                "name": "Titans of Tartarus",
                "look": "dark grey stone-like skin, black bronze, glowing magma cracks and "
                        "storm-dark colors",
                "units": {
                    "pawn": "a one-eyed young cyclops with a club, the smallest figure of "
                            "the army",
                    "knight": "a centaur raider with a black bow",
                    "bishop": "a gorgon with a crown of hissing snakes",
                    "rook": "a hundred-handed giant with many arms",
                    "queen": "a many-headed hydra",
                    "king": "Kronos, a towering Titan with a great scythe and a dark crown, "
                            "the largest and most imposing figure of the army",
                },
            },
        },
    },
    "valhalla": {
        "name": "Valhalla",
        "lore": "Norse myth: the gods of Valhalla against the northern warriors of Hel "
                "and the frost",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "Gods of Valhalla",
                "look": "gold and silver armor, white furs, glowing runes, warm golden "
                        "light of the great hall",
                "units": {
                    "pawn": "a young einherjar warrior with a round shield and an axe, the "
                            "smallest figure of the army",
                    "knight": "a Valkyrie riding a winged white horse",
                    "bishop": "a rune-priest seer with two ravens",
                    "rook": "Heimdall with the great horn Gjallarhorn, standing guard",
                    "queen": "Freya in a falcon-feather cloak in a chariot pulled by two "
                             "large cats",
                    "king": "one-eyed Odin on his eight-legged horse Sleipnir with the spear "
                            "Gungnir, the largest and most imposing figure of the army",
                },
            },
            "evil": {
                "name": "Raiders of Hel",
                "look": "dark iron, black furs, frost-blue skin, rotting leather and glowing "
                        "icy blue eyes",
                "units": {
                    "pawn": "a draugr undead viking with a broken sword, the smallest figure "
                            "of the army",
                    "knight": "a berserker riding a huge black wolf",
                    "bishop": "a dark seiðr witch with a staff of bones",
                    "rook": "a hulking frost giant",
                    "queen": "Hel, half beautiful queen and half skeleton",
                    "king": "Loki the trickster in a horned helmet leading the giant wolf "
                            "Fenrir, the largest and most imposing figure of the army",
                },
            },
        },
    },
    "wizards": {
        "name": "Wizards",
        "lore": "a war of magic: white wizards of light against black wizards of shadow",
        "view": "side",
        "mirror": False,
        "sides": {
            "good": {
                "name": "White Council",
                "look": "white and silver robes with gold embroidery, glowing pale blue and "
                        "golden magic light, staffs of white wood and crystal",
                "units": {
                    "pawn": "a young apprentice wizard holding a small glowing wand, the "
                            "smallest figure of the army",
                    "knight": "a wizard knight riding a winged pegasus",
                    "bishop": "an old sage wizard reading a floating glowing spellbook",
                    "rook": "a summoned crystal golem with glowing runes",
                    "queen": "an enchantress casting a swirl of golden light from both hands",
                    "king": "an archmage with a long white beard, a tall pointed hat and a "
                            "sunstone staff, the largest and most imposing figure of the army",
                },
            },
            "evil": {
                "name": "Black Circle",
                "look": "black and deep violet robes with tarnished silver, glowing green "
                        "and violet shadow magic, staffs of black bone",
                "units": {
                    "pawn": "a hunched cultist acolyte in a black hood with a candle, the "
                            "smallest figure of the army",
                    "knight": "a death rider on a skeletal horse",
                    "bishop": "a necromancer with a skull-topped staff raising green smoke",
                    "rook": "a hulking shadow golem of black stone and chains",
                    "queen": "a witch in a black gown with ravens and violet fire",
                    "king": "a dark lord sorcerer in spiked black armor and a horned crown "
                            "with a staff of violet fire, the largest and most imposing "
                            "figure of the army",
                },
            },
        },
    },
}


PAWN_TAIL = ", the smallest figure of the army"
KING_TAIL = ", the largest and most imposing figure of the army"

# Pilot worlds from docs/lab/worlds-catalog.md, pawn and king only so far:
# (id, name, lore, view, (good name, look, pawn, king), (evil name, look, pawn, king)).
CATALOG = [
    ("heaven_hell", "Heaven and Hell", "the war of heaven and hell", "side",
     ("Host of Heaven", "white feathers, gold armor, soft halo light",
      "a small cherub with tiny wings and a little golden spear",
      "an archangel with six great white wings and a flaming sword"),
     ("Legions of Hell", "red and black skin, horns, bat wings, hellfire",
      "a small horned imp with a pitchfork",
      "a huge horned demon lord with bat wings and a burning whip")),
    ("japan", "Japan", "Japanese legend: samurai and kami against oni and yokai", "side",
     ("Clan of the Rising Sun", "lacquered red and gold samurai armor, cherry blossoms, "
      "warm dawn light",
      "a young ashigaru spearman with a conical hat",
      "a samurai shogun in ornate armor riding a white kitsune fox with nine tails"),
     ("Yokai Night Parade", "dark indigo and crimson, ragged robes, glowing paper "
      "lanterns, horns",
      "a small mischievous kappa with a water dish on its head",
      "a giant red oni with a spiked iron club and tiger-skin loincloth")),
    ("china", "China", "Chinese legend: the Jade Emperor against the demons", "side",
     ("Jade Court", "jade green and imperial gold, silk robes, cloud patterns",
      "a young terracotta-style spearman with a jade shield",
      "the Jade Emperor riding a golden qilin")),
    ("slavic", "Slavic Myth", "Slavic myth: Perun and the bright gods against Veles, "
     "devils and Baba Yaga", "side",
     ("Perun's Host", "white linen with red embroidery, gold, oak leaves, lightning",
      "a young Slavic warrior with an axe and a round painted shield",
      "Perun, the thunder god with a flowing beard and a lightning axe on a war "
      "chariot"),
     ("Veles' Swamp", "dark moss green, black fur, horns, bog fog and will-o'-wisps",
      "a little furry devil čert with horns and a tail",
      "a three-headed fire-breathing zmey dragon")),
    ("arthurian", "Camelot", "Arthurian legend: Camelot against Morgan le Fay", "side",
     ("Knights of Camelot", "shining steel, blue and gold heraldry, the holy grail glow",
      "a young squire with a spear",
      "King Arthur raising Excalibur, with a golden crown and a red dragon cloak"),
     ("Morgan's Shadow", "black and dark green, thorns, mist, sickly violet magic",
      "a hunched thorn goblin",
      "the Black Knight on a black horse in spiked armor")),
    ("aztec", "Aztec Myth", "Aztec myth: the feathered serpent against the night "
     "jaguar god", "side",
     ("Children of Quetzalcoatl", "turquoise, jade, bright green quetzal feathers and "
      "gold",
      "a young eagle warrior with a feathered shield",
      "Quetzalcoatl, a giant feathered serpent with turquoise plumes"),
     ("Night of Tezcatlipoca", "obsidian black, jaguar spots, blood red, smoking "
      "mirrors",
      "a skeletal tzitzimitl star demon",
      "Tezcatlipoca, a god with a smoking obsidian mirror riding a giant black "
      "jaguar")),
    ("sea", "The Deep", "an undersea war: Atlantis against the Kraken", "top",
     ("Atlantis", "pearl white, turquoise and gold, glowing coral",
      "a small seahorse rider with a trident",
      "a giant white whale carrying a golden Atlantean palace on its back"),
     ("Kraken's Abyss", "dark purple and black, bioluminescent green, barnacles",
      "a small spiny anglerfish with a glowing lure",
      "the Kraken, a gigantic octopus with many spread tentacles")),
    ("ice_fire", "Ice and Fire", "a cosy fairy tale for children: the snow kingdom "
     "against the fire imps", "side",
     ("Snow Kingdom", "white snow, pale blue ice crystals, soft glowing frost",
      "a cute little snowman with a carrot nose and a twig sword",
      "a majestic snow unicorn with an ice crystal horn and a snowflake crown"),
     ("Fire Imps", "glowing orange and red flames, charcoal, sparks, cute but "
      "mischievous",
      "a cute little fire sprite with a flame for hair",
      "a big lava dragon with a crown of flames")),
    ("insects", "Insects", "a war in the garden for children: bees and ladybirds "
     "against wasps and spiders", "side",
     ("Garden Guard", "sunny yellow, honey gold, red with black dots, flower petals",
      "a small cute ladybird soldier with a pea-pod shield",
      "a queen bee with a crown riding a big fluffy bumblebee")),
    ("cats_dogs", "Cats and Dogs", "a playful war for children: the cats against "
     "the dogs", "side",
     ("Cat Kingdom", "soft fur in cream, ginger and grey, golden collars, cute",
      "a small kitten soldier with a yarn ball shield",
      "a fat royal cat king with a crown and a red velvet cape on a cushion throne"),
     ("Dog Pack", "brown, black and white fur, studded collars, cute but rowdy",
      "a small puppy soldier with a bone sword",
      "a big bulldog king with a crown and a spiked collar")),
    ("sweets", "Sweets and Veggies", "a funny war for children: candy against "
     "vegetables", "side",
     ("Candy Land", "pastel pink, glossy sugar, frosting, sprinkles, gingerbread",
      "a little gingerbread soldier with a candy cane spear",
      "a cake king with a cherry crown riding a gummy bear dragon"),
     ("Veggie Patch", "fresh green, orange and purple vegetables, soil, leaves",
      "a little angry pea pod soldier",
      "a giant broccoli king with a carrot scepter")),
    ("dinosaurs", "Dinosaurs", "prehistoric war: the herbivores against the "
     "predators", "side",
     ("Herd of the Valley", "earthy greens, sandy beige, ferns, warm sunlight",
      "a small baby triceratops",
      "a huge brachiosaurus with a long neck")),
    ("steampunk", "Steampunk", "a steampunk sky war: the brass airship fleet against "
     "the iron smoke armada", "top",
     ("Brass Fleet", "polished brass and copper, white canvas balloons, gold gears",
      "a small one-man brass ornithopter",
      "a grand brass airship with large white balloons and propellers"),
     ("Iron Armada", "black iron, rust, soot, red glowing furnaces",
      "a small iron mechanical spider drone with rotors",
      "a huge black iron dreadnought airship belching smoke")),
    ("scifi", "Star Guardians", "a science fiction war: guardian mechs of light "
     "against an alien swarm", "top",
     ("Light Guardians", "white and gold armor plates, glowing cyan energy",
      "a small white scout drone",
      "a huge white and gold guardian mothership")),
]
_EVIL_FILL = {
    "china": ("Demon Horde", "dark red, black, tattered robes, green ghost fire",
              "a hopping jiangshi vampire in a Qing robe with a paper talisman",
              "a black destroyer dragon with burning red eyes"),
    "insects": ("Wasp Swarm", "black and acid yellow stripes, dark webs, red eyes",
                "a small spiky wasp soldier with a stinger lance",
                "a giant spider queen with a crown of thorns"),
    "dinosaurs": ("Pack of Predators", "dark green and blood red scales, sharp teeth, "
                  "volcanic sky",
                  "a small raptor with sharp claws",
                  "a huge tyrannosaurus rex with a roaring mouth"),
    "scifi": ("Alien Swarm", "dark purple chitin, glowing green bio-lights, slime",
              "a small alien bug drone",
              "a huge alien hive queen ship"),
}


def _catalog_world(entry):
    world_id, name, lore, view, *sides = entry
    if len(sides) == 1:
        sides.append(_EVIL_FILL[world_id])
    out = {"name": name, "lore": lore, "view": view, "mirror": False, "sides": {}}
    for key, (side_name, look, pawn, king) in zip(("good", "evil"), sides):
        out["sides"][key] = {"name": side_name, "look": look,
                             "units": {"pawn": pawn + PAWN_TAIL, "king": king + KING_TAIL}}
    return world_id, out


WORLDS.update(_catalog_world(entry) for entry in CATALOG)


def prompt_for(world_id, color, unit):
    world = WORLDS[world_id]
    side = world["sides"][SIDE_OF_COLOR[color]]
    role = side["units"][unit]
    intro = (f"Game sprite of {role}, one unit of the \"{side['name']}\" from a world of "
             f"{world['lore']}.\n")
    if world["view"] == "top":
        symmetric = "symmetrical from left to right, " if world["mirror"] else ""
        return intro + (
            "Viewed from DIRECTLY OVERHEAD: strict 90-degree top-down orthographic view "
            "with zero perspective and zero tilt. "
            + TOP_DIRECTION.format(subject="It") + "\n"
            "One single subject, drawn large and highly detailed, centered, with a clear "
            "empty margin on every side.\n"
            f"Look: {side['look']}.\n"
            f"Bold readable silhouette that stays recognizable at small size, {symmetric}"
            "polished digital painting with crisp clean edges.\n"
            "It floats in empty air, evenly lit from every side. "
            "The background is one flat solid neutral mid-gray color, completely plain "
            "and empty. No text."
        )
    return intro + (
        "A painted tabletop wargame miniature standing on a small round base, shown in "
        "STRICT SIDE PROFILE, facing RIGHT, orthographic with no perspective.\n"
        "The whole figure, from the tip of its highest crown, horn or weapon down to its "
        "base, fits inside the frame with a wide empty margin of gray on every side; "
        "nothing touches the edges.\n"
        f"Look: {side['look']}.\n"
        "Bold readable silhouette that stays recognizable at small size, a static heroic "
        "pose, polished digital painting with crisp clean edges.\n"
        "Evenly lit from every side, no cast shadow. "
        "The background is one flat solid neutral mid-gray color, completely plain and "
        "empty. No text."
    )


def seed_for(world_id, color, unit):
    """Stable seed per unit, so a re-run reproduces the same design."""
    h = 2166136261
    for ch in f"{world_id}/{SIDE_OF_COLOR[color]}/{unit}":
        h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return h
