"""The frames, packed into the sheets the game draws from. pleamar keeps every
picture of a scene in one atlas 2048 wide (taller, from pleamar 0.4.10, when
what is seen needs it), in shelves as tall as what is on them, so the sheets
are cut to share it: the party and the horde in
cells of 104, sixteen to a row and six rows each (two shelves, with room at
their side for the blocks and the things); the lords, eight pictures each
—four of walking, four of striking— in cells of 126 by 156, sixteen to a row,
which the game draws a third bigger; blocks in cells of 78, four to a row.

    python3 pack.py FRAMES_DIR      (what make.py rendered; the sheets go to ../pieces)

The game puts a character's feet on the ground by a row of its cell: the
knight's for whoever is with the heroes, 145 for a lord (193 as it is drawn).
The ones that came later are moved up or down in their cells to stand on it.
"""
import os, sys
from PIL import Image
R = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pieces")
LORDS = ["boss", "husk", "great_slime", "frost_archer", "magma_titan", "ender_giant"]
LORD_CELL, LORD_FOOT = (126, 156), 145
LORD_FRAMES = [0, 2, 4, 6, 8, 9, 10, 11]      # of the twelve rendered: every other one of the walk, and the four of the strike

def frames(kind, cell):
    return [Image.open(f"{R}/{kind}/{k:02d}.png").convert("RGBA").resize((cell, cell), Image.LANCZOS) for k in range(16)]

def rows(kinds, cell, columns, foot=None, fixed=()):
    """A row of the sheet for each kind (two, for a lord). With `foot`, every
    kind not in `fixed` is moved so that the lowest of its walking frames is on
    that row; `foot` may be a kind's name, and then it is that kind's own."""
    per = 16 // columns
    sheet = Image.new("RGBA", (cell * columns, cell * per * len(kinds)))
    feet = {}
    for r, kind in enumerate(kinds):
        fs = frames(kind, cell)
        boxes = [f.getchannel("A").getbbox() for f in fs]
        feet[kind] = max(b[3] for b in boxes[:8])
        to = feet[foot] if isinstance(foot, str) else foot
        dy = to - feet[kind] if to is not None and kind not in fixed else 0
        top, bottom = min(b[1] for b in boxes) + dy, max(b[3] for b in boxes) + dy
        assert top >= 0 and bottom <= cell, f"{kind} does not fit its cell once on its feet: {top}..{bottom}"
        assert min(b[0] for b in boxes) > 0 and max(b[2] for b in boxes) < cell, f"{kind} is cut at a side"
        print(f"{kind:12s} foot {feet[kind] + dy:3d}  top {top:3d}  of {cell}" + (f"  (moved {dy:+d})" if dy else ""))
        for k, f in enumerate(fs):
            sheet.paste(f, ((k % columns) * cell, (r * per + k // columns) * cell + dy))
    return sheet

rows(["knight", "archer", "mage", "wolf", "golem", "cleric"], 104, 16, foot="knight", fixed=("knight", "archer", "mage", "wolf")).save(f"{OUT}/heroes.png")
rows(["zombie", "skeleton", "creeper", "spider", "enderman", "slime"], 104, 16).save(f"{OUT}/foes.png")

# The lords: rendered square, kept as the middle of that square —they are
# taller than wide—, three quarters the size the game draws them.
w, h = LORD_CELL
sheet = Image.new("RGBA", (w * 16, h * 3))
for r, kind in enumerate(LORDS):
    fs = [Image.open(f"{R}/{kind}/{k:02d}.png").convert("RGBA").resize((h, h), Image.LANCZOS) for k in LORD_FRAMES]
    boxes = [f.getchannel("A").getbbox() for f in fs]
    left, right = min(b[0] for b in boxes), max(b[2] for b in boxes)
    side = (h - w) // 2
    if left <= side or right >= side + w:
        side = (left + right - w) // 2            # (one that leans out of the middle is kept by its own middle)
    dy = LORD_FOOT - max(b[3] for b in boxes[:4])
    assert left > side and right < side + w, f"{kind} is too wide for its cell: {left}..{right}"
    assert min(b[1] for b in boxes) + dy >= 0 and max(b[3] for b in boxes) + dy <= h, f"{kind} does not fit its cell once on its feet"
    print(f"{kind:12s} foot {LORD_FOOT}  wide {min(b[0] for b in boxes) - side}..{max(b[2] for b in boxes) - side} of {w}  (moved {dy:+d})")
    for k, f in enumerate(fs):
        at = r * 8 + k
        sheet.paste(f.crop((side, 0, side + w, h)), ((at % 16) * w, (at // 16) * h + dy))
sheet.save(f"{OUT}/boss.png")

# What flies: a phantom and a ghast in cells of 128, a row of eight each; the
# dragon on a sheet of its own, four to a row in cells of 256 by 224. Rendered at twice that.
sheet = Image.new("RGBA", (1024, 256))
for k, kind in enumerate(["phantom", "ghast"]):
    for f in range(8):
        im = Image.open(f"{R}/{kind}/{f:02d}.png").convert("RGBA").resize((128, 128), Image.LANCZOS)
        sheet.paste(im, (f * 128, k * 128))
sheet.save(f"{OUT}/flyers.png")
sheet = Image.new("RGBA", (1024, 448))
for f in range(8):
    im = Image.open(f"{R}/dragon/{f:02d}.png").convert("RGBA").resize((256, 224), Image.LANCZOS)
    sheet.paste(im, ((f % 4) * 256, (f // 4) * 224))
sheet.save(f"{OUT}/dragon.png")
print("flyers      phantom and ghast 128, dragon 256x224")

blocks = ["table", "tnt", "tnt_lit", "chest_wood", "chest_wood_open", "chest_iron", "chest_iron_open", "chest_gold", "chest_gold_open", "chest_ender", "chest_ender_open",
          "furnace", "furnace_lit", "enchant", "mine", "farm_0", "farm_1", "farm_2", "farm_3"]
sheet = Image.new("RGBA", (78 * 4, 78 * 7))
for k, b in enumerate(blocks):
    im = Image.open(f"{R}/blocks/{b}.png").convert("RGBA").resize((78, 78), Image.LANCZOS)
    print(f"{b:16s} box {im.getchannel('A').getbbox()}")
    sheet.paste(im, ((k % 4) * 78, (k // 4) * 78))
sheet.save(f"{OUT}/blocks.png")

# The ground of each biome: a strip of sixteen tiles of 16, one after another.
import random
BIOMES = [("plains", "#5fa83a", "#8a5f3a", "#6b4628"), ("desert", "#e3d59a", "#d9c88a", "#c9b574"), ("swamp", "#4a6b3a", "#5a4a32", "#3f3524"),
          ("tundra", "#f2f6f8", "#8a5f3a", "#dfe8ec"), ("nether", "#7a2f2f", "#6b2626", "#4a1a1a"), ("end", "#e6e8a8", "#d9db98", "#c2c486")]
ground = Image.new("RGBA", (256 * len(BIOMES), 16))
for row, (name, top, body, fleck) in enumerate(BIOMES):
    rnd = random.Random(row + 3)
    tone = lambda h, k: tuple(min(255, max(0, int(int(h[i:i + 2], 16) * k))) for i in (1, 3, 5)) + (255,)
    for x in range(256):
        depth = 3 + (rnd.random() < 0.3) + (rnd.random() < 0.15)
        for y in range(16):
            base = top if y < depth else (fleck if rnd.random() < 0.2 else body)
            ground.putpixel((row * 256 + x, y), tone(base, 0.9 + rnd.random() * 0.2))
ground.save(f"{OUT}/ground.png")
