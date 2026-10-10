"""The frames, packed into the sheets the game draws from, at the size they are
drawn: characters in cells of 104, the boss in cells of 208, blocks in cells of 78.

    python3 pack.py FRAMES_DIR      (what make.py rendered; the sheets go to ../pieces)
"""
import os, sys
from PIL import Image
R = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "pieces")

def frames(kind, cell):
    many = 12 if kind == "boss" else 16
    return [Image.open(f"{R}/{kind}/{k:02d}.png").convert("RGBA").resize((cell, cell), Image.LANCZOS) for k in range(many)]

def rows(kinds, cell, columns):
    per = (12 if kinds == ["boss"] else 16) // columns
    sheet = Image.new("RGBA", (cell * columns, cell * per * len(kinds)))
    for r, kind in enumerate(kinds):
        fs = frames(kind, cell)
        boxes = [f.getchannel("A").getbbox() for f in fs]
        print(f"{kind:9s} foot {max(b[3] for b in boxes[:8]):3d}  top {min(b[1] for b in boxes):3d}  of {cell}")
        for k, f in enumerate(fs):
            sheet.paste(f, ((k % columns) * cell, (r * per + k // columns) * cell))
    return sheet

rows(["knight", "archer", "mage", "wolf"], 104, 16).save(f"{OUT}/heroes.png")
rows(["zombie", "skeleton", "creeper"], 104, 16).save(f"{OUT}/foes1.png")
rows(["spider", "enderman", "slime"], 104, 16).save(f"{OUT}/foes2.png")
rows(["boss"], 208, 6).save(f"{OUT}/boss.png")
blocks = ["table", "tnt", "tnt_lit", "chest_wood", "chest_wood_open", "chest_iron", "chest_iron_open", "chest_gold", "chest_gold_open", "chest_ender", "chest_ender_open"]
sheet = Image.new("RGBA", (78 * len(blocks), 78))
for k, b in enumerate(blocks):
    im = Image.open(f"{R}/blocks/{b}.png").convert("RGBA").resize((78, 78), Image.LANCZOS)
    print(f"{b:10s} box {im.getchannel('A').getbbox()}")
    sheet.paste(im, (k * 78, 0))
sheet.save(f"{OUT}/blocks.png")

# The ground of each biome: a strip of sixteen tiles of 16, one row each.
import random
BIOMES = [("plains", "#5fa83a", "#8a5f3a", "#6b4628"), ("desert", "#e3d59a", "#d9c88a", "#c9b574"), ("swamp", "#4a6b3a", "#5a4a32", "#3f3524"),
          ("tundra", "#f2f6f8", "#8a5f3a", "#dfe8ec"), ("nether", "#7a2f2f", "#6b2626", "#4a1a1a"), ("end", "#e6e8a8", "#d9db98", "#c2c486")]
ground = Image.new("RGBA", (256, 16 * len(BIOMES)))
for row, (name, top, body, fleck) in enumerate(BIOMES):
    rnd = random.Random(row + 3)
    tone = lambda h, k: tuple(min(255, max(0, int(int(h[i:i + 2], 16) * k))) for i in (1, 3, 5)) + (255,)
    for x in range(256):
        depth = 3 + (rnd.random() < 0.3) + (rnd.random() < 0.15)
        for y in range(16):
            base = top if y < depth else (fleck if rnd.random() < 0.2 else body)
            ground.putpixel((x, row * 16 + y), tone(base, 0.9 + rnd.random() * 0.2))
ground.save(f"{OUT}/ground.png")
