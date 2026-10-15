-- Edge guard's logic: where everyone is and what they do, every frame, and
-- what the hand asks for. The scene only draws what these lists say.
-- Its parts are in logic/: the tables (data), the camp and its open table
-- (camp), the battle (field), and the map, the bestiary, the feats and what
-- happens while nobody looks (book). They share what is kept here, in `G`.

local G = { W = 1920, H = 1080 }
on("wide", function(v) if v > 100 then G.W = v end end)
on("tall", function(v) if v > 100 then G.H = v end end)
function G.ground() return G.H - 16 end

-- What is kept: 27 slots and then the bar of nine, each one a pile
-- ({ id, n, e }: `e`, its enchantments) or nothing; the crafting grid, the
-- same; what the mouse carries; the furnace, the mine, the wheat and the
-- enchanting table.
G.inv, G.grid, G.held, G.ghosts, G.found = {}, {}, nil, nil, {}
G.furnace = { burn = 0, t = 0 }
G.mine = { level = 1, stock = {}, total = 0, t = 0 }
G.farm = { 0, 0 }
G.bench = { seed = 1 }
-- Who is on the field, and what.
G.heroes, G.wolves, G.horde, G.shots, G.bombs, G.drops, G.puffs = {}, {}, {}, {}, {}, {}, {}
G.chests, G.marks, G.webs, G.queue = {}, {}, {}, {}
-- Where the party is: which world, which of its six lands, which of that
-- land's five waves; how far the way is open; and whether it stays put.
G.world, G.land, G.step, G.reached, G.stay = 1, 0, 0, 0, false
-- Experience: what is gathered towards the next level, the levels not yet spent, and all those earnt in this world.
G.xp, G.points, G.earned = 0, 0, 0
G.kills, G.lords, G.seen, G.feats, G.recruited = {}, { 0, 0, 0, 0, 0, 0 }, {}, {}, {}
G.stats = { felled = 0, harvests = 0, catches = 0, trades = 0 }
G.ui_clock = 0                   -- seconds the game has been shown, stopped or not: for a double press
G.stage, G.stage_in, G.spawn_in, G.smite_in, G.storm, G.clock, G.gone_in = "start", 0, 0, 0, 0, 0, 0   -- start · fight · rest · fallen
-- What the hand is at: the table open and on which page, a thing chosen on the bar, a hero being carried.
G.open, G.tab, G.pages, G.armed, G.carried, G.auto, G.quiet = false, 0, true, nil, nil, false, false
local paused, away, stowed_at = false, false, 0
local craft_in, save_in = 3, 15

local last = {}
function G.say(spec, every)
    -- Quiet, or the same sound too soon after itself: not said.
    if G.quiet then return end
    if every then
        local key = spec.wave .. spec.freq
        if G.clock - (last[key] or -9) < every then return end
        last[key] = G.clock
    end
    sound.tone(spec)
end
function G.pan(x) return math.clamp((x / G.W) * 2 - 1, -1, 1) end
function G.note(what)
    text.toast = what
    emit("note")
end
function G.need() return 12 + 5 * G.earned end
function G.save_soon() save_in = math.min(save_in, 1) end

-- Who can be of the party: the three it starts with, and the two that join.
local ROSTER = {
    knight = { name = "knight", shown = "Knight", row = 0, post = 870, base_max = 140, base_dmg = 10, every = 0.9, range = 80,   strike = 0.44, lands = 0.55, rest = "wood_sword", sweep = 4, push = 240 },
    archer = { name = "archer", shown = "Archer", row = 1, post = 780, base_max = 70,  base_dmg = 8,  every = 1.2, range = 1250, strike = 0.62, lands = 0.75, rest = "bow" },
    witch  = { name = "witch",  shown = "Witch",  row = 2, post = 700, base_max = 60,  base_dmg = 14, every = 2.8, range = 840,  strike = 0.6,  lands = 0.5,  rest = "potion", splash = 90 },
    golem  = { name = "golem",  shown = "Golem",  row = 4, post = 960, base_max = 260, base_dmg = 16, every = 1.7, range = 96,   strike = 0.6,  lands = 0.5,  sweep = 3, push = 420, size = 1.3 },
    cleric = { name = "cleric", shown = "Cleric", row = 5, post = 630, base_max = 55,  base_dmg = 0,  every = 3.0, range = 0,    strike = 0.7,  lands = 0.5,  heals = true, base_heal = 16 },
}
local by_name = {}
function G.enlist(name)
    local h = table.clone(ROSTER[name])
    h.x, h.level, h.wait, h.hurt, h.walk, h.gear = h.post, 1, 0, 0, 0, {}
    h.max, h.hp = h.base_max, h.base_max
    h.prot, h.thorns, h.regen, h.loot, h.quick, h.fire, h.heal = 0, 0, 0, 0, 1, 0, 0
    table.insert(G.heroes, h)
    by_name[name] = h
    if name == "golem" or name == "cleric" then G.recruited[name] = true end
    return h
end
for _, name in { "knight", "archer", "witch" } do G.enlist(name) end

require("logic/data")(G)
require("logic/camp")(G)
require("logic/field")(G)
require("logic/book")(G)
require("logic/trade")(G)
require("logic/sky")(G)
G.refit()
G.stock()

-- ── what was saved ──
local function packed(p) return p and { p.id, p.n, p.e or {} } or { "", 0 } end
local function pairs_of(t)
    local list = {}
    for key, value in t do table.insert(list, { key, value }) end
    return list
end
local function save()
    local party = {}
    for k, h in G.heroes do
        party[k] = { name = h.name, level = h.level, post = math.floor(h.post), gear = { packed(h.gear[1]), packed(h.gear[2]), packed(h.gear[3]), packed(h.gear[4]), packed(h.gear[5]) } }
    end
    local kept = {}
    for k = 1, 36 do kept[k] = packed(G.inv[k]) end
    -- (What lies on the grid, on the enchanting table or in the hand is still the camp's.)
    local loose = {}
    for k = 1, 9 do
        if G.grid[k] then table.insert(loose, packed(G.grid[k])) end
    end
    if G.held then table.insert(loose, packed(G.held)) end
    if G.bench.item then table.insert(loose, packed(G.bench.item)) end
    if G.bench.lapis then table.insert(loose, packed(G.bench.lapis)) end
    local found, feats, seen = {}, {}, {}
    for name in G.found do table.insert(found, name) end
    for id in G.feats do table.insert(feats, id) end
    for beast, things in G.seen do
        local ids = {}
        for id in things do table.insert(ids, id) end
        table.insert(seen, { beast, ids })
    end
    local waiting = {}
    for _, c in G.chests do
        if not c.opened then table.insert(waiting, { math.floor(c.x), c.kind }) end
    end
    local f = G.furnace
    sys.call("files.write", "guard5.json", {
        v = 5, at = os.time(), away = away, world = G.world, land = G.land, step = G.step, reached = G.reached, stay = G.stay,
        xp = G.xp, points = G.points, earned = G.earned, quiet = G.quiet, auto = G.auto, pages = G.pages,
        heroes = party, inv = kept, loose = loose, wolves = #G.wolves, found = found, chests = waiting,
        furnace = { input = packed(f.input), fuel = packed(f.fuel), out = packed(f.out), burn = f.burn },
        mine = { level = G.mine.level, stock = pairs_of(G.mine.stock) }, farm = { G.farm[1], G.farm[2] }, seed = G.bench.seed,
        kills = pairs_of(G.kills), lords = G.lords, seen = seen, feats = feats, stats = pairs_of(G.stats),
        trades = G.trades_saved(),
    })
end

local function num(v, or_) return tonumber(v) or or_ end
-- A pile as it was written: only a thing there is, as many as fit, with enchantments there are.
local function pile_of(one)
    if type(one) ~= "table" or not G.ITEM[one[1]] or num(one[2], 0) <= 0 then return nil end
    local e = nil
    if type(one[3]) == "table" then
        for key, level in one[3] do
            if G.ENCH[key] and num(level, 0) >= 1 then
                e = e or {}
                e[key] = math.min(math.floor(num(level, 1)), G.ENCH[key].max)
            end
        end
    end
    return { id = one[1], n = math.min(math.floor(num(one[2], 1)), G.pile(one[1])), e = e }
end
-- What an earlier Edge guard saved (three heroes, a weapon, an armour and a
-- charm each, and waves counted from one), as this one keeps it.
local function from_before(old)
    local wave = math.max(1, math.floor(num(old.wave, 1)))
    local party, levels = {}, 0
    for k, name in { "knight", "archer", "witch" } do
        local g = type(old.gear) == "table" and old.gear[k] or {}
        local level = math.max(1, num(old.levels and old.levels[k], 1))
        levels += level - 1
        party[k] = { name = name, level = level, post = old.posts and old.posts[k] and num(old.posts[k], 0) + 330 or nil,
                     gear = { { g[1] or "", 1 }, { "", 0 }, { g[2] or "", 1 }, { "", 0 }, { g[3] or "", 1 } } }
    end
    return { world = 1, land = ((wave - 1) // 5) % 6, step = 0, reached = math.min(5, (wave - 1) // 5), xp = old.xp, points = 0, earned = levels,
             quiet = old.quiet, auto = old.auto, heroes = party, inv = old.inv, loose = old.loose, wolves = old.wolves, found = old.found, chests = old.chests }
end
do
    local ok, kept = pcall(sys.ask, "files.read", "guard5.json", "json")
    if not (ok and type(kept) == "table") then
        local had, old = pcall(sys.ask, "files.read", "guard4.json", "json")
        kept = had and type(old) == "table" and from_before(old) or nil
        if kept then log("carried over from an earlier save") end
    end
    if kept then
        G.world = math.max(1, math.floor(num(kept.world, 1)))
        G.land, G.step = math.clamp(math.floor(num(kept.land, 0)), 0, 5), math.clamp(math.floor(num(kept.step, 0)), 0, 4)
        G.reached = math.clamp(math.floor(num(kept.reached, 0)), G.land, 5)
        G.stay, G.quiet, G.auto, G.pages = kept.stay == true, kept.quiet == true, kept.auto == true, kept.pages ~= false
        G.xp, G.points, G.earned = math.max(0, num(kept.xp, 0)), math.max(0, math.floor(num(kept.points, 0))), math.max(0, math.floor(num(kept.earned, 0)))
        for _, one in (type(kept.heroes) == "table" and kept.heroes or {}) do
            local h = by_name[one.name] or ((one.name == "golem" or one.name == "cleric") and G.enlist(one.name)) or nil
            if h then
                h.level = math.max(1, math.floor(num(one.level, 1)))
                h.post = math.clamp(num(one.post, h.post), G.CAMP_END, 1400)
                h.x = h.post
                for j = 1, 5 do
                    local p = pile_of(type(one.gear) == "table" and one.gear[j])
                    if p and G.GEAR[p.id] and G.GEAR[p.id].slot == j then h.gear[j] = p end
                end
            end
        end
        for k = 1, 36 do G.inv[k] = pile_of(kept.inv and kept.inv[k]) end
        for _, one in kept.loose or {} do
            local p = pile_of(one)
            if p then G.add(p.id, p.n, p.e) end
        end
        for _, name in kept.found or {} do G.found[name] = true end
        for _, c in kept.chests or {} do
            if #G.chests < 12 then table.insert(G.chests, { x = num(c[1], 1200), y = G.ground(), vy = 0, kind = math.clamp(num(c[2], 0), 0, 3), t = 9 }) end
        end
        if type(kept.furnace) == "table" then
            local f = kept.furnace
            G.furnace.input, G.furnace.fuel, G.furnace.out, G.furnace.burn = pile_of(f.input), pile_of(f.fuel), pile_of(f.out), math.clamp(num(f.burn, 0), 0, 8)
        end
        if type(kept.mine) == "table" then
            G.mine.level = math.clamp(math.floor(num(kept.mine.level, 1)), 1, 3)
            for _, one in kept.mine.stock or {} do
                if G.ITEM[one[1]] and num(one[2], 0) > 0 then
                    G.mine.stock[one[1]] = num(one[2], 0)
                    G.mine.total += num(one[2], 0)
                end
            end
        end
        if type(kept.farm) == "table" then G.farm[1], G.farm[2] = math.clamp(num(kept.farm[1], 0), 0, 1), math.clamp(num(kept.farm[2], 0), 0, 1) end
        G.bench.seed = math.max(1, math.floor(num(kept.seed, 1)))
        for _, one in kept.kills or {} do G.kills[one[1]] = num(one[2], 0) end
        for k = 1, 6 do G.lords[k] = num(kept.lords and kept.lords[k], 0) end
        for _, one in kept.seen or {} do
            G.seen[one[1]] = {}
            for _, id in one[2] or {} do G.seen[one[1]][id] = true end
        end
        for _, id in kept.feats or {} do G.feats[id] = true end
        for _, one in kept.stats or {} do
            if G.stats[one[1]] then G.stats[one[1]] = num(one[2], 0) end
        end
        G.refit()
        G.stock()
        G.trades_back(kept.trades)
        for _, h in G.heroes do h.hp = h.max end
        for _ = 1, math.clamp(num(kept.wolves, 0), 0, 3) do G.tame() end
        for _, w in G.wolves do w.x = w.post end
        log("back in", G.LANDS[G.land + 1].name, "wave", G.step + 1, "of world", G.world)
        if kept.away == true then
            -- It was put away when it was closed: it still is, and what the camp does meanwhile is told when it is brought back.
            away, stowed_at = true, num(kept.at, os.time())
            fact.away = true
        elseif kept.at then
            -- What the camp did since.
            G.away(os.time() - num(kept.at, os.time()))
        end
    end
end

on("halt", function()
    paused = not paused
    fact.paused = paused
end)
on("stow", function()
    away = not away
    fact.away = away
    if away then
        if G.open then G.shut() end
        G.armed, G.carried = nil, nil
        fact.aiming, fact.armed = false, -1
        stowed_at = os.time()
        save()
    else
        -- Put away, the camp went on by itself: as when nobody was there.
        G.away(os.time() - stowed_at)
        G.save_soon()
    end
end)

-- ── a frame ──
on("frame", function(dt)
    -- Put away: nothing is worked out, and nothing is told to a scene that shows none of it.
    if away then return end
    G.ui_clock += dt
    G.show_camp()
    G.show_book(dt)
    -- Stopped: nothing moves.
    if paused then return end
    G.clock += dt
    G.fight(dt)
    G.smelt(dt)
    G.dig(dt)
    G.grow(dt)

    -- By itself, now and then.
    craft_in -= dt
    if craft_in <= 0 then
        craft_in = 1.5
        if G.auto then G.alone() end
    end
    if G.gone_in > 0 then
        G.gone_in -= dt
        if G.gone_in <= 0 then fact["gone.on"] = false end
    end

    G.show_field()

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
    if p.a and not was.a then G.smite() end
    if p.y and not was.y then
        G.quiet = not G.quiet
        fact.quiet = G.quiet
        if G.quiet then sound.stop() end
    end
    was = { a = p.a, y = p.y }
end)
fact.quiet, fact.auto, fact.pages, fact.land, fact.tab = G.quiet, G.auto, G.pages, G.land, 0
text.where = G.LANDS[G.land + 1].short .. " " .. (G.step + 1) .. "/5"
