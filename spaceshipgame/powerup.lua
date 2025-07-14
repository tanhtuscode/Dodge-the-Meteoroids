local PowerUp = {}
PowerUp.__index = PowerUp

function PowerUp.new(x, y, radius, speed)
    local self = setmetatable({}, PowerUp)
    self.x = x
    self.y = y
    self.radius = radius
    self.speed = speed
    self.time = 0
    self.pulsePhase = math.random() * math.pi * 2
    return self
end

function PowerUp:update(dt, scoreMultiplier)
    local blockSpeedMultiplier = 1 + 0.5 * (scoreMultiplier - 1)
    self.y = self.y + self.speed * dt * blockSpeedMultiplier
    self.time = self.time + dt
end

function PowerUp:draw()
    -- Enhanced power-up with multiple effects
    local t = love.timer.getTime() + self.pulsePhase
    local pulse = 1 + 0.2 * math.sin(t * 4)
    local innerPulse = 1 + 0.12 * math.sin(t * 6)
    local rotation = t * 2
    
    -- Outer energy ring with rotation
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(rotation)
    
    -- Multiple outer rings for depth
    for i = 1, 3 do
        local ringScale = pulse * (2 + i * 0.3)
        local alpha = 0.08 - i * 0.02
        love.graphics.setColor(0.2 + i * 0.1, 1, 0.4 + i * 0.1, alpha)
        love.graphics.circle("line", 0, 0, self.radius * ringScale)
        love.graphics.setLineWidth(2)
    end
    love.graphics.setLineWidth(1)
    love.graphics.pop()
    
    -- Main energy field
    love.graphics.setColor(0.3, 1, 0.5, 0.15)
    love.graphics.circle("fill", self.x, self.y, self.radius * 2.5 * pulse)
    
    -- Secondary glow
    love.graphics.setColor(0.4, 1, 0.6, 0.3)
    love.graphics.circle("fill", self.x, self.y, self.radius * 1.8 * pulse)
    
    -- Core with star shape for power-up look
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(rotation * 0.5)
    
    -- 5-pointed star core
    local starPoints = {}
    local outerRadius = self.radius * innerPulse
    local innerRadius = outerRadius * 0.4
    
    for i = 0, 9 do  -- 10 points total (5 outer + 5 inner)
        local angle = (i / 10) * math.pi * 2
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        table.insert(starPoints, math.cos(angle) * radius)
        table.insert(starPoints, math.sin(angle) * radius)
    end
    
    love.graphics.setColor(0.1, 0.9, 0.3, 0.95)
    love.graphics.polygon("fill", starPoints)
    
    -- Inner bright center
    love.graphics.setColor(0.6, 1, 0.8, 0.9)
    love.graphics.circle("fill", 0, 0, self.radius * 0.3 * innerPulse)
    
    love.graphics.pop()
    
    -- Energy sparks
    if math.random() < 0.3 then
        local sparkX = self.x + math.random(-self.radius * 2, self.radius * 2)
        local sparkY = self.y + math.random(-self.radius * 2, self.radius * 2)
        love.graphics.setColor(1, 1, 0.8, 0.8)
        love.graphics.circle("fill", sparkX, sparkY, 1)
    end
end

return PowerUp
