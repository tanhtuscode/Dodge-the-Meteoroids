-- ParticleSystem.lua
-- Advanced particle system for enhanced visual effects

local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem.new()
    local self = setmetatable({}, ParticleSystem)
    self.particles = {}
    self.warningPulses = {} -- Initialize warning pulses table
    self.time = 0
    return self
end

function ParticleSystem:update(dt)
    self.time = self.time + dt
    
    -- Update warning pulses
    for i = #self.warningPulses, 1, -1 do
        local pulse = self.warningPulses[i]
        pulse.life = pulse.life - dt
        pulse.scale = pulse.scale + dt * 3  -- Expand pulse
        pulse.alpha = pulse.life / pulse.maxLife
        
        if pulse.life <= 0 then
            table.remove(self.warningPulses, i)
        end
    end
    
    -- Update all particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        
        -- Update position
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- Apply forces
        p.vx = p.vx + (p.ax or 0) * dt
        p.vy = p.vy + (p.ay or 0) * dt
        
        -- Apply drag
        local drag = p.drag or 0.98
        p.vx = p.vx * drag
        p.vy = p.vy * drag
        
        -- Update life
        p.life = p.life - dt
        
        -- Update size
        if p.sizeStart and p.sizeEnd then
            local t = 1 - (p.life / p.maxLife)
            p.size = p.sizeStart + (p.sizeEnd - p.sizeStart) * t
        end
        
        -- Update alpha
        if p.alphaStart and p.alphaEnd then
            local t = 1 - (p.life / p.maxLife)
            p.alpha = p.alphaStart + (p.alphaEnd - p.alphaStart) * t
        end
        
        -- Remove dead particles
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    -- Update warning pulses
    for i = #self.warningPulses, 1, -1 do
        local pulse = self.warningPulses[i]
        pulse.life = pulse.life - dt
        
        -- Remove expired pulses
        if pulse.life <= 0 then
            table.remove(self.warningPulses, i)
        end
    end
end

function ParticleSystem:draw()
    for _, p in ipairs(self.particles) do
        local alpha = p.alpha or (p.life / p.maxLife)
        love.graphics.setColor(p.r, p.g, p.b, alpha)
        
        if p.type == "circle" then
            love.graphics.circle("fill", p.x, p.y, p.size)
        elseif p.type == "square" then
            love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
        elseif p.type == "line" then
            love.graphics.setLineWidth(p.size)
            love.graphics.line(p.x, p.y, p.x + p.length * math.cos(p.angle), p.y + p.length * math.sin(p.angle))
        elseif p.type == "spark" then
            love.graphics.setLineWidth(p.size)
            love.graphics.line(p.x, p.y, p.prevX or p.x, p.prevY or p.y)
            p.prevX, p.prevY = p.x, p.y
        elseif p.type == "star" then
            -- Draw a 4-pointed star
            local size = p.size
            love.graphics.polygon("fill",
                p.x, p.y - size,           -- Top point
                p.x - size*0.3, p.y - size*0.3,  -- Top-left inner
                p.x - size, p.y,           -- Left point
                p.x - size*0.3, p.y + size*0.3,  -- Bottom-left inner
                p.x, p.y + size,           -- Bottom point
                p.x + size*0.3, p.y + size*0.3,  -- Bottom-right inner
                p.x + size, p.y,           -- Right point
                p.x + size*0.3, p.y - size*0.3   -- Top-right inner
            )
        end
    end
    
    -- Draw warning pulses
    for _, pulse in ipairs(self.warningPulses) do
        local alpha = pulse.alpha * (pulse.life / pulse.maxLife)
        love.graphics.setColor(1, 0.7, 0, alpha) -- Orange color
        
        love.graphics.circle("line", pulse.x, pulse.y, pulse.scale * 10)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

-- Engine trail for player
function ParticleSystem:addEngineTrail(x, y, vx, vy, color)
    for i = 1, math.random(1, 2) do  -- Reduced particle count
        table.insert(self.particles, {
            x = x + math.random(-1, 1),  -- Even tighter spread
            y = y + math.random(-1, 1),
            vx = vx + math.random(-10, 10),  -- Less spread
            vy = vy + math.random(20, 60),   -- More downward motion from exhaust
            r = color[1] or 0.3,
            g = color[2] or 0.7,
            b = color[3] or 1,
            size = math.random(0.2, 0.21),      -- Even smaller particles
            sizeStart = math.random(0.2, 0.21), -- Even smaller particles
            sizeEnd = 0,
            life = math.random(0.08, 0.2),   -- Shorter lifetime
            maxLife = math.random(0.08, 0.2),
            type = "circle",
            ay = -20,  -- Less upward acceleration
            drag = 0.98
        })
    end
end

function ParticleSystem:addBoostTrail(x, y, vx, vy)
    -- Core particles (white-hot) - much smaller
    for i = 1, math.random(2, 4) do  -- Reduced count
        table.insert(self.particles, {
            x         = x + math.random(-1, 1),
            y         = y + math.random(-1, 1),
            vx        = vx + math.random(-10, 10),
            vy        = vy + math.random(60, 100),
            r         = 1,   g = 1,         b = 1,
            size      = math.random(0.4, 0.7),  -- Much smaller
            sizeStart = math.random(0.4, 0.7),  -- Much smaller
            sizeEnd   = 0,
            life      = math.random(0.08, 0.15),  -- Shorter life
            maxLife   = math.random(0.08, 0.15),
            type      = "circle",
            ay        = -80,
            drag      = 0.9,
        })
    end

    -- Outer flare (orange → red → bluish) - much smaller
    for i = 1, math.random(3, 6) do  -- Reduced count
        local life = math.random(0.15, 0.3)  -- Shorter life
        table.insert(self.particles, {
            x         = x + math.random(-2, 2),
            y         = y + math.random(-1, 1),
            vx        = vx + math.random(-15, 15),
            vy        = vy + math.random(40, 70),
            -- start orange-red:
            r         = 1,
            g         = math.random(0.4, 0.6),
            b         = math.random(0, 0.2),
            size      = math.random(0.3, 0.35),  -- Much smaller
            sizeStart = math.random(0.3, 0.35),  -- Much smaller
            sizeEnd   = 0,
            life      = life,
            maxLife   = life,
            type      = "circle",
            ay        = -50,
            drag      = 0.95,
            -- color ramp function to shift toward blue/gray:
            updateColor = function(p, dt)
                local t = p.life / p.maxLife
                -- as t→0, shift from orange to gray
                p.r = 1 - (1 - 0.6)*(1 - t)
                p.g = p.g * t
                p.b = p.b + (1 - t)*0.3
            end
        })
    end
end


-- Explosion effect for collisions
function ParticleSystem:addExplosion(x, y, intensity)
    intensity = intensity or 1
    local particleCount = math.floor(15 * intensity)
    
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = math.random(100, 300) * intensity
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = 1,
            g = math.random(0.3, 0.8),
            b = math.random(0, 0.4),
            size = math.random(3, 8),
            sizeStart = math.random(3, 8),
            sizeEnd = 0,
            life = math.random(0.5, 1.2),
            maxLife = math.random(0.5, 1.2),
            type = "circle",
            ay = 100,
            drag = 0.9
        })
    end
    
    -- Add some sparks
    for i = 1, math.floor(8 * intensity) do
        local angle = math.random() * math.pi * 2
        local speed = math.random(200, 500) * intensity
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = 1,
            g = 1,
            b = math.random(0.5, 1),
            size = math.random(1, 3),
            life = math.random(0.2, 0.5),
            maxLife = math.random(0.2, 0.5),
            type = "spark",
            drag = 0.85
        })
    end
end

-- Power-up collection effect
function ParticleSystem:addPowerUpEffect(x, y)
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2
        local speed = math.random(80, 200)
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = math.random(0.2, 0.8),
            g = 1,
            b = math.random(0.3, 0.9),
            size = math.random(2, 5),
            sizeStart = math.random(2, 5),
            sizeEnd = 0,
            life = math.random(0.8, 1.5),
            maxLife = math.random(0.8, 1.5),
            type = "circle",
            ay = -30,
            drag = 0.95
        })
    end
end

-- Asteroid entry effect
function ParticleSystem:addAsteroidEntry(x, y, width, height)
    for i = 1, 8 do
        table.insert(self.particles, {
            x = x + math.random(0, width),
            y = y + math.random(0, height),
            vx = math.random(-100, 100),
            vy = math.random(50, 150),
            r = 1,
            g = math.random(0.6, 1),
            b = math.random(0.2, 0.6),
            size = math.random(2, 5),
            sizeStart = math.random(2, 5),
            sizeEnd = 0,
            life = math.random(0.3, 0.8),
            maxLife = math.random(0.3, 0.8),
            type = "circle",
            drag = 0.9
        })
    end
end

-- Warning pulse effect
function ParticleSystem:addWarningPulse(x, y)
    for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2
        local speed = math.random(30, 80)
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = 1,
            g = math.random(0, 0.3),
            b = math.random(0, 0.2),
            size = math.random(0.5, 1),      -- Much smaller particles
            sizeStart = math.random(0.5, 1), -- Much smaller particles
            sizeEnd = 0,
            life = math.random(0.4, 0.8),
            maxLife = math.random(0.4, 0.8),
            type = "circle",
            drag = 0.95
        })
    end
    
    -- Add a warning pulse for close call detection
    local pulse = {
        x = x,
        y = y,
        life = 0.8,
        maxLife = 0.8,
        scale = 0.5,
        alpha = 1.0,
        color = {1, 0.7, 0}  -- Orange warning color
    }
    table.insert(self.warningPulses, pulse)
end

-- Screen flash effect
function ParticleSystem:addScreenFlash(windowWidth, windowHeight, color, intensity)
    intensity = intensity or 1
    color = color or {1, 1, 1}
    
    table.insert(self.particles, {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        width = windowWidth,
        height = windowHeight,
        r = color[1],
        g = color[2],
        b = color[3],
        alpha = 0.3 * intensity,
        alphaStart = 0.3 * intensity,
        alphaEnd = 0,
        life = 0.2,
        maxLife = 0.2,
        type = "screen_flash"
    })
end

-- Draw screen flash
function ParticleSystem:drawScreenEffects()
    for _, p in ipairs(self.particles) do
        if p.type == "screen_flash" then
            love.graphics.setColor(p.r, p.g, p.b, p.alpha or (p.life / p.maxLife))
            love.graphics.rectangle("fill", p.x, p.y, p.width, p.height)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ParticleSystem
