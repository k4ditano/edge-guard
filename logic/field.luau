-- The field: the waves and who comes in them, the party, the lords and what
-- they announce, what flies, what is thrown and what is left behind.
return function(G)
    local ITEM, KIND, LANDS = G.ITEM, G.KIND, G.LANDS
    local note, say, pan, ground = G.note, G.say, G.pan, G.ground
    local heroes, wolves, horde, shots, bombs, drops, puffs, chests, marks, webs, queue =
        G.heroes, G.wolves, G.horde, G.shots, G.bombs, G.drops, G.puffs, G.chests, G.marks, G.webs, G.queue
    local SMITE_EVERY = 20
    local units = {}                 -- everyone the horde can go for, this frame
    G.units = units

    -- Which wave this is, counted from the first land's first: what everything's strength goes by.
    local function wave() return G.land * 5 + G.step + 1 end
    G.wave = wave
    -- A world further on, everything takes three times as much and hits harder.
    local function tough() return 3 ^ (G.world - 1) end
    local function fierce() return 1.6 ^ (G.world - 1) end

    local function front_post()
        local best = heroes[1].post
        for _, h in heroes do best = math.max(best, h.post) end
        return best
    end
    G.front_post = front_post
    function G.tame()
        table.insert(wolves, { wolf = true, x = 120, post = front_post() + 60 + #wolves * 40, hp = 45, max = 45, hurt = 0, t = 0, face = 1, wait = 0 })
    end
    -- A golem or a cleric joins: for good.
    function G.recruit(name)
        if G.recruited[name] then
            note("The " .. name .. " is already with the party")
            return false
        end
        local h = G.enlist(name)
        h.x = 120
        G.refit()
        h.hp = h.max
        G.feat(name)
        note(name == "golem" and "An iron golem stands with the party" or "A cleric comes to heal the party")
        return true
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
    -- ── what shakes the screen and bends what is behind the game ──
    -- A ring through the desktop from where something went off: how far it
    -- reaches, how hard it pushes (negative pulls in), how much its rim shines.
    G.waves, G.shake, G.bolt, G.bolt_t = {}, 0, {}, 0
    local function ring(x, y, size, push, glow, last)
        if #G.waves >= 8 then table.remove(G.waves, 1) end
        table.insert(G.waves, { x = x, y = y, size = size, push = push, glow = glow or 0.4, age = 0, rate = 1 / (last or 0.75) })
    end
    local function quake(amount) G.shake = math.max(G.shake, amount) end
    G.ring, G.quake = ring, quake
    local function burst(x, y, big)
        fact["at.x"], fact["at.y"] = x, y
        emit("boom")
        ring(x, y, big and 300 or 190, big and 22 or 12, 0.5)
        quake(big and 11 or 4)
        if big then emit("debris") end
        smoke(x, y, big and 16 or 9, 1, big and 160 or 90)
        say({ wave = "noise", freq = big and 300 or 420, to = 50, ms = big and 520 or 320, volume = big and 0.16 or 0.1, release = big and 420 or 240, pan = pan(x) })
    end
    G.smoke, G.puff, G.burst = smoke, puff, burst

    -- ── what is left behind ──
    -- (Answers whether there was room on the field for it.)
    local function leave(name, x, y, up, n)
        if #drops >= 64 then return false end
        table.insert(drops, { what = "item", name = name, n = n or 1, cell = ITEM[name], x = x, y = y, vx = (math.random() - 0.5) * 160, vy = -(up or 240) - math.random() * 140, t = 0, size = 0.7 })
        return true
    end
    G.leave = leave
    local function orbs(x, y, worth)
        local many = math.clamp(math.floor(worth / 2 + 0.5), 1, 6)
        for _ = 1, many do
            if #drops >= 64 then
                G.xp += worth / many
            else
                table.insert(drops, { what = "orb", worth = worth / many, cell = ITEM.orb, x = x, y = y, vx = (math.random() - 0.5) * 220, vy = -180 - math.random() * 160, t = 0, size = 0.4 + math.random() * 0.15 })
            end
        end
    end

    -- ── harm ──
    -- `by`: the hero whose blow it is; `how`: "tnt" or "bolt", which stop a lord that is about to do something.
    local function hurt(f, amount, push, slows, by, how)
        if f.hp <= 0 then return end
        if (f.stun or 0) > 0 then amount *= 1.5 end
        f.hp -= amount
        f.hurt = 1
        if by then
            f.by = by
            if by.fire and by.fire > 0 then f.burn, f.burn_dps = 3, math.max(f.burn_dps or 0, amount * by.fire / 3) end
        end
        if slows then f.slow = 2.5 end
        if not f.edge and not f.lord then f.kick = (f.kick or 0) + (push or 0) end
        if f.wind and (how == "tnt" or how == "bolt") then G.interrupt(f) end
        say({ wave = "noise", freq = 900, to = 300, ms = 45, volume = 0.03, pan = pan(f.x) }, 0.09)
        if f.hp <= 0 then
            f.dying = 0
            say({ wave = "square", freq = 240, to = 90, ms = 90, volume = 0.035, pan = pan(f.x) }, 0.15)
        end
    end
    local function harm(u, amount, ail, from, freeze)
        if u.down or u.hp <= 0 then return end
        -- An ender charm: now and then the blow finds nobody there.
        local dodge = u.gear and G.charm(u, "dodge")
        if dodge and math.random() < dodge then
            smoke(u.x, ground() - 50, 5, 2, 50)
            return
        end
        amount *= 1 - (u.prot or 0)
        u.hp -= amount
        u.hurt = 1
        if (u.thorns or 0) > 0 and from and from.hp > 0 then hurt(from, amount * u.thorns * 4, 0) end
        -- What that land's blow leaves: slowed, frozen for a moment, or burning.
        if ail and not u.wolf then u.ail, u.ail_in = ail, freeze or (ail == 2 and 0.9 or 3) end
        say({ wave = "noise", freq = 500, to = 200, ms = 60, volume = 0.04, pan = pan(u.x) }, 0.12)
    end
    local function alive(u) return not u.down and u.hp > 0 end
    G.hurt, G.harm, G.orbs = hurt, harm, orbs

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
    -- A name of a land's list: a kind, or a variant of one.
    local function one_of(id)
        local v = G.VARIANT[id]
        return { kind = v and v.kind or id, as = v }
    end
    local function muster()
        local land = LANDS[G.land + 1]
        table.clear(queue)
        if G.step == 4 then
            table.insert(queue, { kind = land.lord })
            G.omen = { t = 0, boss = KIND[land.lord].boss }
        end
        local many = math.min(5 + wave() * 2, 60)
        -- The rarer ones of a land come as it goes on.
        local total, open_to = 0, math.min(#land.who, 2 + G.step)
        for k = 1, open_to do total += land.who[k][2] end
        for _ = 1, many do
            local r, pick = math.random() * total, land.who[1]
            for k = 1, open_to do
                r -= land.who[k][2]
                if r <= 0 then pick = land.who[k] break end
            end
            local one = one_of(pick[1])
            -- From the second world on, now and then one of them is a champion.
            if G.world > 1 and math.random() < 0.04 + 0.02 * math.min(G.world, 5) then one.elite = true end
            table.insert(queue, one)
        end
        G.spawn_in, G.stage = 0.4, "fight"
        for _, h in heroes do h.saved = nil end
        text.said = if G.step == 0 then land.name .. (G.world > 1 and "  -  World " .. G.world or "") elseif G.step == 4 then KIND[land.lord].name else "Wave " .. (G.step + 1) .. " of 5"
        text.where = land.short .. " " .. (G.step + 1) .. "/5"
        fact.land = G.land
        emit("newwave")
        -- The trader: what he has for this land, and all of it again.
        if G.stocked ~= G.world * 10 + G.land then G.stock() else G.restock() end
        G.sky_muster()
        say({ wave = "saw", freq = 196, to = 294, ms = 240, volume = 0.1 })
    end

    local function arrive(spec, x, small)
        local k = KIND[spec.kind]
        local as = spec.as or {}
        local w = wave()
        local life = k.hp * 1.12 ^ (w - 1) * tough() * (small and 0.4 or 1) * (as.hp or 1) * (spec.elite and 4 or 1)
        local f = { kind = spec.kind, beast = as.id or spec.kind, k = k, as = as, elite = spec.elite, hp = life, max = life,
                    dmg = k.dmg * (1 + (w - 1) * 0.06) * fierce() * (small and 0.5 or 1) * (spec.elite and 1.5 or 1), x = x or G.W + 70, y = ground(), turn = 0,
                    t = math.random(), wait = 0, hurt = 0, lit = 0, slow = 0, stun = 0, reach = k.reach + math.random() * 26, speed = k.speed * (0.9 + math.random() * 0.2) * (as.speed or 1),
                    size = (small and 0.6 or (as.size or k.size or 1)) * (spec.elite and 1.25 or 1), small = small, blink_in = 1.5 + math.random() * 2,
                    wash = spec.elite and 7 or (as.wash or 0), ail = as.ail or k.ail }
        if k.boss then
            -- A lord hits harder, and has something of its own to do every so often.
            f.lord, f.dmg, f.reach, f.sp_in = k.name, f.dmg * 2, k.reach, 6 + math.random() * 2
        end
        if k.climbs and not x then
            -- By the ceiling, then down the wall: it comes in from above. Or
            -- down a thread of its own, from somewhere along the ceiling.
            f.edge, f.x, f.y, f.turn = "ceiling", G.W * (0.5 + math.random() * 0.25), 0, 180
            if math.random() < 0.6 then f.drop_at = f.x + math.random() * (G.W - 80 - f.x) end
        elseif k.hops and not k.boss and not small and not x and math.random() < 0.5 then
            -- A slime out of the sky: it falls from the top of the screen and lands with a thump.
            local from = math.min(front_post() + 260, G.W * 0.7)
            f.edge, f.x, f.y, f.vy = "fall", from + math.random() * (G.W - 120 - from), -140, 0
        end
        table.insert(horde, f)
        return f
    end

    local function smite()
        if G.smite_in > 0 then return end
        -- At the lord that is about to do something, if there is one; if not, at whoever is nearest the camp.
        local target = nil
        for _, f in horde do
            if f.hp > 0 and f.wind then target = f end
        end
        -- If not, at the dragon, if it is up; and then at whoever is nearest the camp.
        if not target then target = G.sky_bolt() end
        if not target then
            for _, f in horde do
                if f.hp > 0 and (not target or f.x < target.x) then target = f end
            end
        end
        if not target then return end
        G.smite_in = SMITE_EVERY
        fact["bolt.x"] = target.x
        emit("smote")
        -- A bolt from the top of the screen, crooked all the way down, and the desktop rippling where it lands.
        table.clear(G.bolt)
        local x, y, g = target.x + (math.random() - 0.5) * 160, 0, ground()
        local bottom = target.air and target.y or g - 40
        local steps = 16
        for k = 1, steps do
            local ny = bottom * k / steps
            local nx = k == steps and target.x or x + (math.random() - 0.5) * 70 + (target.x - x) * 0.25
            table.insert(G.bolt, { x = x, y = y, x2 = nx, y2 = ny, w = 7 - k * 0.25 })
            if k == 6 or k == 11 then
                -- (A branch.)
                local bx, by = nx + (math.random() - 0.5) * 140, ny + 60 + math.random() * 60
                table.insert(G.bolt, { x = nx, y = ny, x2 = bx, y2 = by, w = 2.5 })
            end
            x, y = nx, ny
        end
        G.bolt_t = 0.32
        ring(target.x, target.air and target.y or g - 30, 240, 16, 0.9, 0.6)
        quake(8)
        smoke(target.x, target.y - 40, 10, 1, 100)
        say({ wave = "noise", freq = 2400, to = 90, ms = 480, volume = 0.14, release = 380, pan = pan(target.x) })
        if target.air then
            hurt(target, (40 + wave() * 10) * tough() * 2, 0, nil, nil, "bolt")
            return
        end
        for _, f in horde do
            if math.abs(f.x - target.x) < 130 then hurt(f, (40 + wave() * 10) * tough(), 200, nil, nil, "bolt") end
        end
    end
    G.smite = smite
    on("bolt", smite)

    -- ── the chests the waves leave ──
    -- 0 wood · 1 iron · 2 gold · 3 of the End: rarer, and with more and better in it.
    local function crack(c)
        if c.opened or c.y < ground() then return end
        c.opened, c.t, c.next = true, 0, 0.25
        c.left = ({ [0] = 4, 6, 8, 11 })[c.kind] + math.random(0, 1)
        if c.kind == 3 then G.feat("lucky") end
        say({ wave = "saw", freq = 140, to = 260, ms = 220, volume = 0.07, pan = pan(c.x) })
    end
    G.crack = crack
    -- Where a chest comes down: out on the field, beyond whoever stands furthest out.
    function G.chest_x()
        local from = math.min(front_post() + 110, G.W * 0.8)
        return from + math.random() * (G.W * 0.92 - from)
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
        table.insert(chests, { x = G.chest_x(), y = -90, vy = 0, kind = kind, t = 0 })
        if kind >= 2 then note(kind == 3 and "A chest of the End has fallen!" or "A golden chest has fallen!") end
    end
    -- What each kind of chest holds: a thing, and up to where of a throw of the dice it is that.
    local HOLDS = {
        [0] = { { "diamond", 0.03 }, { "iron", 0.25 }, { "coal", 0.4 }, { "string", 0.5 }, { "bone", 0.6 }, { "gunpowder", 0.7 }, { "flesh", 0.78 }, { "wheat", 0.86 } },
        { { "diamond", 0.07 }, { "iron", 0.5 }, { "raw_gold", 0.6 }, { "lapis", 0.72 }, { "string", 0.8 }, { "gunpowder", 0.88 } },
        { { "diamond", 0.26 }, { "gold", 0.5 }, { "iron", 0.66 }, { "lapis", 0.8 }, { "gunpowder", 0.88 }, { "slimeball", 0.94 } },
        { { "diamond", 0.4 }, { "pearl", 0.66 }, { "scrap", 0.76 }, { "gold", 0.88 }, { "lapis", 1 } },
    }
    local function spill(c)
        local r, name = math.random(), "stick"
        for _, one in HOLDS[c.kind] do
            if r < one[2] then name = one[1] break end
        end
        leave(name, c.x, ground() - 40, 400)
        -- And now and then an emerald, more often the rarer the chest.
        if math.random() < ({ [0] = 0.12, 0.25, 0.4, 0.6 })[c.kind] then leave("emerald", c.x, ground() - 40, 420) end
    end

    -- What is thrown from the camp: TNT, which waits a moment where it lands; a
    -- potion or a web, which do what they do as they land.
    local function throw(what, to)
        table.insert(bombs, { what = what, x = 96, y = ground() - 90, from_x = 96, from_y = ground() - 90, tx = math.clamp(to, 230, G.W - 30), along = 0, fuse = nil, turn = 0 })
        say({ wave = "triangle", freq = 180, to = 120, ms = 90, volume = 0.05 })
    end
    G.throw = throw

    -- ── the lords: what each announces, how it is stopped, and what it does if it is not ──
    local function mark(f, x, w, kind) table.insert(marks, { x = x, w = w, kind = kind, of = f }) end
    local function unmark(f)
        for i = #marks, 1, -1 do
            if marks[i].of == f then table.remove(marks, i) end
        end
    end
    local function webbed(x)
        for _, w in webs do
            if math.abs(w.x - x) < 170 then return true end
        end
        return false
    end
    -- The middle of the living party, and its rear.
    local function party()
        local sum, n, rear = 0, 0, nil
        for _, h in heroes do
            if alive(h) then sum, n, rear = sum + h.x, n + 1, math.min(rear or h.x, h.x) end
        end
        return n > 0 and sum / n or 700, rear or 700
    end
    local function begin(f)
        local what = f.k.special
        f.wind, f.wind_time = 0, G.SPECIAL[what].time
        text.warn = f.lord .. " " .. G.SPECIAL[what].says
        local middle, rear = party()
        if what == "slam" then mark(f, f.x - 150, 440, 0)
        elseif what == "leap" then mark(f, middle, 300, 1)
        elseif what == "erupt" then
            for _, h in heroes do
                if alive(h) then mark(f, h.x, 120, 2) end
            end
        elseif what == "blink" then mark(f, rear + 30, 340, 3) end
        say({ wave = "saw", freq = 110, to = 220, ms = 700, volume = 0.1, attack = 200, pan = pan(f.x) })
        -- By itself, the camp answers with what it has.
        if G.auto then
            if (what == "leap" or what == "blink") and G.spend("cobweb") then throw("web", marks[#marks].x)
            elseif what ~= "erupt" and G.spend("tnt") then throw("tnt", f.x) end
        end
    end
    function G.interrupt(f)
        if not f.wind then return end
        f.wind, f.lit = nil, 0
        unmark(f)
        f.stun, f.sp_in = 3.5, 9 + math.random() * 3
        smoke(f.x, f.y - 120, 12, 1, 120)
        note(f.lord .. " is stopped, and dazed!")
        G.stats.catches += 1
        G.feat("catch")
        say({ wave = "square", freq = 880, to = 220, ms = 260, volume = 0.1, pan = pan(f.x) })
    end
    local function caught(f)
        f.stun = 4
        f.hp = math.max(1, f.hp - f.max * 0.12)
        f.hurt = 1
        note(f.lord .. " is caught in the web!")
        G.stats.catches += 1
        G.feat("catch")
        say({ wave = "square", freq = 880, to = 220, ms = 260, volume = 0.1, pan = pan(f.x) })
    end
    local function struck(f, x, radius, times, ail, freeze)
        for _, u in units do
            if math.abs(u.x - x) < radius then harm(u, f.dmg * times, ail or f.ail, nil, freeze) end
        end
    end
    local function unleash(f)
        local what, g = f.k.special, ground()
        local at = nil
        for _, m in marks do
            if m.of == f then at = m end
        end
        f.sp_in = 10 + math.random() * 4
        if what == "slam" then
            burst(f.x - 90, g - 20, true)
            for k = 1, 6 do smoke(f.x - 60 * k, g - 10, 3, 0, 40) end
            struck(f, f.x - 150, 220, 1.4)
        elseif what == "storm" then
            G.storm, G.storm_dmg = 6, f.dmg
            note("A sandstorm: the party is slowed and worn down")
        elseif what == "volley" then
            for _, u in units do
                if u.hp > 0 then
                    local from_x, from_y = f.x - 50, g - 150
                    table.insert(shots, { kind = 3, x = from_x, y = from_y, from_x = from_x, from_y = from_y, target = u, tx = u.x, ty = g - 50, speed = 700, dmg = f.dmg,
                                          turn = 0, along = 0, lift = 220, theirs = true, ail = 2, freeze = 2.4 })
                end
            end
            say({ wave = "triangle", freq = 240, to = 120, ms = 160, volume = 0.08, pan = pan(f.x) })
        elseif what == "erupt" then
            for _, m in marks do
                if m.of == f then
                    burst(m.x, g - 40, true)
                    smoke(m.x, g - 90, 10, 7, 70)
                    struck(f, m.x, 64, 1.6, 3)
                end
            end
        elseif what == "leap" and at then
            f.act = { what = "leap", from = f.x, to = at.x, t = 0 }
            return                                   -- (its mark stays until it lands)
        elseif what == "blink" and at then
            smoke(f.x, g - 100, 10, 2, 90)
            f.act = { what = "blink", home = f.x, t = 0 }
            f.x = at.x
            smoke(f.x, g - 100, 10, 2, 90)
            say({ wave = "sine", freq = 900, to = 200, ms = 160, volume = 0.07, pan = pan(f.x) })
            if webbed(f.x) then
                f.act.hit = true
                caught(f)
            end
        end
        unmark(f)
    end
    -- A leap and the way back, or a step behind the party and the way home.
    local function acting(f, dt)
        local a, g = f.act, ground()
        if f.stun > 0 then return end
        a.t += dt
        if a.what == "leap" or a.what == "back" then
            local k = math.min(1, a.t / 0.8)
            f.x = a.from + (a.to - a.from) * k
            f.y = g - math.sin(k * math.pi) * 280
            if k >= 1 then
                f.y = g
                if a.what == "back" then
                    f.act = nil
                else
                    unmark(f)
                    if webbed(f.x) then caught(f) else
                        burst(f.x, g - 20, true)
                        struck(f, f.x, 150, 1.6)
                    end
                    f.act = { what = "back", from = f.x, to = a.from, t = 0 }
                end
            end
        elseif a.what == "blink" then
            if not a.hit and a.t >= 0.5 then
                a.hit = true
                puff(f.x - 40, g - 60, 3, 1, 0, 0, 4.5)
                struck(f, f.x, 170, 1.5)
            end
            if a.t >= 1.1 then
                smoke(f.x, g - 100, 10, 2, 90)
                f.x = a.home
                smoke(f.x, g - 100, 10, 2, 90)
                f.act = nil
            end
        end
    end
    -- Half of it gone: it calls its own, and comes on faster.
    local function enrage(f)
        f.enraged = true
        f.speed *= 1.3
        text.said = f.lord .. " calls its own!"
        emit("newwave")
        for _ = 1, 4 + math.min(G.world, 4) do table.insert(queue, 1, one_of(f.k.calls)) end
        G.spawn_in = 0.2
        say({ wave = "saw", freq = 90, to = 180, ms = 600, volume = 0.12, pan = pan(f.x) })
    end
    -- Answers whether the lord is busy with something of its own this frame.
    local function lordly(f, dt, target, gap)
        if not f.enraged and f.hp < f.max * 0.5 then enrage(f) end
        if f.act then
            acting(f, dt)
            return true
        elseif f.stun > 0 then
            return true
        elseif f.wind then
            f.wind += dt / f.wind_time
            f.lit = math.floor(f.wind * 16) % 2
            if f.wind >= 1 then
                f.wind, f.lit = nil, 0
                unleash(f)
            end
            return true
        end
        f.sp_in -= dt
        if f.sp_in <= 0 and target and gap < G.SPECIAL[f.k.special].within then
            begin(f)
            return true
        end
        return false
    end

    local function clear_field()
        for _, t in { horde, queue, shots, bombs, marks, webs } do table.clear(t) end
        G.sky_clear()
        G.storm = 0
        fact.king, fact.wind = false, 0
    end
    -- To another land, from the map: one whose way is open.
    function G.travel(k)
        if k > G.reached then return note(KIND[LANDS[k].lord].name .. " bars the way to " .. LANDS[k + 1].name) end
        if k == G.land then return note("The party is already in " .. LANDS[k + 1].name) end
        G.land, G.step = k, 0
        clear_field()
        G.stage, G.stage_in = "start", 0
        note("The party sets out for " .. LANDS[k + 1].name)
        G.save_soon()
    end
    function G.restart()
        clear_field()
        G.stage, G.stage_in = "start", 0
    end

    on("take", function(i)
        if heroes[i + 1] and not heroes[i + 1].down then G.carried = heroes[i + 1] end
    end)
    on("drop", function()
        G.carried = nil
        G.save_soon()
    end)
    on("crack", function(i)
        if chests[i + 1] then crack(chests[i + 1]) end
    end)

    -- ── a frame of all that ──
    function G.fight(dt)
        local g = ground()

        -- The wave: the horde comes one by one; with none left, a chest; then a rest, and the next.
        G.stage_in -= dt
        if G.stage == "start" then
            muster()
        elseif G.stage == "fallen" then
            if G.stage_in <= 0 then
                for _, h in heroes do h.down, h.hp, h.x, h.ail = nil, h.max, h.post, nil end
                muster()
            end
        elseif G.stage == "fight" then
            if #queue > 0 then
                G.spawn_in -= dt
                if G.spawn_in <= 0 then
                    arrive(table.remove(queue, 1))
                    G.spawn_in = math.max(0.3, 1.0 - wave() * 0.03) * (0.6 + math.random() * 0.8)
                end
            elseif #horde == 0 and not G.sky_holds() then
                -- Cleared: a chest falls for it, and waits to be opened.
                reward(G.step == 4)
                G.stage, G.stage_in = "rest", 2.4
                -- Won: whoever fell stands up again, with half its life.
                for _, h in heroes do
                    if h.down then
                        h.down, h.hp, h.x, h.ail = nil, h.max * 0.5, h.post, nil
                        fact["up.x"] = h.x
                        emit("levelup")
                    end
                end
            end
        elseif G.stage == "rest" and G.stage_in <= 0 then
            if G.step == 4 then
                -- Its lord has fallen: the way on is open, and it is taken unless the party is to stay.
                if G.land < 5 and G.reached < G.land + 1 then
                    G.reached = G.land + 1
                    note("The way to " .. LANDS[G.land + 2].name .. " is open")
                end
                if not G.stay and G.land < 5 then G.land += 1 end
                G.step = 0
            else
                G.step += 1
            end
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
        local carried = G.carried
        if carried then
            if carried.down or not mouse.left then
                G.carried = nil
            elseif mouse.x then
                carried.post = math.clamp(mouse.x, G.CAMP_END, G.W * 0.72)
                carried.x = carried.post
            end
        end

        -- A game controller: the stick moves the knight.
        local p = pad(1)
        fact.pad = p ~= nil
        local push = 0
        if p and not heroes[1].down then
            if math.abs(p.lx) > 0.2 then push = p.lx end
            push += (p.right and 1 or 0) - (p.left and 1 or 0)
        end

        -- A sandstorm: everyone in it slowed, and worn down while it lasts.
        if G.storm > 0 then
            G.storm -= dt
            for _, h in heroes do
                if alive(h) then
                    if not h.ail then h.ail, h.ail_in = 1, 0.4 end
                    h.hp = math.max(1, h.hp - h.max * 0.03 * dt)
                end
            end
        end
        fact.storm = G.storm > 0

        -- The party.
        for _, h in heroes do
            h.hurt = math.max(0, h.hurt - dt * 5)
            if h.ail then
                h.ail_in -= dt
                if h.ail == 3 then h.hp -= h.max * 0.04 * dt end
                if h.ail_in <= 0 then h.ail = nil end
            end
            if alive(h) and h.regen > 0 then h.hp = math.min(h.max, h.hp + h.max * h.regen * dt) end
            if h.down then
                -- Fallen: there it lies until the wave is won or lost.
                h.acting = nil
            elseif h ~= G.carried then
                local moving = false
                if h == heroes[1] and push ~= 0 then
                    h.x = math.clamp(h.x + push * 240 * dt, G.CAMP_END, G.W * 0.72)
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
                        local slows = G.charm(h, "slows") or h.frost
                        if h.sweep then
                            -- A sweep: everything in front of the blade, or the fists, and back it goes.
                            local hits = 0
                            for _, f in horde do
                                if f.hp > 0 and hits < h.sweep and not f.edge and f.x - h.x > -26 and f.x - h.x < h.range + 20 then
                                    hurt(f, h.dmg, h.push, slows, h)
                                    hits += 1
                                end
                            end
                            puff(h.x + 44, g - 50, 3, 1, 0, 0, 4.5)
                            say({ wave = "noise", freq = h.push > 300 and 700 or 1400, to = h.push > 300 and 200 or 500, ms = 70, volume = 0.03 }, 0.2)
                        elseif h.heals then
                            if target and alive(target) then
                                target.hp = math.min(target.max, target.hp + h.heal)
                                smoke(target.x, g - 50, 6, 5, 50)
                                say({ wave = "sine", freq = 660, to = 990, ms = 160, volume = 0.04, pan = pan(target.x) }, 0.3)
                            end
                        elseif target and target.hp > 0 then
                            local potion = h.splash ~= nil
                            local from_x, from_y = h.x + (potion and 16 or 30), g - (potion and 78 or 52)
                            table.insert(shots, { kind = potion and 1 or 0, x = from_x, y = from_y, from_x = from_x, from_y = from_y, target = target, tx = target.x, ty = target.y - 40,
                                                  speed = potion and 520 or 1100, dmg = h.dmg, splash = h.splash, slows = slows, by = h, turn = 0, along = 0, lift = potion and 130 or 50 })
                            say(potion and { wave = "sine", freq = 500, to = 300, ms = 90, volume = 0.04 } or { wave = "triangle", freq = 220, to = 140, ms = 70, volume = 0.05 }, 0.1)
                        end
                    end
                    if h.acting >= 1 then h.acting, h.landed, h.target = nil, nil, nil end
                elseif h.wait <= 0 then
                    if h.heals then
                        -- Whoever of the party is worst off, if anyone is hurt.
                        local worst, share = nil, 0.92
                        for _, u in units do
                            if alive(u) and u.hp / u.max < share then worst, share = u, u.hp / u.max end
                        end
                        if worst then h.acting, h.target, h.wait = 0, worst, h.every end
                    else
                        -- (An arrow never finds an enderman: the archer does not waste one.)
                        local target = near(h.x, g - 40, h.range, h.name == "archer" and function(f) return f.k.blinks and not f.lord end or nil)
                        -- Nothing on the ground within reach: whatever flies, for the bow and the flasks.
                        if not target and (h.name == "archer" or h.name == "witch") then target = G.sky_near(h.x, g - 60, h.range) end
                        if h.sweep and target and (target.edge or target.x - h.x < -26) then target = nil end
                        if target then h.acting, h.target, h.wait = 0, target, h.every / h.quick end
                    end
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
                    hurt(prey, (6 + G.earned * 0.8) * tough(), 90)
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
        table.clear(units)
        for _, h in heroes do if alive(h) then table.insert(units, h) end end
        for _, w in wolves do table.insert(units, w) end
        local function ahead(f)
            local best = nil
            for _, u in units do
                if u.hp > 0 and u.x < f.x + 34 and (not best or u.x > best.x) then best = u end
            end
            return best
        end

        -- The webs that lie on the field, for as long as they hold.
        for i = #webs, 1, -1 do
            webs[i].left -= dt
            if webs[i].left <= 0 then table.remove(webs, i) end
        end

        -- The horde.
        local king = nil
        for _, f in horde do
            f.hurt = math.max(0, f.hurt - dt * 5)
            f.t += dt
            f.stun = math.max(0, f.stun - dt)
            if f.lord and f.hp > 0 then king = f end
            if (f.burn or 0) > 0 and not f.dying then
                -- On fire: it goes on hurting for a while.
                f.burn -= dt
                f.hp -= f.burn_dps * dt
                if math.random() < dt * 8 then puff(f.x + (math.random() - 0.5) * 30, f.y - 30 - math.random() * 40, 7, 6, 0, -40, 2.6) end
                if f.hp <= 0 then f.dying = 0 end
            end
            local walking, frame = true, nil
            if f.dying then
                -- Over it goes, red, and then it is smoke.
                f.dying += dt / 0.45
                f.hurt = 1
                walking = false
                -- (Whatever it had announced goes with it.)
                if f.lord then
                    f.wind = nil
                    unmark(f)
                end
            elseif f.edge == "sky" then
                walking = false
                f.sky += dt
                if math.random() < dt * 10 then puff(f.x + (math.random() - 0.5) * 50, f.y - 20 - math.random() * 90, 2, 6, 0, -20, 1.6) end
                if f.sky >= 1.5 then
                    smoke(f.x, f.y - 64, 9, 2, 70)
                    ring(f.x, f.y - 64, 150, -18, 0.8, 0.5)
                    f.edge, f.x, f.y, f.sky = nil, f.back, g, nil
                    smoke(f.x, g - 64, 9, 2, 70)
                    ring(f.x, g - 64, 150, -18, 0.8, 0.5)
                    say({ wave = "sine", freq = 1100, to = 180, ms = 200, volume = 0.05, pan = pan(f.x) }, 0.2)
                end
            elseif f.edge == "fall" then
                walking = false
                f.vy += 2300 * dt
                f.y += f.vy * dt
                if f.y >= g then
                    f.y, f.edge, f.vy = g, nil, nil
                    smoke(f.x, g - 8, 8, 0, 90)
                    ring(f.x, g - 10, 170, 10, 0.3, 0.6)
                    quake(3)
                    say({ wave = "sine", freq = 140, to = 60, ms = 160, volume = 0.08, pan = pan(f.x) }, 0.15)
                end
            elseif f.edge == "thread" then
                -- Down its own thread, head first.
                f.y += f.speed * 1.6 * dt
                if f.y >= g then f.edge, f.y, f.turn = nil, g, 0 end
            elseif f.edge == "ceiling" then
                f.x += f.speed * dt
                if f.drop_at and f.x >= f.drop_at then f.edge, f.drop_at = "thread", nil end
                if f.edge == "ceiling" and f.x >= G.W then f.edge, f.x, f.y, f.turn = "wall", G.W, 0, 270 end
            elseif f.edge == "wall" then
                f.y += f.speed * dt
                if f.y >= g then f.edge, f.y, f.turn = nil, g, 0 end
            else
                if not f.act then f.y = g end
                -- Knocked back by what hit it.
                if f.kick and f.kick > 1 then
                    f.x = math.min(G.W + 60, f.x + f.kick * dt)
                    f.kick *= math.max(0, 1 - 9 * dt)
                end
                f.slow = math.max(0, f.slow - dt)
                local target = ahead(f)
                local gap = target and f.x - target.x or math.huge
                -- (A lord strides in, and slows down once it is near.)
                local pace = f.speed * (f.slow > 0 and 0.55 or 1) * (f.lord and gap > 520 and 3.5 or 1)
                if f.lord and lordly(f, dt, target, gap) then
                    -- Its own business: it neither walks nor strikes meanwhile.
                    walking = false
                    if f.wind then frame = 4 + math.min(1, math.floor(f.wind * 2)) end
                elseif f.fuse then
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
                            if other ~= f and other.hp > 0 and math.abs(other.x - f.x) < 100 and not other.edge then hurt(other, 40 * tough(), 240) end
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
                            f.wait, f.strike = f.k.every * (f.enraged and 0.75 or 1), 0
                        end
                        if f.strike then
                            local ranged = f.k.shoots or f.k.throws
                            f.strike += dt / (ranged and 0.6 or 0.42)
                            if not f.landed and f.strike >= (f.k.shoots and 0.75 or 0.5) then
                                f.landed = true
                                if ranged then
                                    -- From the bow, or from the hand: an arrow, or a flask that splashes.
                                    local tall = f.k.big and 2 or f.size
                                    local from_x, from_y = f.x - (f.k.throws and 16 or 28) * tall, g - (f.k.throws and 78 or 52) * tall
                                    table.insert(shots, { kind = f.k.throws and 1 or 3, x = from_x, y = from_y, from_x = from_x, from_y = from_y, target = target, tx = target.x, ty = g - 50,
                                                          speed = f.k.throws and 480 or 640, dmg = f.dmg, turn = 0, along = 0, lift = f.k.throws and 130 or 60, theirs = true, ail = f.ail, splash = f.k.throws and 80 or nil })
                                    say({ wave = "triangle", freq = 200, to = 130, ms = 70, volume = 0.04, pan = pan(f.x) }, 0.1)
                                else
                                    harm(target, f.dmg, f.ail, f)
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
                        frame = f.k.big and hop // 2 or hop
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
                            ring(f.x, g - 64, 130, -16, 0.7, 0.45)
                            if math.random() < 0.4 and not f.lord then
                                -- Somewhere up on the screen for a moment, looking down, and then where it was going.
                                f.edge, f.sky, f.back = "sky", 0, to
                                f.x, f.y = 260 + math.random() * (G.W - 520), 190 + math.random() * (g - 520)
                            else
                                f.x = to
                            end
                            smoke(f.x, f.y - 64, 7, 2, 60)
                            ring(f.x, f.y - 64, 130, -16, 0.7, 0.45)
                            say({ wave = "sine", freq = 900, to = 200, ms = 160, volume = 0.05, pan = pan(f.x) }, 0.2)
                        end
                    end
                else
                    walking = false
                end
            end
            -- Eight pictures of walking and eight of striking; a lord, four and four.
            local many = f.k.big and 4 or 8
            if not frame then
                frame = walking and math.floor(f.t * (f.k.climbs and 14 or (f.k.big and 4.5 or 9))) % many
                    or (f.fuse and many + math.min(many - 1, math.floor(f.fuse * many)) or (f.strike and many + math.min(many - 1, math.floor(f.strike * many)) or 0))
            end
            f.cell = (f.k.boss and f.k.boss * 8 or f.k.row * 16) + frame
            -- A lord's steps are felt: a tremor and a ripple at each foot that comes down.
            if f.lord and walking and frame ~= f.footfall and (frame == 0 or frame == 2) then
                quake(2.5)
                ring(f.x, g - 6, 160, 6, 0.1, 0.6)
            end
            f.footfall = walking and frame or nil
        end
        fact.king = king ~= nil
        if king then
            fact["king.hp"] = math.clamp(king.hp / king.max, 0, 1)
            text.lord = king.lord
        end
        fact.wind = king and king.wind or 0
        fact["king.dazed"] = king ~= nil and king.stun > 0

        -- A hero with nothing left goes down for a while; with all of them down, the camp falls.
        local standing = 0
        for _, h in heroes do
            if not h.down and h.hp <= 0 then
                if G.charm(h, "revive") and not h.saved then
                    -- Its totem: once a wave, it gets up instead.
                    h.saved, h.hp, h.ail = true, h.max * 0.5, nil
                    smoke(h.x, g - 50, 10, 1, 70)
                    note("The totem holds the " .. h.shown:lower() .. " up")
                else
                    h.down, h.hp, h.acting = true, 0, nil
                    smoke(h.x, g - 40, 8)
                end
            end
            if not h.down then standing += 1 end
        end
        if standing == 0 and G.stage ~= "fallen" then
            clear_field()
            G.stage, G.stage_in = "fallen", 4
            -- Back to where this land began: what was gathered and learnt is kept.
            G.step = 0
            log("the camp fell: back to the start of", LANDS[G.land + 1].name)
            text.said = "The camp fell - back to the start of " .. LANDS[G.land + 1].name
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
                    elseif s.target.air then
                        if s.target.hp > 0 then hurt(s.target, s.dmg, 0, nil, s.by) end
                    else
                        for _, f in horde do
                            if f.hp > 0 and (f.x - s.x) ^ 2 + (f.y - 40 - s.y) ^ 2 < s.splash ^ 2 then hurt(f, s.dmg, 70, s.slows, s.by) end
                        end
                    end
                elseif s.theirs then
                    if alive(s.target) then harm(s.target, s.dmg, s.ail, nil, s.freeze) end
                elseif s.target.hp > 0 then
                    hurt(s.target, s.dmg, 130, s.slows, s.by)
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
                        -- A web: it slows what is in it, and for a while it lies there for whatever lands on it.
                        smoke(b.x, g - 30, 14, 0, 220)
                        table.insert(webs, { x = b.x, left = 6 })
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
                        if f.hp > 0 and math.abs(f.x - b.x) < (f.k.big and 230 or 170) and not f.edge then hurt(f, (70 + wave() * 14) * tough(), 420, nil, nil, "tnt") end
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
                    orbs(f.x, f.y - 30, f.k.xp * (f.small and 0.4 or 1) * (f.elite and 4 or 1))
                    -- (Whoever felled it may make it leave more.)
                    local more = (1 + 0.25 * ((f.by and f.by.loot) or 0)) * (f.small and 0.5 or 1)
                    for round = 1, f.elite and 2 or 1 do
                        for _, list in { f.k.drops, f.as.drops or {} } do
                            for _, d in list do
                                if math.random() < d[2] * more and leave(d[1], f.x, f.y - (f.k.big and 60 or 30), f.k.big and 420 or nil) then G.dropped(f.beast, d[1]) end
                            end
                        end
                    end
                    if f.lord then
                        ring(f.x, f.y - 100, 560, 34, 0.9, 1.2)
                        quake(20)
                        fact["at.x"], fact["at.y"] = f.x, f.y - 60
                        emit("debris")
                    end
                    if f.k.trophy then
                        leave(f.k.trophy, f.x, f.y - 80, 480)
                        G.dropped(f.beast, f.k.trophy)
                    end
                    G.killed(f)
                    if f.k.parts then
                        -- A lord of slime comes apart into whole ones.
                        for k = 1, f.k.parts do
                            local part = arrive(one_of(f.k.calls), f.x + (k - 2) * 40)
                            part.kick = (k - 1) * 120
                        end
                    elseif f.k.splits and not f.small then
                        for side = -1, 1, 2 do
                            local little = arrive({ kind = f.kind, as = f.as }, f.x + side * 22, true)
                            little.kick = side > 0 and 160 or 0
                        end
                    end
                end
            end
        end

        -- What was left: it jumps out, and then goes to whoever picks it up, or to the chest of the camp.
        local picker = heroes[1]
        for _, h in heroes do
            if alive(h) then picker = h break end
        end
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
                        G.xp += d.worth * (1 + 0.25 * (G.world - 1))
                        say({ wave = "sine", freq = 1100 + math.random() * 500, ms = 60, volume = 0.03 }, 0.07)
                    else
                        G.gain(d.name, d.n)
                        say({ wave = "square", freq = 880, to = 1320, ms = 40, volume = 0.025 }, 0.07)
                    end
                    table.remove(drops, i)
                else
                    d.x += dx / far * step
                    d.y += dy / far * step
                end
            end
        end

        -- Experience fills a level; a level is kept until it is spent, on a hero or on an enchantment.
        local need = G.need()
        while G.xp >= need do
            G.xp -= need
            G.earned += 1
            G.points += 1
            fact["up.x"] = 119
            emit("levelup")
            say({ wave = "sine", freq = 880, to = 1320, ms = 200, volume = 0.07 })
            need = G.need()
        end

        for i = #puffs, 1, -1 do
            local q = puffs[i]
            q.age += dt * q.rate
            q.x += q.vx * dt
            q.y += q.vy * dt
            if q.age >= 1 then table.remove(puffs, i) end
        end
        G.smite_in = math.max(0, G.smite_in - dt)

        -- The rings run out, the screen settles, the bolt goes.
        for i = #G.waves, 1, -1 do
            local w = G.waves[i]
            w.age += dt * w.rate
            if w.age >= 1 then table.remove(G.waves, i) end
        end
        G.shake *= math.exp(-7 * dt)
        if G.shake < 0.3 then G.shake = 0 end
        G.bolt_t = math.max(0, G.bolt_t - dt)
        G.flight(dt)
        -- A lord's shadow, far bigger than it, going by behind the field before it comes: each step a tremor.
        local o = G.omen
        if o then
            o.t += dt
            local step = math.floor(o.t / 1.15)
            if step > (o.step or -1) and o.t < 6.6 then
                o.step = step
                quake(5)
                ring(G.W + 300 - (G.W + 700) * o.t / 7, g, 280, 9, 0.15, 0.9)
                say({ wave = "sine", freq = 70, to = 38, ms = 380, volume = 0.16, release = 300 }, 0.5)
            end
            if o.t >= 7 then G.omen = nil end
        end
    end

    -- ── and all of it, to the scene ──
    function G.show_field()
        local g = ground()
        local team = {}
        for _, h in heroes do
            table.insert(team, { x = h.x, y = g, cell = h.cell or h.row * 16, hp = math.clamp(h.hp / h.max, 0, 1), hurt = h.hurt, hearts = 5, face = 1, down = h.down ~= nil, held = h == G.carried,
                                 ail = h.ail or 0, size = h.size or 1 })
        end
        for _, w in wolves do
            table.insert(team, { x = w.x, y = g + 5, cell = w.cell or 48, hp = math.clamp(w.hp / w.max, 0, 1), hurt = w.hurt, hearts = 3, face = w.face, down = false, held = false, ail = 0, size = 1 })
        end
        model.team = team
        local seen = {}
        for k, f in horde do
            if k > 96 then break end
            seen[k] = { x = f.x, y = f.y, lift = f.k.big and 0 or 99 - f.k.foot, turn = f.turn + (f.dying and math.min(1, f.dying * 1.6) * 88 or 0), cell = f.cell or 0, hurt = f.hurt, lit = f.lit,
                        sheet = f.k.sheet, size = f.size, wash = f.wash, dazed = f.stun > 0, thread = f.edge == "thread" }
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
        local told = {}
        for k, m in marks do
            told[k] = { x = m.x, w = m.w, kind = m.kind, t = m.of.wind or 1 }
        end
        for _, w in webs do
            table.insert(told, { x = w.x, w = 300, kind = 4, t = math.clamp(w.left / 6, 0, 1) })
        end
        model.marks = told
        fact.xp, fact.ready = math.clamp(G.xp / G.need(), 0, 1), 1 - G.smite_in / SMITE_EVERY
        local rings = {}
        for k, w in G.waves do rings[k] = { x = w.x, y = w.y, size = w.size, push = w.push, glow = w.glow, age = w.age } end
        model.waves = rings
        G.show_sky()
        fact["shake.x"], fact["shake.y"] = G.shake * (math.random() * 2 - 1), G.shake * (math.random() * 2 - 1)
        model.bolt = G.bolt_t > 0 and G.bolt or {}
        fact["bolt.lit"] = G.bolt_t / 0.32
        local o = G.omen
        fact["omen.on"] = o ~= nil
        if o then
            fact["omen.x"] = G.W + 300 - (G.W + 700) * o.t / 7
            fact["omen.cell"] = o.boss * 8 + math.floor(o.t / 0.29) % 4
            fact["omen.o"] = math.min(1, o.t / 0.8, (7 - o.t) / 0.8)
        end
    end
end
