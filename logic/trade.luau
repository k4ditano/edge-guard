-- The trader: a villager who keeps a stall at the camp. He buys what the
-- waves leave —so many of a thing for an emerald— and sells, for emeralds,
-- what the camp cannot make or is short of. What he offers changes with the
-- land, and each offer can be taken so many times before he is out of it:
-- he has it again when the next wave starts.
return function(G)
    local NAMES, note, say = G.NAMES, G.note, G.say

    -- What he buys: `n` of a thing for `get` emeralds (one if not said).
    local BUYS = {
        { id = "flesh", n = 16 }, { id = "bone", n = 12 }, { id = "string", n = 12 }, { id = "gunpowder", n = 8 },
        { id = "slimeball", n = 8 }, { id = "redstone", n = 10 }, { id = "coal", n = 16 }, { id = "wheat", n = 18 },
        { id = "raw_gold", n = 5 }, { id = "ice", n = 6 }, { id = "blaze_rod", n = 3 }, { id = "pearl", n = 3 },
        { id = "iron", n = 6 }, { id = "gold", n = 4 }, { id = "diamond", n = 1, get = 3 }, { id = "scrap", n = 1, get = 4 },
    }
    -- What he sells: `n` of a thing for `cost` emeralds.
    local SELLS = {
        { id = "bread", n = 3, cost = 1 }, { id = "heal_potion", n = 2, cost = 2 }, { id = "tnt", n = 2, cost = 3 },
        { id = "cobweb", n = 3, cost = 2 }, { id = "lapis", n = 6, cost = 2 }, { id = "coal", n = 16, cost = 1 },
        { id = "raw_iron", n = 8, cost = 2 }, { id = "pearl", n = 1, cost = 3 }, { id = "diamond", n = 1, cost = 8 },
        { id = "collar", n = 1, cost = 4 }, { id = "xp_bottle", n = 1, cost = 5 }, { id = "string", n = 8, cost = 1 },
    }
    -- What each land's stall leans to: the things found there are what he
    -- wants most, and he keeps something for what comes next.
    local WANTS = {
        { "flesh", "bone", "string", "wheat" },
        { "gunpowder", "raw_gold", "bone", "string" },
        { "slimeball", "redstone", "flesh", "coal" },
        { "ice", "bone", "string", "coal" },
        { "blaze_rod", "raw_gold", "gold", "coal" },
        { "pearl", "diamond", "scrap", "gold" },
    }
    local BUY_USES, SELL_USES = 8, 4
    G.trades = {}

    local function by_id(list, id)
        for _, o in list do
            if o.id == id then return o end
        end
        return nil
    end
    -- The offers of the land the party is in: four he buys, three he sells.
    -- Always the same for the same land and world, so they do not jump about.
    function G.stock()
        table.clear(G.trades)
        local seed = (G.world * 7 + G.land * 13) % 2147483647 + 1
        local function rnd()
            seed = seed * 16807 % 2147483647
            return (seed - 1) / 2147483646
        end
        for _, id in WANTS[G.land + 1] do
            local o = by_id(BUYS, id)
            table.insert(G.trades, { buy = true, id = id, n = o.n, emeralds = o.get or 1, left = BUY_USES, uses = BUY_USES })
        end
        local pool = table.clone(SELLS)
        for k = #pool, 2, -1 do
            local j = 1 + math.floor(rnd() * k)
            pool[k], pool[j] = pool[j], pool[k]
        end
        -- Two of the three are what a fight needs; the third, whatever came up.
        local picked = { by_id(SELLS, "heal_potion"), by_id(SELLS, "tnt") }
        for _, o in pool do
            if #picked < 3 and o.id ~= "heal_potion" and o.id ~= "tnt" then table.insert(picked, o) end
        end
        for _, o in picked do
            table.insert(G.trades, { buy = false, id = o.id, n = o.n, emeralds = o.cost, left = SELL_USES, uses = SELL_USES })
        end
        G.stocked = G.world * 10 + G.land
    end
    -- A new wave: he has everything again.
    function G.restock()
        for _, o in G.trades do o.left = o.uses end
    end

    -- Whether an offer can be taken now.
    function G.can_trade(o)
        if not o or o.left <= 0 then return false end
        if o.buy then return G.count(o.id) >= o.n end
        return G.count("emerald") >= o.emeralds
    end
    -- One trade; with `all`, as many as can be done.
    function G.trade(k, all)
        local o = G.trades[k]
        if not o then return end
        if o.left <= 0 then return note("He is out of that until the next wave") end
        if not G.can_trade(o) then
            if o.buy then return note("He wants " .. o.n .. " " .. NAMES[o.id]:lower() .. ": there are " .. G.count(o.id)) end
            return note("That costs " .. o.emeralds .. (o.emeralds > 1 and " emeralds" or " emerald") .. ": there are " .. G.count("emerald"))
        end
        local done = 0
        repeat
            if o.buy then
                G.remove(o.id, o.n)
                G.gain("emerald", o.emeralds)
            else
                G.remove("emerald", o.emeralds)
                G.gain(o.id, o.n)
            end
            o.left -= 1
            done += 1
        until not all or not G.can_trade(o)
        G.stats.trades = (G.stats.trades or 0) + done
        if G.stats.trades >= 25 then G.feat("trader") end
        say({ wave = "triangle", freq = 740, to = 1110, ms = 110, volume = 0.08 })
        G.save_soon()
    end
    function G.trade_tip(k)
        local o = G.trades[k]
        if not o then return "", "" end
        local title = o.buy and ("Sell " .. o.n .. " " .. NAMES[o.id]) or ("Buy " .. o.n .. " " .. NAMES[o.id])
        local body = "for " .. o.emeralds .. (o.emeralds > 1 and " emeralds" or " emerald")
        if o.left <= 0 then
            body ..= "\nOut of it until the next wave"
        else
            body ..= "\n" .. o.left .. " more " .. (o.left > 1 and "times" or "time") .. " this wave"
        end
        if not o.buy and G.GEAR[o.id] then body ..= "\n" .. G.GEAR[o.id].says end
        return title, body .. "\nShift: as many as can be done"
    end
    -- What he gives for a thing, if he buys it here: for the descriptions.
    function G.buys(id)
        for _, o in G.trades do
            if o.buy and o.id == id then return o end
        end
        return nil
    end

    -- What is kept of him: how many of each offer are left.
    function G.trades_saved()
        local list = {}
        for k, o in G.trades do list[k] = o.left end
        return list
    end
    function G.trades_back(list)
        if type(list) ~= "table" then return end
        for k, o in G.trades do
            local n = tonumber(list[k])
            if n then o.left = math.clamp(math.floor(n), 0, o.uses) end
        end
    end
end
