local Player = {}
Player.__index = Player

-- Creates a new Player.
-- x, y: starting position
-- width, height: dimensions
-- speed: movement speed
-- No textures needed - using custom pixel art
function Player.new(x, y, width, height, speed, spaceshipTextures)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.speed = speed
    
    -- Animation system (no textures needed)
    self.currentColor = "blue"  -- "blue" or "red"
    self.animationState = "idle" -- "idle", "left", "right"
    self.frameIndex = 1  -- 1=idle, 2=left, 3=right
    self.animationTimer = 0  -- For smooth animation transitions
    
    -- Power-up system
    self.isPoweredUp = false
    self.powerUpTimer = 0
    self.powerUpDuration = 10  -- Duration of red variant after power-up
    
    -- Effects
    self.time = 0
    
    -- Smooth movement system
    self.velocityX = 0
    self.velocityY = 0
    self.acceleration = 1200
    self.friction = 8
    
    return self
end

function Player:update(dt, windowWidth, windowHeight)
    self.time = self.time + dt
    
    -- Update power-up timer
    if self.isPoweredUp then
        self.powerUpTimer = self.powerUpTimer - dt
        if self.powerUpTimer <= 0 then
            self.isPoweredUp = false
            self.currentColor = "blue"
        end
    end
    
    -- Adjust speed if powered up - significantly faster for better control feel
    local baseSpeed = self.speed
    if self.isPoweredUp then
        self.speed = baseSpeed * 1.8  -- 80% speed increase for exciting boost feel
    else
        self.speed = baseSpeed
    end
    
    -- Update animation state and smooth movement
    local targetVelX, targetVelY = 0, 0
    local maxSpeed = self.speed
    local isMovingHorizontally = false
    
    self.animationTimer = self.animationTimer + dt
    
    if love.keyboard.isDown("left") then
        targetVelX = -maxSpeed
        if self.animationState ~= "left" then
            self.animationState = "left"
            self.frameIndex = 2  -- Frame 02 (leaning left)
            self.animationTimer = 0
        end
        isMovingHorizontally = true
    elseif love.keyboard.isDown("right") then
        targetVelX = maxSpeed
        if self.animationState ~= "right" then
            self.animationState = "right"
            self.frameIndex = 2  -- Frame 02 (leaning, will be flipped for right)
            self.animationTimer = 0
        end
        isMovingHorizontally = true
    end
    
    if love.keyboard.isDown("up") then
        targetVelY = -maxSpeed
    end
    if love.keyboard.isDown("down") then
        targetVelY = maxSpeed
    end
    
    -- Smooth acceleration/deceleration with boost enhancement
    local accel = self.acceleration * dt
    local responsiveness = self.friction
    if self.isPoweredUp then
        responsiveness = self.friction * 1.5  -- 50% more responsive when boosted
    end
    
    self.velocityX = self.velocityX + (targetVelX - self.velocityX) * responsiveness * dt
    self.velocityY = self.velocityY + (targetVelY - self.velocityY) * responsiveness * dt
    
    -- Apply velocity to position
    self.x = self.x + self.velocityX * dt
    self.y = self.y + self.velocityY * dt
    
    -- Boundary checking for both x and y
    local minY = 0
    local maxY = (windowHeight or 600) - self.height
    if self.x < 0 then 
        self.x = 0
        self.velocityX = 0
    end
    if self.x + self.width > windowWidth then
        self.x = windowWidth - self.width
        self.velocityX = 0
    end
    if self.y < minY then 
        self.y = minY
        self.velocityY = 0
    end
    if self.y > maxY then 
        self.y = maxY
        self.velocityY = 0
    end
    
    -- Update animation when not moving horizontally (with small delay for smooth transition)
    if not isMovingHorizontally then
        if self.animationTimer > 0.1 then  -- Small delay before returning to idle
            self.animationState = "idle"
            self.frameIndex = 1  -- Frame 01 (idle)
        end
    end
end

function Player:draw()
    -- Hover effect
    local hoverOffset = math.sin(self.time * 3) * 2
    
    -- Center position for ship
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2 + hoverOffset
    
    -- Enhanced boost aura with multiple layers if powered up
    if self.isPoweredUp then
        local t = self.time
        local auraAlpha = 0.15 + 0.1 * math.sin(t * 5)
        local auraPulse = 1 + 0.15 * math.sin(t * 4)
        local auraPulse2 = 1 + 0.08 * math.sin(t * 6)
        
        -- Outer energy field
        love.graphics.setColor(1, 0.2, 0.05, auraAlpha * 0.5)
        love.graphics.ellipse("fill", centerX, centerY, 
                             self.width * 1.2 * auraPulse, self.height * 1.0 * auraPulse)
        
        -- Middle aura layer
        love.graphics.setColor(1, 0.4, 0.1, auraAlpha * 0.8)
        love.graphics.ellipse("fill", centerX, centerY, 
                             self.width * 0.9 * auraPulse2, self.height * 0.8 * auraPulse2)
        
        -- Inner bright core
        love.graphics.setColor(1, 0.7, 0.3, auraAlpha)
        love.graphics.ellipse("fill", centerX, centerY, 
                             self.width * 0.6 * auraPulse, self.height * 0.5 * auraPulse)
        
        -- Energy sparks around the ship
        for i = 1, 3 do
            if math.random() < 0.4 then
                local angle = math.random() * math.pi * 2
                local distance = math.random(30, 50)
                local sparkX = centerX + math.cos(angle) * distance
                local sparkY = centerY + math.sin(angle) * distance
                love.graphics.setColor(1, 0.8, 0.4, 0.8)
                love.graphics.circle("fill", sparkX, sparkY, 2)
            end
        end
    end
    
    -- Draw custom pixel art ship
    self:drawPixelShip(centerX, centerY)
end

function Player:drawPixelShip(centerX, centerY)
    -- Calculate lean offset and rotation based on animation state with smooth transitions
    local leanOffset = 0
    local leanRotation = 0
    local leanIntensity = 1
    
    -- Smooth lean transitions based on animation state
    if self.animationState == "left" then
        leanOffset = -4  -- More pronounced lean
        leanRotation = -0.15  -- Slight rotation to the left
        leanIntensity = 1.1  -- Slightly more intense colors
    elseif self.animationState == "right" then
        leanOffset = 4   -- More pronounced lean
        leanRotation = 0.15   -- Slight rotation to the right
        leanIntensity = 1.1   -- Slightly more intense colors
    else
        -- Smooth return to center when idle
        local smoothFactor = math.max(0, 1 - self.animationTimer * 5)  -- Quick return to center
        leanOffset = leanOffset * smoothFactor
        leanRotation = leanRotation * smoothFactor
        leanIntensity = 1 + (leanIntensity - 1) * smoothFactor
    end
    
    -- Add subtle oscillation when moving for more dynamic feel
    if self.velocityX ~= 0 or self.velocityY ~= 0 then
        leanOffset = leanOffset + math.sin(self.time * 8) * 0.5
        leanRotation = leanRotation + math.sin(self.time * 6) * 0.02
    end
    
    -- Exact colors from the pixel art image with lean intensity modulation
    local darkBlue = {0.1 * leanIntensity, 0.2 * leanIntensity, 0.4 * leanIntensity}
    local mediumBlue = {0.2 * leanIntensity, 0.4 * leanIntensity, 0.7 * leanIntensity}
    local lightBlue = {0.4 * leanIntensity, 0.6 * leanIntensity, 0.9 * leanIntensity}
    local veryLightBlue = {0.6 * leanIntensity, 0.8 * leanIntensity, 1.0 * leanIntensity}
    local whiteGray = {0.85 * leanIntensity, 0.9 * leanIntensity, 0.95 * leanIntensity}
    local darkGray = {0.3 * leanIntensity, 0.35 * leanIntensity, 0.4 * leanIntensity}
    
    -- Power-up color override
    if self.isPoweredUp then
        darkBlue = {0.4 * leanIntensity, 0.1, 0.1}
        mediumBlue = {0.7 * leanIntensity, 0.2, 0.2}
        lightBlue = {0.9 * leanIntensity, 0.4, 0.4}
        veryLightBlue = {1.0 * leanIntensity, 0.6, 0.6}
        whiteGray = {1.0 * leanIntensity, 0.8, 0.8}
        darkGray = {0.3, 0.1, 0.1}
    end
    
    -- Apply rotation for lean effect
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(leanRotation)
    love.graphics.translate(-centerX, -centerY)
    
    -- Scale factor to match the image proportions
    local scale = 0.8
    
    -- CENTER MAIN BODY (Dark blue triangle core)
    love.graphics.setColor(darkBlue)
    love.graphics.polygon("fill",
        centerX + leanOffset, centerY - 28*scale,        -- Top point
        centerX - 12*scale + leanOffset, centerY + 8*scale,    -- Bottom left
        centerX + 12*scale + leanOffset, centerY + 8*scale     -- Bottom right
    )
    
    -- MEDIUM BLUE BODY SECTIONS (Main fuselage)
    love.graphics.setColor(mediumBlue)
    -- Left body section
    love.graphics.polygon("fill",
        centerX - 8*scale + leanOffset, centerY - 20*scale,
        centerX - 12*scale + leanOffset, centerY - 5*scale,
        centerX - 8*scale + leanOffset, centerY + 8*scale,
        centerX - 4*scale + leanOffset, centerY - 8*scale
    )
    -- Right body section
    love.graphics.polygon("fill",
        centerX + 8*scale + leanOffset, centerY - 20*scale,
        centerX + 12*scale + leanOffset, centerY - 5*scale,
        centerX + 8*scale + leanOffset, centerY + 8*scale,
        centerX + 4*scale + leanOffset, centerY - 8*scale
    )
    
    -- LIGHT BLUE HIGHLIGHTS (Upper sections)
    love.graphics.setColor(lightBlue)
    -- Center top highlight
    love.graphics.polygon("fill",
        centerX + leanOffset, centerY - 28*scale,
        centerX - 6*scale + leanOffset, centerY - 12*scale,
        centerX + 6*scale + leanOffset, centerY - 12*scale
    )
    
    -- WHITE-GRAY WING EXTENSIONS
    love.graphics.setColor(whiteGray)
    -- Left wing
    love.graphics.polygon("fill",
        centerX - 12*scale + leanOffset, centerY - 5*scale,
        centerX - 22*scale + leanOffset, centerY - 2*scale,
        centerX - 20*scale + leanOffset, centerY + 5*scale,
        centerX - 12*scale + leanOffset, centerY + 8*scale
    )
    -- Right wing  
    love.graphics.polygon("fill",
        centerX + 12*scale + leanOffset, centerY - 5*scale,
        centerX + 22*scale + leanOffset, centerY - 2*scale,
        centerX + 20*scale + leanOffset, centerY + 5*scale,
        centerX + 12*scale + leanOffset, centerY + 8*scale
    )
    
    -- WING TIPS (Extended white sections)
    love.graphics.setColor(whiteGray)
    -- Left wing tip
    love.graphics.polygon("fill",
        centerX - 22*scale + leanOffset, centerY - 2*scale,
        centerX - 28*scale + leanOffset, centerY + 1*scale,
        centerX - 24*scale + leanOffset, centerY + 6*scale,
        centerX - 20*scale + leanOffset, centerY + 5*scale
    )
    -- Right wing tip
    love.graphics.polygon("fill",
        centerX + 22*scale + leanOffset, centerY - 2*scale,
        centerX + 28*scale + leanOffset, centerY + 1*scale,
        centerX + 24*scale + leanOffset, centerY + 6*scale,
        centerX + 20*scale + leanOffset, centerY + 5*scale
    )
    
    -- COCKPIT AREA (Very light blue center)
    love.graphics.setColor(veryLightBlue)
    love.graphics.polygon("fill",
        centerX + leanOffset, centerY - 22*scale,
        centerX - 4*scale + leanOffset, centerY - 15*scale,
        centerX + 4*scale + leanOffset, centerY - 15*scale
    )
    
    -- DARK DETAILS (Engine areas and accents)
    love.graphics.setColor(darkGray)
    -- Left engine detail
    love.graphics.rectangle("fill", centerX - 10*scale + leanOffset, centerY + 6*scale, 3*scale, 4*scale)
    -- Right engine detail
    love.graphics.rectangle("fill", centerX + 7*scale + leanOffset, centerY + 6*scale, 3*scale, 4*scale)
    
    -- THRUSTER FLAMES (when moving or powered up)
    if self.isPoweredUp or self.velocityX ~= 0 or self.velocityY ~= 0 then
        local thrusterColor = self.isPoweredUp and {1, 0.6, 0.2} or {0.3, 0.7, 1}
        love.graphics.setColor(thrusterColor)
        -- Left thruster
        love.graphics.polygon("fill",
            centerX - 10*scale + leanOffset, centerY + 10*scale,
            centerX - 7*scale + leanOffset, centerY + 10*scale,
            centerX - 8.5*scale + leanOffset, centerY + 16*scale
        )
        -- Right thruster
        love.graphics.polygon("fill",
            centerX + 7*scale + leanOffset, centerY + 10*scale,
            centerX + 10*scale + leanOffset, centerY + 10*scale,
            centerX + 8.5*scale + leanOffset, centerY + 16*scale
        )
    end
    
    -- OUTLINE for definition (very subtle)
    love.graphics.setColor(0.05, 0.05, 0.1, 0.3)
    love.graphics.setLineWidth(1)
    -- Main body outline
    love.graphics.polygon("line",
        centerX + leanOffset, centerY - 28*scale,
        centerX - 28*scale + leanOffset, centerY + 1*scale,
        centerX - 12*scale + leanOffset, centerY + 8*scale,
        centerX + 12*scale + leanOffset, centerY + 8*scale,
        centerX + 28*scale + leanOffset, centerY + 1*scale
    )
    
    -- Restore graphics transformation
    love.graphics.pop()
end

-- Reset player state (useful for game restart)
function Player:reset()
    self.isPoweredUp = false
    self.powerUpTimer = 0
    self.currentColor = "blue"
    self.frameIndex = 1
    self.animationState = "idle"
    self.velocityX = 0
    self.velocityY = 0
end

-- Power-up methods
function Player:activatePowerUp()
    self.isPoweredUp = true
    self.currentColor = "red"
    self.powerUpTimer = self.powerUpDuration
end

function Player:getCurrentTexture()
    return self.textures[self.currentColor][self.frameIndex]
end

-- Collision detection
function Player:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return Player
