-- Edge guard's logic: where everyone is and what they do, every frame, and
-- what the hand asks for. The scene only draws what these lists say.

local W, H = 1920, 1080
on("wide", function(v) if v > 100 then W = v end end)
on("tall", function(v) if v > 100 then H = v end end)
local function ground() return H - 16 end

-- The pictures of things, by their place on the sheet.
local ITEM = { stick = 0, iron = 1, diamond = 2, string = 3, bone = 4, gunpowder = 5, flesh = 6, slimeball = 7, pearl = 8,
               iron_sword = 9, diamond_sword = 10, iron_chest = 11, diamond_chest = 12, bow = 13, power_bow = 14, wand = 15,
               tnt = 16, heal_potion = 17, cobweb = 18, collar = 19, slime_charm = 20, ender_charm = 21, potion = 22, wood_sword = 23,
               arrow = 24, orb = 25 }
local NAMES = { stick = "Stick", iron = "Iron Ingot", diamond = "Diamond", string = "String", bone = "Bone", gunpowder = "Gunpowder", flesh = "Rotten Flesh",
                slimeball = "Slimeball", pearl = "Ender Pearl", wood_sword = "Wooden Sword", bow = "Bow", potion = "Splash Potion" }

-- What is made and handed over, or used. `slot`: 1 a weapon, 2 armour, 3 a
-- charm; `who`, the only one that can use it; `use`, something that is spent
-- from the bar. Of a thing that piles up, `pile` says how high.
local GEAR = {
    iron_sword    = { name = "Iron Sword",         slot = 1, who = "knight", dmg = 1.6, says = "the knight hits 60% harder" },
    diamond_sword = { name = "Diamond Sword",      slot = 1, who = "knight", dmg = 2.4, says = "the knight hits more than twice as hard" },
    power_bow     = { name = "Power Bow",          slot = 1, who = "archer", dmg = 1.6, says = "the archer's arrows hit 60% harder" },
    wand          = { name = "Ender Wand",         slot = 1, who = "witch",  dmg = 1.6, says = "the witch's potions hit 60% harder" },
    iron_chest    = { name = "Iron Chestplate",    slot = 2, life = 1.5, says = "half as much life again" },
    diamond_chest = { name = "Diamond Chestplate", slot = 2, life = 2.2, says = "more than twice the life" },
    slime_charm   = { name = "Slime Charm",        slot = 3, slows = true, says = "whoever carries it slows what it hits" },
    ender_charm   = { name = "Eye of Ender",       slot = 3, dodge = 0.3, says = "whoever carries it steps aside from one blow in three" },
    tnt           = { name = "TNT",                use = "tnt",  pile = 16, says = "press it on the bar, then where it should land" },
    heal_potion   = { name = "Potion of Healing",  use = "heal", pile = 16, says = "thrown, it gives half their life back to whoever it splashes" },
    cobweb        = { name = "Cobweb",             use = "web",  pile = 16, says = "thrown, it holds back whatever walks into it" },
    collar        = { name = "Wolf Collar",        use = "tame", pile = 16, says = "press it on the bar and a wolf joins the camp" },
}
for id, def in GEAR do NAMES[id] = def.name end
local function pile(id) return GEAR[id] and (GEAR[id].pile or 1) or 64 end

-- What each kind is: its sheet and row, how much it takes, how fast it walks,
-- what it does and what it leaves.
local KIND = {
    zombie   = { sheet = 0, row = 0, hp = 40,  speed = 46,  dmg = 6,  every = 1.0,  xp = 2,  reach = 46,  foot = 99,  drops = { { "flesh", 0.6 }, { "iron", 0.08 } } },
    skeleton = { sheet = 0, row = 1, hp = 26,  speed = 60,  dmg = 5,  every = 1.7,  xp = 2,  reach = 480, foot = 97,  shoots = true, drops = { { "bone", 0.7 }, { "stick", 0.25 } } },
    creeper  = { sheet = 0, row = 2, hp = 32,  speed = 60,  dmg = 38, every = 1.0,  xp = 3,  reach = 52,  foot = 100, bursts = true, drops = { { "gunpowder", 0.85 } } },
    spider   = { sheet = 1, row = 0, hp = 22,  speed = 150, dmg = 4,  every = 0.55, xp = 2,  reach = 54,  foot = 94,  climbs = true, drops = { { "string", 0.8 } } },
    enderman = { sheet = 1, row = 1, hp = 60,  speed = 52,  dmg = 10, every = 1.0,  xp = 4,  reach = 50,  foot = 98,  blinks = true, drops = { { "pearl", 0.6 } } },
    slime    = { sheet = 1, row = 2, hp = 34,  speed = 70,  dmg = 5,  every = 0.9,  xp = 2,  reach = 42,  foot = 93,  hops = true, splits = true, drops = { { "slimeball", 0.9 } } },
    hag      = { sheet = 3, row = 2, hp = 30,  speed = 50,  dmg = 9,  every = 2.4,  xp = 3,  reach = 420, foot = 99,  throws = true, drops = { { "gunpowder", 0.4 }, { "stick", 0.4 } } },
    boss     = { sheet = 2, row = 0, hp = 700, speed = 26,  dmg = 22, every = 1.3,  xp = 40, reach = 92,  foot = 193, big = true,
                 drops = { { "diamond", 1 }, { "diamond", 1 }, { "iron", 1 }, { "iron", 1 }, { "iron", 1 } } },
}

-- The lands: five waves each, the last with its lord. Getting to one is a
-- place to come back to. Who lives there —a kind, how often, and what makes
-- it that land's: its colour (`wash`), how much more it takes, how fast it
-- is, and what its blow leaves (`ail`: 1 slowed, 2 frozen, 3 burning)—.
local LANDS = {
    { name = "The Plains", lord = { kind = "boss", name = "Zombie King" },
      who = { { "zombie", 5 }, { "skeleton", 3 }, { "spider", 2 } } },
    { name = "The Desert", lord = { kind = "boss", name = "Husk King", wash = 1, ail = 1 },
      who = { { "zombie", 5, wash = 1, hp = 1.5, ail = 1 }, { "creeper", 3 }, { "skeleton", 2 }, { "spider", 1 } } },
    { name = "The Swamp", lord = { kind = "slime", name = "The Great Slime", size = 2.6, hp = 18, splits = 3 },
      who = { { "slime", 5 }, { "zombie", 3 }, { "hag", 2 }, { "spider", 1 } } },
    { name = "The Tundra", lord = { kind = "skeleton", name = "The Frost Archer", size = 1.9, hp = 24, wash = 2, ail = 2 },
      who = { { "skeleton", 5, wash = 2, ail = 2 }, { "zombie", 3, wash = 2, speed = 0.8, hp = 1.3 }, { "spider", 1 }, { "creeper", 1 } } },
    { name = "The Nether", lord = { kind = "slime", name = "The Magma Titan", size = 2.6, hp = 22, wash = 3, ail = 3, splits = 3 },
      who = { { "zombie", 5, wash = 4, speed = 1.7, hp = 0.8 }, { "slime", 4, wash = 3, ail = 3 }, { "skeleton", 2, wash = 6, hp = 1.6, ail = 3 } } },
    { name = "The End", lord = { kind = "enderman", name = "The Ender Giant", size = 1.9, hp = 14 },
      who = { { "enderman", 5 }, { "spider", 4, wash = 5, size = 0.55, speed = 1.3, hp = 0.5 }, { "creeper", 1 } } },
}
local function land_of(w) return LANDS[((w - 1) // 5) % #LANDS + 1], ((w - 1) // 5) % #LANDS end
local function checkpoint(w) return ((w - 1) // 5) * 5 + 1 end

local heroes = {
    { name = "knight", shown = "Knight", row = 0, post = 520, base_max = 140, base_dmg = 10, every = 0.9, range = 80,   strike = 0.44, lands = 0.55, rest = "wood_sword" },
    { name = "archer", shown = "Archer", row = 1, post = 400, base_max = 70,  base_dmg = 8,  every = 1.2, range = 1250, strike = 0.62, lands = 0.75, rest = "bow" },
    { name = "witch",  shown = "Witch",  row = 2, post = 290, base_max = 60,  base_dmg = 14, every = 2.8, range = 840,  strike = 0.6,  lands = 0.5,  rest = "potion", splash = 90 },
}
for _, h in heroes do
    h.x, h.level, h.wait, h.hurt, h.walk, h.max, h.hp, h.gear = h.post, 1, 0, 0, 0, h.base_max, h.base_max, {}
end
local knight, archer, witch = heroes[1], heroes[2], heroes[3]

-- What is kept: 27 slots and then the bar of nine, each one a pile ({ id, n }) or nothing;
-- the crafting grid, the same; and what the mouse carries.
local inv, grid, held, ghosts, found = {}, {}, nil, nil, {}
local wolves = {}
local wave, xp, quiet = 1, 0, false
local horde, shots, bombs, drops, puffs = {}, {}, {}, {}, {}
local queue, spawn_in = {}, 0
local stage, stage_in = "start", 0          -- start · fight · rest · fallen
local chests = {}                            -- the chests the waves left, waiting to be opened
local paused, away = false, false
local smite_in, craft_in, bomb_in, save_in = 0, 3, 2, 15
local clock, last = 0, {}
-- What the hand is at: the backpack open, a thing chosen in it, a hero being carried.
local open, pages, armed, carried, auto = false, true, nil, nil, false

local function say(spec, every)
    -- Quiet, or the same sound too soon after itself: not said.
    if quiet then return end
    if every then
        local key = spec.wave .. spec.freq
        if clock - (last[key] or -9) < every then return end
        last[key] = clock
    end
    sound.tone(spec)
end
local function pan(x) return math.clamp((x / W) * 2 - 1, -1, 1) end

-- ── what each hero is worth, with its level and what it carries ──
local function gained() return knight.level + archer.level + witch.level - 3 end
local function refit()
    for _, h in heroes do
        local share = h.hp / h.max
        local weapon, plate = GEAR[h.gear[1] or ""], GEAR[h.gear[2] or ""]
        h.max = h.base_max * 1.12 ^ (h.level - 1) * (plate and plate.life or 1)
        h.dmg = h.base_dmg * 1.18 ^ (h.level - 1) * (weapon and weapon.dmg or 1)
        h.hp = h.max * share
    end
end
refit()
local function charm(h, what)
    local c = h.gear and GEAR[h.gear[3] or ""]
    return c and c[what]
end

local function front_post()
    local best = heroes[1].post
    for _, h in heroes do best = math.max(best, h.post) end
    return best
end
local function tame()
    table.insert(wolves, { wolf = true, x = 120, post = front_post() + 60 + #wolves * 40, hp = 45, max = 45, hurt = 0, t = 0, face = 1, wait = 0 })
end

-- ── keeping things ──
local function note(what)
    text.toast = what
    emit("note")
end
local function count(id)
    local n = 0
    for k = 1, 36 do
        if inv[k] and inv[k].id == id then n += inv[k].n end
    end
    return n
end
-- Into the first pile of its kind with room, or the first empty slot: what is
-- used goes to the bar first, the rest to the slots above it. Answers how many did not fit.
local function add(id, n)
    local order = {}
    local first, last = 1, 27
    if GEAR[id] and GEAR[id].use then first, last = 28, 36 end
    for k = first, last do table.insert(order, k) end
    for k = (first == 1 and 28 or 1), (first == 1 and 36 or 27) do table.insert(order, k) end
    for _, k in order do
        if n > 0 and inv[k] and inv[k].id == id and inv[k].n < pile(id) then
            local move = math.min(n, pile(id) - inv[k].n)
            inv[k].n, n = inv[k].n + move, n - move
        end
    end
    for _, k in order do
        if n > 0 and not inv[k] then
            local move = math.min(n, pile(id))
            inv[k], n = { id = id, n = move }, n - move
        end
    end
    return n
end
local function remove(id, n)
    for k = 36, 1, -1 do
        if n > 0 and inv[k] and inv[k].id == id then
            local move = math.min(n, inv[k].n)
            inv[k].n, n = inv[k].n - move, n - move
            if inv[k].n <= 0 then inv[k] = nil end
        end
    end
end

-- ── what was saved ──
local function save()
    local carrying, kept = {}, {}
    for k, h in heroes do carrying[k] = { h.gear[1] or "", h.gear[2] or "", h.gear[3] or "" } end
    for k = 1, 36 do kept[k] = inv[k] and { inv[k].id, inv[k].n } or { "", 0 } end
    -- (What lies on the grid or in the hand is still the camp's.)
    local loose = {}
    for k = 1, 9 do
        if grid[k] then table.insert(loose, { grid[k].id, grid[k].n }) end
    end
    if held then table.insert(loose, { held.id, held.n }) end
    local seen = {}
    for name in found do table.insert(seen, name) end
    local waiting = {}
    for _, c in chests do
        if not c.opened then table.insert(waiting, { math.floor(c.x), c.kind }) end
    end
    sys.call("files.write", "guard4.json", { wave = wave, xp = xp, quiet = quiet, auto = auto, levels = { knight.level, archer.level, witch.level },
        posts = { knight.post, archer.post, witch.post }, gear = carrying, inv = kept, loose = loose, wolves = #wolves, found = seen, chests = waiting })
end
do
    local ok, kept = pcall(sys.ask, "files.read", "guard4.json", "json")
    if ok and type(kept) == "table" then
        local n = function(v, or_) return tonumber(v) or or_ end
        wave, xp, quiet, auto = math.max(1, n(kept.wave, 1)), n(kept.xp, 0), kept.quiet == true, kept.auto == true
        for k, h in heroes do
            h.level = math.max(1, n(kept.levels and kept.levels[k], 1))
            h.post = math.clamp(n(kept.posts and kept.posts[k], h.post), 230, 1400)
            h.x = h.post
            for j = 1, 3 do
                local id = kept.gear and kept.gear[k] and kept.gear[k][j]
                if GEAR[id or ""] and GEAR[id].slot == j then h.gear[j] = id end
            end
        end
        for k = 1, 36 do
            local one = kept.inv and kept.inv[k]
            if one and ITEM[one[1]] and n(one[2], 0) > 0 then inv[k] = { id = one[1], n = math.min(n(one[2], 1), pile(one[1])) } end
        end
        for _, one in kept.loose or {} do
            if ITEM[one[1]] then add(one[1], n(one[2], 1)) end
        end
        for _, name in kept.found or {} do found[name] = true end
        for _, c in kept.chests or {} do
            if #chests < 12 then table.insert(chests, { x = n(c[1], 800), y = ground(), vy = 0, kind = math.clamp(n(c[2], 0), 0, 3), t = 9 }) end
        end
        refit()
        for _, h in heroes do h.hp = h.max end
        for _ = 1, math.clamp(n(kept.wolves, 0), 0, 3) do tame() end
        for _, w in wolves do w.x = w.post end
        log("back at wave", wave)
    end
end

-- ── what is seen when something happens ──
local function puff(x, y, kind, size, vx, vy, rate)
    if #puffs >= 96 then table.remove(puffs, 1) end
    table.insert(puffs, { x = x, y = y, age = 0, kind = kind, size = size or 10, vx = vx or 0, vy = vy or 0, rate = rate or 2.2 })
end
local function smoke(x, y, many, kind, spread)
    for _ = 1, many do
        puff(x + (math.random() - 0.5) * (spread or 40), y + (math.random() - 0.5) * (spread or 40), kind or 0, 7 + math.random() * 8, (math.random() - 0.5) * 50, -20 - math.random() * 50, 1.6 + math.random())
    end
end
local function burst(x, y, big)
    fact["at.x"], fact["at.y"] = x, y
    emit("boom")
    smoke(x, y, big and 16 or 9, 1, big and 160 or 90)
    say({ wave = "noise", freq = big and 300 or 420, to = 50, ms = big and 520 or 320, volume = big and 0.16 or 0.1, release = big and 420 or 240, pan = pan(x) })
end

-- ── what is left behind ──
local function leave(name, x, y, up)
    if #drops >= 64 then return end
    table.insert(drops, { what = "item", name = name, cell = ITEM[name], x = x, y = y, vx = (math.random() - 0.5) * 160, vy = -(up or 240) - math.random() * 140, t = 0, size = 0.7 })
end
local function orbs(x, y, worth)
    local many = math.clamp(math.floor(worth / 2 + 0.5), 1, 6)
    for _ = 1, many do
        if #drops >= 64 then return end
        table.insert(drops, { what = "orb", worth = worth / many, cell = ITEM.orb, x = x, y = y, vx = (math.random() - 0.5) * 220, vy = -180 - math.random() * 160, t = 0, size = 0.4 + math.random() * 0.15 })
    end
end

-- ── harm ──
local function hurt(f, amount, push, slows)
    if f.hp <= 0 then return end
    f.hp -= amount
    f.hurt = 1
    if slows then f.slow = 2.5 end
    if not f.edge and not f.lord then f.kick = (f.kick or 0) + (push or 0) end
    say({ wave = "noise", freq = 900, to = 300, ms = 45, volume = 0.03, pan = pan(f.x) }, 0.09)
    if f.hp <= 0 then
        f.dying = 0
        say({ wave = "square", freq = 240, to = 90, ms = 90, volume = 0.035, pan = pan(f.x) }, 0.15)
    end
end
local function harm(u, amount, ail)
    if u.down or u.hp <= 0 then return end
    -- An ender charm: now and then the blow finds nobody there.
    local dodge = charm(u, "dodge")
    if dodge and math.random() < dodge then
        smoke(u.x, ground() - 50, 5, 2, 50)
        return
    end
    u.hp -= amount
    u.hurt = 1
    -- What that land's blow leaves: slowed, frozen for a moment, or burning.
    if ail and not u.wolf then u.ail, u.ail_in = ail, ail == 2 and 0.9 or 3 end
    say({ wave = "noise", freq = 500, to = 200, ms = 60, volume = 0.04, pan = pan(u.x) }, 0.12)
end
local function alive(u) return not u.down and u.hp > 0 end

local function near(x, y, range, skip)
    -- The living foe closest to a point, within a range.
    local best, how = nil, range
    for _, f in horde do
        if f.hp > 0 and not (skip and skip(f)) then
            local d = math.sqrt((f.x - x) ^ 2 + (f.y - y) ^ 2)
            if d < how then best, how = f, d end
        end
    end
    return best
end

-- ── a wave ──
local function muster()
    local land, index = land_of(wave)
    queue = {}
    local step = (wave - 1) % 5                -- how far into this land: 0 to 4
    if step == 4 then table.insert(queue, { kind = land.lord.kind, lord = land.lord }) end
    local many = math.min(5 + wave * 2, 60)
    -- The rarer ones of a land come as it goes on.
    local total, open_to = 0, math.min(#land.who, 2 + step)
    for k = 1, open_to do total += land.who[k][2] end
    for _ = 1, many do
        local r, pick = math.random() * total, land.who[1]
        for k = 1, open_to do
            r -= land.who[k][2]
            if r <= 0 then pick = land.who[k] break end
        end
        table.insert(queue, { kind = pick[1], as = pick })
    end
    spawn_in, stage = 0.4, "fight"
    local lap = (wave - 1) // 30
    text.said = if step == 0 then land.name .. (lap > 0 and " " .. string.rep("I", lap + 1) or "") elseif step == 4 then "Wave " .. wave .. " - " .. land.lord.name else "Wave " .. wave
    fact.wave, fact.land = wave, index
    emit("newwave")
    if step == 0 and wave > 1 then note("Checkpoint: " .. land.name) end
    say({ wave = "saw", freq = 196, to = 294, ms = 240, volume = 0.1 })
end

local function arrive(spec, x, small)
    local kind = type(spec) == "string" and spec or spec.kind
    local as = type(spec) == "table" and (spec.lord or spec.as) or {}
    local k = KIND[kind]
    local tough = 1.12 ^ (wave - 1) * (small and 0.4 or 1) * (as.hp or 1)
    local f = { kind = kind, k = k, hp = k.hp * tough, max = k.hp * tough, dmg = k.dmg * (1 + (wave - 1) * 0.06) * (small and 0.5 or 1), x = x or W + 70, y = ground(), turn = 0,
                t = math.random(), wait = 0, hurt = 0, lit = 0, reach = k.reach + math.random() * 26, speed = k.speed * (0.9 + math.random() * 0.2) * (as.speed or 1),
                size = small and 0.6 or (as.size or 1), small = small, blink_in = 1.5 + math.random() * 2, wash = as.wash or 0, ail = as.ail, splits = as.splits, lord = as.name }
    if f.lord then
        -- A lord takes its time, hits harder and leaves more.
        f.speed, f.dmg, f.reach = f.speed * 0.6, f.dmg * 2, f.reach * math.max(1, f.size * 0.8)
    end
    if k.climbs and not x then
        -- By the ceiling, then down the wall: it comes in from above.
        f.edge, f.x, f.y, f.turn = "ceiling", W * (0.5 + math.random() * 0.25), 0, 180
    end
    table.insert(horde, f)
    return f
end

local function smite()
    if smite_in > 0 then return end
    local target = nil
    for _, f in horde do
        if f.hp > 0 and (not target or f.x < target.x) then target = f end
    end
    if not target then return end
    smite_in = 8
    fact["bolt.x"] = target.x
    emit("smote")
    smoke(target.x, target.y - 40, 10, 1, 100)
    say({ wave = "noise", freq = 2400, to = 90, ms = 480, volume = 0.14, release = 380, pan = pan(target.x) })
    for _, f in horde do
        if math.abs(f.x - target.x) < 130 then hurt(f, 40 + wave * 10, 200) end
    end
end

-- ── the chests the waves leave ──
-- 0 wood · 1 iron · 2 gold · 3 of the End: rarer, and with more and better in it.
local function crack(c)
    if c.opened or c.y < ground() then return end
    c.opened, c.t, c.next = true, 0, 0.25
    c.left = ({ [0] = 4, 6, 8, 11 })[c.kind] + math.random(0, 1)
    say({ wave = "saw", freq = 140, to = 260, ms = 220, volume = 0.07, pan = pan(c.x) })
end
local function reward(lordly)
    if #chests >= 12 then
        -- No room for another: the oldest one still shut opens by itself.
        for _, c in chests do
            if not c.opened then crack(c) break end
        end
    end
    local r = math.random()
    local kind = 0
    if r < 0.02 then kind = 3 elseif r < 0.1 then kind = 2 elseif r < 0.3 then kind = 1 end
    if lordly then kind = math.max(kind, r < 0.25 and 3 or 2) end
    table.insert(chests, { x = W * (0.3 + math.random() * 0.62), y = -90, vy = 0, kind = kind, t = 0 })
    if kind >= 2 then note(kind == 3 and "A chest of the End has fallen!" or "A golden chest has fallen!") end
end
local function spill(c)
    local r = math.random()
    local name = "stick"
    if c.kind == 0 then
        if r < 0.04 then name = "diamond" elseif r < 0.3 then name = "iron" elseif r < 0.42 then name = "string" elseif r < 0.52 then name = "bone" elseif r < 0.62 then name = "gunpowder" elseif r < 0.7 then name = "flesh" end
    elseif c.kind == 1 then
        if r < 0.08 then name = "diamond" elseif r < 0.6 then name = "iron" elseif r < 0.72 then name = "string" elseif r < 0.82 then name = "gunpowder" end
    elseif c.kind == 2 then
        if r < 0.28 then name = "diamond" elseif r < 0.62 then name = "iron" elseif r < 0.74 then name = "gunpowder" elseif r < 0.84 then name = "slimeball" elseif r < 0.92 then name = "string" end
    else
        if r < 0.42 then name = "diamond" elseif r < 0.72 then name = "pearl" elseif r < 0.9 then name = "iron" else name = "slimeball" end
    end
    leave(name, c.x, ground() - 40, 400)
end

-- What is thrown from the camp: TNT, which waits a moment where it lands; a
-- potion or a web, which do what they do as they land.
local function throw(what, to)
    table.insert(bombs, { what = what, x = 96, y = ground() - 90, from_x = 96, from_y = ground() - 90, tx = math.clamp(to, 230, W - 30), along = 0, fuse = nil, turn = 0 })
    say({ wave = "triangle", freq = 180, to = 120, ms = 90, volume = 0.05 })
end

-- ── the book: what can be made, laid out as it has to be on the grid ──
-- A row of letters for each row of the grid, a space for an empty slot; `key`
-- says what each letter is. It may sit anywhere on the grid, and mirrored.
local RECIPES = {
    { out = "iron_sword",    n = 1, rows = { "I", "I", "S" },          key = { I = "iron", S = "stick" } },
    { out = "diamond_sword", n = 1, rows = { "D", "D", "S" },          key = { D = "diamond", S = "stick" } },
    { out = "power_bow",     n = 1, rows = { " ST", "S T", " ST" },    key = { S = "stick", T = "string" } },
    { out = "wand",          n = 1, rows = { "P", "P", "S" },          key = { P = "pearl", S = "stick" } },
    { out = "iron_chest",    n = 1, rows = { "I I", "III", "III" },    key = { I = "iron" } },
    { out = "diamond_chest", n = 1, rows = { "D D", "DDD", "DDD" },    key = { D = "diamond" } },
    { out = "slime_charm",   n = 1, rows = { " T ", "LLL", " L " },    key = { T = "string", L = "slimeball" } },
    { out = "ender_charm",   n = 1, rows = { " T ", "PPP" },           key = { T = "string", P = "pearl" } },
    { out = "tnt",           n = 1, rows = { "G G", " G ", "G G" },    key = { G = "gunpowder" } },
    { out = "heal_potion",   n = 2, rows = { "FF", "FF" },             key = { F = "flesh" } },
    { out = "cobweb",        n = 2, rows = { "TT", "TT" },             key = { T = "string" } },
    { out = "collar",        n = 1, rows = { "BB", "BB" },             key = { B = "bone" } },
}
for _, r in RECIPES do
    -- How many of each it takes, and whether every one of them has ever been found.
    r.needs = {}
    for _, row in r.rows do
        for c = 1, #row do
            local id = r.key[row:sub(c, c)]
            if id then r.needs[id] = (r.needs[id] or 0) + 1 end
        end
    end
end
local function known(r)
    for id in r.needs do
        if not found[id] then return false end
    end
    return true
end
local function enough(r)
    for id, many in r.needs do
        if count(id) < many then return false end
    end
    return true
end
-- What the grid, as it lies, makes.
local function laid()
    local r0, r1, c0, c1 = 4, 0, 4, 0
    for k = 1, 9 do
        if grid[k] then
            local r, c = (k - 1) // 3 + 1, (k - 1) % 3 + 1
            r0, r1, c0, c1 = math.min(r0, r), math.max(r1, r), math.min(c0, c), math.max(c1, c)
        end
    end
    if r1 == 0 then return nil end
    local tall, wide = r1 - r0 + 1, c1 - c0 + 1
    for _, recipe in RECIPES do
        if #recipe.rows == tall and #recipe.rows[1] == wide then
            for _, mirrored in { false, true } do
                local fits = true
                for r = 1, tall do
                    for c = 1, wide do
                        local letter = recipe.rows[r]:sub(mirrored and wide + 1 - c or c, mirrored and wide + 1 - c or c)
                        local there = grid[(r0 + r - 2) * 3 + c0 + c - 1]
                        if (recipe.key[letter] or false) ~= (there and there.id or false) then fits = false end
                    end
                end
                if fits then return recipe end
            end
        end
    end
    return nil
end
local function gain(id, n)
    local left = add(id, n or 1)
    if left > 0 then note("No room left for the " .. NAMES[id]:lower()) end
    -- Something never seen before: a recipe may now be known.
    if not found[id] then
        found[id] = true
        for _, r in RECIPES do
            if r.needs[id] and known(r) then note("New recipe: " .. NAMES[r.out]) end
        end
    end
end
local function clear_grid()
    for k = 1, 9 do
        if grid[k] then
            add(grid[k].id, grid[k].n)
            grid[k] = nil
        end
    end
    ghosts = nil
end
-- A recipe of the book, laid out on the grid from what is kept; or, short of something, shown faintly.
local function lay(r)
    clear_grid()
    if not enough(r) then
        ghosts = {}
        for row = 1, #r.rows do
            for c = 1, #r.rows[row] do
                ghosts[(row - 1) * 3 + c] = r.key[r.rows[row]:sub(c, c)]
            end
        end
        local short = {}
        for id, many in r.needs do
            if count(id) < many then table.insert(short, (many - count(id)) .. " " .. NAMES[id]:lower()) end
        end
        return note(NAMES[r.out] .. " still wants " .. table.concat(short, " and "))
    end
    for row = 1, #r.rows do
        for c = 1, #r.rows[row] do
            local id = r.key[r.rows[row]:sub(c, c)]
            if id then
                remove(id, 1)
                grid[(row - 1) * 3 + c] = { id = id, n = 1 }
            end
        end
    end
    say({ wave = "square", freq = 520, ms = 30, volume = 0.03 })
end
-- What the grid makes, into the hand: one of each thing on it is spent.
local function take_made()
    local r = laid()
    if not r then return end
    if held and (held.id ~= r.out or held.n + r.n > pile(r.out)) then return end
    for k = 1, 9 do
        if grid[k] then
            grid[k].n -= 1
            if grid[k].n <= 0 then grid[k] = nil end
        end
    end
    held = held or { id = r.out, n = 0 }
    held.n += r.n
    found[r.out] = true
    say({ wave = "triangle", freq = 660, to = 990, ms = 120, volume = 0.1 })
    note(NAMES[r.out] .. ": " .. GEAR[r.out].says)
    log("crafted", NAMES[r.out])
end

-- ── where everything of the table is: the same numbers the scene draws it with ──
local function origin()
    local gx, gy = 24, ground() - 150 - 332
    local mx = gx + (pages and 298 or 0)
    return gx, gy, mx, mx + 356
end
local function inside(x, y, rx, ry, w, h) return x >= rx and x < rx + w and y >= ry and y < ry + h end
-- What is under a point: a slot of what is kept, of the grid, of a hero; what
-- is made; a recipe; a button. And where to light it.
local function under(x, y)
    if not x then return nil end
    local gx, gy, mx, tx = origin()
    for i = 0, 8 do
        local sx, sy = mx + 60 + (i % 3) * 36, gy + 34 + (i // 3) * 36
        if inside(x, y, sx, sy, 36, 36) then return { "grid", i + 1, x = sx + 2, y = sy + 2 } end
    end
    if inside(x, y, mx + 240, gy + 62, 52, 52) then return { "made", 0, x = mx + 250, y = gy + 72 } end
    for i = 0, 35 do
        local sx, sy = mx + 16 + (i % 9) * 36, gy + (i < 27 and 168 + (i // 9) * 36 or 284)
        if inside(x, y, sx, sy, 36, 36) then return { "inv", i + 1, x = sx + 2, y = sy + 2 } end
    end
    for k = 0, 2 do
        for j = 0, 2 do
            local sx, sy = tx + 100 + j * 38, gy + 10 + k * 106 + 54
            if inside(x, y, sx, sy, 36, 36) then return { "gear", k * 3 + j + 1, x = sx + 2, y = sy + 2 } end
        end
    end
    if inside(x, y, mx + 10, gy + 68, 40, 36) then return { "pages", 0 } end
    if inside(x, y, mx + 298, gy + 10, 50, 30) then return { "auto", 0 } end
    if pages then
        for i = 0, 15 do
            local sx, sy = gx + 20 + (i % 4) * 64, gy + 50 + (i // 4) * 68
            if inside(x, y, sx, sy, 58, 58) then return { "recipe", i + 1 } end
        end
    end
    return nil
end
local function shown()
    -- The recipes the book shows: those whose every ingredient has been found.
    local list = {}
    for _, r in RECIPES do
        if known(r) then table.insert(list, r) end
    end
    return list
end

-- A slot of a hero: what the hand carries goes on, if it is for that slot and
-- that hero; with an empty hand, what is there comes off.
local function wear(h, j)
    if held then
        local def = GEAR[held.id]
        if not def or not def.slot then return note("That is not something to wear") end
        if def.slot ~= j then return note(def.name .. " goes in " .. ({ "the weapon's", "the armour's", "the charm's" })[def.slot] .. " slot") end
        if def.who and def.who ~= h.name then return note("The " .. h.shown:lower() .. " cannot use the " .. def.name:lower()) end
        local before = h.gear[j]
        h.gear[j] = held.id
        held = before and { id = before, n = 1 } or nil
        refit()
        fact["up.x"] = h.x
        emit("levelup")
        say({ wave = "square", freq = 520, to = 780, ms = 90, volume = 0.07 })
    elseif h.gear[j] then
        held = { id = h.gear[j], n = 1 }
        h.gear[j] = nil
        refit()
    end
end
-- A press on a slot of what is kept or of the grid: pick up, put down, pile, swap.
-- With the right button: half of what is there, or one of what is carried.
local function slot_press(t, k, right)
    local there = t[k]
    if not held then
        if not there then return end
        if right and there.n > 1 then
            local half = math.ceil(there.n / 2)
            held = { id = there.id, n = half }
            there.n -= half
        else
            held, t[k] = there, nil
        end
    elseif not there then
        if right and held.n > 1 then
            t[k] = { id = held.id, n = 1 }
            held.n -= 1
        else
            t[k], held = held, nil
        end
    elseif there.id == held.id and there.n < pile(there.id) then
        local move = right and 1 or math.min(held.n, pile(there.id) - there.n)
        there.n += move
        held.n -= move
        if held.n <= 0 then held = nil end
    elseif not right then
        t[k], held = held, there
    end
    if t == grid then ghosts = nil end
end

local pressed = nil     -- where the button went down, and whether it picked something up there
local function press(ref, right)
    if not ref then return end
    local kind, k = ref[1], ref[2]
    if kind == "inv" then slot_press(inv, k, right)
    elseif kind == "grid" then slot_press(grid, k, right)
    elseif kind == "made" then take_made()
    elseif kind == "gear" then wear(heroes[(k - 1) // 3 + 1], (k - 1) % 3 + 1)
    elseif kind == "recipe" then
        local r = shown()[k]
        if r and not held then lay(r) end
    elseif kind == "pages" then
        pages = not pages
        fact.pages = pages
    elseif kind == "auto" then
        auto = not auto
        fact.auto = auto
        note(auto and "The camp now crafts and hands things over by itself" or "By hand: nothing is made or handed over until you do it")
    end
end
local function shut()
    clear_grid()
    if held then
        add(held.id, held.n)
        held = nil
    end
    open = false
    fact.open = false
end

-- ── what the hand asks for ──
on("toggle", function()
    if open then shut() else
        open, armed = true, nil
        fact.open, fact.aiming, fact.armed = true, false, -1
    end
    say({ wave = "saw", freq = open and 140 or 260, to = open and 260 or 140, ms = 160, volume = 0.06 })
end)
on("click", function()
    local ref = under(mouse.x, mouse.y)
    local empty = held == nil
    press(ref, false)
    pressed = ref and { ref[1], ref[2], picked = empty and held ~= nil } or nil
end)
on("rclick", function()
    press(under(mouse.x, mouse.y), true)
    pressed = nil
end)
on("unclick", function()
    -- Pressed on one slot and let go on another: carried there and put down.
    local ref = under(mouse.x, mouse.y)
    if pressed and pressed.picked and held and ref and (ref[1] ~= pressed[1] or ref[2] ~= pressed[2]) and ref[1] ~= "made" and ref[1] ~= "recipe" then
        press(ref, false)
    end
    pressed = nil
end)
-- The bar, outside: a press on a thing uses it. What is thrown waits for where.
on("use", function()
    local i = math.clamp(math.floor(((mouse.x or 24) - 24) / 40), 0, 8)
    local pile_ = inv[28 + i]
    if not pile_ then
        armed = nil
    else
        local def = GEAR[pile_.id]
        if not def or not def.use then
            note((NAMES[pile_.id] or "That") .. " is not used from here: open the table to hand it over")
        elseif def.use == "tame" then
            if #wolves >= 3 then note("Three wolves is as many as the camp can feed") else
                pile_.n -= 1
                if pile_.n <= 0 then inv[28 + i] = nil end
                tame()
                note("A wolf joins the camp")
            end
        else
            armed = armed ~= i and i or nil
        end
    end
    fact.armed, fact.aiming = armed or -1, armed ~= nil
end)
on("lob", function(x)
    local pile_ = armed and inv[28 + armed]
    if pile_ and GEAR[pile_.id] and GEAR[pile_.id].use then
        throw(GEAR[pile_.id].use, x)
        pile_.n -= 1
        if pile_.n <= 0 then inv[28 + armed], armed = nil, nil end
    else
        armed = nil
    end
    fact.armed, fact.aiming = armed or -1, armed ~= nil
end)
on("take", function(i)
    if heroes[i + 1] and not heroes[i + 1].down then carried = heroes[i + 1] end
end)
on("drop", function()
    carried = nil
    save_in = math.min(save_in, 1)
end)
on("crack", function(i)
    if chests[i + 1] then crack(chests[i + 1]) end
end)
on("halt", function()
    paused = not paused
    fact.paused = paused
end)
on("stow", function()
    away = not away
    fact.away = away
    if away then
        if open then shut() end
        armed, carried = nil, nil
        fact.aiming, fact.armed = false, -1
    end
end)

-- By itself: open what waits, hand over what is better, make what somebody
-- could use, and use what there is when it is needed.
local function spend(id)
    for k = 36, 1, -1 do
        if inv[k] and inv[k].id == id then
            inv[k].n -= 1
            if inv[k].n <= 0 then inv[k] = nil end
            return true
        end
    end
    return false
end
local function alone()
    for _, c in chests do
        if not c.opened and c.y >= ground() then return crack(c) end
    end
    if open then return end
    for k = 1, 36 do
        local def = inv[k] and GEAR[inv[k].id]
        if def and def.slot then
            for _, h in heroes do
                local now = GEAR[h.gear[def.slot] or ""]
                local better = not now or (def.dmg or 0) > (now.dmg or 0) or (def.life or 0) > (now.life or 0)
                if (not def.who or def.who == h.name) and better then
                    local id = inv[k].id
                    inv[k] = nil
                    if h.gear[def.slot] then add(h.gear[def.slot], 1) end
                    h.gear[def.slot] = id
                    refit()
                    fact["up.x"] = h.x
                    emit("levelup")
                    return
                end
            end
        end
    end
    for _, r in RECIPES do
        if known(r) and enough(r) then
            local def, wanted = GEAR[r.out], false
            if def.use then
                wanted = count(r.out) < 2 and (r.out ~= "collar" or #wolves < 3)
            elseif count(r.out) == 0 then
                for _, h in heroes do
                    local now = GEAR[h.gear[def.slot] or ""]
                    if (not def.who or def.who == h.name) and h.gear[def.slot] ~= r.out and (not now or (def.dmg or 0) > (now.dmg or 0) or (def.life or 0) > (now.life or 0) or def.slot == 3) and not (def.slot == 3 and now) then wanted = true end
                end
            end
            if wanted then
                for id, many in r.needs do remove(id, many) end
                gain(r.out, r.n)
                note("Made: " .. NAMES[r.out])
                say({ wave = "triangle", freq = 660, to = 990, ms = 120, volume = 0.08 })
                return
            end
        end
    end
    -- What there is to use, when it is needed.
    local many, sum, lord = 0, 0, nil
    for _, f in horde do
        if f.hp > 0 and not f.edge and f.x < W - 40 then many, sum = many + 1, sum + f.x end
        if f.lord and f.hp > 0 then lord = f end
    end
    if #wolves < 3 and spend("collar") then return tame() end
    for _, h in heroes do
        if alive(h) and h.hp < h.max * 0.45 and spend("heal_potion") then return throw("heal", h.x) end
    end
    if (many >= 5 or (lord and many >= 1)) and spend("tnt") then return throw("tnt", math.max(front_post() + 130, lord and lord.x or sum / many)) end
    if many >= 6 and spend("cobweb") then return throw("web", sum / many) end
end

-- ── what is seen of all that: told every frame, stopped or not ──
local function show()
    local list = {}
    for k = 1, 36 do list[k] = inv[k] and { cell = ITEM[inv[k].id], n = inv[k].n } or { cell = -1, n = 0 } end
    model.slots = list
    local cells = {}
    for k = 1, 9 do
        if grid[k] then cells[k] = { cell = ITEM[grid[k].id], n = grid[k].n, ghost = false }
        elseif ghosts and ghosts[k] then cells[k] = { cell = ITEM[ghosts[k]], n = 0, ghost = true }
        else cells[k] = { cell = -1, n = 0, ghost = false } end
    end
    model.grid = cells
    local made = open and laid() or nil
    fact["out.cell"], fact["out.n"] = made and ITEM[made.out] or -1, made and made.n or 0
    local pagelist, can = {}, 0
    for k, r in shown() do
        local ok = enough(r)
        if ok then can += 1 end
        if k <= 16 then pagelist[k] = { cell = ITEM[r.out], can = ok } end
    end
    model.book = pagelist
    fact.can = can
    local cards = {}
    for k, h in heroes do
        cards[k] = { cell = h.row * 16, name = h.shown, rank = h.level, hp = math.clamp(h.hp / h.max, 0, 1), down = h.down ~= nil,
                     s0 = ITEM[h.gear[1] or h.rest], own = h.gear[1] and 1 or 0, s1 = h.gear[2] and ITEM[h.gear[2]] or -1, s2 = h.gear[3] and ITEM[h.gear[3]] or -1 }
    end
    model.cards = cards
    -- What the mouse carries, the slot it is on, and what that holds is called.
    local mx_, my_ = mouse.x or -100, mouse.y or -100
    fact["hand.x"], fact["hand.y"] = mx_, my_
    fact["hand.cell"], fact["hand.n"] = held and ITEM[held.id] or -1, held and held.n or 0
    local ref = open and under(mouse.x, mouse.y) or nil
    local lit = ref ~= nil and ref.x ~= nil
    fact["over.on"] = lit
    local name = ""
    if lit then
        fact["over.x"], fact["over.y"] = ref.x, ref.y
        local kind, k = ref[1], ref[2]
        local id = nil
        if kind == "inv" then id = inv[k] and inv[k].id
        elseif kind == "grid" then id = grid[k] and grid[k].id
        elseif kind == "made" then id = made and made.out
        elseif kind == "gear" then
            local h, j = heroes[(k - 1) // 3 + 1], (k - 1) % 3 + 1
            id = h.gear[j] or (j == 1 and h.rest) or nil
            if not id then name = ({ "", "Armour", "Charm" })[j] end
        end
        if id then name = NAMES[id] or id end
    elseif ref and ref[1] == "recipe" then
        local r = shown()[ref[2]]
        if r then
            fact["over.on"] = true
            local gx, gy = origin()
            fact["over.x"], fact["over.y"] = gx + 33 + ((ref[2] - 1) % 4) * 64, gy + 63 + ((ref[2] - 1) // 4) * 68
            name = NAMES[r.out]
        end
    end
    text.tip = name
end

-- ── a frame ──
on("frame", function(dt)
    show()
    -- Stopped, or put away: nothing moves and nothing is worked out.
    if paused or away then return end
    clock += dt
    local g = ground()

    -- The wave: the horde comes one by one; with none left, a chest; then a rest, and the next.
    stage_in -= dt
    if stage == "start" then
        muster()
    elseif stage == "fallen" then
        if stage_in <= 0 then
            for _, h in heroes do h.down, h.hp, h.x, h.ail = nil, h.max, h.post, nil end
            muster()
        end
    elseif stage == "fight" then
        if #queue > 0 then
            spawn_in -= dt
            if spawn_in <= 0 then
                arrive(table.remove(queue, 1))
                spawn_in = math.max(0.3, 1.0 - wave * 0.03) * (0.6 + math.random() * 0.8)
            end
        elseif #horde == 0 then
            -- Cleared: a chest falls for it, and waits to be opened.
            reward(wave % 5 == 0)
            stage, stage_in = "rest", 2.4
            -- Won: whoever fell stands up again, with half its life.
            for _, h in heroes do
                if h.down then
                    h.down, h.hp, h.x, h.ail = nil, h.max * 0.5, h.post, nil
                    fact["up.x"] = h.x
                    emit("levelup")
                end
            end
        end
    elseif stage == "rest" and stage_in <= 0 then
        wave += 1
        muster()
    end

    -- The chests: they fall, they wait; opened, they give what they hold and are gone.
    for i = #chests, 1, -1 do
        local c = chests[i]
        if c.y < g then
            c.vy += 2600 * dt
            c.y = math.min(g, c.y + c.vy * dt)
            if c.y >= g then
                smoke(c.x, g - 10, 6, 0, 80)
                say({ wave = "square", freq = 110, to = 60, ms = 120, volume = 0.1, pan = pan(c.x) })
            end
        elseif c.opened then
            c.t += dt
            c.next = (c.next or 0) - dt
            if c.left > 0 and c.next <= 0 then
                c.next, c.left = 0.13, c.left - 1
                spill(c)
            elseif c.left <= 0 and c.t > 2.6 then
                smoke(c.x, g - 30, 8, 0, 70)
                table.remove(chests, i)
            end
        elseif c.kind >= 2 and math.random() < dt * 3 then
            -- A rare one glints while it waits.
            puff(c.x + (math.random() - 0.5) * 50, g - 20 - math.random() * 50, c.kind == 3 and 2 or 1, 6, 0, -30, 2.4)
        end
    end

    -- A hero in the hand goes where the hand goes, and stays where it is let go.
    if carried then
        if carried.down or not mouse.left then
            carried = nil
        elseif mouse.x then
            carried.post = math.clamp(mouse.x, 230, W * 0.72)
            carried.x = carried.post
        end
    end

    -- A game controller: the stick moves the knight.
    local p = pad(1)
    fact.pad = p ~= nil
    local push = 0
    if p and not knight.down then
        if math.abs(p.lx) > 0.2 then push = p.lx end
        push += (p.right and 1 or 0) - (p.left and 1 or 0)
    end

    -- The heroes.
    for _, h in heroes do
        h.hurt = math.max(0, h.hurt - dt * 5)
        if h.ail then
            h.ail_in -= dt
            if h.ail == 3 then h.hp -= h.max * 0.04 * dt end
            if h.ail_in <= 0 then h.ail = nil end
        end
        if h.down then
            -- Fallen: there it lies until the wave is won or lost.
            h.acting = nil
        elseif h ~= carried then
            local moving = false
            if h == knight and push ~= 0 then
                h.x = math.clamp(h.x + push * 240 * dt, 230, W * 0.72)
                h.held, moving = 2.5, true
            elseif (h.held or 0) > 0 then
                h.held -= dt
            elseif math.abs(h.x - h.post) > 2 then
                h.x += math.clamp(h.post - h.x, -110 * dt, 110 * dt)
                moving = true
            end
            h.walk = moving and h.walk + dt or 0
            -- Slowed, it takes half as long again between blows; frozen, it does nothing.
            h.wait -= dt * (h.ail == 1 and 0.65 or (h.ail == 2 and 0 or 1))
            if h.acting then
                h.acting += dt / h.strike * (h.ail == 2 and 0 or 1)
                -- The blow lands where the swing comes down, or the string is let go.
                if not h.landed and h.acting >= h.lands then
                    h.landed = true
                    local target = h.target
                    local slows = charm(h, "slows")
                    if h == knight then
                        -- A sweep: everything in front of the blade, and back it goes.
                        local hits = 0
                        for _, f in horde do
                            if f.hp > 0 and hits < 4 and not f.edge and f.x - h.x > -26 and f.x - h.x < h.range + 20 then
                                hurt(f, h.dmg, 240, slows)
                                hits += 1
                            end
                        end
                        puff(h.x + 44, g - 50, 3, 1, 0, 0, 4.5)
                        say({ wave = "noise", freq = 1400, to = 500, ms = 70, volume = 0.03 }, 0.2)
                    elseif target and target.hp > 0 then
                        local potion = h.splash ~= nil
                        local from_x, from_y = h.x + (potion and 16 or 30), g - (potion and 78 or 52)
                        table.insert(shots, { kind = potion and 1 or 0, x = from_x, y = from_y, from_x = from_x, from_y = from_y, target = target, tx = target.x, ty = target.y - 40,
                                              speed = potion and 520 or 1100, dmg = h.dmg, splash = h.splash, slows = slows, turn = 0, along = 0, lift = potion and 130 or 50 })
                        say(potion and { wave = "sine", freq = 500, to = 300, ms = 90, volume = 0.04 } or { wave = "triangle", freq = 220, to = 140, ms = 70, volume = 0.05 }, 0.1)
                    end
                end
                if h.acting >= 1 then h.acting, h.landed, h.target = nil, nil, nil end
            elseif h.wait <= 0 then
                -- (An arrow never finds an enderman: the archer does not waste one.)
                local target = near(h.x, g - 40, h.range, h == archer and function(f) return f.k.blinks end or nil)
                if h == knight and target and (target.edge or target.x - h.x < -26) then target = nil end
                if target then h.acting, h.target, h.wait = 0, target, h.every end
            end
        else
            h.walk, h.acting = 0, nil
        end
        h.cell = h.row * 16 + (h.acting and 8 + math.min(7, math.floor(h.acting * 8)) or (h.walk > 0 and math.floor(h.walk * 10) % 8 or 0))
    end

    -- The wolves: each by its post, ahead of whoever stands furthest out, until
    -- something comes near; then at it.
    local out = front_post()
    for i = #wolves, 1, -1 do
        local w = wolves[i]
        w.hurt = math.max(0, w.hurt - dt * 5)
        w.post = out + 60 + (i - 1) * 40
        w.wait -= dt
        local prey = w.prey
        if not prey or prey.hp <= 0 or prey.edge or math.abs(prey.x - w.post) > 440 then
            prey = nil
            local how = 360
            for _, f in horde do
                if f.hp > 0 and not f.edge and math.abs(f.x - w.post) < how then prey, how = f, math.abs(f.x - w.post) end
            end
            w.prey = prey
        end
        local goal = prey and prey.x - 38 or w.post
        local running = math.abs(goal - w.x) > 6
        if running then
            local step = math.clamp(goal - w.x, -230 * dt, 230 * dt)
            w.x += step
            w.face = step >= 0 and 1 or -1
            w.t += dt
        else
            w.face = 1
            if prey and w.wait <= 0 then w.wait, w.bite = 0.6, 0 end
        end
        if w.bite then
            w.bite += dt / 0.28
            if not w.bit and w.bite >= 0.5 and prey and prey.hp > 0 then
                w.bit = true
                hurt(prey, 6 + gained() * 0.8, 90)
            end
            if w.bite >= 1 then w.bite, w.bit = nil, nil end
        end
        w.cell = 48 + (w.bite and 8 + math.min(7, math.floor(w.bite * 8)) or (running and math.floor(w.t * 12) % 8 or 0))
        if w.hp <= 0 then
            smoke(w.x, g - 24, 7)
            say({ wave = "sine", freq = 700, to = 300, ms = 260, volume = 0.06, pan = pan(w.x) })
            table.remove(wolves, i)
        end
    end

    -- Everyone the horde can go for, and the one each of them meets first.
    local units = {}
    for _, h in heroes do if alive(h) then table.insert(units, h) end end
    for _, w in wolves do table.insert(units, w) end
    local function ahead(f)
        local best = nil
        for _, u in units do
            if u.hp > 0 and u.x < f.x + 34 and (not best or u.x > best.x) then best = u end
        end
        return best
    end

    -- The horde.
    local king = nil
    for _, f in horde do
        f.hurt = math.max(0, f.hurt - dt * 5)
        f.t += dt
        if f.lord and f.hp > 0 then king = f end
        local walking, frame = true, nil
        if f.dying then
            -- Over it goes, red, and then it is smoke.
            f.dying += dt / 0.45
            f.hurt = 1
            walking = false
        elseif f.edge == "ceiling" then
            f.x += f.speed * dt
            if f.x >= W then f.edge, f.x, f.y, f.turn = "wall", W, 0, 270 end
        elseif f.edge == "wall" then
            f.y += f.speed * dt
            if f.y >= g then f.edge, f.y, f.turn = nil, g, 0 end
        else
            f.y = g
            -- Knocked back by what hit it.
            if f.kick and f.kick > 1 then
                f.x = math.min(W + 60, f.x + f.kick * dt)
                f.kick *= math.max(0, 1 - 9 * dt)
            end
            f.slow = math.max(0, (f.slow or 0) - dt)
            local pace = f.speed * (f.slow > 0 and 0.55 or 1)
            local target = ahead(f)
            local gap = target and f.x - target.x or math.huge
            if f.fuse then
                -- A creeper, lit: it flashes, swells and goes off, and spares nobody near it.
                walking = false
                f.fuse += dt / 1.1
                f.lit = math.floor(f.fuse * 9) % 2
                if f.fuse >= 1 then
                    burst(f.x, f.y - 40, true)
                    for _, u in units do
                        if math.abs(u.x - f.x) < 120 then harm(u, f.dmg, f.ail) end
                    end
                    for _, other in horde do
                        if other ~= f and other.hp > 0 and math.abs(other.x - f.x) < 100 and not other.edge then hurt(other, 40, 240) end
                    end
                    f.hp, f.gone = 0, true
                end
            elseif gap <= f.reach then
                walking = false
                if f.k.bursts then
                    f.fuse = 0
                    say({ wave = "noise", freq = 3000, to = 1800, ms = 700, volume = 0.05, attack = 200, pan = pan(f.x) })
                else
                    f.wait -= dt
                    if f.wait <= 0 then
                        f.wait, f.strike = f.k.every, 0
                    end
                    if f.strike then
                        local ranged = f.k.shoots or f.k.throws
                        f.strike += dt / (ranged and 0.6 or 0.42)
                        if not f.landed and f.strike >= (f.k.shoots and 0.75 or 0.5) then
                            f.landed = true
                            if ranged then
                                -- From the bow, or from the hand: an arrow, or a flask that splashes.
                                local from_x, from_y = f.x - (f.k.throws and 16 or 28) * f.size, g - (f.k.throws and 78 or 52) * f.size
                                table.insert(shots, { kind = f.k.throws and 1 or 3, x = from_x, y = from_y, from_x = from_x, from_y = from_y, target = target, tx = target.x, ty = g - 50,
                                                      speed = f.k.throws and 480 or 640, dmg = f.dmg, turn = 0, along = 0, lift = f.k.throws and 130 or 60, theirs = true, ail = f.ail, splash = f.k.throws and 80 or nil })
                                say({ wave = "triangle", freq = 200, to = 130, ms = 70, volume = 0.04, pan = pan(f.x) }, 0.1)
                            else
                                harm(target, f.dmg, f.ail)
                            end
                        end
                        if f.strike >= 1 then f.strike, f.landed = nil, nil end
                    end
                end
            elseif f.x > 130 or target then
                if f.k.hops then
                    -- A slime only moves while it is in the air.
                    local hop = math.floor(f.t * 8) % 8
                    if hop >= 1 and hop <= 3 then f.x -= pace * 2.6 * dt end
                    frame = hop
                else
                    f.x -= pace * dt
                end
                if f.k.blinks then
                    -- An enderman does not walk all the way: now and then it is somewhere nearer.
                    f.blink_in -= dt
                    if f.blink_in <= 0 and target then
                        f.blink_in = 1.8 + math.random() * 2.2
                        local to = math.max(target.x + f.reach - 10, f.x - 150 - math.random() * 170)
                        smoke(f.x, g - 64, 7, 2, 60)
                        f.x = to
                        smoke(f.x, g - 64, 7, 2, 60)
                        say({ wave = "sine", freq = 900, to = 200, ms = 160, volume = 0.05, pan = pan(f.x) }, 0.2)
                    end
                end
            else
                walking = false
            end
        end
        -- Eight pictures of walking, then those of striking: eight, or the king's four.
        local strikes = f.k.big and 4 or 8
        if not frame then
            frame = walking and math.floor(f.t * (f.k.climbs and 14 or 9)) % 8
                or (f.fuse and 8 + math.min(strikes - 1, math.floor(f.fuse * strikes)) or (f.strike and 8 + math.min(strikes - 1, math.floor(f.strike * strikes)) or 0))
        end
        f.cell = (f.k.big and 0 or f.k.row * 16) + frame
    end
    fact.king = king ~= nil
    if king then fact["king.hp"] = math.clamp(king.hp / king.max, 0, 1) end

    -- A hero with nothing left goes down for a while; with all three down, the camp falls.
    local standing = 0
    for _, h in heroes do
        if not h.down and h.hp <= 0 then
            h.down, h.hp, h.acting = true, 0, nil
            smoke(h.x, g - 40, 8)
        end
        if not h.down then standing += 1 end
    end
    if standing == 0 and stage ~= "fallen" then
        stage, stage_in = "fallen", 4
        horde, queue, shots, bombs = {}, {}, {}, {}
        -- Back to where this land began: what was gathered and learnt is kept.
        wave = checkpoint(wave)
        log("the camp fell: back to wave", wave)
        text.said = "The camp fell - back to " .. land_of(wave).name
        emit("newwave")
        say({ wave = "saw", freq = 220, to = 70, ms = 600, volume = 0.1 })
    end

    -- What flies: towards whoever it was meant for, or where they were.
    for i = #shots, 1, -1 do
        local s = shots[i]
        if s.target.hp > 0 and not s.target.down then
            s.tx = s.target.x
            if not s.theirs then s.ty = s.target.y - (s.target.k.big and 90 or 40 * s.target.size) end
        end
        local dx, dy = s.tx - s.from_x, s.ty - s.from_y
        local far = math.max(1, math.sqrt(dx * dx + dy * dy))
        s.along = math.min(1, s.along + s.speed * dt / far)
        local lift = math.sin(s.along * math.pi) * math.min(s.lift, far * 0.2)
        local nx, ny = s.from_x + dx * s.along, s.from_y + dy * s.along - lift
        -- An arrow points where it goes (its picture points up and to the right); a potion tumbles.
        s.turn = s.kind == 1 and (s.turn + 720 * dt) or math.deg(math.atan2(ny - s.y, nx - s.x)) + 45
        s.x, s.y = nx, ny
        if s.along >= 1 then
            if s.kind == 1 then
                -- Glass, and what was in it over everything near.
                smoke(s.x, s.y, 10, 4, s.splash * 1.3)
                say({ wave = "noise", freq = 3200, to = 900, ms = 110, volume = 0.05, pan = pan(s.x) }, 0.1)
                if s.theirs then
                    for _, u in units do
                        if math.abs(u.x - s.x) < s.splash then harm(u, s.dmg, s.ail) end
                    end
                else
                    for _, f in horde do
                        if f.hp > 0 and (f.x - s.x) ^ 2 + (f.y - 40 - s.y) ^ 2 < s.splash ^ 2 then hurt(f, s.dmg, 70, s.slows) end
                    end
                end
            elseif s.theirs then
                if alive(s.target) then harm(s.target, s.dmg, s.ail) end
            elseif s.target.hp > 0 then
                hurt(s.target, s.dmg, 130, s.slows)
            end
            table.remove(shots, i)
        end
    end

    -- What was thrown: TNT waits a moment where it lands; a potion and a web do what they do at once.
    for i = #bombs, 1, -1 do
        local b = bombs[i]
        if not b.fuse then
            b.along = math.min(1, b.along + dt / 0.9)
            b.x = b.from_x + (b.tx - b.from_x) * b.along
            b.y = b.from_y + (g - b.from_y) * b.along - math.sin(b.along * math.pi) * 240
            b.turn += 540 * dt
            if b.along >= 1 and b.what == "tnt" then
                b.fuse = 0
                say({ wave = "noise", freq = 3000, to = 2000, ms = 900, volume = 0.05, attack = 300, pan = pan(b.x) })
            elseif b.along >= 1 then
                say({ wave = "noise", freq = 3200, to = 900, ms = 110, volume = 0.05, pan = pan(b.x) })
                if b.what == "heal" then
                    smoke(b.x, g - 40, 12, 5, 150)
                    for _, u in units do
                        if math.abs(u.x - b.x) < 130 then u.hp = math.min(u.max, u.hp + u.max * 0.5) end
                    end
                else
                    smoke(b.x, g - 30, 14, 0, 220)
                    for _, f in horde do
                        if f.hp > 0 and not f.edge and math.abs(f.x - b.x) < 200 then f.slow = 5 end
                    end
                end
                table.remove(bombs, i)
            end
        else
            b.fuse += dt / 1.0
            if b.fuse >= 1 then
                burst(b.x, g - 30, true)
                for _, f in horde do
                    if f.hp > 0 and math.abs(f.x - b.x) < 170 and not f.edge then hurt(f, 70 + wave * 14, 420) end
                end
                table.remove(bombs, i)
            end
        end
    end

    -- What has fallen over is gone: smoke, and what it leaves.
    for i = #horde, 1, -1 do
        local f = horde[i]
        if f.gone or (f.dying and f.dying >= 1) then
            table.remove(horde, i)
            if not f.gone then
                smoke(f.x + (f.k.big and 50 or 24), f.y - 16, f.k.big and 16 or 6, 0, f.k.big and 120 or 50)
                orbs(f.x, f.y - 30, f.k.xp * (f.small and 0.4 or 1))
                for _, d in f.k.drops do
                    if math.random() < d[2] * (f.small and 0.5 or 1) then leave(d[1], f.x, f.y - 30) end
                end
                if f.lord and not f.k.big then
                    for _, d in KIND.boss.drops do leave(d[1], f.x, f.y - 60, 420) end
                    orbs(f.x, f.y - 40, 40)
                end
                if f.splits then
                    -- A lord of slime comes apart into whole ones.
                    for k = 1, f.splits do
                        local part = arrive({ kind = f.kind, as = { wash = f.wash, ail = f.ail } }, f.x + (k - 2) * 40)
                        part.kick = (k - 1) * 120
                    end
                elseif f.k.splits and not f.small then
                    for side = -1, 1, 2 do
                        local little = arrive({ kind = "slime", as = { wash = f.wash, ail = f.ail } }, f.x + side * 22, true)
                        little.kick = side > 0 and 160 or 0
                    end
                end
            end
        end
    end

    -- What was left: it jumps out, and then goes to whoever picks it up, or to the chest of the camp.
    local picker = alive(knight) and knight or (alive(archer) and archer or witch)
    for i = #drops, 1, -1 do
        local d = drops[i]
        d.t += dt
        if d.t < 0.5 then
            d.vy += 900 * dt
            d.x += d.vx * dt
            d.y = math.min(g - 12, d.y + d.vy * dt)
        else
            local tx, ty = 96, g - 40
            if d.what == "orb" then tx, ty = picker.x, g - 50 end
            local dx, dy = tx - d.x, ty - d.y
            local far = math.sqrt(dx * dx + dy * dy)
            local step = (500 + (d.t - 0.5) * 2200) * dt
            if far <= math.max(step, 16) then
                if d.what == "orb" then
                    xp += d.worth
                    say({ wave = "sine", freq = 1100 + math.random() * 500, ms = 60, volume = 0.03 }, 0.07)
                else
                    gain(d.name, 1)
                    say({ wave = "square", freq = 880, to = 1320, ms = 40, volume = 0.025 }, 0.07)
                end
                table.remove(drops, i)
            else
                d.x += dx / far * step
                d.y += dy / far * step
            end
        end
    end

    -- Experience levels up whoever is furthest behind.
    local need = 12 + 5 * gained()
    while xp >= need do
        xp -= need
        local who = knight
        for _, h in heroes do
            if h.level < who.level then who = h end
        end
        who.level += 1
        refit()
        who.hp = who.max
        fact["up.x"] = who.x
        emit("levelup")
        say({ wave = "sine", freq = 660, to = 1320, ms = 320, volume = 0.1 })
        need = 12 + 5 * gained()
    end

    -- By itself, now and then.
    craft_in -= dt
    if craft_in <= 0 then
        craft_in = 1.5
        if auto then alone() end
    end

    for i = #puffs, 1, -1 do
        local q = puffs[i]
        q.age += dt * q.rate
        q.x += q.vx * dt
        q.y += q.vy * dt
        if q.age >= 1 then table.remove(puffs, i) end
    end
    smite_in = math.max(0, smite_in - dt)

    -- And all of it, to the scene.
    local team = {}
    for _, h in heroes do
        table.insert(team, { x = h.x, y = g, cell = h.cell, hp = math.clamp(h.hp / h.max, 0, 1), hurt = h.hurt, hearts = 5, face = 1, down = h.down ~= nil, held = h == carried, ail = h.ail or 0 })
    end
    for _, w in wolves do
        table.insert(team, { x = w.x, y = g + 5, cell = w.cell, hp = math.clamp(w.hp / w.max, 0, 1), hurt = w.hurt, hearts = 3, face = w.face, down = false, held = false })
    end
    model.team = team
    local seen = {}
    for k, f in horde do
        if k > 96 then break end
        seen[k] = { x = f.x, y = f.y, lift = f.k.big and 0 or 99 - f.k.foot, turn = f.turn + (f.dying and math.min(1, f.dying * 1.6) * 88 or 0), cell = f.cell, hurt = f.hurt, lit = f.lit,
                    sheet = f.k.sheet, size = f.size, wash = f.wash }
    end
    model.horde = seen
    local flying = {}
    for _, s in shots do table.insert(flying, s) end
    for _, b in bombs do
        if b.what == "tnt" then
            table.insert(flying, { x = b.x, y = b.y + 24, turn = 0, kind = (b.fuse and math.floor(b.fuse * 10) % 2 == 1) and 4 or 2 })
        else
            table.insert(flying, { x = b.x, y = b.y, turn = b.turn, kind = b.what == "heal" and 5 or 6 })
        end
    end
    model.shots = flying
    model.drops = drops
    model.puffs = puffs
    model.chests = chests
    if king then text.lord = king.lord end
    fact.xp, fact.level, fact.ready = math.clamp(xp / need, 0, 1), gained(), 1 - smite_in / 8

    save_in -= dt
    if save_in <= 0 then
        save_in = 15
        save()
    end
end)

-- A press on the controller: A for the lightning, Y to silence it.
local was = {}
sys.watch("gamepad", function(pads)
    local p = pads[1]
    if not p then was = {} return end
    if p.a and not was.a then smite() end
    if p.y and not was.y then
        quiet = not quiet
        fact.quiet = quiet
        if quiet then sound.stop() end
    end
    was = { a = p.a, y = p.y }
end)
fact.quiet, fact.auto = quiet, auto
fact.land = select(2, land_of(wave))
