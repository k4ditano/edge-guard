"""The things that are picked up, made, worn and thrown, as pixel art of
16 × 16: each one written out pixel by pixel, eight to a row of the sheet.
A letter is a colour of that thing's own palette; a dot is nothing."""
import os
from PIL import Image
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pieces", "items.png")

WOOD = dict(o="#2a1c0c", d="#5a3d1e", m="#7a552a", l="#a37a44")
def metal(o, d, m, l, w):
    return dict(o=o, d=d, m=m, l=l, w=w)
IRON = metal("#2f3338", "#6f777e", "#a9b1b8", "#d6dce1", "#ffffff")
DIAMOND = metal("#0d3b38", "#1f9f95", "#4ee6d6", "#a8fff2", "#ffffff")
TIMBER = metal("#2a1c0c", "#5a3d1e", "#8a6233", "#b8945f", "#d9b888")

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

def bow(glint):
    pal = dict(o="#2a1c0c", d="#5a3d1e", m="#8a5a2b", l="#b98548", s="#e8e2d0", S="#b8b2a2", g=glint or "#8a5a2b", G=glint and "#f2c9ff" or "#b98548")
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
]
NAMES = [i[0] for i in ICONS]

def hexa(h):
    h = h.lstrip("#")
    return tuple(int(h[k:k + 2], 16) for k in (0, 2, 4)) + (255,)

sheet = Image.new("RGBA", (128, 16 * ((len(ICONS) + 7) // 8)), (0, 0, 0, 0))
for k, (name, lines, pal) in enumerate(ICONS):
    assert len(lines) == 16 and all(len(l) == 16 for l in lines), (name, [len(l) for l in lines])
    for y, line in enumerate(lines):
        for x, ch in enumerate(line):
            if ch != ".":
                sheet.putpixel(((k % 8) * 16 + x, (k // 8) * 16 + y), hexa(pal[ch]))
sheet.save(OUT)
print(sheet.size, " ".join(f"{n}={k}" for k, n in enumerate(NAMES)))
