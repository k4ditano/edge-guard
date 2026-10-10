"""Blocky characters and blocks with pixel textures, rendered as frames for sprite sheets.

    blender -b --factory-startup -P make.py -- OUT_DIR [KIND…]

Every box is one pixel of texture for each unit of its size, painted here:
a base colour that varies a little from pixel to pixel, and on top whatever
the box wants drawn on each of its faces (a face, a collar, planks).
Characters get 8 frames of walking and 8 of attacking (a land's lord, 4, and
twice as big a picture): OUT_DIR/KIND/00.png … What is held is held as it
would be: a sword out from the fist, a bow across the hand that holds it, its
string drawn and let go. Heroes look to the right, the rest to the left.
Blocks get one picture each: OUT_DIR/blocks/NAME.png.
"""
import bpy, math, random, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "frames"
ONLY = argv[1:]

scene = bpy.context.scene
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

TEXEL = 8          # image pixels for each pixel of texture: big, so that it stays a sharp square
FACES = ("front", "back", "right", "left", "top", "bottom")
count = [0]

def rgb(h):
    h = h.lstrip("#")
    return [int(h[k:k + 2], 16) / 255 for k in (0, 2, 4)]

def shade(c, k):
    return [min(1.0, max(0.0, x * k)) for x in c]

def joint(name, at, parent=None):
    e = bpy.data.objects.new(name, None)
    scene.collection.objects.link(e)
    e.parent = parent
    e.location = Vector(at) - (world_of(parent) if parent else Vector())
    e["at"] = tuple(at)
    return e

def world_of(o):
    return Vector(o["at"]) if o and "at" in o.keys() else Vector()

def box(size, centre, colour, parent, paint=None, rough=0.07, seed=None):
    """A box of that size (x, y, z), its centre there in the model's own space.
    `paint(face, w, h)` gives the pixels to draw over the base on that face:
    a dict of (x, y) → colour, (0, 0) at the bottom left as it is looked at."""
    count[0] += 1
    rnd = random.Random(seed if seed is not None else count[0] * 7919)
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.active_object
    o.scale = size
    o.parent = parent
    o.location = Vector(centre) - world_of(parent)
    sx, sy, sz = (max(1, round(s)) for s in size)
    dims = {"front": (sy, sz), "back": (sy, sz), "right": (sx, sz), "left": (sx, sz), "top": (sy, sx), "bottom": (sy, sx)}
    cell = max(sx, sy, sz)
    width, height = cell * 6 * TEXEL, cell * TEXEL
    img = bpy.data.images.new("t%d" % count[0], width, height, alpha=False)
    base = rgb(colour)
    pixels = [0.0] * (width * height * 4)
    for k, face in enumerate(FACES):
        w, h = dims[face]
        over = paint(face, w, h) if paint else {}
        for y in range(h):
            for x in range(w):
                c = over.get((x, y))
                c = shade(rgb(c) if c else base, 1 + (rnd.random() - 0.5) * 2 * rough)
                # The top a little lighter and the underside darker, as the sun would have it.
                c = shade(c, {"top": 1.08, "bottom": 0.7, "back": 0.86, "left": 0.92}.get(face, 1.0))
                for py in range(TEXEL):
                    row = (y * TEXEL + py) * width
                    for px in range(TEXEL):
                        i = (row + (k * cell + x) * TEXEL + px) * 4
                        pixels[i:i + 4] = (c[0], c[1], c[2], 1.0)
    img.pixels.foreach_set(pixels)
    mat = bpy.data.materials.new("m%d" % count[0])
    mat.use_nodes = True
    tree = mat.node_tree
    tex = tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    tree.nodes.active = tex
    o.data.materials.append(mat)
    # Each face onto its piece of the image.
    uv = o.data.uv_layers.active.data
    for poly in o.data.polygons:
        n = poly.normal
        axis = max(range(3), key=lambda a: abs(n[a]))
        face = (("back", "front"), ("right", "left"), ("bottom", "top"))[axis][n[axis] > 0]
        k = FACES.index(face)
        w, h = dims[face]
        for li in poly.loop_indices:
            v = o.data.vertices[o.data.loops[li].vertex_index].co
            if face == "front": a, b = 0.5 - v.y, v.z + 0.5
            elif face == "back": a, b = v.y + 0.5, v.z + 0.5
            elif face == "right": a, b = v.x + 0.5, v.z + 0.5
            elif face == "left": a, b = 0.5 - v.x, v.z + 0.5
            elif face == "top": a, b = 0.5 - v.y, v.x + 0.5
            else: a, b = 0.5 - v.y, 0.5 - v.x
            uv[li].uv = ((k * cell + a * w) / (cell * 6), (b * h) / cell)
    return o

def on(face_name, pixels):
    """A painter that draws those pixels on one face (and nothing on the rest)."""
    return lambda face, w, h: pixels if face == face_name else {}

def rows(*lines, colours):
    """Pixels written as text, the top row first: a letter for each colour, `.` for none."""
    out = {}
    for y, line in enumerate(reversed(lines)):
        for x, ch in enumerate(line):
            if ch != ".":
                out[(x, y)] = colours[ch]
    return out

def both(*painters):
    def paint(face, w, h):
        out = {}
        for p in painters:
            out.update(p(face, w, h))
        return out
    return paint

def band(rows_from_bottom, colour, faces=("front", "back", "right", "left")):
    """Whole rows of a colour all round: a belt, a cuff, a shoe."""
    return lambda face, w, h: {(x, y): colour for y in rows_from_bottom for x in range(w)} if face in faces else {}

def speckle(colour, share, seed, faces=FACES):
    """Some pixels in another tone, here and there."""
    def paint(face, w, h):
        rnd = random.Random(seed + FACES.index(face))
        return {(x, y): colour for y in range(h) for x in range(w) if rnd.random() < share} if face in faces else {}
    return paint

# ── faces, eight by eight ──
SKIN, HAIR = "#c8956c", "#4a3020"
STEVE = rows("HHHHHHHH", "HHHHHHHH", "HSSSSSSH", "SSSSSSSS", "SWISSIWS", "SSSNNSSS", "SSMMMMSS", "SSMSSMSS",
             colours=dict(H=HAIR, S=SKIN, W="#f2f2f2", I="#3d5fc4", N="#a8744e", M="#6b3f2a"))
ALEX = rows("HHHHHHHH", "HHHHHHHH", "HHSSSSHH", "HSSSSSSH", "SWGSSGWS", "SSSNNSSS", "SSSPPSSS", "SSSSSSSS",
            colours=dict(H="#c8752e", S="#e6b89a", W="#f2f2f2", G="#2f7d4f", N="#c99a7c", P="#c9706b"))
WITCH = rows("SSSSSSSS", "SBBSSBBS", "SWISSIWS", "SSSNNSSS", "SSSNNSSS", "SSMMMMSS", "SSSSSSSS", "SSSSSSSS",
             colours=dict(S="#b89a84", B="#3a2a22", W="#f2f2f2", I="#6a3fb0", N="#a3846e", M="#6b3a3a"))
ZOMBIE = rows("GGGGGGGG", "GGGGGGGG", "GGGGGGGG", "GDGGGGDG", "GKKGGKKG", "GGGDDGGG", "GGDKKDGG", "GGGDDGGG",
              colours=dict(G="#4f8a3f", D="#3a6b30", K="#14201a"))
KING = rows("GGGGGGGG", "GGGGGGGG", "GGGGGGGG", "GDGGGGDG", "GRRGGRRG", "GGGDDGGG", "GDKKKKDG", "GGDDDDGG",
            colours=dict(G="#4a7a66", D="#35584a", K="#101a18", R="#ff3b3b"))
SKULL = rows("WWWWWWWW", "WWWWWWWW", "WWWWWWWW", "WKKWWKKW", "WKKWWKKW", "WWWKKWWW", "WKWKWKWW", "WWWWWWWW",
             colours=dict(W="#c9cdd0", K="#3a3d42"))
CREEPER = rows("GGGGGGGG", "GGGGGGGG", "GKKGGKKG", "GKKGGKKG", "GGGKKGGG", "GGKKKKGG", "GGKKKKGG", "GGKGGKGG",
               colours=dict(G="#5ab552", K="#101510"))
ENDER = rows("KKKKKKKK", "KKKKKKKK", "KKKKKKKK", "PMPKKPMP", "KKKKKKKK", "KKKKKKKK", "KKKKKKKK", "KKKKKKKK",
             colours=dict(K="#161616", P="#e079fa", M="#cc00fa"))

def humanoid(c, thin=False, limb=12):
    """Legs of 12, a body of 12, a head of 8: its feet at the origin, looking along +x."""
    root = joint("root", (0, 0, 0))
    w = 2 if thin else 4
    parts = {"root": root}
    body = joint("body", (0, 0, limb), root)
    box((4 if not thin else 2, 8, 12), (0, 0, limb + 6), c["shirt"], body, paint=c.get("shirt_paint"))
    head = joint("head", (0, 0, limb + 12), body)
    box((8, 8, 8), (0, 0, limb + 16), c["skin"], head, paint=both(c.get("head_paint", lambda *a: {}), on("front", c["face"])))
    for name, y in (("arm_r", -(4 + w / 2)), ("arm_l", 4 + w / 2)):
        a = joint(name, (0, y, limb + 10), body)
        box((w, w, limb), (0, y, limb + 12 - limb / 2), c.get("sleeve", c["skin"]), a, paint=c.get("arm_paint"))
        parts[name] = a
    for name, y in (("leg_r", -2 if not thin else -1.5), ("leg_l", 2 if not thin else 1.5)):
        l = joint(name, (0, y, limb), root)
        box((w, w if thin else 4, limb), (0, y, limb / 2), c["pants"], l, paint=c.get("leg_paint"))
        parts[name] = l
    parts.update(body=body, head=head)
    return parts

def bow(p, y, wood="#7a4f24"):
    """A bow in the left hand, across it: with the arm out in front it stands
    upright. Its string is two pieces from its tips to where it is drawn to,
    and an arrow lies on it while it is: all three are placed frame by frame."""
    a = p["arm_l"]
    hand = (0, y, 11)
    box((16, 1, 1.2), (0, y, 11), wood, a, paint=on("right", {(7, 0): "#3a2a1a", (8, 0): "#3a2a1a"}))
    for side in (-1, 1):
        box((1.2, 1, 3), (side * 8, y, 12.4), wood, a)
        p["tip%d" % side] = joint("tip%d" % side, (side * 8, y, 13.8), a)
    p["grip"] = joint("grip", hand, a)
    # Where the string is drawn to: straight back from the grip, towards whoever holds it.
    p["draw"] = joint("draw", (0, y, 13.8), a)
    for name in ("string1", "string2"):
        p[name] = box((1, 0.3, 0.3), (0, 0, 0), "#efe9d8", None, rough=0)
    p["arrow"] = box((1, 0.5, 0.5), (0, 0, 0), "#b9a27a", None, paint=band((0,), "#e9e9e9", ("front", "back")), rough=0)
    p["arrowhead"] = box((1.6, 1.2, 1.2), (0, 0, 0), "#c9cdd0", None, rough=0)

def stretch(o, a, b, thick):
    """A box from one point to another."""
    a, b = Vector(a), Vector(b)
    d = b - a
    o.location = (a + b) / 2
    o.scale = (max(d.length, 0.01), thick, thick)
    o.rotation_euler = d.to_track_quat("X", "Z").to_euler()

def string(p, pull):
    """The bow's string, drawn back `pull` units, and its arrow if `pull` is not None."""
    bpy.context.view_layer.update()
    tips = [p["tip-1"].matrix_world.translation.copy(), p["tip1"].matrix_world.translation.copy()]
    grip = p["grip"].matrix_world.translation.copy()
    rest = p["draw"].matrix_world.translation.copy()
    back = (rest - grip).normalized()
    at = rest + back * (pull or 0)
    stretch(p["string1"], tips[0], at, 0.3)
    stretch(p["string2"], tips[1], at, 0.3)
    if pull is None:
        p["arrow"].scale = p["arrowhead"].scale = (0, 0, 0)
    else:
        head = grip - back * 6
        stretch(p["arrow"], at, head, 0.5)
        stretch(p["arrowhead"], head, head - back * 1.8, 1.3)

def knight():
    iron, dark, light = "#b9c2c9", "#7d8891", "#e3e9ee"
    plate = both(band((0,), dark), band((11,), dark), on("front", rows("........", ".LLLLLL.", ".LDDDDL.", ".L....L.", ".L.DD.L.", "........", colours=dict(L=light, D=dark))))
    p = humanoid(dict(skin=SKIN, face=STEVE, head_paint=speckle(HAIR, 1, 3, ("back", "top", "left", "right")),
                      shirt=iron, shirt_paint=plate, sleeve=iron, arm_paint=both(band((0, 1, 2), SKIN), band((3,), dark), band((11,), light)),
                      pants="#8f9aa3", leg_paint=both(band((0, 1, 2), "#5a646d"), band((6,), dark))))
    h = p["head"]
    # The helmet: over the hair, open at the face.
    box((8.6, 8.6, 3.4), (0, 0, 30.6), iron, h, paint=band((0,), dark))
    box((1.2, 8.6, 5.6), (-3.8, 0, 26.6), iron, h)
    box((7, 0.8, 5), (-0.3, -4, 26.8), iron, h)
    box((7, 0.8, 5), (-0.3, 4, 26.8), iron, h)
    box((0.6, 1.4, 3), (4.1, 0, 28.4), dark, h)
    # The sword: its grip in the fist, its blade forward and a little up.
    grip = joint("grip", (0.4, -6, 11), p["arm_r"])
    box((1, 1.6, 15), (0.4, -6, 20.5), "#dfe6eb", grip, paint=band((0, 14), "#aab4bc"), rough=0.03)
    box((1, 5, 1.2), (0.4, -6, 12.6), "#8a6a2a", grip, rough=0.04)
    box((1, 1.4, 3), (0.4, -6, 10.6), "#5a3d1e", grip, rough=0.04)
    grip.rotation_euler.y = math.radians(68)
    grip["keep"] = 68
    p["grip"] = grip
    shield = rows("BBBBBBB", "BWWWWWB", "BWRRRWB", "BWRWRWB", "BWRRRWB", "BWWWWWB", "BWWWWWB", "BBWWWBB", ".BBWBB.", "..BBB..",
                  colours=dict(B="#3a2a1a", W="#b9c2c9", R="#c43d3d"))
    box((1, 7, 10), (0.6, 8.7, 16), "#6b4a2a", p["arm_l"], paint=lambda f, w, h: shield if f in ("left", "right") else {})
    return p

def archer():
    tunic = both(band((0, 1), "#3a2a1a"), on("front", rows("TTSSSSTT", "TTTSSTTT", colours=dict(T="#3f7d3a", S="#e6b89a"))), speckle("#356b31", 0.2, 5))
    p = humanoid(dict(skin="#e6b89a", face=ALEX, head_paint=speckle("#c8752e", 1, 4, ("back", "top", "left", "right")),
                      shirt="#3f7d3a", shirt_paint=tunic, sleeve="#3f7d3a", arm_paint=band((0, 1, 2, 3), "#e6b89a"),
                      pants="#6b4a2f", leg_paint=band((0, 1, 2), "#3a2a1a")))
    box((3, 5, 9), (-3.4, 0, 19), "#6b4a2a", p["body"], paint=band((7,), "#3a2a1a"))   # the quiver
    for k in (-1.2, 0, 1.2):
        box((0.7, 0.7, 4), (-3.4, k, 25), "#e9e2d0", p["body"], paint=band((3,), "#c43d3d"), rough=0)
    bow(p, 6)
    return p

def mage():
    robe = both(band((0,), "#2a1a45"), speckle("#4a2f85", 0.25, 9), on("front", rows("...GG...", "...GG...", "........", colours=dict(G="#3aa655"))))
    p = humanoid(dict(skin="#b89a84", face=WITCH, shirt="#5a3a9a", shirt_paint=robe, sleeve="#5a3a9a", arm_paint=both(band((0, 1, 2), "#b89a84"), speckle("#4a2f85", 0.25, 2)),
                      pants="#4a2f85", leg_paint=band((0, 1), "#2a1a45")))
    box((5, 9, 9), (0, 0, 8), "#5a3a9a", p["root"], paint=both(band((0,), "#2a1a45"), speckle("#4a2f85", 0.25, 8)))   # the robe, over the legs
    h = p["head"]
    box((1.2, 2, 2.4), (4.5, 0, 26.6), "#a3846e", h)                                     # a nose, and its wart
    box((0.6, 0.8, 0.8), (5.2, -0.5, 26.2), "#5a8a3a", h, rough=0)
    box((13, 13, 1.2), (0, 0, 32.4), "#231a2e", h, rough=0.1)                            # the hat
    box((8.4, 8.4, 3), (0, 0, 34.2), "#231a2e", h, paint=both(band((0,), "#3aa655"), on("front", {(3, 0): "#e8c35a", (4, 0): "#e8c35a"})))
    for k, s in enumerate((6, 4, 2.4)):
        box((s, s, 2.6), (-0.8 * (k + 1), 0, 36.8 + k * 2.4), "#231a2e", h, rough=0.1)
    a = p["arm_r"]                                                                       # a potion in the hand
    p["flask"] = joint("flask", (0.6, -6, 10), a)
    box((2.8, 2.8, 3.2), (0.6, -6, 8.6), "#c94fd8", p["flask"], paint=band((2,), "#f2c9f7"), rough=0.12)
    box((1.2, 1.2, 1.6), (0.6, -6, 11), "#d9d2c4", p["flask"], rough=0)
    return p

def zombie(boss=False):
    green = "#4f8a3f" if not boss else "#4a7a66"
    torn = lambda seed: speckle(green, 0.16, seed, ("front", "back", "right", "left"))
    p = humanoid(dict(skin=green, face=KING if boss else ZOMBIE, head_paint=speckle("#3a6b30" if not boss else "#35584a", 0.2, 11),
                      shirt="#2f9a9a" if not boss else "#6a2530", shirt_paint=both(torn(12), band((0,), "#237878" if not boss else "#4a1820")),
                      sleeve=green, arm_paint=both(speckle("#3a6b30" if not boss else "#35584a", 0.2, 13), band((9, 10, 11), "#2f9a9a" if not boss else "#6a2530")),
                      pants="#3f3a8a" if not boss else "#2a2540", leg_paint=both(band((0, 1), "#2a2760" if not boss else "#15121f"), torn(14))))
    if boss:
        h = p["head"]
        box((9, 9, 1.6), (0, 0, 32.6), "#e8c35a", h, paint=speckle("#fff0a0", 0.2, 3))   # a crown
        for y in (-3.4, 0, 3.4):
            box((1.6, 1.6, 2.6), (3.6, y, 34.2), "#e8c35a", h, paint=on("front", {(0, 1): "#d83a3a"}))
            box((1.6, 1.6, 2.6), (-3.6, y, 34.2), "#e8c35a", h)
        box((5, 9, 4), (0, 0, 21.5), "#3a3340", p["body"], paint=band((0,), "#e8c35a"))
    return p

def skeleton():
    bone, dark = "#c9cdd0", "#7d8388"
    ribs = on("front", rows("BBBBBBBB", "DBBDDBBD", "BBBBBBBB", "DBBDDBBD", "BBBBBBBB", "DBBDDBBD", "BBBDDBBB", "BBBDDBBB", "BBBDDBBB", "BBBBBBBB", "DDBBBBDD", "BBBBBBBB", colours=dict(B=bone, D="#4a4f54")))
    p = humanoid(dict(skin=bone, face=SKULL, head_paint=speckle(dark, 0.08, 21), shirt=bone, shirt_paint=ribs, sleeve=bone, arm_paint=speckle(dark, 0.15, 22),
                      pants=bone, leg_paint=speckle(dark, 0.15, 23)), thin=True)
    bow(p, 5)                                                                            # it shoots, as they do
    return p

def enderman():
    c = dict(skin="#161616", face=ENDER, shirt="#161616", sleeve="#161616", pants="#161616", shirt_paint=speckle("#232323", 0.2, 31), arm_paint=speckle("#232323", 0.2, 32), leg_paint=speckle("#232323", 0.2, 33))
    return humanoid(c, thin=True, limb=28)

def creeper():
    root = joint("root", (0, 0, 0))
    mottle = lambda seed: both(speckle("#3f8f3a", 0.28, seed), speckle("#7fd070", 0.14, seed + 50))
    body = joint("body", (0, 0, 6), root)
    box((4, 8, 12), (0, 0, 12), "#5ab552", body, paint=mottle(41))
    head = joint("head", (0, 0, 18), body)
    box((8, 8, 8), (0, 0, 22), "#5ab552", head, paint=both(mottle(42), on("front", CREEPER)))
    parts = dict(root=root, body=body, head=head)
    for name, x, y in (("leg_fr", 4, -2), ("leg_fl", 4, 2), ("leg_br", -4, -2), ("leg_bl", -4, 2)):
        l = joint(name, (x, y, 6), root)
        box((4, 4, 6), (x, y, 3), "#5ab552", l, paint=both(mottle(43), band((0,), "#1d2a20"), on("front", {(0, 0): "#101510", (2, 0): "#101510"})))
        parts[name] = l
    return parts

def spider():
    root = joint("root", (0, 0, 0))
    hide = lambda seed: speckle("#3a343c", 0.3, seed)
    body = joint("body", (0, 0, 5), root)
    box((10, 9, 7), (-6, 0, 8), "#29242d", body, paint=hide(51))        # abdomen
    box((6, 6, 5), (2, 0, 7), "#322c36", body, paint=hide(52))          # thorax
    head = joint("head", (5, 0, 7), body)
    eyes = rows(".......", ".RR.RR.", ".RR.RR.", "..R.R..", ".......", colours=dict(R="#e0281e"))
    box((5, 7, 5), (7, 0, 7), "#29242d", head, paint=both(hide(53), on("front", eyes)))
    parts = dict(root=root, body=body, head=head)
    for k in range(4):
        for side in (-1, 1):
            name = "leg_%d%s" % (k, "r" if side < 0 else "l")
            x = 4 - k * 2.4
            l = joint(name, (x, side * 3, 7), body)
            box((1.2, 8, 1.2), (x, side * 6.8, 8.6), "#1d1a21", l)
            box((1.2, 1.2, 9.6), (x, side * 10.4, 4.6), "#1d1a21", l)
            l["side"] = side
            parts[name] = l
    return parts

def slime():
    root = joint("root", (0, 0, 0))
    body = joint("body", (0, 0, 0), root)
    face = rows("..........", "..........", ".KK....KK.", ".KK....KK.", "..........", ".....K....", "..........", "..........", "..........", "..........", colours=dict(K="#1f3d1a"))
    box((10, 10, 10), (0, 0, 5), "#6fbf5a", body, paint=both(speckle("#8fd67a", 0.25, 61), speckle("#57a546", 0.2, 62), on("front", face)), rough=0.05)
    return dict(root=root, body=body)

def wolf():
    fur, dark = "#d9d6d2", "#a8a4a0"
    root = joint("root", (0, 0, 0))
    body = joint("body", (0, 0, 8), root)
    box((9, 6, 6), (-3, 0, 11), fur, body, paint=speckle(dark, 0.18, 71))
    box((6, 8, 7), (3.5, 0, 11.5), fur, body, paint=both(speckle(dark, 0.18, 72), band((0,), "#c43d3d", ("front",))))
    head = joint("head", (6, 0, 13), body)
    muzzle = rows("FFFFFF", "FKFFKF", "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF", colours=dict(F=fur, K="#1a1a1a"))
    box((4, 6, 6), (8.5, 0, 13.5), fur, head, paint=both(speckle(dark, 0.12, 73), on("front", muzzle)))
    box((3, 3, 3), (11.6, 0, 12.2), "#e8e4de", head, paint=on("front", {(1, 2): "#1a1a1a", (1, 0): "#7a2a2a"}))
    for y in (-2, 2):
        box((1, 2, 2), (8, y, 17.4), fur, head, paint=on("front", {(0, 0): "#c9a0a0", (1, 0): "#c9a0a0"}))
    tail = joint("tail", (-7.5, 0, 13), body)
    box((2, 2, 8), (-8.2, 0, 10), fur, tail, paint=speckle(dark, 0.2, 74))
    parts = dict(root=root, body=body, head=head, tail=tail)
    for name, x, y in (("leg_fr", 4, -2), ("leg_fl", 4, 2), ("leg_br", -6, -2), ("leg_bl", -6, 2)):
        l = joint(name, (x, y, 8), root)
        box((2, 2, 8), (x, y, 4), fur, l, paint=speckle(dark, 0.18, 75))
        parts[name] = l
    return parts

# ── the two who can be brought to the camp ──
def golem():
    iron, dark, light = "#d6d2c8", "#aaa59a", "#eeeae0"
    worn = lambda seed: both(speckle(dark, 0.14, seed), speckle(light, 0.1, seed + 40))
    vine = lambda seed: speckle("#5a8a3a", 0.07, seed, ("front", "right", "left", "back"))
    root = joint("root", (0, 0, 0))
    parts = dict(root=root)
    for name, y in (("leg_r", -2.7), ("leg_l", 2.7)):
        l = joint(name, (0, y, 10), root)
        box((4.6, 4.8, 10), (0, y, 5), iron, l, paint=both(worn(201), band((0, 1), dark)))
        parts[name] = l
    body = joint("body", (0, 0, 10), root)
    box((5, 8.4, 5), (0, 0, 12.5), iron, body, paint=both(worn(202), band((4,), dark)))
    chest = rows("...............", "...............", "...R...........", "..RYR.....G....", "...R.....GG....", "...G....GG.....", "...GG..GG......", "....GGGG.......",
                 "....G..........", "...GG..........", "...............", colours=dict(R="#d83a3a", Y="#ffe27a", G="#5a8a3a"))
    box((7, 15, 11), (0, 0, 20.5), iron, body, paint=both(worn(203), vine(204), band((0,), dark), on("front", chest)))
    head = joint("head", (0, 0, 26), body)
    face = rows("IIIIIII", "IIIIIII", "DDDDDDD", "IRRIRRI", "IIIIIII", "IIIIIII", "IIDDDII", "IIIIIII", colours=dict(I=iron, D="#7d776c", R="#c4281e"))
    box((6.4, 7, 8), (0.4, 0, 30), iron, head, paint=both(worn(205), on("front", face)))
    box((2, 2, 4), (4.4, 0, 28.6), "#b8a79a", head)                                     # its nose
    for name, y in (("arm_r", -9.6), ("arm_l", 9.6)):
        a = joint(name, (0, y, 24.5), body)
        box((4, 4, 20), (0, y, 16), iron, a, paint=both(worn(206), vine(207), band((0, 1), dark)))
        parts[name] = a
    parts.update(body=body, head=head)
    return parts

def cleric():
    skin, robe, dark, white, gold = "#bd8b72", "#6b4a2f", "#4a3320", "#e9e2d0", "#e8c35a"
    stripe = lambda face, w, h: {(x, y): white for y in range(h) for x in (w // 2 - 1, w // 2)} if face == "front" else {}
    root = joint("root", (0, 0, 0))
    parts = dict(root=root)
    for name, y in (("leg_r", -2), ("leg_l", 2)):
        l = joint(name, (0, y, 12), root)
        box((4, 4, 12), (0, y, 6), robe, l, paint=band((0, 1), "#2a1c10"))
        parts[name] = l
    box((5, 9, 9.6), (0, 0, 8), robe, root, paint=both(speckle(dark, 0.15, 211), band((0,), gold), stripe))      # the robe, over the legs
    body = joint("body", (0, 0, 12), root)
    box((4, 8, 12), (0, 0, 18), robe, body, paint=both(speckle(dark, 0.15, 212), stripe, band((11,), gold)))
    head = joint("head", (0, 0, 24), body)
    face = rows("SSSSSSSS", "SSSSSSSS", "SSSSSSSS", "BBBBBBBB", "SWGSSGWS", "SSSSSSSS", "SSSSSSSS", "SSMMMMSS", "SSSSSSSS", "SSSSSSSS",
                colours=dict(S=skin, B="#3a2a1a", W="#f2f2f2", G="#2f7d4f", M="#8a5a48"))
    box((8, 8, 10), (0, 0, 29), skin, head, paint=on("front", face))
    box((2, 2, 4.4), (4.8, 0, 26.6), "#a8745a", head)                                   # the nose they all have
    box((8.6, 8.6, 2.4), (0, 0, 34.6), white, head, paint=band((0,), gold))             # a cap
    box((1.2, 8.6, 6), (-3.8, 0, 31), white, head)
    for name, y in (("arm_r", -6), ("arm_l", 6)):
        a = joint(name, (0, y, 22), body)
        box((4, 4, 11), (0, y, 18.5), robe, a, paint=both(band((0, 1), skin), band((2,), gold)))
        parts[name] = a
    # Folded, the hands are inside one sleeve; to heal, one of them comes out with something golden in it.
    parts["muff"] = joint("muff", (5.6, 0, 15.6), body)
    box((4.4, 9.6, 4.4), (5.6, 0, 15.6), robe, parts["muff"], paint=band((0,), dark))
    parts["charm"] = joint("charm", (0, -6, 11.5), parts["arm_r"])
    box((2.6, 2.6, 2.6), (0, -6, 11), "#ffd23a", parts["charm"], paint=speckle("#fff7c9", 0.3, 213), rough=0)
    box((1, 1, 1), (0, -6, 9.2), "#fff7c9", parts["charm"], rough=0)
    for dx, dy in ((2.4, 0), (-2.4, 0), (0, 2.4), (0, -2.4)):
        box((0.8, 0.8, 0.8), (dx, -6 + dy, 11), "#fff2a0", parts["charm"], rough=0)
    parts.update(body=body, head=head)
    return parts

# ── the lords of the other lands ──
def husk():
    sand, dark, wrap, cloth = "#c9b182", "#9a8458", "#ece3c8", "#6b5236"
    sides = ("front", "back", "right", "left")
    face = rows("SSSSSSSS", "SSSSSSSS", "WWWWWWWW", "SDSSSSDS", "SYYSSYYS", "SSSDDSSS", "SDKKKKDS", "SSDDDDSS",
                colours=dict(S=sand, D=dark, K="#1a140c", W=wrap, Y="#ffb01e"))
    torn = lambda seed: speckle(sand, 0.16, seed, sides)
    p = humanoid(dict(skin=sand, face=face, head_paint=both(speckle(dark, 0.2, 221), band((5,), wrap, ("back", "right", "left"))),
                      shirt=cloth, shirt_paint=both(torn(222), band((0,), "#4a3824"), band((4, 8), wrap)),
                      sleeve=sand, arm_paint=both(speckle(dark, 0.2, 223), band((2, 3, 7), wrap), band((10, 11), cloth)),
                      pants="#57452f", leg_paint=both(band((0, 1), "#3a2d1e"), band((5, 8), wrap), torn(224))))
    h = p["head"]
    # Its crown: a band, one tall point over the brow, and the cloth of a king of the sands down each side.
    box((9, 9, 1.8), (0, 0, 32.7), "#e8c35a", h, paint=both(speckle("#fff0a0", 0.2, 225), on("front", {(4, 0): "#1fd0c0", (4, 1): "#1fd0c0"})))
    box((1.8, 2.2, 5), (3.6, 0, 35.6), "#e8c35a", h, paint=on("front", {(0, 3): "#1fd0c0", (1, 3): "#1fd0c0"}))
    box((1.6, 1.6, 2.2), (3.6, -3.4, 34.4), "#e8c35a", h)
    box((1.6, 1.6, 2.2), (3.6, 3.4, 34.4), "#e8c35a", h)
    stripes = lambda face, w, hh: {(x, y): "#2f6fb0" for y in range(0, hh, 2) for x in range(w)}
    for y in (-4.9, 4.9):
        box((6, 1.2, 9), (-0.6, y, 27.6), "#e8c35a", h, paint=stripes)
    box((5, 9, 4), (0, 0, 21.5), "#4a3824", p["body"], paint=band((0,), "#e8c35a"))
    return p

def great_slime():
    root = joint("root", (0, 0, 0))
    body = joint("body", (0, 0, 0), root)
    def core(face, w, h):          # what is seen through it: a darker one inside
        return {(x, y): "#4f9a40" for y in range(5, 15) for x in range(5, 15)} if face not in ("top", "bottom") else {}
    face = rows("....................", "....................", "....................", "....................", "....................",
                "..KKKK........KKKK..", "...KKKK......KKKK...", "...KWKK......KKWK...", "...KKKK......KKKK...", "....................",
                "....................", "....................", ".....KKKKKKKKKK.....", ".....KWKWKKWKWK.....", "......KKKKKKKK......",
                "....................", "....................", "....................", "....................", "....................", colours=dict(K="#173312", W="#e4ffd6"))
    box((20, 20, 20), (0, 0, 10), "#74c75e", body, paint=both(speckle("#93dc7c", 0.22, 231), speckle("#5cae4a", 0.18, 232), core, speckle("#3f8a34", 0.12, 233, ("front", "back", "right", "left")), on("front", face)), rough=0.05)
    # A crown, as the lord of the swamp it is.
    box((10, 10, 2), (0, 0, 21), "#e8c35a", body, paint=both(speckle("#fff0a0", 0.2, 234), on("front", {(4, 0): "#d83a3a", (5, 0): "#d83a3a"})))
    for x, y, tall in ((4, -4, 3), (4, 4, 3), (-4, -4, 3), (-4, 4, 3), (4, 0, 5)):
        box((2, 2, tall), (x, y, 22 + tall / 2), "#e8c35a", body, paint=on("front", {(0, tall - 2): "#d83a3a", (1, tall - 2): "#d83a3a"}), rough=0.04)
    return dict(root=root, body=body)

def frost_archer():
    bone, dark, cloth, shade_ = "#c4d2da", "#7d8c96", "#5f7384", "#44566a"
    skull = rows("WWWWWWWW", "WWWWWWWW", "WWWWWWWW", "WKKWWKKW", "WBBWWBBW", "WWWKKWWW", "WKWKWKWW", "WWWWWWWW", colours=dict(W=bone, K="#2a3038", B="#7fe0ff"))
    ribs = on("front", rows("BBBBBBBB", "DBBDDBBD", "BBBBBBBB", "DBBDDBBD", "BBBBBBBB", "DBBDDBBD", "BBBDDBBB", "BBBDDBBB", "BBBDDBBB", "BBBBBBBB", "DDBBBBDD", "BBBBBBBB", colours=dict(B=bone, D="#3f4a54")))
    p = humanoid(dict(skin=bone, face=skull, head_paint=speckle(dark, 0.08, 241), shirt=bone, shirt_paint=ribs, sleeve=bone, arm_paint=both(speckle(dark, 0.15, 242), band((9, 10, 11), cloth)),
                      pants=bone, leg_paint=both(speckle(dark, 0.15, 243), band((8, 9, 10, 11), cloth))), thin=True)
    h = p["head"]
    rag = lambda seed: speckle(shade_, 0.3, seed)
    # The hood: over the skull, open at the face, and frost on its top.
    box((9, 9, 3), (-0.3, 0, 30.9), cloth, h, paint=rag(244))
    box((1.6, 9, 7.4), (-4, 0, 26.4), cloth, h, paint=rag(245))
    box((7.4, 1, 6.6), (-0.5, -4.2, 26.9), cloth, h, paint=rag(246))
    box((7.4, 1, 6.6), (-0.5, 4.2, 26.9), cloth, h, paint=rag(247))
    for x, y, tall in ((2.4, -2.4, 3), (0, 0.6, 4.4), (-2.2, 2.6, 2.6), (1.6, 2.8, 2)):
        box((1.4, 1.4, tall), (x, y, 32.4 + tall / 2), "#bfeaff", h, paint=speckle("#ffffff", 0.3, 248), rough=0.03)
    # Rags: what is left of a coat over the ribs, and strips of it down the back and the legs.
    box((2.8, 8.6, 5), (0, 0, 21.2), cloth, p["body"], paint=both(rag(249), band((0,), shade_)))
    for y, tall in ((-2.6, 13), (0, 9), (2.6, 15)):
        box((0.8, 2.4, tall), (-1.7, y, 23.8 - tall / 2), cloth, p["body"], paint=rag(250))
    for y, tall in ((-1.8, 6), (1.8, 4)):
        box((2.6, 2.6, tall), (0, y, 12.6 - tall / 2), cloth, p["root"], paint=rag(251))
    bow(p, 5, "#8ac4ee")
    return p

def magma_titan():
    crust, deep = "#2e0d0a", "#1a0605"
    root = joint("root", (0, 0, 0))
    body = joint("body", (0, 0, 0), root)
    parts = dict(root=root, body=body)
    # What burns inside is seen between its layers when they come apart.
    parts["core"] = joint("core", (0, 0, 10), body)
    box((16, 16, 16), (0, 0, 10), "#ff8a1e", parts["core"], paint=both(speckle("#ffd23a", 0.35, 261), speckle("#e0501a", 0.2, 262)), rough=0.1)
    eye = lambda rows_: {(x, y): c for y, c in rows_ for x in (2, 3, 4, 5, 14, 15, 16, 17)}
    for k in range(4):
        l = joint("layer%d" % k, (0, 0, k * 5), body)
        paint = [speckle("#4a1a12", 0.25, 263 + k), speckle(deep, 0.2, 270 + k), band((0,), "#c4401a"), band((4,), "#7a2010")]
        if k == 3:
            paint.append(on("front", {**eye(((0, "#ffb01e"), (1, "#ffd23a"), (2, "#ffb01e"))), (3, 1): "#fff7c9", (16, 1): "#fff7c9"}))
        if k == 2:
            paint.append(on("front", eye(((4, "#e03a1a"), (3, "#ff7a1e")))))
        box((20, 20, 5), (0, 0, k * 5 + 2.5), crust, l, paint=both(*paint), rough=0.08)
        parts["layer%d" % k] = l
    return parts

def ender_giant():
    black = "#141416"
    hide = lambda seed: both(speckle("#2a2033", 0.22, seed), speckle("#b84ff0", 0.035, seed + 30))
    root = joint("root", (0, 0, 0))
    parts = dict(root=root)
    for name, y in (("leg_r", -3), ("leg_l", 3)):
        l = joint(name, (0, y, 26), root)
        box((4, 4, 26), (0, y, 13), black, l, paint=hide(281))
        parts[name] = l
    body = joint("body", (0, 0, 26), root)
    gem = rows("..........", "..........", "....PP....", "...PMMP...", "...PMMP...", "....PP....", colours=dict(P="#e079fa", M="#ffffff"))
    box((6, 12, 13), (0, 0, 32.5), black, body, paint=both(hide(282), on("front", {(x + 1, y + 3): c for (x, y), c in gem.items()})))
    head = joint("head", (0, 0, 39), body)
    face = rows("KKKKKKKKK", "KKKKKKKKK", "KKKKKKKKK", "PPPKKKPPP", "PMPKKKPMP", "KKKKKKKKK", "KKKKKKKKK", "KKPPPPPKK", "KKKKKKKKK", colours=dict(K=black, P="#e079fa", M="#ffffff"))
    box((9, 9, 9), (0, 0, 43.5), black, head, paint=both(hide(283), on("front", face)))
    # The crown of the End's lord: crystals, and a horn each side.
    for x, y, tall, c in ((3, -3, 4, "#b84ff0"), (3, 0, 6, "#e079fa"), (3, 3, 4, "#b84ff0"), (-3, -3, 3, "#7a2fb0"), (-3, 3, 3, "#7a2fb0"), (0, -3.4, 3.4, "#9a3fd0"), (0, 3.4, 3.4, "#9a3fd0"), (-3, 0, 4.6, "#b84ff0")):
        box((1.8, 1.8, tall), (x, y, 48 + tall / 2), c, head, paint=speckle("#f2c9ff", 0.25, 284), rough=0.04)
    for side in (-1, 1):
        horn = joint("horn%d" % side, (0, side * 4.5, 45), head)
        box((2, 2, 10), (0, side * 4.5, 50), "#5a3f7a", horn, paint=band((7, 8, 9), "#f2c9ff"))
        horn.rotation_euler.x = math.radians(-52 * side)
    for name, y in (("arm_r", -8), ("arm_l", 8)):
        a = joint(name, (0, y, 37), body)
        box((4, 4, 30), (0, y, 23.5), black, a, paint=both(hide(285), band((0, 1), "#5a3f7a")))
        parts[name] = a
    parts.update(body=body, head=head)
    return parts

# ── blocks, sixteen a side ──
def planks(light="#b8945f", dark="#7a5c34"):
    def paint(face, w, h):
        out = {}
        for y in range(h):
            for x in range(w):
                if y % 4 == 3 or (x + (y // 4) * 5) % 8 == 0:
                    out[(x, y)] = dark
        return out
    return paint

def grass():
    root = joint("root", (0, 0, 0))
    def paint(face, w, h):
        if face == "top":
            return {(x, y): "#5fa83a" for y in range(h) for x in range(w)}
        if face == "bottom":
            return {}
        rnd = random.Random(7 + FACES.index(face))
        return {(x, y): "#5fa83a" for x in range(w) for y in range(h - 2 - rnd.randint(0, 2), h)}
    box((16, 16, 16), (0, 0, 8), "#8a5f3a", root, paint=both(speckle("#6b4628", 0.25, 81), speckle("#a3764a", 0.12, 82), paint), rough=0.09)
    return dict(root=root)

def table():
    root = joint("root", (0, 0, 0))
    def paint(face, w, h):
        out = planks()(face, w, h)
        if face == "top":
            out = {(x, y): "#6b4a2a" for y in range(h) for x in range(w) if x in (0, 5, 10, 15) or y in (0, 5, 10, 15)}
        elif face != "bottom":
            out.update({(x, y): "#4a3320" for x in range(w) for y in (12, 15)})
            out.update({(x, y): "#c9cdd0" for x in (3, 4) for y in range(4, 11)})          # a saw, or near enough
            out.update({(x, y): "#5a3d1e" for x in (10, 11) for y in range(3, 11)})         # and a hammer
            out.update({(x, y): "#8f979e" for x in range(8, 14) for y in (9, 10)})
        return out
    box((16, 16, 16), (0, 0, 8), "#b8945f", root, paint=paint, rough=0.05)
    return dict(root=root)

CHESTS = {   # wood, its lines, its edges, its latch
    "wood":  ("#a8742a", "#8a5c1e", "#4a3015", "#c9cdd0"),
    "iron":  ("#c2c8cd", "#9aa2a9", "#5a6268", "#3a4046"),
    "gold":  ("#f2cf4a", "#d9a92a", "#8a6410", "#fff3b0"),
    "ender": ("#16323a", "#0f242b", "#06141a", "#7fe0d4"),
}
def chest(kind="wood", open_=False):
    root = joint("root", (0, 0, 0))
    main, line, rim, latch = CHESTS[kind]
    edge = lambda face, w, h: {(x, y): rim for y in range(h) for x in range(w) if x in (0, w - 1) or y in (0, h - 1)} if face != "bottom" else {}
    spark = speckle("#9ff7ea", 0.06, 91) if kind == "ender" else (speckle("#fff6c0", 0.08, 92) if kind == "gold" else (lambda *a: {}))
    box((14, 14, 10), (0, 0, 5), main, root, paint=both(planks(main, line), spark, edge), rough=0.06)
    lid = joint("lid", (-7, 0, 10), root)
    box((14, 14, 4), (0, 0, 12), main, lid, paint=both(planks(main, line), spark, edge), rough=0.06)
    box((1, 2, 4), (7.4, 0, 10), latch, lid, paint=on("front", {(0, 0): rim, (1, 0): rim}), rough=0.03)   # the latch
    if open_:
        lid.rotation_euler.y = math.radians(-70)
        box((12, 12, 1), (0, 0, 9.4), "#2a1c0c", root, rough=0.1)       # dark inside
    return dict(root=root, lid=lid)

def tnt(lit=False):
    root = joint("root", (0, 0, 0))
    red = "#f2f2f2" if lit else "#d8352a"
    def paint(face, w, h):
        if face in ("top", "bottom"):
            return {(x, y): "#b8b0a0" if (x - 7.5) ** 2 + (y - 7.5) ** 2 < 30 else red for y in range(h) for x in range(w)}
        out = {(x, y): "#f2f2f2" for x in range(w) for y in range(5, 11)}
        letters = rows("KKK.K..K.KKK", ".K..KK.K..K.", ".K..K.KK..K.", ".K..K..K..K.", colours=dict(K="#1a1a1a"))
        out.update({(x + 2, y + 6): c for (x, y), c in letters.items()})
        out.update({(x, y): "#a8251d" if not lit else "#d9d9d9" for x in range(0, w, 4) for y in list(range(0, 5)) + list(range(11, 16))})
        return out
    box((16, 16, 16), (0, 0, 8), red, root, paint=paint, rough=0.04)
    return dict(root=root)


def cobble(seed, edge="#5f5f5f"):
    def paint(face, w, h):
        rnd = random.Random(seed + FACES.index(face))
        out = {}
        for y in range(h):
            for x in range(w):
                k = rnd.random()
                if x in (0, w - 1) or y in (0, h - 1): out[(x, y)] = edge
                elif (x + (y // 4) * 3) % 6 == 0 or y % 4 == 0: out[(x, y)] = "#6a6a6a" if k < 0.7 else "#7a7a7a"
                elif k < 0.12: out[(x, y)] = "#a4a4a4"
        return out
    return paint

def furnace(lit=False):
    root = joint("root", (0, 0, 0))
    def mouth(face, w, h):
        if face != "right":
            return {}
        out = {(x, y): "#4a4a4a" for x in range(2, 14) for y in range(1, 9)}
        out.update({(x, y): "#141414" for x in range(3, 13) for y in range(2, 8)})
        out.update({(x, y): "#4a4a4a" for x in range(3, 13) for y in range(10, 14)})
        out.update({(x, y): "#1a1a1a" for x in range(4, 12) for y in range(11, 13)})
        if lit:
            flame = rows("..Y....Y..", ".YY.Y.YYY.", "YFYYFYYFYY", "FFYFFFYFFF", "FRFFRFFFRF", "RRRRRRRRRR", colours=dict(Y="#ffe27a", F="#ff9a1e", R="#e0501a"))
            out.update({(x + 3, y + 2): c for (x, y), c in flame.items()})
            out.update({(x, y): "#7a3a1a" for x in range(4, 12) for y in range(11, 13)})
        return out
    box((16, 16, 16), (0, 0, 8), "#8a8a8a", root, paint=both(cobble(301), mouth), rough=0.05)
    return dict(root=root)

def enchant():
    root = joint("root", (0, 0, 0))
    def paint(face, w, h):
        if face == "top":
            out = {(x, y): "#8a1f2a" for y in range(h) for x in range(w)}
            out.update({(x, y): "#4ee6d6" for x in (0, 1, 2, w - 3, w - 2, w - 1) for y in (0, 1, 2, h - 3, h - 2, h - 1)})
            out.update({(x, y): "#c9a24a" for x in range(5, 11) for y in (5, 10)})
            out.update({(x, y): "#c9a24a" for x in (5, 10) for y in range(5, 11)})
            return out
        if face == "bottom":
            return {}
        out = {(x, y): "#8a1f2a" for x in range(w) for y in range(h - 3, h)}
        out.update({(x, y): "#4ee6d6" for x in (0, 1, w - 2, w - 1) for y in range(h - 3, h)})
        out.update({(x, y): "#a8fff2" for x in (0, w - 1) for y in (h - 1,)})
        return out
    box((16, 16, 12), (0, 0, 6), "#1a1326", root, paint=both(speckle("#2f2444", 0.3, 311), speckle("#0f0a18", 0.2, 312), paint), rough=0.06)
    # The book that floats over it, open.
    book = joint("book", (0, 0, 16.4), root)
    box((6, 9, 0.8), (0, 0, 16), "#7a4f24", book, rough=0.04)
    for side in (-1, 1):
        page = joint("page%d" % side, (0, 0, 16.4), book)
        box((5.2, 4, 0.9), (0, side * 2.1, 16.9), "#f2ecd8", page, paint=lambda face, w, h: {(x, y): "#8a7a9a" for y in (1, 3) for x in range(1, w - 1)} if face == "top" else {}, rough=0.02)
        page.rotation_euler.x = math.radians(16 * side)
    book.rotation_euler = (0, math.radians(34), math.radians(-50))      # tilted towards whoever looks
    return dict(root=root)

def mine():
    root = joint("root", (0, 0, 0))
    ORES = ("#262626", "#262626", "#d9a878", "#d9a878", "#f2cf4a", "#4ee6d6")
    def ores(face, w, h):
        rnd = random.Random(321 + FACES.index(face))
        out = {}
        for k in range(7 if face != "right" else 4):
            c = ORES[k % len(ORES)]
            x, y = rnd.randint(1, w - 3), rnd.randint(1, h - 3)
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1) if rnd.random() < 0.5 else (0, 0)):
                out[(x + dx, y + dy)] = c
        return out
    def tunnel(face, w, h):
        if face != "right":
            return {}
        out = {(x, y): "#0f0c0a" for x in range(4, 12) for y in range(0, 11)}
        out.update({(x, y): "#241c16" for x in range(5, 11) for y in range(0, 3)})
        out.update({(x, y): "#7a552a" for x in (3, 12) for y in range(0, 12)})
        out.update({(x, y): "#8a6233" for x in range(2, 14) for y in (11, 12)})
        out.update({(x, 0): "#8f979e" for x in (5, 10)})                       # rails, going in
        out.update({(x, 1): "#8f979e" for x in (6, 9)})
        return out
    box((16, 16, 16), (0, 0, 8), "#8a8a8a", root, paint=both(cobble(322), ores, tunnel), rough=0.05)
    return dict(root=root)

def farm(stage):
    root = joint("root", (0, 0, 0))
    def soil(face, w, h):
        if face == "top":
            return {(x, y): "#4a3020" if x % 4 in (1, 2) else "#6b4628" for y in range(h) for x in range(w)}
        return {(x, 0): "#3a2616" for x in range(w)}
    box((16, 16, 7), (0, 0, 3.5), "#5a3d24", root, paint=both(speckle("#6b4a2c", 0.2, 331), speckle("#46301c", 0.2, 332), soil), rough=0.08)
    rnd = random.Random(333)
    tall, colour, tip = ((1.6, "#7fd070", None), (4.5, "#5fa83a", "#8fd67a"), (8.5, "#5fa83a", "#a6c84a"), (9.5, "#d9b03a", "#f7e08a"))[stage]
    for x in (-6, -2, 2, 6):
        for y in (-6, -2, 2, 6):
            t = tall * (0.82 + rnd.random() * 0.36)
            box((1.1, 1.1, t), (x, y, 7 + t / 2), colour, root, rough=0.1)
            if tip:
                box((1.8, 1.8, 2.6 if stage == 3 else 1.4), (x, y, 7 + t + 0.6), tip, root, rough=0.08)
    return dict(root=root)

KINDS = {
    "knight": (knight, "hero"), "archer": (archer, "hero"), "mage": (mage, "hero"), "wolf": (wolf, "hero"),
    "golem": (golem, "hero"), "cleric": (cleric, "hero"),
    "zombie": (zombie, "foe"), "skeleton": (skeleton, "foe"), "creeper": (creeper, "foe"),
    "spider": (spider, "foe"), "enderman": (enderman, "foe"), "slime": (slime, "foe"),
    "boss": (lambda: zombie(boss=True), "foe"),
    "husk": (husk, "foe"), "great_slime": (great_slime, "foe"), "frost_archer": (frost_archer, "foe"),
    "magma_titan": (magma_titan, "foe"), "ender_giant": (ender_giant, "foe"),
}
# The lords: four frames of striking, and a picture twice the size.
LORDS = ("boss", "husk", "great_slime", "frost_archer", "magma_titan", "ender_giant")
# Who moves as who.
POSE_AS = {"husk": "boss", "great_slime": "slime", "frost_archer": "skeleton"}
BLOCKS = {"grass": grass, "table": table, "tnt": tnt, "tnt_lit": lambda: tnt(True),
          "furnace": furnace, "furnace_lit": lambda: furnace(True), "enchant": enchant, "mine": mine}
for _stage in range(4):
    BLOCKS["farm_%d" % _stage] = (lambda s: lambda: farm(s))(_stage)
for _kind in CHESTS:
    BLOCKS["chest_" + _kind] = (lambda k: lambda: chest(k))(_kind)
    BLOCKS["chest_" + _kind + "_open"] = (lambda k: lambda: chest(k, True))(_kind)

def rest(p):
    for name, o in p.items():
        if name.startswith("string") or name.startswith("arrow"):
            continue
        o.rotation_euler = (0, math.radians(o["keep"]) if "keep" in o.keys() else 0, 0)
        o.scale = (1, 1, 1)
    p["root"].location = (0, 0, 0)
    # (Which way it faces is its own: the ones that come from the right stay turned.)
    p["root"].rotation_euler.z = p["root"]["turn"] if "turn" in p["root"].keys() else 0

def along(values, hit):
    """What a list of poses says at a point of the strike, 0 to 1: between the two nearest."""
    k = hit * (len(values) - 1)
    a = min(int(k), len(values) - 2)
    return values[a] + (values[a + 1] - values[a]) * (k - a)

def pose(kind, p, frame, strikes=8):
    """Frames 0–7 walk; the rest strike."""
    kind = POSE_AS.get(kind, kind)
    rest(p)
    walking = frame < 8
    t = (frame % 8) / 8 * math.tau
    s, bob = math.sin(t), abs(math.sin(t))
    hit = (frame - 8) / (strikes - 1) if not walking else 0          # 0 … 1 along the strike
    r = math.radians
    swing = math.sin(hit * math.pi)
    # (A lunge goes the way it faces.)
    ahead = -1 if "turn" in p["root"].keys() else 1
    if kind in ("knight", "archer", "mage", "zombie", "skeleton", "boss", "enderman", "ender_giant", "golem", "cleric"):
        stride = {"boss": 26, "enderman": 22, "ender_giant": 20, "golem": 22, "cleric": 24}.get(kind, 34)
        if walking:
            p["leg_r"].rotation_euler.y = r(stride * s)
            p["leg_l"].rotation_euler.y = r(-stride * s)
            p["root"].location.z = 0.7 * bob
            p["head"].rotation_euler.y = r(2 * s)
        if kind in ("zombie", "boss"):
            # Arms out in front, as they do; to strike, up and down on whoever is there.
            lift = -84 if walking else along((-84, -120, -140, -60, -30, -50, -70, -84), hit)
            p["arm_r"].rotation_euler.y = r(lift + 5 * s)
            p["arm_l"].rotation_euler.y = r(lift - 5 * s)
            p["body"].rotation_euler.y = r(4 if walking else along((4, -4, -8, 14, 18, 12, 8, 4), hit))
            if not walking:
                p["leg_r"].rotation_euler.y = r(-18 * swing)
        elif kind == "enderman":
            p["arm_r"].rotation_euler.y = r(-10 * s if walking else along((0, -60, -150, -170, -60, -20, -10, 0), hit))
            p["arm_l"].rotation_euler.y = r(10 * s if walking else along((0, -40, -130, -165, -70, -25, -10, 0), hit))
            p["body"].rotation_euler.y = r(0 if walking else along((0, -4, -8, -8, 12, 10, 4, 0), hit))
        elif kind == "ender_giant":
            # Both arms up and forward, and down on whoever is there: not as high as its head.
            p["arm_r"].rotation_euler.y = r(-8 * s if walking else along((0, -50, -118, -126, -60, -20, -10, 0), hit))
            p["arm_l"].rotation_euler.y = r(8 * s if walking else along((0, -36, -104, -120, -66, -24, -10, 0), hit))
            p["body"].rotation_euler.y = r(0 if walking else along((0, -4, -8, -8, 12, 10, 4, 0), hit))
        elif kind == "golem":
            p["root"].location.z = 0.5 * bob
            if walking:
                p["arm_r"].rotation_euler.y = r(-9 * s)
                p["arm_l"].rotation_euler.y = r(9 * s)
                p["body"].rotation_euler.x = r(2.5 * s)
            else:
                # Both arms back and up, and down hard on what is in front.
                p["arm_r"].rotation_euler.y = r(along((0, -60, -118, -128, -74, -44, -38, -10), hit))
                p["arm_l"].rotation_euler.y = r(along((0, -52, -110, -124, -78, -46, -38, -10), hit))
                p["body"].rotation_euler.y = r(along((0, -4, -8, -10, 6, 14, 10, 2), hit))
                p["root"].location.x = along((0, -0.5, -1, -1, 1, 2, 1.5, 0), hit)
        elif kind == "cleric":
            p["arm_l"].rotation_euler.y = r(-56)
            p["charm"].scale = (0, 0, 0)
            if walking:
                p["arm_r"].rotation_euler.y = r(-56)
            else:
                # One hand out of the sleeve and up, with what heals in it.
                p["muff"].scale = (0, 0, 0)
                p["charm"].scale = (1, 1, 1) if 1 <= frame - 8 <= 6 else (0, 0, 0)
                p["arm_r"].rotation_euler.y = r(along((-56, -96, -132, -148, -148, -144, -110, -56), hit))
                p["arm_l"].rotation_euler.y = r(along((-56, -40, -24, -20, -20, -24, -40, -56), hit))
                p["body"].rotation_euler.y = r(along((0, -3, -6, -8, -8, -6, -3, 0), hit))
                p["head"].rotation_euler.y = r(along((0, -4, -10, -14, -14, -10, -4, 0), hit))
        elif kind == "knight":
            p["arm_l"].rotation_euler.y = r(6 * s - 30)
            if walking:
                p["arm_r"].rotation_euler.y = r(-14 * s - 8)
            else:
                # Back over the shoulder, down hard in front, and through.
                p["arm_r"].rotation_euler.y = r(along((-20, -90, -150, -165, -70, -5, 12, -8), hit))
                p["grip"].rotation_euler.y = r(along((68, 60, 40, 30, 70, 95, 90, 68), hit))
                p["body"].rotation_euler.y = r(along((0, -5, -10, -12, 8, 14, 9, 2), hit))
                p["root"].location.x = along((0, -0.5, -1, -1, 1.5, 2.5, 1.5, 0), hit)
                p["leg_r"].rotation_euler.y = r(along((0, 6, 10, 10, -14, -20, -10, 0), hit))
                p["leg_l"].rotation_euler.y = r(along((0, -4, -8, -8, 10, 14, 8, 0), hit))
        elif kind in ("archer", "skeleton"):
            if walking:
                p["arm_r"].rotation_euler.y = r(-20 * s)
                p["arm_l"].rotation_euler.y = r(16 * s - 12)
                string(p, None)
            else:
                # The bow comes up, the string comes back with an arrow on it, and it is let go.
                p["arm_l"].rotation_euler.y = r(along((-30, -70, -89, -89, -89, -89, -89, -60), hit))
                p["arm_r"].rotation_euler.y = r(along((-20, -60, -82, -78, -74, -72, -80, -40), hit))
                p["body"].rotation_euler.z = r(along((0, 8, 14, 14, 14, 14, 12, 4), hit))
                p["head"].rotation_euler.z = r(-along((0, 8, 14, 14, 14, 14, 12, 4), hit))
                step = frame - 8
                string(p, (None, 0, 2, 4.5, 6.5, 7, None, None)[min(step, 7)] if strikes == 8 else (None, 3, 7, None)[min(step, 3)])
        elif kind == "mage":
            p["arm_l"].rotation_euler.y = r(14 * s)
            if walking:
                p["arm_r"].rotation_euler.y = r(-26 + 4 * s)
            else:
                # Back over the shoulder, and thrown: the flask leaves the hand halfway.
                p["arm_r"].rotation_euler.y = r(along((-26, -100, -170, -200, -110, -40, -10, -26), hit))
                p["body"].rotation_euler.y = r(along((0, -6, -12, -14, 10, 14, 8, 0), hit))
                p["root"].location.x = along((0, -0.5, -1, -1, 1.5, 2, 1, 0), hit)
                if frame - 8 >= 4:
                    p["flask"].scale = (0, 0, 0)
    elif kind == "creeper":
        if walking:
            for name, sign in (("leg_fr", 1), ("leg_bl", 1), ("leg_fl", -1), ("leg_br", -1)):
                p[name].rotation_euler.y = r(30 * s * sign)
            p["root"].location.z = 0.5 * bob
            p["head"].rotation_euler.z = r(4 * s)
        else:
            # It swells before it goes off.
            k = 1 + along((0.02, 0.06, 0.1, 0.15, 0.2, 0.25, 0.3, 0.36), hit)
            p["body"].scale = (k, k, k)
    elif kind == "wolf":
        for name, sign in (("leg_fr", 1), ("leg_bl", 1), ("leg_fl", -1), ("leg_br", -1)):
            p[name].rotation_euler.y = r(34 * s * sign) if walking else r(-22 * swing * sign)
        p["tail"].rotation_euler.y = r(-50 + 12 * s)
        if walking:
            p["root"].location.z = 0.8 * bob
        else:
            p["root"].location.x = 4 * swing * ahead
            p["root"].location.z = 2 * swing
            p["head"].rotation_euler.y = r(along((0, -14, -20, 10, 26, 18, 8, 0), hit))
    elif kind == "slime":
        # It gathers itself, leaps and lands flat.
        if walking:
            up = max(0.0, math.sin(t))
            squash = 1 - 0.22 * max(0.0, -math.sin(t)) + 0.12 * up
            p["body"].scale = (1 + (1 - squash) * 0.6, 1 + (1 - squash) * 0.6, squash)
            p["root"].location.z = 9 * up
        else:
            p["root"].location.x = 5 * swing * ahead
            p["root"].location.z = 4 * swing
            squash = 1 - 0.18 * math.sin(hit * math.tau)
            p["body"].scale = (1 + (1 - squash) * 0.6, 1 + (1 - squash) * 0.6, squash)
    elif kind == "magma_titan":
        # It hops as a slime does, and its layers come apart as it goes up.
        up = max(0.0, math.sin(t)) if walking else swing
        gap = 1.5 * up
        for k in range(4):
            p["layer%d" % k].location.z = k * 5 + k * gap
        p["core"].scale = (1, 1, 1 + gap * 3 / 16)
        if walking:
            squash = 1 - 0.16 * max(0.0, -math.sin(t))
            p["body"].scale = (1 + (1 - squash) * 0.6, 1 + (1 - squash) * 0.6, squash)
            p["root"].location.z = 8 * up
        else:
            p["root"].location.x = 5 * swing * ahead
            p["root"].location.z = 3 * swing
    elif kind == "spider":
        for name, l in p.items():
            if not name.startswith("leg_"):
                continue
            k = int(name[4])
            phase = t + k * math.pi / 2 + (0 if l["side"] < 0 else math.pi)
            l.rotation_euler.z = r(-18 + k * 12 + (16 * math.sin(phase) if walking else 8 * swing))
            l.rotation_euler.x = r(l["side"] * (6 * max(0, math.cos(phase)) if walking else 0))
        if walking:
            p["root"].location.z = 0.4 * bob
        else:
            p["root"].location.x = 4 * swing * ahead
            p["root"].location.z = 2.5 * swing
            p["head"].rotation_euler.y = r(-22 * swing)

# ── the camera, the light and how it is rendered ──
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam

def look(side, scale, aim_z):
    """From the front and a little above: heroes are seen from their right, the rest from their left."""
    yaw, pitch, far = math.radians(40) * side, math.radians(16), 300
    cam.location = (math.sin(yaw) * far * math.cos(pitch), -math.cos(yaw) * far * math.cos(pitch), aim_z + math.sin(pitch) * far)
    direction = Vector((0, 0, aim_z)) - Vector(cam.location)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam_data.ortho_scale = scale

r_ = scene.render
r_.film_transparent = True
r_.image_settings.file_format = "PNG"
r_.image_settings.color_mode = "RGBA"
r_.resolution_percentage = 100
scene.view_settings.view_transform = "Standard"
scene.view_settings.exposure = 0.75
r_.engine = "BLENDER_WORKBENCH"
sh = scene.display.shading
sh.light = "STUDIO"
sh.color_type = "TEXTURE"
sh.show_shadows = False
sh.show_cavity = True
sh.cavity_type = "WORLD"
sh.show_object_outline = True
sh.object_outline_color = (0.02, 0.02, 0.03)
sh.show_specular_highlight = False
try:
    scene.display.render_aa = "16"
except TypeError:
    pass

def clear():
    for o in list(bpy.data.objects):
        if o is not cam:
            bpy.data.objects.remove(o, do_unlink=True)

SCALE = {"spider": 40, "mage": 50, "boss": 46, "enderman": 62, "wolf": 40, "slime": 40,
         "golem": 52, "cleric": 46, "husk": 50, "great_slime": 47, "frost_archer": 48, "magma_titan": 47, "ender_giant": 68}
AIM = {"spider": 12, "mage": 21, "boss": 18.5, "enderman": 26, "wolf": 14, "slime": 13,
       "golem": 19, "cleric": 19, "husk": 20, "great_slime": 17.2, "frost_archer": 19, "magma_titan": 16.2, "ender_giant": 28}
for kind, (build, team) in KINDS.items():
    if ONLY and kind not in ONLY:
        continue
    parts = build()
    if team == "foe":
        parts["root"]["turn"] = math.pi             # the rest come from the right
    r_.resolution_x = r_.resolution_y = 512 if kind in LORDS else 256
    look(1 if team == "hero" else -1, SCALE.get(kind, 44), AIM.get(kind, 18))
    strikes = 4 if kind in LORDS else 8
    for frame in range(8 + strikes):
        pose(kind, parts, frame, strikes)
        r_.filepath = "%s/%s/%02d.png" % (OUT, kind, frame)
        bpy.ops.render.render(write_still=True)
    clear()
    print("made", kind)

for kind, build in BLOCKS.items():
    if ONLY and kind not in ONLY:
        continue
    build()
    r_.resolution_x = r_.resolution_y = 192
    look(1, 33, 8)
    r_.filepath = "%s/blocks/%s.png" % (OUT, kind)
    bpy.ops.render.render(write_still=True)
    clear()
    print("made", kind)
