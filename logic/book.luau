-- The camp's book: what has been met and what it left, the feats, the map of
-- the lands and the way to a new world, and what the camp did while nobody
-- was looking.
return function(G)
    local ITEM, KIND, LANDS = G.ITEM, G.KIND, G.LANDS
    local note, say = G.note, G.say

    -- ── the feats ──
    function G.feat(id)
        if G.feats[id] then return end
        G.feats[id] = true
        for _, f in G.FEATS do
            if f.id == id then
                text.feat = f.name
                fact["feat.cell"] = ITEM[f.icon]
                emit("feat")
                log("feat:", f.name)
            end
        end
        say({ wave = "triangle", freq = 523, to = 1046, ms = 380, volume = 0.09 })
        G.save_soon()
    end

    -- ── what has been met ──
    function G.dropped(beast, id)
        local seen = G.seen[beast] or {}
        seen[id] = true
        G.seen[beast] = seen
    end
    function G.killed(f)
        G.kills[f.beast] = (G.kills[f.beast] or 0) + 1
        G.stats.felled += 1
        G.feat("blood")
        if G.stats.felled >= 1000 then G.feat("slayer") end
        if f.k.boss then
            G.lords[f.k.boss + 1] = (G.lords[f.k.boss + 1] or 0) + 1
            G.feat("lord" .. f.k.boss)
            G.save_soon()
        end
        if not G.feats.scholar then
            for _, id in G.BEASTS do
                if not G.kills[id] then return end
            end
            G.feat("scholar")
        end
    end
    local BEAST = {}
    for k, id in G.BEASTS do BEAST[k] = G.beast(id) end

    -- ── the map ──
    function G.land_tip(k)
        local land = LANDS[k + 1]
        if k > G.reached then return KIND[LANDS[k].lord].name .. " bars the way" end
        if k == G.land then return land.name .. ": the party is here" end
        return "Go to " .. land.name
    end
    function G.world_tip()
        return G.count("giant_eye") > 0 and "A new world: harder, and a star that stays" or "It takes an Eye of the Giant, from the lord of the End"
    end
    -- Through to a new world: the lands and the party's levels start over;
    -- what it carries, knows and has met stays, and it is a star stronger.
    local sure_until = -1
    function G.new_world()
        if G.count("giant_eye") == 0 then return note("The way to a new world takes an Eye of the Giant: the lord of the End leaves one") end
        if G.clock > sure_until then
            sure_until = G.clock + 6
            return note("Press again to step through: the lands and the party's levels start over")
        end
        sure_until = -1
        G.remove("giant_eye", 1)
        G.world += 1
        G.land, G.step, G.reached, G.stay = 0, 0, 0, false
        G.xp, G.points, G.earned = 0, 0, 0
        for _, h in G.heroes do h.level, h.down, h.ail = 1, nil, nil end
        G.refit()
        for _, h in G.heroes do h.hp = h.max end
        G.shut()
        G.restart()
        G.feat("world")
        note("World " .. G.world .. ": everything in it is stronger, and so is the party, by a star")
        log("a new world:", G.world)
        G.save_soon()
    end

    -- ── what is seen of it, a few times a second, while its page is open ──
    local tell_in = 0
    function G.show_book(dt)
        fact.world, fact.stay = G.world, G.stay
        if not G.open or G.tab < 3 or G.tab > 5 then return end
        tell_in -= dt
        if tell_in > 0 then return end
        tell_in = 0.2
        if G.tab == 3 then
            local list = {}
            for k, land in LANDS do
                local t = land.things
                list[k] = { name = land.name, lord = KIND[land.lord].name, boss = KIND[land.lord].boss, open = k - 1 <= G.reached, here = k - 1 == G.land,
                            felled = G.lords[k] or 0, m0 = ITEM[t[1]], m1 = t[2] and ITEM[t[2]] or -1, m2 = t[3] and ITEM[t[3]] or -1 }
            end
            model.lands = list
            fact["world.can"] = G.count("giant_eye") > 0
        elseif G.tab == 4 then
            local list, met = {}, 0
            for k, id in G.BEASTS do
                local b, kills, seen = BEAST[k], G.kills[id] or 0, G.seen[id] or {}
                if kills > 0 then met += 1 end
                local d = {}
                for j = 1, 4 do
                    -- A thing it left, a thing it has yet to leave (-2), or nothing more (-1).
                    d[j] = b.drops[j] and (seen[b.drops[j]] and ITEM[b.drops[j]] or -2) or -1
                end
                list[k] = { name = kills > 0 and b.name or "???", sheet = b.sheet, cell = b.cell, wash = b.wash, lord = b.lord, kills = kills, known = kills > 0,
                            d0 = d[1], d1 = d[2], d2 = d[3], d3 = d[4] }
            end
            model.beasts = list
            text.count = met .. " of " .. #G.BEASTS .. " met  -  " .. G.stats.felled .. " felled"
        elseif G.tab == 5 then
            local list, done = {}, 0
            for k, f in G.FEATS do
                if G.feats[f.id] then done += 1 end
                list[k] = { cell = ITEM[f.icon], name = f.name, says = f.says, done = G.feats[f.id] == true }
            end
            model.feats = list
            text.count = done .. " of " .. #G.FEATS
        end
    end

    -- ── while nobody was looking ──
    local function span(seconds)
        local m = math.floor(seconds / 60)
        if m >= 60 then return (m // 60) .. " h " .. (m % 60) .. " min" end
        return m .. " min"
    end
    -- The mine dug, the furnace burnt, the wheat grew, and the party held the
    -- first wave of its land now and then, for a quarter of what that leaves.
    function G.away(seconds)
        seconds = math.min(seconds, 8 * 3600)
        if seconds < 60 then return end
        local got = {}
        G.dig_for(seconds)
        local smelted = G.smelt_for(seconds)
        G.grow(seconds)
        local land = LANDS[G.land + 1]
        local waves = math.min(120, math.floor(seconds / 240))
        local base = G.land * 5 + 1
        local many = math.min(5 + base * 2, 60) * waves
        local total = land.who[1][2] + land.who[2][2]
        local xp = 0
        for k = 1, 2 do
            local v = G.VARIANT[land.who[k][1]]
            local kind = KIND[v and v.kind or land.who[k][1]]
            local n = many * land.who[k][2] / total * 0.25
            xp += n * kind.xp
            for _, list in { kind.drops, v and v.drops or {} } do
                for _, d in list do
                    local m = math.floor(n * d[2] + math.random())
                    if m > 0 then got[d[1]] = (got[d[1]] or 0) + m end
                end
            end
        end
        local list = {}
        for id, n in got do
            G.gain(id, n)
            table.insert(list, { cell = ITEM[id], n = n })
        end
        table.sort(list, function(a, b) return a.n > b.n end)
        while #list > 9 do table.remove(list) end
        if G.mine.total > 0 then table.insert(list, { cell = ITEM[G.PICKS[G.mine.level]], n = G.mine.total }) end
        if smelted > 0 then table.insert(list, { cell = ITEM.tab_furnace, n = smelted }) end
        G.xp += xp * (1 + 0.25 * (G.world - 1))
        local levels = 0
        while G.xp >= G.need() do
            G.xp -= G.need()
            G.earned += 1
            G.points += 1
            levels += 1
        end
        -- A chest every dozen waves waits on the field.
        for _ = 1, math.min(12 - #G.chests, waves // 12) do
            table.insert(G.chests, { x = G.chest_x(), y = G.ground(), vy = 0, kind = math.random() < 0.2 and 1 or 0, t = 9 })
        end
        model.gains = list
        text.gone = "While you were away  -  " .. span(seconds)
        text.gone2 = (waves > 0 and (waves .. (waves > 1 and " waves" or " wave") .. " held in " .. land.name) or "The camp kept working")
            .. (levels > 0 and ("  -  " .. levels .. (levels > 1 and " levels" or " level") .. " gained") or "")
        fact["gone.on"] = true
        G.gone_in = 40
        log("away for", span(seconds), "-", waves, "waves,", levels, "levels")
    end
    on("dismiss", function()
        fact["gone.on"] = false
        G.gone_in = 0
    end)
end
