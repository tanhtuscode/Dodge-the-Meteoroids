local Meteoroid = {}
Meteoroid.__index = Meteoroid

-- Create a new Meteoroid with custom pixel art
-- x, y: starting position
-- width, height: desired dimensions
-- speed: falling speed
-- meteoroidType: 1-4 for different visual styles
function Meteoroid.new(x, y, width, height, speed, meteoroidType)
    local self = setmetatable({}, Meteoroid)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.speed = speed
    self.rotation = 0
    self.rotationSpeed = math.random(-5, 5)
    self.time = math.random() * math.pi * 2 -- Random start phase
    self.meteoroidType = meteoroidType or math.random(1, 4)
    
    -- Trail system
    self.trail = {}
    self.trailMaxLength = 8  -- Number of trail segments
    self.trailTimer = 0
    self.trailInterval = 0.05  -- Add trail point every 0.05 seconds
    
    return self
end

function Meteoroid:update(dt, scoreMultiplier)
    local meteoroidSpeedMultiplier = 1 + 0.3 * (scoreMultiplier - 1)
    self.y = self.y + self.speed * dt * meteoroidSpeedMultiplier
    self.rotation = self.rotation + self.rotationSpeed * dt
    self.time = self.time + dt
    
    -- Update trail
    self.trailTimer = self.trailTimer + dt
    if self.trailTimer >= self.trailInterval then
        self.trailTimer = 0
        
        -- Add current position to trail
        table.insert(self.trail, 1, {
            x = self.x + self.width / 2,
            y = self.y + self.height / 2,
            rotation = self.rotation
        })
        
        -- Keep trail at max length
        if #self.trail > self.trailMaxLength then
            table.remove(self.trail)
        end
    end
end

function Meteoroid:drawPixelAsteroid()
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(self.rotation)
    
    -- Enhanced visibility effects
    local time = love.timer.getTime()
    local pulseScale = 1 + 0.15 * math.sin(time * 3 + self.x * 0.01)
    local glowIntensity = 0.6 + 0.4 * math.abs(math.sin(time * 2))
    
    -- Color scheme based on meteoroid type with enhanced contrast
    local colors = {
        {0.6, 0.5, 0.4}, -- Lighter gray
        {0.7, 0.4, 0.2}, -- Brighter brown
        {0.4, 0.4, 0.7}, -- Brighter blue-gray
        {0.6, 0.3, 0.4}  -- Brighter dark red
    }
    local baseColor = colors[self.meteoroidType]
    
    -- Scale factor
    local scale = math.min(self.width, self.height) / 50
    
    -- Add warning glow aura around meteoroid
    love.graphics.setColor(1, 0.3, 0.2, 0.3 * glowIntensity)
    local glowScale = scale * pulseScale * 1.5
    if self.meteoroidType == 2 then
        love.graphics.circle("fill", 0, 0, 20 * glowScale)
    else
        -- Glow for polygonal asteroids
        if self.meteoroidType == 1 then
            love.graphics.polygon("fill", 
                -18*glowScale, -12*glowScale, -10*glowScale, -21*glowScale, 
                6*glowScale, -18*glowScale, 21*glowScale, -6*glowScale, 
                15*glowScale, 10*glowScale, -2*glowScale, 19*glowScale,
                -15*glowScale, 12*glowScale, -21*glowScale, 2*glowScale
            )
        elseif self.meteoroidType == 3 then
            love.graphics.polygon("fill",
                -15*glowScale, -15*glowScale, 15*glowScale, -10*glowScale,
                19*glowScale, 7*glowScale, 10*glowScale, 17*glowScale,
                -10*glowScale, 15*glowScale, -19*glowScale, 0*glowScale
            )
        else
            love.graphics.polygon("fill",
                -10*glowScale, -19*glowScale, 10*glowScale, -15*glowScale,
                15*glowScale, 0*glowScale, 7*glowScale, 19*glowScale,
                -7*glowScale, 17*glowScale, -17*glowScale, 5*glowScale,
                -12*glowScale, -10*glowScale
            )
        end
    end
    
    -- Different asteroid shapes based on type
    if self.meteoroidType == 1 then
        -- Jagged asteroid
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3])
        love.graphics.polygon("fill", 
            -15*scale, -10*scale,  -- top left
            -8*scale, -18*scale,   -- top
            5*scale, -15*scale,    -- top right
            18*scale, -5*scale,    -- right
            12*scale, 8*scale,     -- bottom right
            -2*scale, 16*scale,    -- bottom
            -12*scale, 10*scale,   -- bottom left
            -18*scale, 2*scale     -- left
        )
        -- Highlight
        love.graphics.setColor(baseColor[1] + 0.2, baseColor[2] + 0.2, baseColor[3] + 0.2)
        love.graphics.polygon("fill",
            -15*scale, -10*scale,
            -8*scale, -18*scale,
            -5*scale, -12*scale,
            -12*scale, -5*scale
        )
        
    elseif self.meteoroidType == 2 then
        -- Round asteroid with craters
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3])
        love.graphics.circle("fill", 0, 0, 16*scale)
        -- Craters
        love.graphics.setColor(baseColor[1] - 0.1, baseColor[2] - 0.1, baseColor[3] - 0.1)
        love.graphics.circle("fill", -6*scale, -4*scale, 4*scale)
        love.graphics.circle("fill", 8*scale, 2*scale, 3*scale)
        love.graphics.circle("fill", 2*scale, 8*scale, 2*scale)
        
    elseif self.meteoroidType == 3 then
        -- Angular asteroid
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3])
        love.graphics.polygon("fill",
            -12*scale, -12*scale,  -- top left
            12*scale, -8*scale,    -- top right
            16*scale, 6*scale,     -- right
            8*scale, 14*scale,     -- bottom right
            -8*scale, 12*scale,    -- bottom left
            -16*scale, 0*scale     -- left
        )
        -- Edge highlight
        love.graphics.setColor(baseColor[1] + 0.15, baseColor[2] + 0.15, baseColor[3] + 0.15)
        love.graphics.polygon("fill",
            -12*scale, -12*scale,
            12*scale, -8*scale,
            8*scale, -4*scale,
            -8*scale, -8*scale
        )
        
    else -- type 4
        -- Elongated asteroid
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3])
        love.graphics.polygon("fill",
            -8*scale, -16*scale,   -- top
            8*scale, -12*scale,    -- top right
            12*scale, 0*scale,     -- middle right
            6*scale, 16*scale,     -- bottom right
            -6*scale, 14*scale,    -- bottom left
            -14*scale, 4*scale,    -- left
            -10*scale, -8*scale    -- top left
        )
        -- Surface detail
        love.graphics.setColor(baseColor[1] + 0.1, baseColor[2] + 0.1, baseColor[3] + 0.1)
        love.graphics.polygon("fill",
            -8*scale, -16*scale,
            8*scale, -12*scale,
            2*scale, -6*scale,
            -4*scale, -10*scale
        )
    end
    
    -- Add enhanced glowing outline for better visibility
    love.graphics.setColor(1, 0.6, 0.2, 0.8 * glowIntensity)
    love.graphics.setLineWidth(3)
    if self.meteoroidType == 2 then
        love.graphics.circle("line", 0, 0, 16*scale)
    else
        -- Outline for polygonal asteroids
        local outlinePoints = {}
        if self.meteoroidType == 1 then
            outlinePoints = {
                -15*scale, -10*scale, -8*scale, -18*scale, 5*scale, -15*scale,
                18*scale, -5*scale, 12*scale, 8*scale, -2*scale, 16*scale,
                -12*scale, 10*scale, -18*scale, 2*scale
            }
        elseif self.meteoroidType == 3 then
            outlinePoints = {
                -12*scale, -12*scale, 12*scale, -8*scale, 16*scale, 6*scale,
                8*scale, 14*scale, -8*scale, 12*scale, -16*scale, 0*scale
            }
        else
            outlinePoints = {
                -8*scale, -16*scale, 8*scale, -12*scale, 12*scale, 0*scale,
                6*scale, 16*scale, -6*scale, 14*scale, -14*scale, 4*scale,
                -10*scale, -8*scale
            }
        end
        love.graphics.polygon("line", unpack(outlinePoints))
    end
    
    -- Add secondary subtle outline for depth
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.setLineWidth(1)
    if self.meteoroidType == 2 then
        love.graphics.circle("line", 0, 0, 16*scale)
    else
        -- Outline for polygonal asteroids
        local outlinePoints = {}
        if self.meteoroidType == 1 then
            outlinePoints = {
                -15*scale, -10*scale, -8*scale, -18*scale, 5*scale, -15*scale,
                18*scale, -5*scale, 12*scale, 8*scale, -2*scale, 16*scale,
                -12*scale, 10*scale, -18*scale, 2*scale
            }
        elseif self.meteoroidType == 3 then
            outlinePoints = {
                -12*scale, -12*scale, 12*scale, -8*scale, 16*scale, 6*scale,
                8*scale, 14*scale, -8*scale, 12*scale, -16*scale, 0*scale
            }
        else
            outlinePoints = {
                -8*scale, -16*scale, 8*scale, -12*scale, 12*scale, 0*scale,
                6*scale, 16*scale, -6*scale, 14*scale, -14*scale, 4*scale,
                -10*scale, -8*scale
            }
        end
        love.graphics.polygon("line", unpack(outlinePoints))
    end
    
    love.graphics.pop()
end

function Meteoroid:drawTrail()
    -- Draw trail behind the asteroid
    for i, trailPoint in ipairs(self.trail) do
        local alpha = (self.trailMaxLength - i + 1) / self.trailMaxLength * 0.4
        local size = (self.trailMaxLength - i + 1) / self.trailMaxLength * 0.6
        
        -- Color based on meteoroid type
        local colors = {
            {0.4, 0.4, 0.4}, -- Gray
            {0.5, 0.3, 0.2}, -- Brown
            {0.3, 0.3, 0.5}, -- Blue-gray
            {0.4, 0.2, 0.3}  -- Dark red
        }
        local baseColor = colors[self.meteoroidType]
        
        love.graphics.push()
        love.graphics.translate(trailPoint.x, trailPoint.y)
        love.graphics.rotate(trailPoint.rotation)
        
        -- Draw small simplified trail particles
        local scale = math.min(self.width, self.height) / 50 * size
        
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], alpha)
        
        if self.meteoroidType == 2 then
            -- Circle trail for round asteroids
            love.graphics.circle("fill", 0, 0, 6*scale)
        else
            -- Diamond/square trail for angular asteroids
            love.graphics.polygon("fill",
                -4*scale, 0,
                0, -4*scale,
                4*scale, 0,
                0, 4*scale
            )
        end
        
        love.graphics.pop()
    end
end

function Meteoroid:draw(scoreMultiplier)
    -- Draw trail first (behind asteroid)
    self:drawTrail()
    -- Then draw the main asteroid
    self:drawPixelAsteroid()
end

return Meteoroid
