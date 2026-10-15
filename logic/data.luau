-- Edge guard's tables: the things, who can carry what, what is made of what,
-- who lives in each land, what a thing can be enchanted with, and the feats.
return function(G)
    -- The pictures of things, by their place on the sheet (eight to a row).
    local ITEM = { stick = 0, iron = 1, diamond = 2, string = 3, bone = 4, gunpowder = 5, flesh = 6, slimeball = 7, pearl = 8,
                   iron_sword = 9, diamond_sword = 10, iron_chest = 11, diamond_chest = 12, bow = 13, power_bow = 14, wand = 15,
                   tnt = 16, heal_potion = 17, cobweb = 18, collar = 19, slime_charm = 20, ender_charm = 21, potion = 22, wood_sword = 23,
                   arrow = 24, orb = 25, heart = 26, book = 29,
                   raw_iron = 30, raw_gold = 31, gold = 32, coal = 33, lapis = 34, redstone = 35, ice = 36, blaze_rod = 37, scrap = 38,
                   wheat = 39, bread = 40, iron_block = 41,
                   netherite_sword = 42, crossbow = 43, frost_bow = 44, blaze_staff = 45, ender_staff = 46,
                   iron_helmet = 47, diamond_helmet = 48, netherite_helmet = 49, iron_boots = 50, diamond_boots = 51, netherite_boots = 52,
                   netherite_chest = 53, wood_pick = 54, iron_pick = 55, diamond_pick = 56,
                   crown = 57, scarab = 58, slime_core = 59, frost_string = 60, magma_heart = 61, giant_eye = 62,
                   totem = 63, bell = 64, golem_core = 65, star = 66, lock = 67, skull = 68, map = 69,
                   tab_craft = 70, tab_furnace = 71, tab_enchant = 72, cup = 73, bolt = 74, emerald = 75, xp_bottle = 76 }
    local NAMES = { stick = "Stick", iron = "Iron Ingot", diamond = "Diamond", string = "String", bone = "Bone", gunpowder = "Gunpowder", flesh = "Rotten Flesh",
                    slimeball = "Slimeball", pearl = "Ender Pearl", wood_sword = "Wooden Sword", bow = "Bow", potion = "Splash Potion",
                    raw_iron = "Raw Iron", raw_gold = "Raw Gold", gold = "Gold Ingot", coal = "Coal", lapis = "Lapis Lazuli", redstone = "Redstone Dust",
                    ice = "Frost Shard", blaze_rod = "Ember Rod", scrap = "Netherite Scrap", wheat = "Wheat", iron_block = "Block of Iron",
                    crown = "King's Crown", scarab = "Desert Scarab", slime_core = "Great Slime's Core", frost_string = "Frozen Bowstring",
                    magma_heart = "Magma Heart", giant_eye = "Eye of the Giant", emerald = "Emerald" }

    -- What is made and handed over, or used. `slot`: 1 a weapon, 2 a helmet,
    -- 3 a chestplate, 4 boots, 5 a charm; `who`, the only one that can use it;
    -- `use`, something that is spent from the bar. Of a thing that piles up,
    -- `pile` says how high.
    local GEAR = {
        iron_sword       = { name = "Iron Sword",          slot = 1, who = "knight", dmg = 1.6, says = "the knight hits 60% harder" },
        diamond_sword    = { name = "Diamond Sword",       slot = 1, who = "knight", dmg = 2.4, says = "the knight hits more than twice as hard" },
        netherite_sword  = { name = "Netherite Sword",     slot = 1, who = "knight", dmg = 3.4, says = "the knight hits more than three times as hard" },
        power_bow        = { name = "Power Bow",           slot = 1, who = "archer", dmg = 1.6, says = "the archer's arrows hit 60% harder" },
        crossbow         = { name = "Crossbow",            slot = 1, who = "archer", dmg = 2.4, says = "the archer's bolts hit more than twice as hard" },
        frost_bow        = { name = "Frost Bow",           slot = 1, who = "archer", dmg = 3.4, slows = true, says = "more than three times as hard, and it slows what it hits" },
        wand             = { name = "Redstone Wand",       slot = 1, who = "witch",  dmg = 1.6, says = "the witch's potions hit 60% harder" },
        blaze_staff      = { name = "Ember Staff",         slot = 1, who = "witch",  dmg = 2.4, burns = true, says = "more than twice as hard, and it sets them on fire" },
        ender_staff      = { name = "Staff of the Giant",  slot = 1, who = "witch",  dmg = 3.4, burns = true, says = "more than three times as hard, and it sets them on fire" },
        iron_helmet      = { name = "Iron Helmet",         slot = 2, life = 1.2,  says = "a fifth more life" },
        diamond_helmet   = { name = "Diamond Helmet",      slot = 2, life = 1.4,  says = "two fifths more life" },
        netherite_helmet = { name = "Netherite Helmet",    slot = 2, life = 1.6,  says = "three fifths more life" },
        iron_chest       = { name = "Iron Chestplate",     slot = 3, life = 1.5,  says = "half as much life again" },
        diamond_chest    = { name = "Diamond Chestplate",  slot = 3, life = 2.2,  says = "more than twice the life" },
        netherite_chest  = { name = "Netherite Chestplate", slot = 3, life = 3.0, says = "three times the life" },
        iron_boots       = { name = "Iron Boots",          slot = 4, life = 1.15, says = "a little more life" },
        diamond_boots    = { name = "Diamond Boots",       slot = 4, life = 1.3,  says = "a third more life" },
        netherite_boots  = { name = "Netherite Boots",     slot = 4, life = 1.5,  says = "half as much life again" },
        slime_charm      = { name = "Slime Charm",         slot = 5, slows = true, says = "whoever carries it slows what it hits" },
        ender_charm      = { name = "Eye of Ender",        slot = 5, dodge = 0.3, says = "whoever carries it steps aside from one blow in three" },
        totem            = { name = "Totem of the Sands",  slot = 5, revive = true, says = "whoever carries it gets up once a wave, instead of falling" },
        tnt              = { name = "TNT",                 use = "tnt",  pile = 16, says = "press it on the bar, then where it should land" },
        heal_potion      = { name = "Potion of Healing",   use = "heal", pile = 16, says = "thrown, it gives half their life back to whoever it splashes" },
        cobweb           = { name = "Cobweb",              use = "web",  pile = 16, says = "thrown, it holds back whatever walks into it" },
        collar           = { name = "Wolf Collar",         use = "tame", pile = 16, says = "press it on the bar and a wolf joins the camp" },
        bread            = { name = "Bread",               use = "feast", pile = 16, says = "press it on the bar: a third of their life back to everyone" },
        iron_pick        = { name = "Iron Pickaxe",        use = "pick", level = 2, says = "press it on the bar: the mine digs faster and finds gold, lapis and redstone" },
        diamond_pick     = { name = "Diamond Pickaxe",     use = "pick", level = 3, says = "press it on the bar: the mine digs faster still, and finds diamonds" },
        golem_core       = { name = "Heart of Iron",       use = "golem", says = "press it on the bar and an iron golem stands with the party" },
        bell             = { name = "Village Bell",        use = "cleric", says = "press it on the bar and a cleric comes to heal the party" },
        xp_bottle        = { name = "Bottle o' Enchanting", use = "xp", pile = 16, says = "press it on the bar: a level of experience to spend" },
    }
    for id, def in GEAR do NAMES[id] = def.name end
    G.ITEM, G.NAMES, G.GEAR = ITEM, NAMES, GEAR
    function G.pile(id) return GEAR[id] and (GEAR[id].pile or 1) or 64 end

    -- What a weapon or a piece of armour can be enchanted with, and how far.
    G.ENCH = {
        sharp  = { name = "Sharpness",    max = 5, on = "weapon", says = "20% harder a level" },
        loot   = { name = "Looting",      max = 3, on = "weapon", says = "what it fells leaves more" },
        fire   = { name = "Fire Aspect",  max = 2, on = "weapon", says = "what it hits burns" },
        haste  = { name = "Swiftness",    max = 3, on = "weapon", says = "10% faster a level" },
        prot   = { name = "Protection",   max = 4, on = "armour", says = "4% less harm a level" },
        thorns = { name = "Thorns",       max = 3, on = "armour", says = "gives back a tenth of each blow a level" },
        mend   = { name = "Regeneration", max = 3, on = "armour", says = "life comes back by itself" },
    }
    G.ENCH_ORDER = { "sharp", "loot", "fire", "haste", "prot", "thorns", "mend" }
    G.ROMAN = { "I", "II", "III", "IV", "V" }

    -- What each kind is: its sheet (0 the horde's, 2 the lords', 3 the party's
    -- own) and row, how much it takes, how fast it walks, what it does and
    -- what it leaves. A lord has its pictures on the lords' sheet
    -- (`boss`: which one), a trophy, an attack that it announces (`special`)
    -- and its own to call when half of it is gone (`calls`).
    G.KIND = {
        zombie   = { name = "Zombie",   sheet = 0, row = 0, hp = 40,  speed = 46,  dmg = 6,  every = 1.0,  xp = 2,  reach = 46,  foot = 99,  drops = { { "flesh", 0.6 }, { "iron", 0.08 } } },
        skeleton = { name = "Skeleton", sheet = 0, row = 1, hp = 26,  speed = 60,  dmg = 5,  every = 1.7,  xp = 2,  reach = 480, foot = 97,  shoots = true, drops = { { "bone", 0.7 }, { "stick", 0.25 } } },
        creeper  = { name = "Creeper",  sheet = 0, row = 2, hp = 32,  speed = 60,  dmg = 38, every = 1.0,  xp = 3,  reach = 52,  foot = 100, bursts = true, drops = { { "gunpowder", 0.85 } } },
        spider   = { name = "Spider",   sheet = 0, row = 3, hp = 22,  speed = 150, dmg = 4,  every = 0.55, xp = 2,  reach = 54,  foot = 94,  climbs = true, drops = { { "string", 0.8 } } },
        enderman = { name = "Enderman", sheet = 0, row = 4, hp = 60,  speed = 52,  dmg = 10, every = 1.0,  xp = 4,  reach = 50,  foot = 98,  blinks = true, drops = { { "pearl", 0.6 } } },
        slime    = { name = "Slime",    sheet = 0, row = 5, hp = 34,  speed = 70,  dmg = 5,  every = 0.9,  xp = 2,  reach = 42,  foot = 93,  hops = true, splits = true, drops = { { "slimeball", 0.9 } } },
        hag      = { name = "Swamp Witch", sheet = 3, row = 2, hp = 30, speed = 50, dmg = 9,  every = 2.4,  xp = 3,  reach = 420, foot = 99,  throws = true, drops = { { "redstone", 0.6 }, { "gunpowder", 0.3 }, { "stick", 0.3 } } },
        king         = { name = "Zombie King",      boss = 0, sheet = 2, hp = 700, speed = 16, dmg = 22, every = 1.3, xp = 40, reach = 92,  foot = 193, big = true,
                         trophy = "crown", special = "slam", calls = "zombie" },
        husk_king    = { name = "Husk King",        boss = 1, sheet = 2, hp = 760, speed = 15, dmg = 20, every = 1.3, xp = 50, reach = 92,  foot = 193, big = true, ail = 1,
                         trophy = "scarab", special = "storm", calls = "husk" },
        great_slime  = { name = "The Great Slime",  boss = 2, sheet = 2, hp = 640, speed = 42, dmg = 20, every = 1.4, xp = 60, reach = 104, foot = 193, big = true, hops = true, parts = 3,
                         trophy = "slime_core", special = "leap", calls = "slime" },
        frost_archer = { name = "The Frost Archer", boss = 3, sheet = 2, hp = 520, speed = 20, dmg = 16, every = 1.9, xp = 70, reach = 560, foot = 193, big = true, shoots = true, ail = 2, size = 1.15,
                         trophy = "frost_string", special = "volley", calls = "stray" },
        magma_titan  = { name = "The Magma Titan",  boss = 4, sheet = 2, hp = 700, speed = 40, dmg = 22, every = 1.4, xp = 80, reach = 104, foot = 193, big = true, hops = true, parts = 3, ail = 3,
                         trophy = "magma_heart", special = "erupt", calls = "magma" },
        ender_giant  = { name = "The Ender Giant",  boss = 5, sheet = 2, hp = 820, speed = 22, dmg = 24, every = 1.2, xp = 90, reach = 100, foot = 193, big = true, size = 1.15,
                         trophy = "giant_eye", special = "blink", calls = "endermite" },
    }
    for _, k in G.KIND do
        if k.boss then k.drops = { { "diamond", 1 }, { "diamond", 1 }, { "iron", 1 }, { "iron", 1 }, { "iron", 1 } } end
    end
    -- What a lord's announced attack is, how long it takes to come, how near the party it has to be, and what is told of it.
    G.SPECIAL = {
        slam   = { time = 3.0, within = 330, says = "raises its fists - TNT or the lightning stops it" },
        storm  = { time = 3.0, within = 700, says = "calls a sandstorm - TNT or the lightning stops it" },
        leap   = { time = 2.8, within = 900, says = "gathers itself to leap - a cobweb where it will land" },
        volley = { time = 3.0, within = 800, says = "draws a volley of ice - TNT or the lightning stops it" },
        erupt  = { time = 2.8, within = 900, says = "makes the ground glow - move the party off the marks" },
        blink  = { time = 2.8, within = 900, says = "is about to step behind the party - a cobweb on the mark" },
    }

    -- The ones of a land that are not quite the plain kind: `VARIANT[id]` says
    -- what makes them that land's: a name, a colour (`wash`), how much more
    -- they take, how fast they are, what their blow leaves (`ail`: 1 slowed,
    -- 2 frozen, 3 burning) and what else they drop.
    G.VARIANT = {
        husk      = { kind = "zombie",   name = "Husk",             wash = 1, hp = 1.5, ail = 1, drops = { { "raw_gold", 0.3 } } },
        stray     = { kind = "skeleton", name = "Stray",            wash = 2, ail = 2, drops = { { "ice", 0.5 } } },
        frozen    = { kind = "zombie",   name = "Frozen Zombie",    wash = 2, speed = 0.8, hp = 1.3, drops = { { "ice", 0.25 } } },
        piglin    = { kind = "zombie",   name = "Zombified Piglin", wash = 4, speed = 1.7, hp = 0.8, drops = { { "raw_gold", 0.4 } } },
        magma     = { kind = "slime",    name = "Magma Cube",       wash = 3, ail = 3, drops = { { "blaze_rod", 0.35 } } },
        wither    = { kind = "skeleton", name = "Wither Skeleton",  wash = 6, hp = 1.6, ail = 3, drops = { { "coal", 0.5 }, { "scrap", 0.12 } } },
        endermite = { kind = "spider",   name = "Endermite",        wash = 5, size = 0.55, speed = 1.3, hp = 0.5, drops = { { "pearl", 0.08 } } },
    }
    for id, v in G.VARIANT do v.id = id end

    -- The lands: five waves each, the last with its lord. `who`: a kind or a
    -- variant, and how often; the rarer ones come as the land goes on.
    -- `things`: what is found there more than anywhere else.
    G.LANDS = {
        { name = "The Plains", short = "Plains", lord = "king",         things = { "flesh", "bone", "string" },
          who = { { "zombie", 5 }, { "skeleton", 3 }, { "spider", 2 } } },
        { name = "The Desert", short = "Desert", lord = "husk_king",    things = { "gunpowder", "raw_gold" },
          who = { { "husk", 5 }, { "creeper", 3 }, { "skeleton", 2 }, { "spider", 1 } } },
        { name = "The Swamp",  short = "Swamp",  lord = "great_slime",  things = { "slimeball", "redstone" },
          who = { { "slime", 5 }, { "zombie", 3 }, { "hag", 2 }, { "spider", 1 } } },
        { name = "The Tundra", short = "Tundra", lord = "frost_archer", things = { "ice", "bone" },
          who = { { "stray", 5 }, { "frozen", 3 }, { "spider", 1 }, { "creeper", 1 } } },
        { name = "The Nether", short = "Nether", lord = "magma_titan",  things = { "blaze_rod", "scrap", "raw_gold" },
          who = { { "piglin", 5 }, { "magma", 4 }, { "wither", 2 } } },
        { name = "The End",    short = "End",    lord = "ender_giant",  things = { "pearl", "diamond" },
          who = { { "enderman", 5 }, { "endermite", 4 }, { "creeper", 1 } } },
    }

    -- Everything there is to meet, in the order the book shows it: a kind, or a variant of one.
    G.BEASTS = { "zombie", "skeleton", "spider", "king", "husk", "creeper", "husk_king", "slime", "hag", "great_slime",
                 "stray", "frozen", "frost_archer", "piglin", "magma", "wither", "magma_titan", "enderman", "endermite", "ender_giant" }
    function G.beast(id)
        -- What the book needs of one: its name, where its picture is, and all it can leave.
        local v = G.VARIANT[id]
        local k = G.KIND[v and v.kind or id]
        local drops = {}
        for _, d in k.drops do
            if not table.find(drops, d[1]) then table.insert(drops, d[1]) end
        end
        for _, d in (v and v.drops or {}) do
            if not table.find(drops, d[1]) then table.insert(drops, d[1]) end
        end
        if k.trophy then table.insert(drops, 1, k.trophy) end
        return { name = v and v.name or k.name, sheet = k.sheet, cell = k.boss and k.boss * 8 or k.row * 16, wash = v and v.wash or 0,
                 lord = k.boss ~= nil, drops = drops }
    end

    -- ── the book: what can be made, laid out as it has to be on the grid ──
    -- A row of letters for each row of the grid, a space for an empty slot;
    -- `key` says what each letter is. It may sit anywhere on the grid, and
    -- mirrored. `keeps`: the letter of the thing whose enchantments go on to
    -- what is made of it.
    G.RECIPES = {
        { out = "iron_sword",       n = 1, rows = { "I", "I", "S" },          key = { I = "iron", S = "stick" } },
        { out = "iron_helmet",      n = 1, rows = { "III", "I I" },           key = { I = "iron" } },
        { out = "iron_chest",       n = 1, rows = { "I I", "III", "III" },    key = { I = "iron" } },
        { out = "iron_boots",       n = 1, rows = { "I I", "I I" },           key = { I = "iron" } },
        { out = "power_bow",        n = 1, rows = { " ST", "S T", " ST" },    key = { S = "stick", T = "string" } },
        { out = "crossbow",         n = 1, rows = { "SIS", "TIT", " S " },    key = { S = "stick", I = "iron", T = "string" } },
        { out = "wand",             n = 1, rows = { "R", "R", "S" },          key = { R = "redstone", S = "stick" } },
        { out = "diamond_sword",    n = 1, rows = { "D", "D", "S" },          key = { D = "diamond", S = "stick" } },
        { out = "diamond_helmet",   n = 1, rows = { "DDD", "D D" },           key = { D = "diamond" } },
        { out = "diamond_chest",    n = 1, rows = { "D D", "DDD", "DDD" },    key = { D = "diamond" } },
        { out = "diamond_boots",    n = 1, rows = { "D D", "D D" },           key = { D = "diamond" } },
        { out = "netherite_sword",  n = 1, rows = { " C ", "CXC", " C " },    key = { C = "scrap", X = "diamond_sword" },  keeps = "X" },
        { out = "netherite_helmet", n = 1, rows = { " C ", "CXC", " C " },    key = { C = "scrap", X = "diamond_helmet" }, keeps = "X" },
        { out = "netherite_chest",  n = 1, rows = { " C ", "CXC", " C " },    key = { C = "scrap", X = "diamond_chest" },  keeps = "X" },
        { out = "netherite_boots",  n = 1, rows = { " C ", "CXC", " C " },    key = { C = "scrap", X = "diamond_boots" },  keeps = "X" },
        { out = "frost_bow",        n = 1, rows = { " CT", "D F", " CT" },    key = { C = "ice", D = "diamond", T = "string", F = "frost_string" } },
        { out = "blaze_staff",      n = 1, rows = { "H", "B", "B" },          key = { H = "magma_heart", B = "blaze_rod" } },
        { out = "ender_staff",      n = 1, rows = { " E ", "PBP", " B " },    key = { E = "giant_eye", P = "pearl", B = "blaze_rod" } },
        { out = "slime_charm",      n = 1, rows = { " T ", "LLL", " L " },    key = { T = "string", L = "slimeball" } },
        { out = "ender_charm",      n = 1, rows = { " T ", "PPP" },           key = { T = "string", P = "pearl" } },
        { out = "totem",            n = 1, rows = { " G ", "GSG", " G " },    key = { G = "gold", S = "scarab" } },
        { out = "tnt",              n = 1, rows = { "G G", " G ", "G G" },    key = { G = "gunpowder" } },
        { out = "heal_potion",      n = 2, rows = { "FF", "FF" },             key = { F = "flesh" } },
        { out = "cobweb",           n = 2, rows = { "TT", "TT" },             key = { T = "string" } },
        { out = "bread",            n = 1, rows = { "WWW" },                  key = { W = "wheat" } },
        { out = "collar",           n = 1, rows = { "BB", "BB" },             key = { B = "bone" } },
        { out = "iron_pick",        n = 1, rows = { "III", " S ", " S " },    key = { I = "iron", S = "stick" } },
        { out = "diamond_pick",     n = 1, rows = { "DDD", " S ", " S " },    key = { D = "diamond", S = "stick" } },
        { out = "iron_block",       n = 1, rows = { "III", "III", "III" },    key = { I = "iron" } },
        { out = "golem_core",       n = 1, rows = { " K ", "BBB", " B " },    key = { K = "crown", B = "iron_block" } },
        { out = "bell",             n = 1, rows = { " S ", "GCG", "G G" },    key = { S = "stick", G = "gold", C = "slime_core" } },
    }
    for _, r in G.RECIPES do
        -- How many of each it takes.
        r.needs = {}
        for _, row in r.rows do
            for c = 1, #row do
                local id = r.key[row:sub(c, c)]
                if id then r.needs[id] = (r.needs[id] or 0) + 1 end
            end
        end
    end
    G.SAYS = { iron_block = "four of them and a king's crown make something that walks" }

    -- The furnace: what becomes what, and how many things a piece of fuel smelts.
    G.SMELT = { raw_iron = "iron", raw_gold = "gold" }
    G.FUEL = { coal = 8, stick = 1 }
    G.SMELT_TIME = 6
    -- The mine, by its pickaxe: a thing every so many seconds, how many it
    -- keeps until they are fetched, and what it finds (and how often).
    G.MINE = {
        { every = 20, holds = 48,  finds = { { "raw_iron", 55 }, { "coal", 45 } } },
        { every = 13, holds = 96,  finds = { { "raw_iron", 40 }, { "coal", 25 }, { "raw_gold", 15 }, { "lapis", 12 }, { "redstone", 8 } } },
        { every = 8,  holds = 160, finds = { { "raw_iron", 32 }, { "coal", 20 }, { "raw_gold", 16 }, { "lapis", 14 }, { "redstone", 10 }, { "diamond", 8 } } },
    }
    G.PICKS = { "wood_pick", "iron_pick", "diamond_pick" }
    -- The field of wheat: how long from sown to golden, in seconds.
    G.FARM_TIME = 240

    -- The feats: what there is to have done, and the thing that stands for each.
    G.FEATS = {
        { id = "blood",    name = "First Blood",        says = "Fell a foe",                         icon = "wood_sword" },
        { id = "craft",    name = "Handmade",           says = "Make something at the table",        icon = "tab_craft" },
        { id = "smelt",    name = "Smelter",            says = "Take an ingot out of the furnace",   icon = "tab_furnace" },
        { id = "enchant",  name = "Spellbound",         says = "Enchant a thing",                    icon = "tab_enchant" },
        { id = "harvest",  name = "Green Thumb",        says = "Reap the wheat ten times",           icon = "wheat" },
        { id = "pick",     name = "Deep Down",          says = "Give the mine a diamond pickaxe",    icon = "diamond_pick" },
        { id = "ironclad", name = "Iron Clad",          says = "A hero in helmet, chestplate and boots", icon = "iron_chest" },
        { id = "shiny",    name = "Shiny",              says = "Make something of diamond",          icon = "diamond" },
        { id = "nether",   name = "Darker than Night",  says = "Make something of netherite",        icon = "netherite_chest" },
        { id = "pack",     name = "Pack Leader",        says = "Three wolves in the camp",           icon = "collar" },
        { id = "golem",    name = "A Friend of Iron",   says = "An iron golem joins the party",      icon = "golem_core" },
        { id = "cleric",   name = "Ring the Bell",      says = "A cleric joins the party",           icon = "bell" },
        { id = "catch",    name = "Not Today",          says = "Stop a lord's attack before it lands", icon = "bolt" },
        { id = "lord0",    name = "Kingslayer",         says = "Fell the Zombie King",               icon = "crown" },
        { id = "lord1",    name = "Dust to Dust",       says = "Fell the Husk King",                 icon = "scarab" },
        { id = "lord2",    name = "Sticky End",         says = "Fell the Great Slime",               icon = "slime_core" },
        { id = "lord3",    name = "Cold Snap",          says = "Fell the Frost Archer",              icon = "frost_string" },
        { id = "lord4",    name = "Meltdown",           says = "Fell the Magma Titan",               icon = "magma_heart" },
        { id = "lord5",    name = "The Giant Falls",    says = "Fell the Ender Giant",               icon = "giant_eye" },
        { id = "lucky",    name = "Lucky Day",          says = "Open a chest of the End",            icon = "pearl" },
        { id = "slayer",   name = "Slayer",             says = "A thousand foes felled",             icon = "skull" },
        { id = "scholar",  name = "Scholar",            says = "Meet everything in the book",        icon = "book" },
        { id = "maxed",    name = "Masterwork",         says = "An enchantment as far as it goes",   icon = "lapis" },
        { id = "trader",   name = "Good Deal",          says = "Trade with the villager 25 times",   icon = "emerald" },
        { id = "return",   name = "Back at You",        says = "Send a ghast's fireball back at it", icon = "blaze_rod" },
        { id = "dragon",   name = "Dragonfall",         says = "Fell the Ender Dragon",              icon = "pearl" },
        { id = "world",    name = "A New World",        says = "Step through with the Eye of the Giant", icon = "star" },
    }
end
