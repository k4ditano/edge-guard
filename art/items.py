"""The things that are picked up, made, worn and thrown, as pixel art of
16 × 16: each one written out pixel by pixel, eight to a row of the sheet,
which always has ten rows. A letter is a colour of that thing's own palette;
a dot is nothing. The order is the game's: a new thing goes at the end."""
import os
from PIL import Image
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pieces", "items.png")

WOOD = dict(o="#2a1c0c", d="#5a3d1e", m="#7a552a", l="#a37a44")
def metal(o, d, m, l, w):
    return dict(o=o, d=d, m=m, l=l, w=w)
IRON = metal("#2f3338", "#6f777e", "#a9b1b8", "#d6dce1", "#ffffff")
DIAMOND = metal("#0d3b38", "#1f9f95", "#4ee6d6", "#a8fff2", "#ffffff")
TIMBER = metal("#2a1c0c", "#5a3d1e", "#8a6233", "#b8945f", "#d9b888")
GOLD = metal("#5a3a08", "#c28a12", "#f2c832", "#ffe97a", "#ffffff")
NETHERITE = metal("#141016", "#2e2832", "#4a4350", "#6e6676", "#9a90a4")
FROST = metal("#1a3a5a", "#4a8ac0", "#8ac4ee", "#c4e6ff", "#ffffff")

def sword(blade):
    pal = dict(blade, h="#5a3d1e", g="#3a2a14", k="#8a6a2a", K="#c9a24a")
    return ["................",
            ".............ooo",
            "............olwo",
            "...........olmlo",
            "..........olmlo.",
            ".........olmlo..",
            "........olmlo...",
            "..oo...olmlo....",
            "..oKo.olmdo.....",
            "...oKolmdo......",
            "....oKmdo.......",
            "...ohoKKo.......",
            "..ohgo.oKo......",
            ".ohgo...oo......",
            ".ogo............",
            "..o............."], pal

def chestplate(m):
    return ["................",
            ".ooo......ooo...",
            "olmmo....ommlo..",
            "olmmmooooommlo..",
            "olmmmllllmmmdo..",
            "oodmmmmmmmmdoo..",
            ".oodmmmmmmdoo...",
            "..olmmllmmdo....",
            "..olmmlmmmdo....",
            "..olmmmmmmdo....",
            "..olmmmmmmdo....",
            "..oddmmmmddo....",
            "..oodddddooo....",
            "...oooooooo.....",
            "................",
            "................"], m

def bow(glint, wood=None):
    pal = dict(o="#2a1c0c", d="#5a3d1e", m="#8a5a2b", l="#b98548", s="#e8e2d0", S="#b8b2a2", g=glint or "#8a5a2b", G=glint and "#f2c9ff" or "#b98548")
    if wood:
        pal.update(o=wood["o"], d=wood["d"], m=wood["m"], l=wood["l"], G=wood["w"])
    return ["................",
            "......oooo......",
            "....oolmmdoS....",
            "...olmdoo..S....",
            "..olmdo....S....",
            "..omdo.....s....",
            ".olgo......s....",
            ".omGo......s....",
            ".omGo......s....",
            ".olgo......s....",
            "..omdo.....s....",
            "..olmdo....S....",
            "...olmdoo..S....",
            "....oolmmdoS....",
            "......oooo......",
            "................"], pal

def flask(dark, mid, light):
    pal = dict(o="#1f2a30", g="#a9c4cc", G="#e6f4f7", c="#8a6233", C="#b8945f", d=dark, m=mid, l=light)
    return ["................",
            "......oooo......",
            "......oCco......",
            "......oooo......",
            "......oGgo......",
            ".....ooGgoo.....",
            "....oGGgggdo....",
            "...oGlmmmmddo...",
            "...olmmmmmmdo...",
            "..olmmlmmmmddo..",
            "..olmlmmmmmmdo..",
            "..ommmmmmmmddo..",
            "...ommmmmmddo...",
            "...oddmmmddo....",
            "....oooooooo....",
            "................"], pal

def heart(a, b, shine):
    pal = dict(o="#1a0a0a", a=a, b=b, s=shine, A=a if a == "#3a1512" else "#a81d16", B=b if b == "#3a1512" else "#a81d16")
    return ["................",
            "................",
            "..ooo....ooo....",
            ".oasaoo.obbbo...",
            "oasaaaoobbbbbo..",
            "oaaaaaabbbbbbo..",
            "oaaaaaabbbbbbo..",
            "oAaaaaabbbbbBo..",
            ".oAaaaabbbbBo...",
            "..oAaaabbbBo....",
            "...oAaabbBo.....",
            "....oAabBo......",
            ".....oABo.......",
            "......oo........",
            "................",
            "................"], pal

def ingot(m):
    return ["................", "................", "................", "....ooooooooo...", "...olwlllllldo..", "..olwllllllmdo..", ".olmmmmmmmmddo..", "olmmmmmmmmmdoo..",
            "ommmmmmmmmddo...", "oddddddddddo....", ".oooooooooo.....", "................", "................", "................", "................", "................"], m

def lump(m):
    """Something raw, as it comes out of the rock."""
    return ["................",
            "................",
            ".....oooo.......",
            "....olllmoo.....",
            "...olwlmmmdo....",
            "..olllmmmmddo...",
            "..olmmmmlmmdo...",
            ".olmmmdmmmmmdo..",
            ".ommmmmmmmdmdo..",
            ".omdmmmlmmmddo..",
            ".oddmmmmmmddo...",
            "..oddmmdmddo....",
            "...oodddddo.....",
            ".....ooooo......",
            "................",
            "................"], m

def helmet(m):
    return ["................",
            "................",
            "....oooooooo....",
            "...ollllllmmo...",
            "..olwllmmmmmdo..",
            "..olllmmmmmmdo..",
            ".ollmmmmmmmmmdo.",
            ".olmmmmmmmmmmdo.",
            ".olmmmoooommmdo.",
            ".olmmo....ommdo.",
            ".olmdo....omddo.",
            ".oddo......oddo.",
            "..oo........oo..",
            "................",
            "................",
            "................"], m

def boots(m):
    return ["................",
            "................",
            "................",
            "..ooooo..ooooo..",
            "..ollmo..ollmo..",
            "..olmmo..olmmo..",
            "..olmmo..olmmo..",
            "..olmdo..olmdo..",
            "..olmmoo.olmmoo.",
            ".oolmmmdoolmmmdo",
            ".olmmmmdolmmmmdo",
            ".oddddddoddddddo",
            ".ooooooooooooooo",
            "................",
            "................",
            "................"], m

def pick(head):
    pal = dict(head, h="#8a6233", H="#5a3d1e", k="#2a1c0c")
    return ["................",
            "...ooooooo......",
            "..olllmmmmoo....",
            "...ooooomlmdo...",
            "........khmmdo..",
            ".......khHomdo..",
            "......khHk.omdo.",
            ".....khHk..omdo.",
            "....khHk...omdo.",
            "...khHk....omdo.",
            "..khHk......odo.",
            ".khHk........o..",
            ".kHk............",
            "..k.............",
            "................",
            "................"], pal

def staff(shaft, head):
    """A long stick with something on its end: `head` gives h, H and w."""
    pal = dict(o="#1a1210", K="#ffe27a", k="#c9a24a", l=shaft[0], m=shaft[1], d=shaft[2], **head)
    return ["................",
            "..........oooo..",
            ".........ohhhho.",
            "........ohhwwhho",
            "........ohwwhhHo",
            "........ohhhhHHo",
            ".........ohHHHo.",
            "........oKkooo..",
            ".......oKko.....",
            "......olmo......",
            ".....olmdo......",
            "....olmdo.......",
            "...olmdo........",
            "..olmdo.........",
            ".omdo...........",
            "..oo............"], pal

ICONS = [
    ("stick", ["................", "............oo..", "...........olmo.", "..........olmdo.", ".........olmdo..", "........olmdo...", ".......olmdo....", "......olmdo.....",
               ".....olmdo......", "....olmdo.......", "...olmdo........", "..olmdo.........", ".olmdo..........", ".omdo...........", "..oo............", "................"], WOOD),
    ("iron", ["................", "................", "................", "....ooooooooo...", "...olwlllllldo..", "..olwllllllmdo..", ".olmmmmmmmmddo..", "olmmmmmmmmmdoo..",
              "ommmmmmmmmddo...", "oddddddddddo....", ".oooooooooo.....", "................", "................", "................", "................", "................"], IRON),
    ("diamond", ["................", "................", ".....oooooo.....", "....olwllmdo....", "...olwllmmmdo...", "..olwllmmmmmdo..", ".olllmmmmmmmddo.", ".ommmmmlmmmmddo.",
                 ".oddmmmmmmmdddo.", "..oddmmmmmdddo..", "...oddmmmdddo...", "....oddmdddo....", ".....odddo......", "......ooo.......", "................", "................"], DIAMOND),
    ("string", ["................", "..oo.......oo...", ".owwo.....owso..", ".owsooooooowso..", "..owwwwwwwwso...", "...oooosooooo...", "......owso......", ".....owso.......",
                "....owsooooo....", "...owwwwwwwso...", "...owsoooowso...", "...owso..owso...", "....oo...owso...", ".........owso...", "..........oo....", "................"], dict(o="#3a3a3a", w="#f2f2f2", s="#c2c2c2")),
    ("bone", ["................", "..........oo.oo.", ".........olwolwo", ".........olwwwso", "..........owwso.", ".........owwso..", "........owwso...", ".......owwso....",
              "......owwso.....", ".....owwso......", "....owwso.......", ".oo.owso........", "olwowwso........", "olwwwso.........", ".osoosso........", "..o..oo........."], dict(o="#3a382f", w="#f6f3ea", l="#ffffff", s="#c9c5b5")),
    ("gunpowder", ["................", "................", "........oo......", ".......odmo.....", "....oo.ommo.oo..", "...odmoodmoodmo.", "...ommmmmmmmmo..", "..oodmlmmmdmmoo.",
                   ".odmmmmmlmmmmdo.", ".ommlmmmmmmlmmo.", "odmmmmdmmmmmmmdo", "ommmlmmmmlmmdmmo", "oddmmmmdmmmmmddo", ".oodddddddddddo.", "...ooooooooooo..", "................"], dict(o="#151515", d="#2f2f2f", m="#4a4a4a", l="#6e6e6e")),
    ("flesh", ["................", "................", "....ooooo.......", "...olmmmdooo....", "..olmmgmmmmdo...", ".olmmmmmmbmmdo..", ".ommbmmmmmmmdo..", "olmmmmmgmmmmmdo.",
               "ommmmmmmmmmbmdo.", "odmmgmmmmmmmmdo.", ".odmmmmbmmgmdo..", ".oddmmmmmmmddo..", "..ooddmmmdddo...", "....ooddddoo....", "......oooo......", "................"], dict(o="#2a120a", d="#7a2f1a", m="#b5502f", l="#d97a52", b="#5e2212", g="#6f8a3a")),
    ("slimeball", ["................", "................", ".....oooooo.....", "...oolllmmdoo...", "..olwwllmmmmdo..", ".olwwlmmmmmmmdo.", ".olwlmmmmmmmmdo.", "olllmmmmmmmmmddo",
                   "olmmmmmmmmmmmddo", "ommmmmmmmmmmdddo", "ommmmmmmmmmddddo", ".ommmmmmmmdddddo", ".odmmmmmmddddo..", "..ooddddddddo...", "....oooooooo....", "................"], dict(o="#17320f", d="#3f8a2f", m="#6fbf5a", l="#a6e88e", w="#e4ffd6")),
    ("pearl", ["................", "................", ".....oooooo.....", "...oodmmmmdoo...", "..odmmllllmmdo..", ".odmllwwllmmmdo.", ".omllwlllmmmmdo.", "odmllllmmmmmmddo",
               "omllmmmmmmmmdddo", "ommmmmmmmmmddddo", "odmmmmmmmmdddddo", ".odmmmmmmdddddo.", ".oddmmmddddddo..", "..oodddddddoo...", "....ooooooo.....", "................"], dict(o="#04201d", d="#0f4a44", m="#1f7d73", l="#3fb8aa", w="#a8fff2")),
    ("iron_sword",) + sword(IRON),
    ("diamond_sword",) + sword(DIAMOND),
    ("iron_chest",) + chestplate(IRON),
    ("diamond_chest",) + chestplate(DIAMOND),
    ("bow",) + bow(None),
    ("power_bow",) + bow("#c94fd8"),
    ("wand", ["................", "...........ooo..", "..........olwlo.", ".........olwmmdo", ".........olmmmdo", ".........odmmdo.", "........oKooo...", ".......oKko.....",
              "......olmo......", ".....olmdo......", "....olmdo.......", "...olmdo........", "..olmdo.........", ".olmdo..........", ".omdo...........", "..oo............"], dict(WOOD, w="#a8fff2", K="#c9a24a", k="#8a6a2a", **{"l": "#3fb8aa", "m": "#1f7d73", "d": "#0f4a44"})),
    ("tnt", ["................", ".oooooooooooooo.", ".orRrRrrRrRrrRo.", ".orRrRrrRrRrrRo.", ".orRrRrrRrRrrRo.", ".owwwwwwwwwwwwo.", ".owkkkwkwkwkkko.", ".owwkwwkkkwwkwo.",
             ".owwkwwkwkwwkwo.", ".owwkwwkwkwwkwo.", ".owwwwwwwwwwwwo.", ".orRrRrrRrRrrRo.", ".orRrRrrRrRrrRo.", ".orRrRrrRrRrrRo.", ".oooooooooooooo.", "................"], dict(o="#3a0f0c", r="#d8352a", R="#a8251d", w="#f2f2f2", k="#1a1a1a")),
    ("heal_potion",) + flask("#a81d3a", "#f2587a", "#ffb3c4"),
    ("cobweb", ["o......oo......o", ".w.....ww.....w.", "..w...wwww...w..", "...wwww..wwww...", "...w.ww..ww.w...", "..ww..wwww..ww..", ".ww...w..w...ww.", "owwwwww..wwwwwwo",
                "owwwwww..wwwwwwo", ".ww...w..w...ww.", "..ww..wwww..ww..", "...w.ww..ww.w...", "...wwww..wwww...", "..w...wwww...w..", ".w.....ww.....w.", "o......oo......o"], dict(o="#9a9a9a", w="#f2f2f2")),
    ("collar", ["................", "................", "....oooooooo....", "..oorrrrrrrroo..", ".orRrooooooRrro.", ".orro......orro.", "orRo........oRro", "orro........orro",
                "orRo........oRro", ".orro......orro.", ".orRrooooooRrro.", "..oorrrgGrrroo..", "....oooGgooo....", "......ogGo......", ".......oo.......", "................"], dict(o="#3a0f0c", r="#d8352a", R="#a8251d", g="#c9a24a", G="#ffe27a")),
    ("slime_charm", ["................", "......oooo......", ".....osssso.....", "....os....so....", "....os....so....", ".....os..so.....", "......oooo......", ".....olllmo.....",
                     "....olwlmmdo....", "...olwlmmmmdo...", "...olmmmmmmdo...", "...ommmmmmddo...", "....odmmmddo....", ".....oddddo.....", "......oooo......", "................"], dict(o="#17320f", s="#c9cdd0", d="#3f8a2f", m="#6fbf5a", l="#a6e88e", w="#e4ffd6")),
    ("ender_charm", ["................", "................", ".....oooooo.....", "...oogmmmmgoo...", "..ogmmlllmmmgo..", ".ogmllkkkllmmgo.", ".omllkkpkkllmmo.", "ogmlkkpPpkklmmgo",
                     "ogmlkkpppkklmmgo", ".omllkkkkkllmmo.", ".ogmllkkkllmmgo.", "..ogmmlllmmmgo..", "...oogmmmmgoo...", ".....oooooo.....", "................", "................"], dict(o="#04201d", g="#2a6b3a", m="#3f9a4a", l="#8fd67a", k="#0d1a12", p="#1f7d73", P="#a8fff2")),
    ("potion",) + flask("#7a1f8a", "#c94fd8", "#f2c9f7"),
    ("wood_sword",) + sword(TIMBER),
    ("arrow", ["................", "...........ooooo", "...........owwlo", "...........owlmo", "..........oolmdo", ".........olmoooo", "........olmo....", ".......olmo.....",
               "......olmo......", ".....olmo.......", "..o.olmo........", ".owoomo.........", "owwwoo..........", ".owwwo..........", "..owo...........", "...o............"], dict(o="#2a1c0c", l="#a37a44", m="#7a552a", w="#f2f2f2", d="#8f979e")),
    ("orb", ["................", "................", "................", ".....oooooo.....", "....ogllllgo....", "...ogllwwllgo...", "...ollwwwlllo...", "...ollwwllllo...",
             "...olllllllgo...", "...ogllllllgo...", "....ogllllgo....", ".....oggggo.....", "......oooo......", "................", "................", "................"], dict(o="#3a6b12", g="#7fd92e", l="#c8ff7a", w="#ffffff")),
    ("heart",) + heart("#e0281e", "#e0281e", "#ff9a9a"),
    ("heart_half",) + heart("#e0281e", "#3a1512", "#ff9a9a"),
    ("heart_empty",) + heart("#3a1512", "#3a1512", "#3a1512"),
    ("book", ["................", "..oooooooooooo..", ".ogGGGGGGGGGGgo.", ".ogGllllllllGgo.", ".ogGlwwwwwwlGgo.", ".ogGllllllllGgo.", ".ogGGGGGGGGGGgo.", ".ogGGGGkkGGGGgo.",
              ".ogGGGkKKkGGGgo.", ".ogGGGGkkGGGGgo.", ".ogGGGGGGGGGGgo.", ".ogggggggggggpo.", ".oPPPPPPPPPPPpo.", ".oooooooooooooo.", "................", "................"], dict(o="#10300c", g="#2f7d1f", G="#4aa838", l="#8fd67a", w="#e4ffd6", k="#c9a24a", K="#ffe27a", p="#c9c5b5", P="#f6f3ea")),

    # ── what the mine, the lands and their lords give, and what is made of it ──
    ("raw_iron",) + lump(dict(o="#3a2a20", d="#8a6a55", m="#c9a58a", l="#e8cdb8", w="#fff2e6")),
    ("raw_gold",) + lump(dict(o="#5a3a08", d="#b07a10", m="#e8b830", l="#ffe27a", w="#fff7c9")),
    ("gold",) + ingot(GOLD),
    ("coal", ["................", "................", "......ooooo.....", "....ooddmmdo....", "...odmmlwmmdo...", "..odmmllmmmdo...", "..ommmmmmmdddo..", ".odmmmmmmlmddo..",
              ".ommdmmmmmmmdo..", ".odmmmmdmmmddo..", "..oddmmmmmddo...", "..oodddmdddo....", "....oodddoo.....", "......ooo.......", "................", "................"], dict(o="#050505", d="#1a1a1a", m="#303030", l="#555555", w="#8a8a8a")),
    ("lapis", ["................", "................", ".......oooo.....", ".....oollmdo....", "....olwlmmmdo...", "...olwlmmmmdo...", "...ollmmmdmmdo..", "..olmmmmmmmmdo..",
               "..ommmdmmmmddo..", "..odmmmmmlmddo..", "...odmmmmmddo...", "...oddmmdddo....", "....ooddddo.....", "......oooo......", "................", "................"], dict(o="#0a1a4a", d="#1a3a9a", m="#2f5fd0", l="#6a94f0", w="#c4d6ff")),
    ("redstone", ["................", "................", "................", "................", ".......oo.......", "......orRo..oo..", "..oo.orRrro.oro.", ".orrooRrRRroo...",
                  ".oRo.orRrRRro...", "..o.orRrwRrRro..", "...orRrRRrRrRo..", "..orRRrRrRRrRro.", ".orrRrRRrRrRRro.", ".oooooooooooooo.", "................", "................"], dict(o="#3a0606", r="#c41a1a", R="#ff3a2a", w="#ff9a8a")),
    ("ice", ["................", "...........oo...", "..........olwo..", ".........olwlo..", "........olwllo..", ".......olwlmdo..", "......olwlmmdo..", ".....olwlmmdo...",
             "....olwlmmdo....", "...ollmmmdo.....", "..olmmmmdo......", "..ommmddo.......", "..oddddo........", "...oooo.........", "................", "................"], FROST),
    ("blaze_rod", ["................", "............oo..", "...........olwo.", "..........olmdo.", ".........olmdo..", "........olwdo...", ".......olmdo....", "......olmdo.....",
                   ".....olwdo......", "....olmdo.......", "...olmdo........", "..olwdo.........", ".olmdo..........", ".omdo...........", "..oo............", "................"], dict(o="#5a2a00", d="#c46a00", m="#f2a81e", l="#ffd23a", w="#fff7c9")),
    ("scrap", ["................", "................", "....oo..........", "...olmo..ooo....", "...ommdoolmdo...", "..olmmmmmmmdo...", "..ommdmmmlmmdo..", ".olmmmmmmmmddo..",
               ".ommmlmmdmmdo...", ".oddmmmmmmmdo...", "..oodmmdmmddo...", "....odmmmddo....", "....oodddoo.....", "......ooo.......", "................", "................"], dict(o="#1a100e", d="#3a2622", m="#5a3d36", l="#8a6a5e")),
    ("wheat", ["................", "..oo....oo...oo.", ".oYYo..oYYo.oYYo", ".oyYo..oyYo.oYyo", ".oYyo..oYyo.oyYo", "..oYyo.oyYooYyo.", "..oyYo.oYyooyo..", "...oyYooyooyo...", "....oyYoyoyo....", ".....oyyyyo.....", ".....ogggo......", ".....oyyyo......", "....oyoyoyo.....", "...oyo.o.oyo....", "...oo.....oo....", "................"], dict(o="#4a3a08", y="#d9b03a", Y="#f7e08a", g="#7a9a2a")),
    ("bread", ["................", "................", "................", "................", "....oooooooo....", "..oollllllllmo..", ".ollwllwllwlmmo.", ".olmlmmlmmlmmdo.",
               ".ommmmmmmmmmmdo.", ".ommmmmmmmmmddo.", ".oddmmmmmmmdddo.", "..oodddddddddo..", "....ooooooooo...", "................", "................", "................"], dict(o="#3a2208", d="#8a5a1e", m="#c48a3a", l="#e0b060", w="#f7dfa0")),
    ("iron_block", ["................", ".oooooooooooooo.", ".olllllllllllmo.", ".olwwlllllllmdo.", ".olwmmmmmmmmmdo.", ".ollmmmmmmmmmdo.", ".ollmmmmdmmmmdo.", ".ollmmmmmmmmmdo.",
                    ".ollmmdmmmmmmdo.", ".ollmmmmmmmdmdo.", ".ollmmmmmmmmmdo.", ".olmmmmmmmmmddo.", ".omdddddddddddo.", ".oooooooooooooo.", "................", "................"], IRON),
    ("netherite_sword",) + sword(NETHERITE),
    ("crossbow", ["................", "................", "...oooooooooo...", ".oolmmmkkmmmloo.", "olmdoookKooodmlo", "omdo.s.kK.s.odmo", "omo...sohs...omo", "oo.....oho....oo", ".......oho......", ".......oho......", ".......ohko.....", ".......ohKo.....", ".......oho......", ".......oho......", "........o.......", "................"], dict(o="#2a1c0c", d="#5a3d1e", m="#8a5a2b", l="#b98548", s="#e8e2d0", h="#7a552a", k="#6f777e", K="#d6dce1")),
    ("frost_bow",) + bow("#ffffff", FROST),
    ("blaze_staff",) + staff(("#ffd23a", "#f2a81e", "#c46a00"), dict(h="#ff9a1e", H="#e0501a", w="#fff2a0")),
    ("ender_staff",) + staff(("#6a4a8a", "#3f2a5a", "#241636"), dict(h="#b84ff0", H="#6a1f9a", w="#a8fff2")),
    ("iron_helmet",) + helmet(IRON),
    ("diamond_helmet",) + helmet(DIAMOND),
    ("netherite_helmet",) + helmet(NETHERITE),
    ("iron_boots",) + boots(IRON),
    ("diamond_boots",) + boots(DIAMOND),
    ("netherite_boots",) + boots(NETHERITE),
    ("netherite_chest",) + chestplate(NETHERITE),
    ("wood_pick",) + pick(TIMBER),
    ("iron_pick",) + pick(IRON),
    ("diamond_pick",) + pick(DIAMOND),
    # ── what each lord leaves ──
    ("crown", ["................", "................", "................", ".oo...oo...oo...", "oyYo.oyYo.oyYo..", "oyYooyYYyooYyo..", "oyYYyYrrYyYYyo..", "oyrYYYrrYYYryo..",
               "oyYYYYYYYYYYyo..", "oydyyyyyyyyydo..", "oddddddddddddo..", ".oooooooooooo...", "................", "................", "................", "................"], dict(o="#5a3a08", y="#f2c832", Y="#ffe97a", d="#c28a12", r="#d8352a")),
    ("scarab", ["................", "......o..o......", ".....oo..oo.....", "....ooyyyyoo....", "...oyyYYYYyyo...", "..o.oyYbbYyo.o..", ".oo.oyyyyyyo.oo.", "..ooyYYooYYyoo..",
                "...oyYyooyYyo...", ".oooyYyooyYyooo.", ".o..oyYooYyo..o.", "....oyYooYyo....", "...oooyyyyooo...", "...o..oooo..o...", "................", "................"], dict(o="#3a2a08", y="#c9a24a", Y="#f2d98a", b="#1fd0c0")),
    ("slime_core", ["................", "................", ".....oooooo.....", "...oolllmmdoo...", "..olwwllmmmmdo..", ".olwlhhmmhhmmdo.", ".ollhHHhhHHhmdo.", "olmmhHWHHHHhmddo",
                    "olmmhHHHHHHhmddo", "ommmmhHHHHhmdddo", "ommmmmhHHhmmdddo", ".ommmmmhhmmdddo.", ".odmmmmmmddddo..", "..ooddddddddo...", "....oooooooo....", "................"], dict(o="#17320f", d="#3f8a2f", m="#6fbf5a", l="#a6e88e", w="#e4ffd6", h="#0d4a2a", H="#1fd06a", W="#b8ffd6")),
    ("frost_string", ["................", "..oo.......oo...", ".owwo.....owso..", ".owsooooooowso..", "..owwwwwwwwso...", "...oooosooooo...", "......owso......", ".....owso.......",
                      "....owsooooo....", "...owwwwwwwso...", "...owsoooowso...", "...owso..owso...", "....oo...owso...", ".........owso...", "..........oo....", "................"], dict(o="#1a3a5a", w="#e4f4ff", s="#8ac4ee")),
    ("magma_heart", ["................", "................", "..ooo....ooo....", ".odddoo.odddo...", "odmymdoodmmmdo..", "odmmymmmmymmdo..", "odmmmymmymmmdo..", "oDmmyYyyYmmmDo..",
                     ".oDmmmyYmmmDo...", "..oDmmmymmDo....", "...oDmmymDo.....", "....oDmmDo......", ".....oDDo.......", "......oo........", "................", "................"], dict(o="#1a0505", d="#6a1a12", D="#3a0a08", m="#9a2a1c", y="#ff9a1e", Y="#ffe27a")),
    ("giant_eye", ["................", "................", ".....oooooo.....", "...oogmmmmgoo...", "..ogmmlllmmmgo..", ".ogmllkkkllmmgo.", ".omllkkpkkllmmo.", "ogmlkkpPpkklmmgo",
                   "ogmlkkpppkklmmgo", ".omllkkkkkllmmo.", ".ogmllkkkllmmgo.", "..ogmmlllmmmgo..", "...oogmmmmgoo...", ".....oooooo.....", "................", "................"], dict(o="#1a0626", g="#4a1a6a", m="#7a2fb0", l="#d49af7", k="#12061a", p="#e079fa", P="#ffffff")),
    # ── what brings someone to the camp, and what keeps one standing ──
    ("totem", ["................", ".....oooooo.....", "....oyYYYYyo....", "....oYgYYgYo....", "....oYYYYYYo....", "..ooooyddyoooo..", ".oyYooyYYyooYyo.", ".oyyyyyYYyyyyyo.",
               "..ooooyYYyoooo..", ".....oyYYyo.....", ".....oyYYyo.....", "....oyyYYyyo....", "....oyYddYyo....", "....oyyooyyo....", ".....oo..oo.....", "................"], dict(o="#5a3a08", y="#e0b020", Y="#ffe97a", d="#b07a10", g="#1fd06a")),
    ("bell", ["................", ".......oo.......", "......oyyo......", ".....oooooo.....", "....oyYYyydo....", "...oyYwYyyydo...", "...oyYYyyyydo...", "..oyYYyyyyyydo..",
              "..oyYyyyyyyydo..", "..oyYyyyyyyydo..", ".oyYYyyyyyyyydo.", ".oyyyyyyyyydddo.", ".oooooooooooooo.", "......oddo......", ".......oo.......", "................"], dict(o="#5a3a08", y="#f2c832", Y="#ffe97a", d="#c28a12", w="#ffffff")),
    ("golem_core", ["................", "................", "...oooooooooo...", "..ollllllllmdo..", "..olwllllllmdo..", "..ollmmmmmmmdo..", "..olkkmmmkkmdo..", "..olrrmmmrrmdo..",
                    "..olmmmnnmmmdo..", "..olmmmnnmmmdo..", "..ommgmnnmmddo..", "..omggmmmmmddo..", "..oddgdddddddo..", "...oooooooooo...", "................", "................"], dict(o="#3a3632", d="#8a857a", m="#c2bdb0", l="#e0dcd0", w="#ffffff", r="#e0281e", k="#5a544a", n="#9a8a80", g="#5a8a3a")),
    # ── signs for the panels ──
    ("star", ["................", ".......oo.......", "......oYYo......", "......oYYo......", ".....oYYYYo.....", "ooooooYYYYoooooo", "oyYYYYYYYYYYYYyo", ".oyYYYYYYYYYYyo.",
              "..oyYYYYYYYYyo..", "...oyYYYYYYyo...", "...oyYYYYYYyo...", "..oyYYYyyYYYyo..", "..oyYYyooyYYyo..", ".oyYyoo..ooyYyo.", ".oooo......oooo.", "................"], dict(o="#6a4a08", y="#e0a81e", Y="#ffe04a")),
    ("lock", ["................", ".....oooooo.....", "....olllllso....", "...olsoooolso...", "...olo....oso...", "...olo....oso...", "..oooooooooooo..", "..oyYYYYYYYYDo..",
              "..oyYYYkkYYyDo..", "..oyYYYkkYYyDo..", "..oyYYYYkYYyDo..", "..oyyYYYkYyyDo..", "..oyyyyyyyyDDo..", "..oooooooooooo..", "................", "................"], dict(o="#2a2014", l="#d6dce1", s="#8f979e", y="#e0a81e", Y="#ffe04a", D="#a8741a", k="#2a2014")),
    ("skull", ["................", "....oooooooo....", "...owwwwwwwso...", "..owwwwwwwwsso..", "..owwwwwwwwsso..", "..owkkkwkkkwso..", "..owkkkwkkkwso..", "..owkkwwwkkwso..",
               "..owwwwkwwwsso..", "..oswwkwkwwsso..", "...oswwwwwsso...", "...owkwkwkwso...", "...owowowowso...", "....oooooooo....", "................", "................"], dict(o="#2a2a26", w="#f2efe6", s="#b8b4a6", k="#1a1a18")),
    ("map", ["................", ".oooooooooooooo.", ".oppppPppppPpdo.", ".opgggPpbbbPpdo.", ".opggpPbbbpPpdo.", ".oppppPpbppPpdo.", ".oprppPppppPpdo.", ".opprrPpggpPpdo.",
             ".oppprPgggpPpdo.", ".oppppPrgppPxdo.", ".oppbbPprppxpdo.", ".opbbbPpprxpxdo.", ".oddddddddddddo.", ".oooooooooooooo.", "................", "................"], dict(o="#4a3a1a", p="#f0e2b4", P="#c9b888", d="#a8966a", g="#6aa84a", b="#4a8ac0", r="#b05a50", x="#d8352a")),
    ("tab_craft", ["................", ".oooooooooooooo.", ".oTTtTTTTtTTTTo.", ".oTtTTtTTTTtTTo.", ".oDDDDDDDDDDDDo.", ".omssmmmmmmhhmo.", ".omssmmlmmhhhmo.", ".omssmmmmmmhmmo.",
                   ".omssmmmdmmhmmo.", ".ommsmmmmmmhmmo.", ".olmmmmdmmmhmmo.", ".ommmmmmmmmmmlo.", ".ommdmmmmlmmmmo.", ".oDDDDDDDDDDDDo.", ".oooooooooooooo.", "................"], dict(o="#2a1c0c", T="#c9a870", t="#8a6a3a", D="#4a3320", m="#b8945f", l="#d9b888", d="#7a5c34", s="#c9cdd0", h="#5a3d1e")),
    ("tab_furnace", ["................", ".oooooooooooooo.", ".olmmlmmmmlmmdo.", ".ommmmmdmmmmmdo.", ".omkkkkkkkkkkmo.", ".omkddddddddkmo.", ".omkkkkkkkkkkmo.", ".olmmmmmmmmmmdo.",
                     ".omkkkkkkkkkkmo.", ".omkfFkfFFkfkmo.", ".omkFyFFyFFFkmo.", ".omkyYyyYyyYkmo.", ".omkkkkkkkkkkdo.", ".odddddddddddoo.", ".oooooooooooooo.", "................"], dict(o="#1a1a1a", l="#b0b0b0", m="#8a8a8a", d="#5f5f5f", k="#262626", f="#e0501a", F="#ff9a1e", y="#ffd23a", Y="#fff2a0")),
    ("tab_enchant", ["................", "................", "......p....p....", "...p.....P......", ".ooooooo.ooooooo", "owwwwwwsowwwwwwo", "owkkkkwsowkPkwso", "owwwwwwsowwwwwso",
                     "owkkPkwsowkkkwso", "owwwwwwsowwwwwso", "owkkkwwsowkkkwso", "owwwwwwsowwwwwso", "orrrrrrrorrrrrro", ".ooooooooooooooo", "................", "................"], dict(o="#2a1430", w="#f6f3ea", s="#c9c5b5", k="#8a7a9a", r="#8a1f2a", p="#b84ff0", P="#e8a8ff")),
    ("cup", ["................", "..oooooooooooo..", ".ooyYYYYYYYydoo.", "oyoyYwYYYYyydoyo", "oyoyYwYYYYyydoyo", "oyoyYYYYYYyydoyo", ".ooyYYYYYYyydoo.", "...oyYYYYyydo...",
             "....oyYYyydo....", ".....oyyydo.....", "......oydo......", "......oydo......", "....ooyyydoo....", "...oyYYYyyydo...", "...oooooooooo...", "................"], dict(o="#5a3a08", y="#f2c832", Y="#ffe97a", d="#c28a12", w="#ffffff")),
    ("bolt", ["................", ".........ooooo..", "........owwlbo..", ".......owwlbo...", "......owwlbo....", ".....owwlbo.....", "....owwwlooo....", "...owwwwwlbo....",
              "....oooowlbo....", "......owlbo.....", ".....owlbo......", "....owlbo.......", "...owbo.........", "...obo..........", "...oo...........", "................"], dict(o="#1a3a5a", w="#ffffff", l="#cfe6ff", b="#7ab8f0")),
    # ── the trader's ──
    ("emerald", ["................", "......oooo......", ".....oglLgo.....", "....oglLLmgo....", "...ogllLmmmgo...", "..oglwlLmmmdgo..", "..oglllLmmmdgo..", "..ogllLLmmddgo..",
                 "..ogllLmmmddgo..", "..ogllLmmmddgo..", "...oglLmmddgo...", "....oglmmdgo....", ".....ogmdgo.....", "......oooo......", "................", "................"], dict(o="#0a3a1a", g="#17803a", l="#4fe08a", L="#9affc0", m="#2fbf62", d="#1a9a48", w="#ffffff")),
    ("xp_bottle",) + flask("#3a7a10", "#9be84a", "#e6ff7a"),
]
NAMES = [i[0] for i in ICONS]

def hexa(h):
    h = h.lstrip("#")
    return tuple(int(h[k:k + 2], 16) for k in (0, 2, 4)) + (255,)

ROWS = 15      # always: the scene counts its cells as 8 by 15, and those of the small sheet as 4 by 30
assert len(ICONS) <= 8 * ROWS
sheet = Image.new("RGBA", (128, 16 * ROWS), (0, 0, 0, 0))
small = Image.new("RGBA", (64, 16 * ROWS * 2), (0, 0, 0, 0))
for k, (name, lines, pal) in enumerate(ICONS):
    assert len(lines) == 16 and all(len(l) == 16 for l in lines), (name, [len(l) for l in lines])
    for y, line in enumerate(lines):
        for x, ch in enumerate(line):
            if ch != ".":
                sheet.putpixel(((k % 8) * 16 + x, (k // 8) * 16 + y), hexa(pal[ch]))
                small.putpixel(((k % 4) * 16 + x, (k // 4) * 16 + y), hexa(pal[ch]))
sheet.save(OUT)
# The same things again, four to a row: drawn at their own size (hearts, what
# a land gives), from a sheet tall enough to share its shelf with the big ones.
small.save(os.path.join(os.path.dirname(OUT), "tiny.png"))
print(sheet.size, " ".join(f"{n}={k}" for k, n in enumerate(NAMES)))
