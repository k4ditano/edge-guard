-- What flies: not along the ground but over the whole screen. Phantoms wheel
-- above the overworld's waves and dive at the party; ghasts float high over
-- the Nether and spit fireballs, which can be pressed to send them back; and
-- in the End, at its third wave, the dragon comes, and the wave is not won
-- while it lives. The archer and the witch shoot at what flies when nothing
-- walks within reach; the lightning finds the dragon; and anything up there
-- can be pressed to strike it.
return function(G)
    local note, say, pan, ground = G.note, G.say, G.pan, G.ground
    local heroes = G.heroes
    local sky, balls = {}, {}
    G.sky, G.balls = sky, balls

    -- What each one is: how much it takes and how hard it hits, before the
    -- wave and the world make it more; how long it stays before it goes.
    local FLY = {
        phantom = { name = "Phantom", hp = 30, dmg = 9, xp = 3, stays = 26, drops = { { "string", 0.5 }, { "flesh", 0.3 } } },
        ghast = { name = "Ghast", hp = 46, dmg = 30, xp = 5, stays = 48, drops = { { "gunpowder", 0.7 }, { "raw_gold", 0.25 } } },
        dragon = { name = "The Ender Dragon", hp = 120, dmg = 12, xp = 120,
                   drops = { { "diamond", 1 }, { "diamond", 1 }, { "diamond", 1 }, { "pearl", 1 }, { "pearl", 1 }, { "xp_bottle", 1 }, { "xp_bottle", 1 } } },
    }
    G.FLY = FLY
    local function tough() return 3 ^ (G.world - 1) end
    local function fierce() return 1.6 ^ (G.world - 1) end

    local function living(u) return not u.down and u.hp > 0 end
    local function someone()
        local list = {}
        for _, u in G.units do
            if living(u) then table.insert(list, u) end
        end
        return #list > 0 and list[math.random(#list)] or nil
    end

    -- ── who comes, and when ──
    local later = {}                 -- { kind, in } still to come this wave
    local function come(kind)
        local w, f = G.wave(), FLY[kind]
        local life = f.hp * 1.12 ^ (w - 1) * tough()
        local one = { kind = kind, f = f, k = { air = true }, size = 0, air = true, edge = "air", beast = kind,
                      hp = life, max = life, dmg = f.dmg * (1 + (w - 1) * 0.06) * fierce(),
                      x = G.W + 160, y = 60 + math.random() * 160, vx = 0, vy = 0, t = math.random() * 10, life = 0,
                      hurt = 0, stun = 0, slow = 0, lit = 0, face = 1, tilt = 0 }
        if kind == "phantom" then
            one.spin, one.speed = math.random() * math.pi * 2, 0.4 + math.random() * 0.2
            one.dive_in = 3 + math.random() * 3
        elseif kind == "ghast" then
            one.hx, one.hy = G.W * (0.5 + math.random() * 0.4), 140 + math.random() * (ground() * 0.3)
            one.y, one.shoot_in, one.home_in = one.hy, 3 + math.random() * 2, 6
        else
            one.spin, one.pass_in = 0, 7
            one.x, one.y = G.W + 400, ground() * 0.2
            text.said = "The Ender Dragon!"
            emit("newwave")
            G.ring(G.W * 0.5, ground() * 0.4, 900, 26, 0.8, 1.6)
            G.quake(12)
            say({ wave = "saw", freq = 80, to = 40, ms = 1400, volume = 0.16, attack = 200, release = 600 })
            say({ wave = "noise", freq = 900, to = 120, ms = 1100, volume = 0.08, release = 500 })
        end
        table.insert(sky, one)
        return one
    end

    -- At the start of each wave: what of the sky comes with it.
    function G.sky_muster()
        table.clear(later)
        local land, step = G.land, G.step
        if land <= 3 and step >= 1 and step <= 3 and math.random() < 0.55 + 0.1 * step then
            for k = 1, (step >= 3 and 2 or 1) + (G.world > 1 and 1 or 0) do
                table.insert(later, { kind = "phantom", at = 4 + math.random() * 10 + k * 3 })
            end
        elseif land == 4 then
            for k = 1, (step >= 2 and 2 or 1) + (G.world > 1 and 1 or 0) do
                table.insert(later, { kind = "ghast", at = 2 + math.random() * 8 + (k - 1) * 9 })
            end
        elseif land == 5 and step == 2 then
            table.insert(later, { kind = "dragon", at = 3 })
        end
    end

    -- Whether the wave has to wait for what flies: the dragon, alive, and
    -- what has yet to come. A phantom or a ghast goes by itself in time.
    function G.sky_holds()
        if #later > 0 then return true end
        for _, s in sky do
            if s.hp > 0 and not s.leaving then return true end
        end
        return false
    end

    function G.sky_clear()
        table.clear(sky)
        table.clear(balls)
        table.clear(later)
    end

    -- The nearest living thing up there, within reach of a point.
    function G.sky_near(x, y, range)
        local best, how = nil, range
        for _, s in sky do
            if s.hp > 0 and not s.leaving and s.x > 0 and s.x < G.W then
                local d = math.sqrt((s.x - x) ^ 2 + (s.y - y) ^ 2)
                if d < how then best, how = s, d end
            end
        end
        return best
    end
    -- Where the lightning goes when the dragon is up.
    function G.sky_bolt()
        for _, s in sky do
            if s.kind == "dragon" and s.hp > 0 and s.x > 0 and s.x < G.W then return s end
        end
        return nil
    end

    -- ── pressed ──
    on("swat", function(i)
        local s = sky[i + 1]
        if not s or s.hp <= 0 then return end
        G.hurt(s, (18 + G.wave() * 5) * tough() * (s.kind == "dragon" and 0.35 or 1), 0)
        G.ring(s.x, s.y, 110, 8, 0.5, 0.35)
        G.smoke(s.x, s.y, 4, 1, 40)
        say({ wave = "square", freq = 330, to = 160, ms = 70, volume = 0.06, pan = pan(s.x) })
    end)
    on("deflect", function(i)
        local b = balls[i + 1]
        if not b or b.back then return end
        b.back = true
        G.ring(b.x, b.y, 140, 14, 0.9, 0.4)
        G.quake(3)
        say({ wave = "square", freq = 220, to = 660, ms = 120, volume = 0.1, pan = pan(b.x) })
    end)

    -- ── falling ──
    local function felled(s)
        G.orbs(s.x, s.y, s.f.xp * (G.world > 1 and 2 or 1))
        for _, d in s.f.drops do
            if math.random() < d[2] then G.leave(d[1], s.x, s.y, 120) end
        end
        G.killed({ beast = s.kind, k = {} })
        if s.kind == "dragon" then
            G.ring(s.x, s.y, 1100, 44, 1, 1.6)
            G.quake(26)
            fact["at.x"], fact["at.y"] = s.x, s.y
            emit("debris")
            emit("debris")
            G.smoke(s.x, s.y, 30, 2, 260)
            note("The Ender Dragon falls!")
            G.feat("dragon")
            say({ wave = "saw", freq = 60, to = 30, ms = 1800, volume = 0.16, release = 900 })
        else
            G.smoke(s.x, s.y, s.kind == "ghast" and 14 or 8, 0, s.kind == "ghast" and 90 or 50)
            G.ring(s.x, s.y, s.kind == "ghast" and 260 or 160, 12, 0.4, 0.6)
        end
    end

    -- ── a frame of it ──
    function G.flight(dt)
        local g = ground()
        for i = #later, 1, -1 do
            later[i].at -= dt
            if later[i].at <= 0 then
                come(later[i].kind)
                table.remove(later, i)
            end
        end
        for i = #sky, 1, -1 do
            local s = sky[i]
            local ox, oy = s.x, s.y
            s.t += dt
            s.life += dt
            s.hurt = math.max(0, s.hurt - dt * 5)
            s.stun = math.max(0, (s.stun or 0) - dt)
            if (s.burn or 0) > 0 and not s.dying then
                s.burn -= dt
                s.hp -= s.burn_dps * dt
                if s.hp <= 0 then s.dying = 0 end
            end
            if s.dying then
                -- The dragon goes up shaking and breaking into light; the rest fall.
                s.dying += dt / (s.kind == "dragon" and 3 or 0.6)
                s.hurt = 1
                if s.kind == "dragon" then
                    s.y -= 30 * dt
                    G.quake(4)
                    if math.random() < dt * 6 then
                        local a = math.random() * math.pi * 2
                        G.ring(s.x + math.cos(a) * 140, s.y + math.sin(a) * 90, 260, 18, 1, 0.5)
                        G.smoke(s.x + math.cos(a) * 120, s.y + math.sin(a) * 70, 4, 2, 60)
                    end
                else
                    s.vy += 900 * dt
                    s.y += s.vy * dt
                    s.tilt += 200 * dt
                end
                if s.dying >= 1 then
                    felled(s)
                    table.remove(sky, i)
                end
            elseif s.leaving then
                s.y -= 260 * dt
                s.x += s.vx * dt
                if s.y < -260 then table.remove(sky, i) end
            elseif s.kind == "phantom" then
                -- A figure of eight over the screen, and now and then a dive at one of the party.
                if s.life > s.f.stays then s.leaving, s.vx = true, -s.face * 120 end
                local d = s.dive
                if d then
                    d.t += dt / 1.5
                    local k = math.min(1, d.t)
                    local a, b, c = (1 - k) ^ 2, 2 * (1 - k) * k, k * k
                    s.x = a * d.x0 + b * d.cx + c * d.x1
                    s.y = a * d.y0 + b * d.cy + c * d.y1
                    if not d.hit and k >= 0.5 then
                        d.hit = true
                        local u = d.u
                        if living(u) and math.abs(u.x - s.x) < 90 then
                            G.harm(u, s.dmg)
                            G.smoke(u.x, g - 60, 4, 0, 40)
                            -- Whoever has a blade or fists gives one back as it goes by.
                            if u.sweep then G.hurt(s, u.dmg, 0, nil, u) end
                        end
                    end
                    if k >= 1 then s.dive, s.dive_in = nil, 4 + math.random() * 4 end
                else
                    s.spin += dt * s.speed
                    local px = G.W * 0.55 + G.W * 0.38 * math.sin(s.spin)
                    local py = g * 0.3 + g * 0.17 * math.sin(s.spin * 2)
                    local ease = math.min(1, 2.2 * dt)
                    s.x += (px - s.x) * ease
                    s.y += (py - s.y) * ease
                    s.dive_in -= dt
                    local u = s.dive_in <= 0 and someone()
                    if u then
                        local side = s.x > u.x and -1 or 1
                        local x1, y1 = u.x + side * 380, g * 0.3
                        -- Through the hero halfway: the middle point pulled down twice as far.
                        s.dive = { t = 0, u = u, x0 = s.x, y0 = s.y, x1 = x1, y1 = y1, cx = 2 * u.x - (s.x + x1) / 2, cy = 2 * (g - 70) - (s.y + y1) / 2 }
                        say({ wave = "noise", freq = 2600, to = 700, ms = 520, volume = 0.05, attack = 120, pan = pan(s.x) })
                    end
                end
            elseif s.kind == "ghast" then
                -- It drifts high up, now here, now there, and spits fire at the party.
                if s.life > s.f.stays then s.leaving, s.vx = true, 40 end
                s.home_in -= dt
                if s.home_in <= 0 then
                    s.home_in = 5 + math.random() * 4
                    s.hx, s.hy = G.W * (0.4 + math.random() * 0.5), 120 + math.random() * (g * 0.32)
                end
                s.x += (s.hx - s.x) * math.min(1, 0.5 * dt)
                s.y += (s.hy + math.sin(s.t * 1.3) * 14 - s.y) * math.min(1, 0.8 * dt)
                s.shoot_in -= dt
                if s.shoot_in <= 0 and not s.charge then
                    local u = someone()
                    if u then s.charge, s.aim = 0, u else s.shoot_in = 2 end
                end
                if s.charge then
                    s.charge += dt / 0.9
                    if s.charge >= 1 then
                        local u = s.aim
                        local fx, fy = s.x - s.face * 60, s.y + 20
                        local dx, dy = u.x - fx, (g - 50) - fy
                        local far = math.max(1, math.sqrt(dx * dx + dy * dy))
                        table.insert(balls, { x = fx, y = fy, vx = dx / far * 330, vy = dy / far * 330, spin = 0, from = s, dmg = s.dmg })
                        say({ wave = "noise", freq = 700, to = 200, ms = 380, volume = 0.09, release = 260, pan = pan(fx) })
                        say({ wave = "saw", freq = 330, to = 150, ms = 260, volume = 0.05, pan = pan(fx) })
                        s.charge, s.aim, s.shoot_in = nil, nil, 4.5 + math.random() * 2.5
                    end
                end
            else
                -- The dragon: wide loops over the whole screen, and every so often
                -- down along the field breathing, through whoever is in the way.
                local p = s.pass
                if p then
                    p.t += dt / 3.2
                    local k = math.min(1, p.t)
                    s.x = p.x0 + (p.x1 - p.x0) * k
                    s.y = p.y0 + (g - 120 - p.y0) * math.sin(k * math.pi) ^ 0.6
                    if s.y > g * 0.55 then
                        if math.random() < dt * 30 then
                            G.puff(s.x - s.face * 150, s.y + 40, 2, 14 + math.random() * 10, -s.face * (120 + math.random() * 80), 60 + math.random() * 60, 1.2)
                        end
                        for _, u in G.units do
                            if living(u) and not p.hit[u] and math.abs(u.x - s.x) < 90 then
                                p.hit[u] = true
                                G.harm(u, s.dmg, 3)
                                if u.sweep then G.hurt(s, u.dmg * 2, 0, nil, u) end
                            end
                        end
                    end
                    if k >= 1 then s.pass, s.pass_in = nil, 7 + math.random() * 4 end
                else
                    s.spin += dt * 0.38
                    local px = G.W * 0.5 + G.W * 0.36 * math.sin(s.spin)
                    local py = g * 0.32 + g * 0.16 * math.sin(s.spin * 2)
                    local ease = math.min(1, 1.4 * dt)
                    s.x += (px - s.x) * ease
                    s.y += (py - s.y) * ease
                    s.pass_in -= dt
                    if s.pass_in <= 0 and someone() then
                        local from_right = s.x > G.W * 0.5
                        s.pass = { t = 0, x0 = s.x, y0 = s.y, x1 = from_right and -200 or G.W + 200, hit = {} }
                        if not s.warned then
                            s.warned = true
                            note("The dragon swoops - press it, or call the lightning on it")
                        end
                        say({ wave = "saw", freq = 140, to = 70, ms = 900, volume = 0.12, attack = 120, pan = pan(s.x) })
                    end
                end
                -- Each beat of its wings is felt.
                local beat = math.floor(s.t * 6) % 8
                if beat == 0 and s.beat ~= 0 then
                    G.quake(1.6)
                    say({ wave = "noise", freq = 300, to = 90, ms = 240, volume = 0.04, pan = pan(s.x) }, 0.3)
                end
                s.beat = beat
            end
            -- Which way it faces, and how it leans, from how it went.
            local vx, vy = s.x - ox, s.y - oy
            if not s.dying then
                if math.abs(vx) > 0.4 then s.face = vx < 0 and 1 or -1 end
                if s.kind == "ghast" and s.charge then s.face = s.aim.x < s.x and 1 or -1 end
                local lean = s.kind == "ghast" and 0 or math.deg(math.atan2(vy, math.max(0.5, math.abs(vx))))
                s.tilt += (math.clamp(lean, -40, 40) * 0.7 - s.tilt) * math.min(1, 8 * dt)
            end
        end

        -- The fireballs: on, until they meet the ground or someone; sent back, at their ghast.
        for i = #balls, 1, -1 do
            local b = balls[i]
            b.spin += 400 * dt
            if b.back then
                local s = b.from
                if s and s.hp > 0 and sky[table.find(sky, s) or 0] == s then
                    local dx, dy = s.x - b.x, s.y - b.y
                    local far = math.max(1, math.sqrt(dx * dx + dy * dy))
                    b.vx, b.vy = dx / far * 760, dy / far * 760
                    if far < 60 then
                        G.burst(s.x, s.y, true)
                        G.hurt(s, s.max * 1.2, 0)
                        G.stats.returned = (G.stats.returned or 0) + 1
                        G.feat("return")
                        table.remove(balls, i)
                        continue
                    end
                end
            end
            b.x += b.vx * dt
            b.y += b.vy * dt
            if math.random() < dt * 40 then G.puff(b.x, b.y, 7, 8 + math.random() * 6, -b.vx * 0.1, -b.vy * 0.1 - 20, 2.4) end
            local hit = not b.back and b.y >= g - 50
            if not b.back then
                for _, u in G.units do
                    if living(u) and math.abs(u.x - b.x) < 40 and math.abs((g - 50) - b.y) < 60 then hit = true end
                end
            end
            if hit then
                G.burst(b.x, b.y, true)
                for _, u in G.units do
                    if living(u) and math.abs(u.x - b.x) < 120 then G.harm(u, b.dmg, 3) end
                end
                table.remove(balls, i)
            elseif b.x < -200 or b.x > G.W + 200 or b.y < -200 or b.y > g + 100 then
                table.remove(balls, i)
            end
        end

        -- With no ground lord, the dragon's life is the bar at the top.
        if not fact.king then
            local d = G.sky_bolt()
            if d then
                fact.king, fact["king.hp"], fact["king.dazed"] = true, math.clamp(d.hp / d.max, 0, 1), false
                text.lord = d.f.name
            end
        end
    end

    -- ── to the scene ──
    function G.show_sky()
        local seen = {}
        for k, s in sky do
            local frame
            if s.kind == "ghast" then
                frame = 8 + (s.charge and 4 + math.floor(s.charge * 4) % 4 or math.floor(s.t * 4) % 4)
            else
                frame = math.floor(s.t * (s.kind == "dragon" and 6 or 10)) % 8
            end
            seen[k] = { x = s.x, y = s.y, cell = frame, sheet = s.kind == "dragon" and 1 or 0, face = s.face, tilt = s.tilt, hurt = s.hurt,
                        size = s.kind == "ghast" and 1.5 or (s.kind == "dragon" and 1.6 or 0.95), alive = s.hp > 0 and not s.dying }
        end
        model.sky = seen
        local fire = {}
        for k, b in balls do fire[k] = { x = b.x, y = b.y, spin = b.spin, back = b.back == true } end
        model.balls = fire
    end
end
