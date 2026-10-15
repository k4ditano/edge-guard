-- The camp: what is kept, what is made and how, the furnace, the mine, the
-- field of wheat, the enchanting table, what each hero carries, and where
-- everything of the open table is —the same numbers the scene draws it with—.
return function(G)
    local ITEM, NAMES, GEAR, RECIPES, ENCH = G.ITEM, G.NAMES, G.GEAR, G.RECIPES, G.ENCH
    local pile, note, say = G.pile, G.note, G.say
    local inv, grid = G.inv, G.grid
    -- Where the mine and the two plots of wheat are, along the edge.
    local MINE_X, FARM_X = 367, { 439, 501 }
    -- (The trader keeps his stall just past the wheat.)
    G.CAMP_END, G.TRADER_X = 620, 572

    local function glint(p) return p ~= nil and p.e ~= nil and next(p.e) ~= nil end
    function G.describe(p)
        if not p then return "" end
        local s = NAMES[p.id] or p.id
        if p.e then
            for _, key in G.ENCH_ORDER do
                if p.e[key] then s ..= " - " .. ENCH[key].name .. " " .. G.ROMAN[p.e[key]] end
            end
        end
        return s
    end

    -- ── keeping things ──
    local function count(id)
        local n = 0
        for k = 1, 36 do
            if inv[k] and inv[k].id == id then n += inv[k].n end
        end
        return n
    end
    -- Into the first pile of its kind with room, or the first empty slot: what is
    -- used goes to the bar first, the rest to the slots above it. An enchanted
    -- thing keeps a slot to itself. Answers how many did not fit.
    local function add(id, n, e)
        local order = {}
        local first, last = 1, 27
        if GEAR[id] and GEAR[id].use then first, last = 28, 36 end
        for k = first, last do table.insert(order, k) end
        for k = (first == 1 and 28 or 1), (first == 1 and 36 or 27) do table.insert(order, k) end
        if not (e and next(e)) then
            for _, k in order do
                if n > 0 and inv[k] and inv[k].id == id and not glint(inv[k]) and inv[k].n < pile(id) then
                    local move = math.min(n, pile(id) - inv[k].n)
                    inv[k].n, n = inv[k].n + move, n - move
                end
            end
        end
        for _, k in order do
            if n > 0 and not inv[k] then
                local move = math.min(n, pile(id))
                inv[k], n = { id = id, n = move, e = e }, n - move
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
    -- One of a thing, out of what is kept, as it is (enchanted or not).
    local function take_one(id)
        for k = 36, 1, -1 do
            if inv[k] and inv[k].id == id then
                local one = { id = id, n = 1, e = inv[k].e }
                inv[k].n -= 1
                if inv[k].n <= 0 then inv[k] = nil end
                return one
            end
        end
        return nil
    end
    local function spend(id) return take_one(id) ~= nil end
    G.count, G.add, G.remove, G.spend = count, add, remove, spend

    local function known(r)
        for id in r.needs do
            if not G.found[id] then return false end
        end
        return true
    end
    local function enough(r)
        for id, many in r.needs do
            if count(id) < many then return false end
        end
        return true
    end
    function G.gain(id, n, e)
        local left = add(id, n or 1, e)
        if left > 0 then note("No room left for the " .. NAMES[id]:lower()) end
        -- Something never seen before: a recipe may now be known.
        if not G.found[id] then
            G.found[id] = true
            for _, r in RECIPES do
                if r.needs[id] and known(r) then note("New recipe: " .. NAMES[r.out]) end
            end
        end
    end

    -- ── the crafting grid ──
    local function back(p)
        if p then add(p.id, p.n, p.e) end
    end
    local function clear_grid()
        for k = 1, 9 do
            back(grid[k])
            grid[k] = nil
        end
        G.ghosts = nil
    end
    local function clear_bench()
        back(G.bench.item)
        back(G.bench.lapis)
        G.bench.item, G.bench.lapis = nil, nil
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
                            local at = mirrored and wide + 1 - c or c
                            local letter = recipe.rows[r]:sub(at, at)
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
    -- A recipe of the book, laid out on the grid from what is kept; or, short of something, shown faintly.
    local function lay(r)
        clear_grid()
        if not enough(r) then
            G.ghosts = {}
            for row = 1, #r.rows do
                for c = 1, #r.rows[row] do
                    G.ghosts[(row - 1) * 3 + c] = r.key[r.rows[row]:sub(c, c)]
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
                if id then grid[(row - 1) * 3 + c] = take_one(id) end
            end
        end
        say({ wave = "square", freq = 520, ms = 30, volume = 0.03 })
    end
    local function made_feats(out)
        G.feat("craft")
        if out:sub(1, 8) == "diamond_" then G.feat("shiny") end
        if out:sub(1, 10) == "netherite_" then G.feat("nether") end
    end
    -- What the grid makes, into the hand: one of each thing on it is spent.
    local function take_made()
        local r = laid()
        if not r then return end
        local held = G.held
        if held and (held.id ~= r.out or held.n + r.n > pile(r.out)) then return end
        local e = nil
        for k = 1, 9 do
            if grid[k] then
                if r.keeps and grid[k].id == r.key[r.keeps] then e = grid[k].e end
                grid[k].n -= 1
                if grid[k].n <= 0 then grid[k] = nil end
            end
        end
        held = held or { id = r.out, n = 0, e = e }
        held.n += r.n
        G.held = held
        G.found[r.out] = true
        made_feats(r.out)
        say({ wave = "triangle", freq = 660, to = 990, ms = 120, volume = 0.1 })
        note(NAMES[r.out] .. ": " .. (GEAR[r.out] and GEAR[r.out].says or G.SAYS[r.out] or ""))
        log("crafted", NAMES[r.out])
    end

    -- ── what each hero is worth, with its level and what it carries ──
    function G.refit()
        local star = 1 + 0.25 * (G.world - 1)
        for _, h in G.heroes do
            local share = h.max and h.hp / h.max or 1
            local life, prot, thorns, mend = 1, 0, 0, 0
            for j = 2, 4 do
                local p = h.gear[j]
                if p then
                    life *= GEAR[p.id].life or 1
                    if p.e then prot, thorns, mend = prot + (p.e.prot or 0), thorns + (p.e.thorns or 0), mend + (p.e.mend or 0) end
                end
            end
            local weapon = h.gear[1]
            local def, e = weapon and GEAR[weapon.id] or nil, weapon and weapon.e or {}
            h.max = h.base_max * 1.12 ^ (h.level - 1) * life * star
            h.dmg = h.base_dmg * 1.18 ^ (h.level - 1) * (def and def.dmg or 1) * (1 + 0.2 * (e.sharp or 0)) * star
            h.heal = (h.base_heal or 0) * 1.18 ^ (h.level - 1) * star
            h.prot, h.thorns, h.regen = math.min(0.6, prot * 0.04), thorns * 0.1, mend * 0.003
            h.loot, h.quick = e.loot or 0, 1 + 0.1 * (e.haste or 0)
            h.fire = (e.fire or 0) * 0.15 + (def and def.burns and 0.2 or 0)
            h.frost = def and def.slows or false
            h.hp = h.max * share
        end
    end
    function G.charm(h, what)
        local c = h.gear and h.gear[5] and GEAR[h.gear[5].id]
        return c and c[what]
    end
    function G.level_cost(h) return 1 + h.level // 4 end
    function G.level_up(h)
        local cost = G.level_cost(h)
        if G.points < cost then
            note("The " .. h.shown:lower() .. "'s next level takes " .. cost .. (cost > 1 and " levels" or " level") .. " of experience")
            return false
        end
        G.points -= cost
        h.level += 1
        G.refit()
        if not h.down then h.hp = h.max end
        fact["up.x"] = h.x
        emit("levelup")
        say({ wave = "sine", freq = 660, to = 1320, ms = 320, volume = 0.1 })
        return true
    end
    -- Whether a hero can carry a thing, and what it is worth to it.
    local function fits(h, def) return not def.who or def.who == h.name end
    local function worth(def) return def and ((def.dmg or 0) + (def.life or 0)) or 0 end

    -- A slot of a hero: what the hand carries goes on, if it is for that slot and
    -- that hero; with an empty hand, what is there comes off.
    local SLOTS = { "the weapon's", "the helmet's", "the chestplate's", "the boots'", "the charm's" }
    local function wear(h, j)
        local held = G.held
        if held then
            local def = GEAR[held.id]
            if not def or not def.slot then return note("That is not something to wear") end
            if def.slot ~= j then return note(def.name .. " goes in " .. SLOTS[def.slot] .. " slot") end
            if not fits(h, def) then return note("The " .. h.shown:lower() .. " cannot use the " .. def.name:lower()) end
            local before = h.gear[j]
            h.gear[j] = held
            G.held = before
            G.refit()
            fact["up.x"] = h.x
            emit("levelup")
            say({ wave = "square", freq = 520, to = 780, ms = 90, volume = 0.07 })
            if h.gear[2] and h.gear[3] and h.gear[4] then G.feat("ironclad") end
        elseif h.gear[j] then
            G.held = h.gear[j]
            h.gear[j] = nil
            G.refit()
        end
    end

    -- ── the furnace ──
    -- What would come out now: something to smelt, room for it, and fire or fuel.
    local function smelting()
        local f = G.furnace
        local into = f.input and G.SMELT[f.input.id]
        if not into or (f.out and (f.out.id ~= into or f.out.n >= 64)) then return nil end
        if f.burn <= 0 and not f.fuel then return nil end
        return into
    end
    local function smelt_one()
        local f = G.furnace
        local into = smelting()
        if not into then return false end
        if f.burn <= 0 then
            f.burn = G.FUEL[f.fuel.id]
            f.fuel.n -= 1
            if f.fuel.n <= 0 then f.fuel = nil end
        end
        f.burn -= 1
        f.input.n -= 1
        if f.input.n <= 0 then f.input = nil end
        f.out = f.out or { id = into, n = 0 }
        f.out.n += 1
        return true
    end
    function G.smelt(dt)
        local f = G.furnace
        if not smelting() then f.t = 0 return end
        f.t += dt
        if f.t >= G.SMELT_TIME then
            f.t = 0
            smelt_one()
        end
    end
    function G.smelt_for(seconds)
        local made = 0
        for _ = 1, math.floor(seconds / G.SMELT_TIME) do
            if not smelt_one() then break end
            made += 1
        end
        return made
    end

    -- ── the mine ──
    local function dig_one()
        local m = G.mine
        local def = G.MINE[m.level]
        if m.total >= def.holds then return nil end
        local sum = 0
        for _, f in def.finds do sum += f[2] end
        local r = math.random() * sum
        for _, f in def.finds do
            r -= f[2]
            if r <= 0 then
                m.stock[f[1]] = (m.stock[f[1]] or 0) + 1
                m.total += 1
                return f[1]
            end
        end
        return nil
    end
    function G.dig(dt)
        local m = G.mine
        m.t += dt
        if m.t >= G.MINE[m.level].every then
            m.t = 0
            dig_one()
        end
    end
    function G.dig_for(seconds)
        local got = {}
        for _ = 1, math.floor(seconds / G.MINE[G.mine.level].every) do
            local id = dig_one()
            if not id then break end
            got[id] = (got[id] or 0) + 1
        end
        return got
    end
    -- The mine, pressed: all it has comes out and goes to the chest.
    local function fetch()
        local m = G.mine
        if m.total == 0 then return note("The mine has nothing yet: it finds something every " .. G.MINE[m.level].every .. " seconds") end
        for id, n in m.stock do
            if not G.leave(id, MINE_X, G.ground() - 50, 300, n) then G.gain(id, n) end
        end
        m.stock, m.total = {}, 0
        say({ wave = "square", freq = 180, to = 120, ms = 80, volume = 0.06 })
    end

    -- ── the wheat ──
    function G.grow(seconds)
        for k = 1, 2 do G.farm[k] = math.min(1, G.farm[k] + seconds / G.FARM_TIME) end
    end
    local function ripe()
        return G.farm[1] >= 1 or G.farm[2] >= 1
    end
    local function reap()
        if not ripe() then return note("The wheat is not golden yet") end
        for k = 1, 2 do
            if G.farm[k] >= 1 then
                G.farm[k] = 0
                local n = 2 + math.random(0, 1)
                if not G.leave("wheat", FARM_X[k], G.ground() - 30, 260, n) then G.gain("wheat", n) end
            end
        end
        G.stats.harvests += 1
        if G.stats.harvests >= 10 then G.feat("harvest") end
        say({ wave = "triangle", freq = 520, to = 780, ms = 90, volume = 0.06 })
    end

    -- ── the enchanting table ──
    local function rng(seed)
        local s = seed % 2147483647
        if s <= 0 then s += 2147483646 end
        return function()
            s = s * 16807 % 2147483647
            return (s - 1) / 2147483646
        end
    end
    -- What it offers for the thing on it: up to three, each one level more of
    -- something; they stay the same until one is taken.
    local function offers()
        local list = {}
        local p = G.bench.item
        if not p then return list end
        local on = GEAR[p.id].slot == 1 and "weapon" or "armour"
        local some = {}
        for _, key in G.ENCH_ORDER do
            if ENCH[key].on == on and ((p.e and p.e[key]) or 0) < ENCH[key].max then table.insert(some, key) end
        end
        local rnd = rng(G.bench.seed * 31 + ITEM[p.id] * 7 + 1)
        for k = #some, 2, -1 do
            local j = 1 + math.floor(rnd() * k)
            some[k], some[j] = some[j], some[k]
        end
        for k = 1, math.min(3, #some) do
            local to = ((p.e and p.e[some[k]]) or 0) + 1
            table.insert(list, { key = some[k], to = to, cost = to })
        end
        return list
    end
    local function enchant(k)
        local o = offers()[k]
        if not o then return end
        local lapis = G.bench.lapis and G.bench.lapis.n or 0
        if G.points < o.cost then return note("That takes " .. o.cost .. (o.cost > 1 and " levels" or " level") .. " of experience") end
        if lapis < o.cost then return note("That takes " .. o.cost .. " lapis lazuli in the slot beside it") end
        local p = G.bench.item
        p.e = p.e or {}
        p.e[o.key] = o.to
        G.points -= o.cost
        G.bench.lapis.n -= o.cost
        if G.bench.lapis.n <= 0 then G.bench.lapis = nil end
        G.bench.seed += 1
        G.feat("enchant")
        if o.to >= ENCH[o.key].max then G.feat("maxed") end
        say({ wave = "sine", freq = 880, to = 1760, ms = 420, volume = 0.08 })
        note(G.describe(p))
        fact["up.x"] = 299
        emit("levelup")
    end

    -- ── where everything of the table is ──
    -- (The scene draws it with the same numbers: a slot is 40 a side, the
    -- window 404 high, and its columns —the book or the trader's offers, what
    -- is open with what is kept under it, and the party— one beside the other.)
    local S, H, BOOK_W, PARTY_W = 40, 404, 264, 330
    local FULL = 14 + BOOK_W + 16 + 9 * S + 16 + PARTY_W + 14
    -- The pages, in the order their tabs go: crafting, furnace, enchanting, the trader, the lands, the bestiary, the feats.
    local TABS = { 0, 1, 2, 6, 3, 4, 5 }
    G.TABS = TABS
    local function left_column() return G.pages or G.tab == 6 end
    local function origin()
        local wx, wy = 24, G.ground() - 156 - H
        local bx = wx + 14
        local mx = bx + (left_column() and BOOK_W + 16 or 0)
        return wx, wy, mx, mx + 9 * S + 16, bx
    end
    function G.table_box()
        local wx, wy, _, tx = origin()
        local w = (G.tab >= 3 and G.tab <= 5) and FULL or tx + PARTY_W + 14 - wx
        return wx, wy, w, H
    end
    local function inside(x, y, rx, ry, w, h) return x >= rx and x < rx + w and y >= ry and y < ry + h end
    -- Where a slot of what is kept is: 27 in three rows, and the bar of nine under them.
    local function inv_at(i, mx, wy)
        return mx + (i % 9) * S, wy + (i < 27 and 224 + (i // 9) * S or 352)
    end
    -- What is under a point: a tab, a slot of what is kept, of the grid, of the
    -- furnace, of the enchanting table, of a hero; what is made; a recipe, an
    -- offer of the trader's; a button; a land of the map. And the box to light.
    local function under(x, y)
        if not x then return nil end
        local wx, wy, mx, tx, bx = origin()
        for c = 0, 6 do
            if inside(x, y, wx + c * 138, wy - 46, 134, 40) then return { "tab", TABS[c + 1] } end
        end
        if G.tab == 3 then
            for k = 0, 5 do
                if inside(x, y, wx + 16 + k * 164, wy + 56, 156, 224) then return { "land", k } end
            end
            if inside(x, y, wx + 16, wy + 300, 360, 32) then return { "stay", 0 } end
            if inside(x, y, wx + FULL - 276, wy + 296, 260, 60) then return { "world", 0 } end
            return nil
        elseif G.tab == 4 or G.tab == 5 then
            return nil
        end
        if G.tab == 0 then
            for i = 0, 8 do
                local sx, sy = mx + 60 + (i % 3) * S, wy + 60 + (i // 3) * S
                if inside(x, y, sx, sy, S, S) then return { "grid", i + 1, x = sx, y = sy, s = S } end
            end
            if inside(x, y, mx + 270, wy + 92, 56, 56) then return { "made", 0, x = mx + 270, y = wy + 92, s = 56 } end
            if inside(x, y, mx, wy + 100, 44, 40) then return { "pages", 0 } end
        elseif G.tab == 1 then
            if inside(x, y, mx + 110, wy + 56, S, S) then return { "fin", 0, x = mx + 110, y = wy + 56, s = S } end
            if inside(x, y, mx + 110, wy + 148, S, S) then return { "ffuel", 0, x = mx + 110, y = wy + 148, s = S } end
            if inside(x, y, mx + 270, wy + 92, 56, 56) then return { "fout", 0, x = mx + 270, y = wy + 92, s = 56 } end
        elseif G.tab == 2 then
            if inside(x, y, mx + 4, wy + 96, S, S) then return { "eitem", 0, x = mx + 4, y = wy + 96, s = S } end
            if inside(x, y, mx + 50, wy + 96, S, S) then return { "elapis", 0, x = mx + 50, y = wy + 96, s = S } end
            for k = 0, 2 do
                if inside(x, y, mx + 100, wy + 56 + k * 46, 260, 42) then return { "offer", k + 1 } end
            end
        end
        for i = 0, 35 do
            local sx, sy = inv_at(i, mx, wy)
            if inside(x, y, sx, sy, S, S) then return { "inv", i + 1, x = sx, y = sy, s = S } end
        end
        for k = 0, #G.heroes - 1 do
            local cy = wy + 48 + k * 68
            for j = 0, 4 do
                local sx, sy = tx + 70 + j * S, cy + 22
                if inside(x, y, sx, sy, S, S) then return { "gear", k * 5 + j + 1, x = sx, y = sy, s = S } end
            end
            if inside(x, y, tx + 280, cy + 24, 44, 36) then return { "level", k + 1 } end
        end
        if inside(x, y, mx + 9 * S - 70, wy + 14, 70, 26) then return { "auto", 0 } end
        if inside(x, y, mx + 9 * S - 64, wy + 196, 64, 24) then return { "sort", 0 } end
        if G.tab == 6 then
            for k = 0, #G.trades - 1 do
                if inside(x, y, bx, wy + 52 + k * 46, BOOK_W, 42) then return { "trade", k + 1, x = bx, y = wy + 52 + k * 46, w = BOOK_W, h = 42 } end
            end
        elseif G.pages then
            for i = 0, 35 do
                local sx, sy = bx + (i % 6) * 44, wy + 52 + (i // 6) * 44
                if inside(x, y, sx, sy, 42, 42) then return { "recipe", i + 1, x = sx, y = sy, s = 42 } end
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

    -- What may lie in a slot that is not for everything.
    local ONLY = {
        fin = function(id) return G.SMELT[id] ~= nil end,
        ffuel = function(id) return G.FUEL[id] ~= nil end,
        eitem = function(id) return GEAR[id] ~= nil and GEAR[id].slot ~= nil and GEAR[id].slot <= 4 end,
        elapis = function(id) return id == "lapis" end,
    }
    local WRONG = { fin = "Only raw iron and raw gold are smelted", ffuel = "It burns coal, or sticks", eitem = "Only a weapon or a piece of armour takes an enchantment", elapis = "That slot is for lapis lazuli" }
    -- A press on a slot: pick up, put down, pile, swap. With the right button:
    -- half of what is there, or one of what is carried.
    local function slot_press(t, k, right, kind)
        local there, held = t[k], G.held
        if held and kind and not ONLY[kind](held.id) then return note(WRONG[kind]) end
        if not held then
            if not there then return end
            if right and there.n > 1 then
                local half = math.ceil(there.n / 2)
                G.held = { id = there.id, n = half }
                there.n -= half
            else
                G.held, t[k] = there, nil
            end
        elseif not there then
            if right and held.n > 1 then
                t[k] = { id = held.id, n = 1 }
                held.n -= 1
            else
                t[k], G.held = held, nil
            end
        elseif there.id == held.id and there.n < pile(there.id) then
            local move = right and 1 or math.min(held.n, pile(there.id) - there.n)
            there.n += move
            held.n -= move
            if held.n <= 0 then G.held = nil end
        elseif not right then
            t[k], G.held = held, there
        end
        if t == grid then G.ghosts = nil end
    end
    -- What the furnace has made: only ever taken.
    local function take_smelted()
        local f, held = G.furnace, G.held
        if not f.out then return end
        if not held then
            G.held, f.out = f.out, nil
        elseif held.id == f.out.id and held.n + f.out.n <= 64 then
            held.n += f.out.n
            f.out = nil
        else
            return
        end
        G.feat("smelt")
    end
    local function set_tab(n)
        if n == G.tab then return end
        clear_grid()
        clear_bench()
        G.tab = n
        fact.tab = n
        say({ wave = "square", freq = 440, ms = 25, volume = 0.03 })
    end

    -- ── moving things as there: with Shift, to where they belong; twice, all
    --    of a kind into the hand; dragged over slots, shared out among them ──
    -- A pile into a stretch of what is kept: onto piles of its kind first, then
    -- into empty slots. Answers what did not fit.
    local function move_into(p, first, last)
        if not (p.e and next(p.e)) then
            for k = first, last do
                if p.n > 0 and inv[k] and inv[k].id == p.id and not glint(inv[k]) and inv[k].n < pile(p.id) then
                    local move = math.min(p.n, pile(p.id) - inv[k].n)
                    inv[k].n, p.n = inv[k].n + move, p.n - move
                end
            end
        end
        for k = first, last do
            if p.n > 0 and not inv[k] then
                inv[k] = { id = p.id, n = p.n, e = p.e }
                p.n = 0
            end
        end
        return p.n > 0 and p or nil
    end
    -- Out of one of the table's own slots and into what is kept.
    local function home(t, key)
        local p = t[key]
        if not p then return end
        local left = add(p.id, p.n, p.e)
        if left > 0 then
            p.n = left
            note("No room left for the " .. NAMES[p.id]:lower())
        else
            t[key] = nil
        end
    end
    -- Into a slot of the furnace or the enchanting table, from slot k of what is kept.
    local function into(t, key, k)
        local p, there = inv[k], t[key]
        if not there then
            t[key], inv[k] = p, nil
        elseif there.id == p.id and there.n < pile(p.id) then
            local move = math.min(p.n, pile(p.id) - there.n)
            there.n, p.n = there.n + move, p.n - move
            if p.n <= 0 then inv[k] = nil end
        end
    end
    -- What the grid makes, as many times as it can, into what is kept.
    local function craft_all()
        local made = 0
        for _ = 1, 64 do
            local r = laid()
            if not r then break end
            local e = nil
            for k = 1, 9 do
                if grid[k] and r.keeps and grid[k].id == r.key[r.keeps] then e = grid[k].e end
            end
            if add(r.out, r.n, e) > 0 then note("No room left for the " .. NAMES[r.out]:lower()) break end
            for k = 1, 9 do
                if grid[k] then
                    grid[k].n -= 1
                    if grid[k].n <= 0 then grid[k] = nil end
                end
            end
            G.found[r.out] = true
            made_feats(r.out)
            made += 1
        end
        if made > 0 then
            say({ wave = "triangle", freq = 660, to = 990, ms = 120, volume = 0.1 })
            log("crafted", made, "at once")
        end
    end
    local function quick(ref)
        local kind, k = ref[1], ref[2]
        if kind == "inv" then
            local p = inv[k]
            if not p then return end
            local def = GEAR[p.id]
            if G.tab == 1 and G.SMELT[p.id] then return into(G.furnace, "input", k) end
            if G.tab == 1 and G.FUEL[p.id] then return into(G.furnace, "fuel", k) end
            if G.tab == 2 and p.id == "lapis" then return into(G.bench, "lapis", k) end
            if G.tab == 2 and def and def.slot and def.slot <= 4 and not G.bench.item then
                G.bench.item, inv[k] = p, nil
                return
            end
            -- Something to wear: onto the first hero who can and has that slot free.
            if def and def.slot then
                for _, h in G.heroes do
                    if not h.gear[def.slot] and fits(h, def) then
                        G.held, inv[k] = p, nil
                        wear(h, def.slot)
                        if G.held then back(G.held) G.held = nil end
                        return
                    end
                end
            end
            -- Otherwise between what is kept and the bar.
            inv[k] = nil
            local left = k <= 27 and move_into(p, 28, 36) or move_into(p, 1, 27)
            if left then
                -- No room there: it stays where it was, as much as is left of it.
                inv[k] = left
            end
            say({ wave = "square", freq = 600, ms = 20, volume = 0.03 })
        elseif kind == "grid" then home(grid, k)
        elseif kind == "fin" then home(G.furnace, "input")
        elseif kind == "ffuel" then home(G.furnace, "fuel")
        elseif kind == "fout" then
            if G.furnace.out then G.feat("smelt") end
            home(G.furnace, "out")
        elseif kind == "eitem" then home(G.bench, "item")
        elseif kind == "elapis" then home(G.bench, "lapis")
        elseif kind == "made" then craft_all()
        elseif kind == "gear" then
            local h, j = G.heroes[(k - 1) // 5 + 1], (k - 1) % 5 + 1
            local p = h.gear[j]
            if p and add(p.id, p.n, p.e) == 0 then
                h.gear[j] = nil
                G.refit()
            end
        elseif kind == "trade" then G.trade(k, true)
        else
            return false
        end
        return true
    end
    -- Every pile of the kind the hand carries, gathered into it as far as it goes.
    local function gather()
        local held = G.held
        if not held or glint(held) then return end
        for _, t in { inv, grid } do
            for k = 1, (t == inv and 36 or 9) do
                local p = t[k]
                if held.n < pile(held.id) and p and p.id == held.id and not glint(p) then
                    local move = math.min(p.n, pile(held.id) - held.n)
                    held.n, p.n = held.n + move, p.n - move
                    if p.n <= 0 then t[k] = nil end
                end
            end
        end
    end
    -- What is kept, in order: piles of a kind together, in the order of the sheet. The bar stays as it is.
    local function sort_kept()
        local list = {}
        for k = 1, 27 do
            if inv[k] then table.insert(list, inv[k]) end
            inv[k] = nil
        end
        table.sort(list, function(a, b)
            if a.id ~= b.id then return ITEM[a.id] < ITEM[b.id] end
            return a.n > b.n
        end)
        for _, p in list do move_into(p, 1, 27) end
        say({ wave = "square", freq = 500, to = 700, ms = 60, volume = 0.04 })
    end

    local pressed = nil     -- where the button went down, and whether it picked something up there
    local spread = nil      -- a pile being shared out over the slots the mouse goes over, button down
    local last_click = nil  -- for a second press on the same slot
    local function press(ref, right)
        if not ref then return end
        local kind, k = ref[1], ref[2]
        if kind == "tab" then set_tab(k)
        elseif kind == "inv" then slot_press(inv, k, right)
        elseif kind == "grid" then slot_press(grid, k, right)
        elseif kind == "made" then take_made()
        elseif kind == "fin" then slot_press(G.furnace, "input", right, kind)
        elseif kind == "ffuel" then slot_press(G.furnace, "fuel", right, kind)
        elseif kind == "fout" then take_smelted()
        elseif kind == "eitem" then slot_press(G.bench, "item", false, kind)
        elseif kind == "elapis" then slot_press(G.bench, "lapis", right, kind)
        elseif kind == "offer" then enchant(k)
        elseif kind == "gear" then wear(G.heroes[(k - 1) // 5 + 1], (k - 1) % 5 + 1)
        elseif kind == "level" then G.level_up(G.heroes[k])
        elseif kind == "trade" then G.trade(k, false)
        elseif kind == "sort" then sort_kept()
        elseif kind == "recipe" then
            local r = shown()[k]
            if r and not G.held then
                set_tab(0)
                lay(r)
            end
        elseif kind == "pages" then
            G.pages = not G.pages
            fact.pages = G.pages
        elseif kind == "auto" then
            G.auto = not G.auto
            fact.auto = G.auto
            note(G.auto and "The camp now crafts, hands things over and spends its levels by itself" or "By hand: nothing is made, handed over or learnt until you do it")
        elseif kind == "land" then G.travel(k)
        elseif kind == "stay" then
            G.stay = not G.stay
            note(G.stay and "The party stays in this land, wave after wave" or "The party goes on to the next land when a lord falls")
        elseif kind == "world" then G.new_world()
        end
    end
    local function shut()
        clear_grid()
        clear_bench()
        back(G.held)
        G.held, spread = nil, nil
        G.open = false
        fact.open = false
    end
    G.shut = shut
    local function open_at(n)
        if G.open and G.tab == n then
            shut()
        else
            if G.open then set_tab(n) else G.tab = n end
            G.open, G.armed = true, nil
            fact.open, fact.tab, fact.aiming, fact.armed = true, n, false, -1
        end
        say({ wave = "saw", freq = G.open and 140 or 260, to = G.open and 260 or 140, ms = 160, volume = 0.06 })
    end

    -- ── what the hand asks for ──
    local function shift() return held("Shift_L") or held("Shift_R") end
    -- Whether a slot of what is kept or of the grid can take some of the pile in hand.
    local function takes(ref)
        if not ref or (ref[1] ~= "inv" and ref[1] ~= "grid") or not G.held then return false end
        local p = (ref[1] == "inv" and inv or grid)[ref[2]]
        return not p or (p.id == G.held.id and not glint(p) and not glint(G.held) and p.n < pile(p.id))
    end
    -- Let go after going over several slots: the pile shared out evenly among them.
    local function share()
        local s = spread
        spread = nil
        if not s then return end
        local t = s.kind == "inv" and inv or grid
        if #s.list == 1 then return press({ s.kind, s.list[1] }, false) end
        local held = G.held
        if not held then return end
        local each = math.max(1, held.n // #s.list)
        for _, k in s.list do
            if held.n <= 0 then break end
            local p = t[k]
            local room = p and (pile(held.id) - p.n) or pile(held.id)
            local move = math.min(each, room, held.n)
            if move > 0 then
                if p then p.n += move else t[k] = { id = held.id, n = move, e = held.e } end
                held.n -= move
            end
        end
        if held.n <= 0 then G.held = nil end
        if t == grid then G.ghosts = nil end
        say({ wave = "square", freq = 560, ms = 25, volume = 0.03 })
    end
    on("toggle", function() open_at(0) end)
    on("station", function(n) open_at(n) end)
    on("click", function()
        local ref = under(mouse.x, mouse.y)
        if ref and shift() and quick(ref) then
            pressed, last_click = nil, nil
            return
        end
        -- Twice on the same slot, quickly: everything of that kind into the hand.
        if ref and last_click and last_click[1] == ref[1] and last_click[2] == ref[2] and G.ui_clock - last_click.t < 0.35 and G.held and (ref[1] == "inv" or ref[1] == "grid") then
            gather()
            pressed, last_click = nil, nil
            return
        end
        last_click = ref and { ref[1], ref[2], t = G.ui_clock } or nil
        -- With something in hand, on a slot that can take it: wait to see whether the mouse goes over others.
        if takes(ref) then
            spread = { kind = ref[1], list = { ref[2] }, seen = { [ref[2]] = true } }
            pressed = nil
            return
        end
        local empty = G.held == nil
        press(ref, false)
        pressed = ref and { ref[1], ref[2], picked = empty and G.held ~= nil } or nil
    end)
    -- The right button: half, or one; and dragged with it held, one in each slot it goes over.
    local rspread = nil
    on("rclick", function()
        local ref = under(mouse.x, mouse.y)
        press(ref, true)
        pressed = nil
        rspread = ref and (ref[1] == "inv" or ref[1] == "grid") and G.held and { kind = ref[1], seen = { [ref[2]] = true } } or nil
    end)
    local DROPS_ON = { inv = true, grid = true, gear = true, fin = true, ffuel = true, eitem = true, elapis = true }
    on("unclick", function()
        if spread then return share() end
        -- Pressed on one slot and let go on another: carried there and put down.
        local ref = under(mouse.x, mouse.y)
        if pressed and pressed.picked and G.held and ref and (ref[1] ~= pressed[1] or ref[2] ~= pressed[2]) and DROPS_ON[ref[1]] then
            press(ref, false)
        end
        pressed = nil
    end)
    -- While a button is held, the slots the mouse goes over.
    function G.drag_slots()
        if spread then
            if not mouse.left then return share() end
            local ref = under(mouse.x, mouse.y)
            if ref and ref[1] == spread.kind and not spread.seen[ref[2]] and takes(ref) and #spread.list < (G.held and G.held.n or 0) then
                spread.seen[ref[2]] = true
                table.insert(spread.list, ref[2])
            end
        end
        if rspread then
            if not mouse.right or not G.held then rspread = nil return end
            local ref = under(mouse.x, mouse.y)
            if ref and ref[1] == rspread.kind and not rspread.seen[ref[2]] and takes(ref) then
                rspread.seen[ref[2]] = true
                slot_press(ref[1] == "inv" and inv or grid, ref[2], true)
            end
        end
    end
    function G.spreading()
        local list = {}
        if spread then
            local wx, wy, mx = origin()
            for _, k in spread.list do
                if spread.kind == "inv" then
                    local x, y = inv_at(k - 1, mx, wy)
                    table.insert(list, { x = x, y = y })
                else
                    table.insert(list, { x = mx + 60 + ((k - 1) % 3) * S, y = wy + 60 + ((k - 1) // 3) * S })
                end
            end
        end
        return list
    end
    -- The keyboard, while the table is open: Esc or E shuts it; 1 to 9 swap
    -- the slot the mouse is on with that slot of the bar.
    on("key_down", function(name)
        if not G.open then return end
        if name == "Escape" or name == "e" then
            shut()
            say({ wave = "saw", freq = 260, to = 140, ms = 160, volume = 0.06 })
            return
        end
        local n = tonumber(name)
        if n and n >= 1 and n <= 9 then
            local ref = under(mouse.x, mouse.y)
            if ref and ref[1] == "inv" and ref[2] ~= 27 + n then
                inv[ref[2]], inv[27 + n] = inv[27 + n], inv[ref[2]]
                say({ wave = "square", freq = 600, ms = 20, volume = 0.03 })
            end
        end
    end)
    on("dig", fetch)
    on("reap", reap)
    -- The bar, outside: a press on a thing uses it. What is thrown waits for where.
    local function use_up(i)
        inv[28 + i].n -= 1
        if inv[28 + i].n <= 0 then inv[28 + i] = nil end
    end
    local function used(def, i)
        -- Answers whether it was spent.
        if def.use == "tame" then
            if #G.wolves >= 3 then note("Three wolves is as many as the camp can feed") return false end
            G.tame()
            note("A wolf joins the camp")
            if #G.wolves >= 3 then G.feat("pack") end
        elseif def.use == "feast" then
            local hungry = false
            for _, h in G.heroes do
                if not h.down and h.hp < h.max then hungry = true end
            end
            if not hungry then note("Nobody is hurt") return false end
            for _, h in G.heroes do
                if not h.down then
                    h.hp = math.min(h.max, h.hp + h.max / 3)
                    G.smoke(h.x, G.ground() - 50, 4, 5, 50)
                end
            end
        elseif def.use == "pick" then
            if G.mine.level >= def.level then note("The mine already has a pickaxe as good as that") return false end
            G.mine.level = def.level
            note("The mine digs with " .. (def.level == 3 and "diamond" or "iron") .. " now")
            if def.level == 3 then G.feat("pick") end
        elseif def.use == "golem" or def.use == "cleric" then
            if not G.recruit(def.use) then return false end
        elseif def.use == "xp" then
            G.points += 1
            note("A level of experience to spend")
            emit("levelup")
        else
            return false
        end
        say({ wave = "triangle", freq = 440, to = 660, ms = 120, volume = 0.07 })
        return true
    end
    on("use", function()
        local i = math.clamp(math.floor(((mouse.x or 24) - 24) / 40), 0, 8)
        local p = inv[28 + i]
        if not p then
            G.armed = nil
        else
            local def = GEAR[p.id]
            if not def or not def.use then
                note((NAMES[p.id] or "That") .. " is not used from here: open the table to hand it over")
            elseif def.use == "tnt" or def.use == "heal" or def.use == "web" then
                G.armed = G.armed ~= i and i or nil
            elseif used(def, i) then
                use_up(i)
            end
        end
        fact.armed, fact.aiming = G.armed or -1, G.armed ~= nil
    end)
    on("lob", function(x)
        local p = G.armed and inv[28 + G.armed]
        if p and GEAR[p.id] and GEAR[p.id].use then
            G.throw(GEAR[p.id].use, x)
            p.n -= 1
            if p.n <= 0 then inv[28 + G.armed], G.armed = nil, nil end
        else
            G.armed = nil
        end
        fact.armed, fact.aiming = G.armed or -1, G.armed ~= nil
    end)

    -- ── by itself: learn, open what waits, hand over what is better, make what
    --    somebody could use, keep the furnace fed, fetch what the camp grows
    --    and digs, and use what there is when it is needed ──
    local function made_alone(r)
        local e = nil
        for id, many in r.needs do
            for _ = 1, many do
                local one = take_one(id)
                if r.keeps and id == r.key[r.keeps] and one then e = one.e end
            end
        end
        G.gain(r.out, r.n, e)
        made_feats(r.out)
        note("Made: " .. NAMES[r.out])
        say({ wave = "triangle", freq = 660, to = 990, ms = 120, volume = 0.08 })
    end
    function G.alone()
        for _, c in G.chests do
            if not c.opened and c.y >= G.ground() then return G.crack(c) end
        end
        if G.mine.total >= G.MINE[G.mine.level].holds / 2 then return fetch() end
        if ripe() then return reap() end
        -- Its levels, to whoever is furthest behind.
        local who = nil
        for _, h in G.heroes do
            if not who or h.level < who.level then who = h end
        end
        if who and G.points >= G.level_cost(who) then return G.level_up(who) end
        if G.open then return end
        -- The furnace: what it made comes out, and it is given ore and coal.
        local f = G.furnace
        if f.out and f.out.n >= 8 or (f.out and not f.input) then
            G.gain(f.out.id, f.out.n)
            f.out = nil
            G.feat("smelt")
            return
        end
        for id in G.SMELT do
            if count(id) > 0 and (not f.input or (f.input.id == id and f.input.n < 64)) then
                local n = math.min(count(id), 64 - (f.input and f.input.n or 0))
                remove(id, n)
                f.input = f.input or { id = id, n = 0 }
                f.input.n += n
                return
            end
        end
        if f.input and not f.fuel and f.burn <= 0 and count("coal") > 0 then
            local n = math.min(count("coal"), 16)
            remove("coal", n)
            f.fuel = { id = "coal", n = n }
            return
        end
        for k = 1, 36 do
            local def = inv[k] and GEAR[inv[k].id]
            if def and def.slot then
                for _, h in G.heroes do
                    local now = h.gear[def.slot]
                    local better = not now or (def.slot < 5 and worth(def) > worth(GEAR[now.id]))
                    if fits(h, def) and better and not (def.slot == 1 and not def.who) then
                        local p = inv[k]
                        inv[k] = nil
                        back(now)
                        h.gear[def.slot] = p
                        G.refit()
                        fact["up.x"] = h.x
                        emit("levelup")
                        if h.gear[2] and h.gear[3] and h.gear[4] then G.feat("ironclad") end
                        return
                    end
                end
            elseif def and def.use and def.use ~= "tnt" and def.use ~= "heal" and def.use ~= "web" and def.use ~= "feast" then
                -- A collar, a pickaxe, a heart of iron, a bell: used as soon as there is one.
                local ok = (def.use ~= "tame" or #G.wolves < 3) and (def.use ~= "pick" or G.mine.level < def.level)
                    and ((def.use ~= "golem" and def.use ~= "cleric") or not G.recruited[def.use])
                if ok and used(def, k - 28) then
                    inv[k].n -= 1
                    if inv[k].n <= 0 then inv[k] = nil end
                    return
                end
            end
        end
        for _, r in RECIPES do
            if known(r) and enough(r) then
                local def, wanted = GEAR[r.out], false
                if r.out == "iron_block" then
                    wanted = count("crown") > 0 and not G.recruited.golem and count("iron_block") < 4
                elseif def.use == "pick" then
                    wanted = G.mine.level < def.level and count(r.out) == 0
                elseif def.use == "golem" or def.use == "cleric" then
                    wanted = not G.recruited[def.use] and count(r.out) == 0
                elseif def.use then
                    wanted = count(r.out) < (r.out == "bread" and 4 or 2) and (r.out ~= "collar" or #G.wolves < 3)
                elseif count(r.out) == 0 then
                    for _, h in G.heroes do
                        local now = h.gear[def.slot]
                        if fits(h, def) and (not now or (def.slot < 5 and worth(def) > worth(GEAR[now.id]))) then wanted = true end
                    end
                end
                if wanted then return made_alone(r) end
            end
        end
        -- What there is to use, when it is needed.
        local many, sum, lord = 0, 0, nil
        for _, f in G.horde do
            if f.hp > 0 and not f.edge and f.x < G.W - 40 then many, sum = many + 1, sum + f.x end
            if f.lord and f.hp > 0 then lord = f end
        end
        local hurt, low = 0, nil
        for _, h in G.heroes do
            if not h.down and h.hp > 0 then
                if h.hp < h.max * 0.6 then hurt += 1 end
                if h.hp < h.max * 0.45 then low = h end
            end
        end
        if low and spend("heal_potion") then return G.throw("heal", low.x) end
        if hurt >= 2 and count("bread") > 0 then
            for k = 28, 36 do
                if inv[k] and inv[k].id == "bread" and used(GEAR.bread, k - 28) then return use_up(k - 28) end
            end
        end
        if (many >= 5 or (lord and many >= 1 and not lord.wind)) and spend("tnt") then return G.throw("tnt", math.max(G.front_post() + 130, lord and lord.x or sum / many)) end
        if many >= 6 and spend("cobweb") then return G.throw("web", sum / many) end
    end

    -- ── what is seen of all that: told every frame, stopped or not ──
    local function cell(p) return p and ITEM[p.id] or -1 end
    -- What a thing is, when the mouse is on it: its name, in the colour of how
    -- rare it is, and under it what it does, what it is made into, and what
    -- the trader gives for it.
    local TROPHY = { crown = true, scarab = true, slime_core = true, frost_string = true, magma_heart = true, giant_eye = true, totem = true, golem_core = true, bell = true }
    local RARE = { diamond = true, ender_staff = true, frost_bow = true, ender_charm = true, pearl = true, xp_bottle = true }
    local function tone(p)
        if glint(p) then return 3 end
        if TROPHY[p.id] then return 1 end
        if p.id == "emerald" then return 4 end
        if RARE[p.id] or p.id:find("diamond") or p.id:find("netherite") then return 2 end
        return 0
    end
    local function sentence(s) return s:sub(1, 1):upper() .. s:sub(2) end
    local function about(p)
        local lines = {}
        if p.e then
            for _, key in G.ENCH_ORDER do
                if p.e[key] then table.insert(lines, ENCH[key].name .. " " .. G.ROMAN[p.e[key]]) end
            end
        end
        local def = GEAR[p.id]
        if def and def.says then table.insert(lines, sentence(def.says)) end
        if def and def.who then table.insert(lines, "Only the " .. def.who .. " can use it") end
        if G.SAYS[p.id] then table.insert(lines, sentence(G.SAYS[p.id])) end
        if G.SMELT[p.id] then table.insert(lines, "The furnace makes it into " .. NAMES[G.SMELT[p.id]]:lower()) end
        if G.FUEL[p.id] then table.insert(lines, "Fuel: one smelts " .. G.FUEL[p.id] .. (G.FUEL[p.id] > 1 and " things" or " thing")) end
        local into_ = {}
        for _, r in RECIPES do
            if r.needs[p.id] and known(r) then table.insert(into_, NAMES[r.out]) end
        end
        if #into_ > 0 then
            local more = #into_ > 3 and (" and " .. (#into_ - 3) .. " more") or ""
            while #into_ > 3 do table.remove(into_) end
            table.insert(lines, "Goes into: " .. table.concat(into_, ", ") .. more)
        end
        if p.id == "emerald" then table.insert(lines, "What the trader pays and asks for") end
        local o = G.buys(p.id)
        if o then table.insert(lines, "The trader gives " .. o.emeralds .. (o.emeralds > 1 and " emeralds" or " emerald") .. " for " .. o.n) end
        return table.concat(lines, "\n")
    end
    local function tell(title, body, t)
        text.tip, text.tip2 = title or "", body or ""
        fact["tip.tone"] = t or 0
    end
    local TAB_SAYS = {
        [0] = { "Crafting", "Lay things on the grid as their recipe says.\nThe book at the left lays one out for you" },
        [1] = { "Furnace", "Raw iron and raw gold become ingots.\nIt goes on by itself, also while you are away" },
        [2] = { "Enchanting", "A weapon or armour, lapis and levels:\nsomething more on what a hero carries" },
        [6] = { "Trading", "The villager buys what the waves leave\nand sells what the camp is short of" },
        [3] = { "The lands", "Where the party is, and where it can go" },
        [4] = { "Bestiary", "Everything met, and what it left" },
        [5] = { "Feats", "What there is to have done" },
    }
    local SLOT_NAMES = { "Weapon", "Helmet", "Chestplate", "Boots", "Charm" }
    function G.show_camp()
        G.drag_slots()
        local list = {}
        for k = 1, 36 do list[k] = inv[k] and { cell = ITEM[inv[k].id], n = inv[k].n, glint = glint(inv[k]) } or { cell = -1, n = 0, glint = false } end
        model.slots = list
        local m, f = G.mine, G.furnace
        fact["mine.n"], fact["mine.full"], fact["mine.pick"] = m.total, m.total >= G.MINE[m.level].holds, ITEM[G.PICKS[m.level]]
        model.plots = { { stage = math.floor(G.farm[1] * 3 + 0.001) }, { stage = math.floor(G.farm[2] * 3 + 0.001) } }
        fact["farm.ripe"] = ripe()
        fact["furnace.lit"] = smelting() ~= nil
        fact.points = G.points
        fact.emeralds = count("emerald")
        local mx_, my_ = mouse.x or -100, mouse.y or -100
        fact["hand.x"], fact["hand.y"] = mx_, my_
        fact["hand.cell"], fact["hand.n"], fact["hand.glint"] = cell(G.held), G.held and G.held.n or 0, glint(G.held)
        if not G.open then
            fact["over.on"], fact.tipped = false, false
            tell("", "")
            return
        end
        local wx, wy, w = G.table_box()
        fact["ui.x"], fact["ui.y"], fact["ui.w"] = wx, wy, w
        local _, _, mx, tx, bx = origin()
        fact["ui.mx"], fact["ui.tx"], fact["ui.bx"] = mx, tx, bx
        fact["ui.left"] = left_column()
        model.spread = G.spreading()
        local made = nil
        if G.tab == 0 then
            local cells = {}
            for k = 1, 9 do
                if grid[k] then cells[k] = { cell = ITEM[grid[k].id], n = grid[k].n, ghost = false }
                elseif G.ghosts and G.ghosts[k] then cells[k] = { cell = ITEM[G.ghosts[k]], n = 0, ghost = true }
                else cells[k] = { cell = -1, n = 0, ghost = false } end
            end
            model.grid = cells
            made = laid()
            fact["out.cell"], fact["out.n"] = made and ITEM[made.out] or -1, made and made.n or 0
        elseif G.tab == 1 then
            fact["fin.cell"], fact["fin.n"] = cell(f.input), f.input and f.input.n or 0
            fact["ffuel.cell"], fact["ffuel.n"] = cell(f.fuel), f.fuel and f.fuel.n or 0
            fact["fout.cell"], fact["fout.n"] = cell(f.out), f.out and f.out.n or 0
            fact["furnace.t"], fact["furnace.burn"] = math.clamp(f.t / G.SMELT_TIME, 0, 1), math.clamp(f.burn / 8, 0, 1)
        elseif G.tab == 2 then
            fact["eitem.cell"], fact["eitem.glint"] = cell(G.bench.item), glint(G.bench.item)
            fact["elapis.cell"], fact["elapis.n"] = cell(G.bench.lapis), G.bench.lapis and G.bench.lapis.n or 0
            local rows, lapis = {}, G.bench.lapis and G.bench.lapis.n or 0
            for k, o in offers() do
                rows[k] = { name = ENCH[o.key].name .. " " .. G.ROMAN[o.to], cost = o.cost, can = G.points >= o.cost and lapis >= o.cost }
            end
            model.offers = rows
            fact["eitem.done"] = G.bench.item ~= nil and #rows == 0
        elseif G.tab == 6 then
            local rows = {}
            for k, o in G.trades do
                rows[k] = { buy = o.buy, cell = ITEM[o.id], n = o.n, em = o.emeralds, left = o.left, uses = o.uses, can = G.can_trade(o) }
            end
            model.trades = rows
        end
        if G.tab <= 2 or G.tab == 6 then
            local pagelist, can = {}, 0
            for k, r in shown() do
                local ok = enough(r)
                if ok then can += 1 end
                if k <= 36 then pagelist[k] = { cell = ITEM[r.out], can = ok } end
            end
            model.book = pagelist
            fact.can = can
            local cards = {}
            for k, h in G.heroes do
                local g = h.gear
                cards[k] = { cell = h.row * 16, name = h.shown, rank = h.level, hp = math.clamp(h.hp / h.max, 0, 1), down = h.down ~= nil,
                             s0 = g[1] and ITEM[g[1].id] or (h.rest and ITEM[h.rest] or -1), own = g[1] and 1 or 0, s1 = cell(g[2]), s2 = cell(g[3]), s3 = cell(g[4]), s4 = cell(g[5]),
                             g0 = glint(g[1]) and 1 or 0, g1 = glint(g[2]) and 1 or 0, g2 = glint(g[3]) and 1 or 0, g3 = glint(g[4]) and 1 or 0,
                             cost = G.level_cost(h), can = G.points >= G.level_cost(h) }
            end
            model.cards = cards
        end
        -- The slot the mouse is on, lit, and what it holds, told.
        local ref = under(mouse.x, mouse.y)
        local lit = ref ~= nil and ref.x ~= nil
        fact["over.on"] = lit
        if lit then
            fact["over.x"], fact["over.y"], fact["over.w"], fact["over.h"] = ref.x, ref.y, ref.w or ref.s, ref.h or ref.s
        end
        local title, body, t = "", "", 0
        local function thing(p, empty_title, empty_body)
            if p then title, body, t = NAMES[p.id] or p.id, about(p), tone(p)
            else title, body = empty_title or "", empty_body or "" end
        end
        if ref then
            local kind, k = ref[1], ref[2]
            if kind == "inv" then thing(inv[k])
            elseif kind == "grid" then thing(grid[k])
            elseif kind == "made" then
                if made then
                    thing({ id = made.out, n = made.n })
                    body = (body ~= "" and body .. "\n" or "") .. "Shift: make as many as there is for"
                end
            elseif kind == "fin" then thing(f.input, "To smelt", "Raw iron or raw gold")
            elseif kind == "ffuel" then thing(f.fuel, "Fuel", "Coal smelts eight things, a stick one")
            elseif kind == "fout" then thing(f.out)
            elseif kind == "eitem" then thing(G.bench.item, "To enchant", "A weapon or a piece of armour")
            elseif kind == "elapis" then thing(G.bench.lapis, "Lapis lazuli", "One for each level an enchantment takes")
            elseif kind == "gear" then
                local h, j = G.heroes[(k - 1) // 5 + 1], (k - 1) % 5 + 1
                if h.gear[j] then thing(h.gear[j])
                elseif j == 1 and h.rest then title, body = NAMES[h.rest] or h.rest, "What the " .. h.shown:lower() .. " has when nothing better is given"
                else title, body = SLOT_NAMES[j], "Drag one here, or Shift and a press on it below" end
            elseif kind == "recipe" then
                local r = shown()[k]
                if r then
                    local need = {}
                    for id, many in r.needs do table.insert(need, many .. " " .. NAMES[id]:lower()) end
                    title, t = NAMES[r.out], tone({ id = r.out })
                    body = "Takes " .. table.concat(need, ", ") .. (enough(r) and "" or "\nSomething is short")
                    local def = GEAR[r.out]
                    if def and def.says then body ..= "\n" .. sentence(def.says) end
                end
            elseif kind == "offer" then
                local o = offers()[k]
                if o then title, body, t = ENCH[o.key].name .. " " .. G.ROMAN[o.to], sentence(ENCH[o.key].says) .. "\n" .. o.cost .. (o.cost > 1 and " levels and " or " level and ") .. o.cost .. " lapis", 3 end
            elseif kind == "level" then
                local h = G.heroes[k]
                title = h.shown .. " to level " .. (h.level + 1)
                body = "Takes " .. G.level_cost(h) .. (G.level_cost(h) > 1 and " levels" or " level") .. " of experience\nMore life, and harder blows"
            elseif kind == "trade" then
                title, body = G.trade_tip(k)
                t = 4
            elseif kind == "tab" then
                local says = TAB_SAYS[k]
                if says then title, body = says[1], says[2] end
            elseif kind == "sort" then title, body = "Sort", "Piles of a kind together, in order.\nThe bar stays as it is"
            elseif kind == "auto" then title, body = "By itself", "The camp crafts, hands things over and\nspends its levels without being told"
            elseif kind == "pages" then title, body = "The book", "Every recipe whose things have been found"
            elseif kind == "land" then title = G.land_tip(k)
            elseif kind == "world" then title = G.world_tip()
            end
        end
        tell(title, body, t)
        fact.tipped = title ~= ""
    end
    G.under, G.FULL = under, FULL
end
