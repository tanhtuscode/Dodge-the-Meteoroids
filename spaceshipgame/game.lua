local Player = require("player")
local Meteoroid = require("meteoroid")
local PowerUp = require("powerup")
local AssetInitializer = require("assetinitializer")
local ParticleSystem = require("particlesystem")

local Game = {}
Game.__index = Game

-- Helper collision function
local function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function Game.new()
    local self = setmetatable({}, Game)
    self.windowWidth = love.graphics.getWidth()
    self.windowHeight = love.graphics.getHeight()
    
    -- Initialize asset management system
    self.assetManager = AssetInitializer.quickDevSetup()
    
    -- Enhanced fonts using asset manager
    local vcrFont = love.graphics.newFont("assets/fonts/VCR_OSD_MONO_1.001.ttf", 24)
    local vcrTitleFont = love.graphics.newFont("assets/fonts/VCR_OSD_MONO_1.001.ttf", 48)
    self.font = vcrFont
    self.titleFont = vcrTitleFont
    self.smallFont = love.graphics.newFont("assets/fonts/VCR_OSD_MONO_1.001.ttf", 16)
    love.graphics.setFont(self.font)
    
    self.score = 0
    self.scoreMultiplier = 1
    self.multiplierTimer = 0
    self.multiplierDuration = 10
    
    -- Animated score system
    self.displayScore = 0
    self.scoreAnimTimer = 0
    self.lastScoreIncrease = 0
    
    -- High score tracking
    self.highScore = self:loadHighScore()
    
    -- Popup notification system
    self.popups = {}
    self.lastScoreMilestone = 0
    self.scoreMilestones = {100, 250, 500, 750, 1000, 1500, 2000, 3000, 5000, 7500, 10000}
    
    -- Close call system (more generous settings)
    self.closeCallDistance = 25 -- Increased pixels for close call detection
    self.closeCallStreak = 0
    self.closeCallTimer = 0
    self.closeCallCooldown = 0.3 -- Shorter cooldown for more frequent close calls
    
    -- Game state
    self.gameState = "menu" -- "menu", "playing", "exploding", "gameOver", "credits"
    
    -- Explosion animation settings
    self.explosionTimer = 0
    self.explosionDuration = 1.5  -- 1.5 seconds of explosion animation
    
    -- Initialize particle system
    self.particleSystem = ParticleSystem.new()
    
    -- Visual effects
    self.stars = {}
    self.shakeTimer = 0
    self.shakeIntensity = 0
    
    -- Generate enhanced starfield background with multiple star types
    for i = 1, 200 do
        local starType = math.random(1, 3)
        local depth = math.random(1, 3) -- Add depth layers
        table.insert(self.stars, {
            x = math.random(0, self.windowWidth),
            y = math.random(0, self.windowHeight),
            speed = math.random(20, 80) * depth,
            size = math.random(0.5, 3) / depth,
            brightness = math.random(0.2, 0.9),
            depth = depth,
            twinkleTimer = math.random() * 2,
            twinkleSpeed = math.random(2, 6),
            color = {
                math.random(0.8, 1),
                math.random(0.8, 1),
                math.random(0.9, 1)
            }
        })
    end
    
    self.spawnInterval = 0.8
    self.meteoroidTimer = 0
    self.meteoroids = {}
    self.pendingWarnings = {}
    
    self.powerUpSpawnInterval = 6
    self.powerUpSpawnTimer = 0
    self.powerUp = nil

    self.player = Player.new((self.windowWidth - 80) / 2, self.windowHeight - 80 - 10, 80, 60, 300, nil)
    
    -- Menu buttons
    self.retryButton = { x = (self.windowWidth - 150) / 2, y = self.windowHeight / 2 + 60, width = 150, height = 50 }
    self.menuButton = { x = (self.windowWidth - 150) / 2, y = self.windowHeight / 2 + 120, width = 150, height = 50 }
    
    -- Main menu buttons (4 buttons now)
    local buttonW, buttonH = 220, 56
    local buttonSpacing = 20
    local centerX = (self.windowWidth - buttonW) / 2
    local startY = self.windowHeight / 2 + 50
    
    self.playButton = { x = centerX, y = startY, width = buttonW, height = buttonH }
    self.tutorialButton = { x = centerX, y = startY + buttonH + buttonSpacing, width = buttonW, height = buttonH }
    self.creditsButton = { x = centerX, y = startY + (buttonH + buttonSpacing) * 2, width = buttonW, height = buttonH }
    self.exitButton = { x = centerX, y = startY + (buttonH + buttonSpacing) * 3, width = buttonW, height = buttonH }
    self.gameOver = false

    return self
end

function Game:reset()
    self.player.x = (self.windowWidth - self.player.width) / 2
    self.player.y = self.windowHeight - self.player.height - 10
    self.player:reset()  -- Reset player power-up state
    self.meteoroids = {}
    self.meteoroidTimer = 0
    self.powerUp = nil
    self.powerUpSpawnTimer = 0
    self.score = 0
    self.scoreMultiplier = 1
    self.multiplierTimer = 0
    self.spawnInterval = 0.8
    self.powerUpSpawnInterval = 6
    self.gameState = "playing"
    self.shakeTimer = 0
    self.shakeIntensity = 0
    self.pendingWarnings = {}
    
    -- Reset particle system
    self.particleSystem = ParticleSystem.new()
    
    -- Reset popup system
    self.popups = {}
    self.lastScoreMilestone = 0
    
    -- Reset close call system
    self.closeCallStreak = 0
    self.closeCallCooldown = 0
    
    -- Reset explosion state
    self.explosionTimer = 0
    
    -- Regenerate stars
    self.stars = {}
    for i = 1, 200 do
        local starType = math.random(1, 3)
        local depth = math.random(1, 3) -- Add depth layers
        table.insert(self.stars, {
            x = math.random(0, self.windowWidth),
            y = math.random(0, self.windowHeight),
            speed = math.random(20, 80) * depth,
            size = math.random(0.5, 3) / depth,
            brightness = math.random(0.2, 0.9),
            depth = depth,
            twinkleTimer = math.random() * 2,
            twinkleSpeed = math.random(2, 6),
            color = {
                math.random(0.8, 1),
                math.random(0.8, 1),
                math.random(0.9, 1)
            }
        })
    end
end

function Game:update(dt)
    -- Handle different game states
    if self.gameState == "menu" then
        self:updateMenu(dt)
        return
    elseif self.gameState == "credits" then
        self:updateCredits(dt)
        return
    elseif self.gameState == "exploding" then
        self:updateExplosion(dt)
        return
    elseif self.gameState ~= "playing" then 
        return 
    end
    
    -- Enhanced screen shake with decay
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.shakeIntensity = self.shakeIntensity * 0.95 -- Gradual decay
    end
    
    -- Update enhanced starfield with parallax effect and player movement
    for _, star in ipairs(self.stars) do
        -- Base movement speed increases with score
        star.y = star.y + (star.speed + self.score * 0.1) * dt / star.depth
        
        -- Reset stars that go off screen
        if star.y > self.windowHeight + star.size then
            star.y = -star.size - math.random(0, 20)
            star.x = math.random(0, self.windowWidth)
        end
        
        -- Add subtle parallax based on player movement
        if self.player.velocityX ~= 0 then
            star.x = star.x - (self.player.velocityX * dt * 0.15) / star.depth
            if star.x < -star.size then
                star.x = self.windowWidth + star.size
            elseif star.x > self.windowWidth + star.size then
                star.x = -star.size
            end
        end
    end
    
    -- Update score and check for milestones
    local oldScore = self.score
    self.score = self.score + dt * self.scoreMultiplier * 10
    
    -- Check for score milestones
    for _, milestone in ipairs(self.scoreMilestones) do
        if oldScore < milestone and self.score >= milestone then
            self:addMilestonePopup(milestone)
            break
        end
    end
    
    -- Animate score increase
    if self.score > oldScore then
        self.lastScoreIncrease = self.score - oldScore
        self.scoreAnimTimer = 0.8
    end
    
    -- Update displayed score animation
    if self.scoreAnimTimer > 0 then
        self.scoreAnimTimer = self.scoreAnimTimer - dt
        local animProgress = 1 - (self.scoreAnimTimer / 0.8)
        self.displayScore = self.displayScore + (self.score - self.displayScore) * animProgress * 8 * dt
    else
        self.displayScore = self.score
    end
    
    -- Update multiplier timer
    if self.multiplierTimer > 0 then
        self.multiplierTimer = self.multiplierTimer - dt
        if self.multiplierTimer <= 0 then
            self.scoreMultiplier = 1
        end
    end
    
    -- Update close call cooldown
    if self.closeCallCooldown > 0 then
        self.closeCallCooldown = self.closeCallCooldown - dt
    end
    
    -- Update popup system
    self:updatePopups(dt)
    
    -- Increase player's speed based on score (gradual increase)
    self.player.speed = 300 * (1 + 0.05 * math.floor(self.score / 100))
    self.player:update(dt, self.windowWidth, self.windowHeight)
    
    -- Update particle system
    self.particleSystem:update(dt)
    
    -- Add engine trail particles based on player movement from actual exhaust positions
    if self.player.velocityX ~= 0 or self.player.velocityY ~= 0 then
        local centerX = self.player.x + self.player.width / 2
        local centerY = self.player.y + self.player.height / 2
        local scale = 0.8
        
        -- Left engine exhaust position
        local leftExhaustX = centerX - 8.5 * scale
        local leftExhaustY = centerY + 10 * scale
        
        -- Right engine exhaust position  
        local rightExhaustX = centerX + 8.5 * scale
        local rightExhaustY = centerY + 10 * scale
        
        local trailColor = self.player.isPoweredUp and {1, 0.5, 0.1} or {0.3, 0.7, 1}
        
        if self.player.isPoweredUp then
            self.particleSystem:addBoostTrail(leftExhaustX, leftExhaustY, 0, 0)
            self.particleSystem:addBoostTrail(rightExhaustX, rightExhaustY, 0, 0)
        else
            self.particleSystem:addEngineTrail(leftExhaustX, leftExhaustY, 0, 0, trailColor)
            self.particleSystem:addEngineTrail(rightExhaustX, rightExhaustY, 0, 0, trailColor)
        end
    end
    
    -- Spawn meteoroids with increasing difficulty and varied sizes
    self.meteoroidTimer = self.meteoroidTimer + dt
    if self.meteoroidTimer >= self.spawnInterval then
        self.meteoroidTimer = 0
        
        -- Much more varied asteroid sizes
        local sizeVariation = math.random(1, 4)
        local width, height
        
        if sizeVariation == 1 then
            -- Small asteroids (30-50)
            width = math.random(30, 50)
            height = math.random(30, 50)
        elseif sizeVariation == 2 then
            -- Medium asteroids (50-75) 
            width = math.random(50, 75)
            height = math.random(50, 75)
        elseif sizeVariation == 3 then
            -- Large asteroids (75-100)
            width = math.random(75, 100)
            height = math.random(75, 100)
        else
            -- Extra large asteroids (100-130)
            width = math.random(100, 130)
            height = math.random(100, 130)
        end
        local x = math.random(0, self.windowWidth - width)
        local y = -height
        local speed = math.random(200, 400) + self.score * 0.5
        -- Create meteoroid type (for different visual styles)
        local meteoroidType = math.random(1, 4)
        -- Set warning delay
        local warningDelay = self.scoreMultiplier > 1 and 0.4 or 1.2
        table.insert(self.pendingWarnings, {
            x = x,
            width = width,
            height = height,
            speed = speed,
            meteoroidType = meteoroidType,
            timer = warningDelay
        })
        self.spawnInterval = math.max(self.spawnInterval - 0.002, 0.3)
    end
    -- Update pending warnings and spawn asteroids when timer expires
    for i = #self.pendingWarnings, 1, -1 do
        local w = self.pendingWarnings[i]
        w.timer = w.timer - dt
        if w.timer <= 0 then
            local meteoroid = Meteoroid.new(w.x, -w.height, w.width, w.height, w.speed, w.meteoroidType)
            table.insert(self.meteoroids, meteoroid)
            
            -- Add entry effect particles for asteroid
            self.particleSystem:addAsteroidEntry(w.x, -w.height, w.width, w.height)
            
            table.remove(self.pendingWarnings, i)
        end
    end
    
    for _, meteoroid in ipairs(self.meteoroids) do
        meteoroid:update(dt, self.scoreMultiplier)
    end
    
    for i = #self.meteoroids, 1, -1 do
        if self.meteoroids[i].y > self.windowHeight then
            table.remove(self.meteoroids, i)
        end
    end
    
    -- Close call detection: check for near misses
    if self.closeCallCooldown <= 0 then
        for i, meteoroid in ipairs(self.meteoroids) do
            -- Calculate distance between player center and meteoroid center
            local playerCenterX = self.player.x + self.player.width / 2
            local playerCenterY = self.player.y + self.player.height / 2
            local meteoroidCenterX = meteoroid.x + meteoroid.width / 2
            local meteoroidCenterY = meteoroid.y + meteoroid.height / 2
            
            local distance = math.sqrt((playerCenterX - meteoroidCenterX)^2 + (playerCenterY - meteoroidCenterY)^2)
            
            -- Check if meteoroid is passing close to the player (horizontally aligned and moving past)
            local horizontalDistance = math.abs(playerCenterX - meteoroidCenterX)
            local verticalDistance = math.abs(playerCenterY - meteoroidCenterY)
            
            -- Trigger close call if asteroid is very close horizontally and has passed vertically (more generous detection)
            if horizontalDistance < 70 and verticalDistance < 50 and 
               meteoroidCenterY > playerCenterY + 5 and meteoroidCenterY < playerCenterY + 80 then
                
                self.closeCallStreak = self.closeCallStreak + 1
                self.closeCallCooldown = 0.4 -- Shorter cooldown for more frequent close calls
                
                -- Add visual effects
                self.particleSystem:addWarningPulse(playerCenterX, playerCenterY)
                self:addCloseCallPopup(self.closeCallStreak)
                
                -- Light screen shake for excitement
                self.shakeTimer = 0.3
                self.shakeIntensity = 5
                
                break -- Only one close call per frame
            end
        end
    end
    
    -- Check collision: player and meteoroids with more precise collision detection
    for i, meteoroid in ipairs(self.meteoroids) do
        -- Much more precise collision detection for triangular ship
        -- Use smaller collision box that matches the actual ship shape better
        local playerMargin = 12  -- Increased margin for more forgiving collision
        local meteoroidMargin = 8
        
        -- Calculate tighter collision bounds that match the triangular ship shape
        local playerCollisionX = self.player.x + playerMargin
        local playerCollisionY = self.player.y + playerMargin * 1.5  -- Account for triangle shape
        local playerCollisionW = self.player.width - playerMargin * 2
        local playerCollisionH = self.player.height - playerMargin * 2.5  -- Smaller height for triangle
        
        if checkCollision(playerCollisionX, playerCollisionY, playerCollisionW, playerCollisionH,
                          meteoroid.x + meteoroidMargin, meteoroid.y + meteoroidMargin, 
                          meteoroid.width - meteoroidMargin * 2, meteoroid.height - meteoroidMargin * 2) then
            
            -- Start explosion animation instead of immediately going to game over
            self.gameState = "exploding"
            self.explosionTimer = 0
            
            -- Create multiple explosion effects at collision point
            local explosionX = self.player.x + self.player.width / 2
            local explosionY = self.player.y + self.player.height / 2
            self.particleSystem:addExplosion(explosionX, explosionY, 3)  -- Bigger explosion
            
            -- Additional smaller explosions around the ship
            self.particleSystem:addExplosion(explosionX - 15, explosionY - 10, 1)
            self.particleSystem:addExplosion(explosionX + 15, explosionY - 10, 1)
            self.particleSystem:addExplosion(explosionX, explosionY + 15, 2)
            
            -- Screen flash effect
            self.particleSystem:addScreenFlash(self.windowWidth, self.windowHeight, {1, 0.3, 0.3}, 1.2)
            
            -- Enhanced screen shake with intensity based on meteoroid size
            self.shakeTimer = 1.5
            self.shakeIntensity = 20 + (meteoroid.width + meteoroid.height) * 0.15
            
            -- Save high score if needed
            if self.score > self.highScore then
                self.highScore = self.score
                self:saveHighScore(self.score)
            end
            
            -- Reset close call streak on collision
            self.closeCallStreak = 0
            
            break  -- Only one collision per frame
        end
    end
    
    -- Power-up spawning
    self.powerUpSpawnTimer = self.powerUpSpawnTimer + dt
    if not self.powerUp and self.powerUpSpawnTimer >= self.powerUpSpawnInterval then
        self.powerUpSpawnTimer = 0
        local x = math.random(15, self.windowWidth - 15)
        self.powerUp = PowerUp.new(x, -15, 18, math.random(150, 300))
    end
    
    if self.powerUp then
        self.powerUp:update(dt, self.scoreMultiplier)
        if self.powerUp.y - self.powerUp.radius > self.windowHeight then
            self.powerUp = nil
        elseif checkCollision(self.player.x, self.player.y, self.player.width, self.player.height,
                              self.powerUp.x - self.powerUp.radius, self.powerUp.y - self.powerUp.radius,
                              self.powerUp.radius * 2, self.powerUp.radius * 2) then
            -- Add power-up collection particle effect
            self.particleSystem:addPowerUpEffect(self.powerUp.x, self.powerUp.y)
            
            -- Screen flash effect for power-up
            self.particleSystem:addScreenFlash(self.windowWidth, self.windowHeight, {0.3, 1, 0.5}, 0.4)
            
            -- Activate player power-up visual effect (red variant)
            self.player:activatePowerUp()
            self.scoreMultiplier = self.scoreMultiplier * 2  -- Stack multiplier (x2 each time)
            self.multiplierTimer = self.multiplierDuration      -- Reset timer to full duration
            self.spawnInterval = math.max(self.spawnInterval - 0.1, 0.2)
            self.powerUpSpawnInterval = math.max(self.powerUpSpawnInterval - 0.1, 1)
            
            -- Show boost popup
            self:addBoostPopup()
            
            self.powerUp = nil
        end
    end
    
    -- Update popups
    self:updatePopups(dt)
end

function Game:draw()
    -- Handle different game states
    if self.gameState == "menu" then
        self:drawMenu()
        return
    elseif self.gameState == "tutorial" then
        self:drawTutorial()
        return
    elseif self.gameState == "credits" then
        self:drawCredits()
        return
    elseif self.gameState == "exploding" then
        self:drawExploding()
        return
    end
    
    -- Enhanced screen shake with multiple directions
    local shakeX, shakeY = 0, 0
    if self.shakeTimer > 0 then
        shakeX = (math.random() - 0.5) * self.shakeIntensity
        shakeY = (math.random() - 0.5) * self.shakeIntensity
    end
    
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Enhanced space-themed gradient background with nebula effects
    local bgColor1 = {0.01, 0.02, 0.08}  -- Deep space blue
    local bgColor2 = {0.03, 0.04, 0.12}  -- Slightly lighter
    local bgColor3 = {0.05, 0.03, 0.15}  -- Purple tint
    
    if self.scoreMultiplier > 1 then
        bgColor1 = {0.08, 0.02, 0.05}    -- Deep red
        bgColor2 = {0.12, 0.03, 0.08}    -- Red-purple
        bgColor3 = {0.15, 0.05, 0.12}    -- Lighter red-purple
    end
    
    -- Multi-layer gradient for depth
    for y = 0, self.windowHeight, 2 do
        local factor1 = y / self.windowHeight
        local factor2 = math.sin(factor1 * math.pi) * 0.3  -- Sine wave for nebula effect
        
        local r = bgColor1[1] + (bgColor2[1] - bgColor1[1]) * factor1 + (bgColor3[1] - bgColor2[1]) * factor2
        local g = bgColor1[2] + (bgColor2[2] - bgColor1[2]) * factor1 + (bgColor3[2] - bgColor2[2]) * factor2
        local b = bgColor1[3] + (bgColor2[3] - bgColor1[3]) * factor1 + (bgColor3[3] - bgColor2[3]) * factor2
        
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 2)
    end

    -- Retro scanlines effect for authentic pixel art feel
    for y = 0, self.windowHeight, 4 do
        love.graphics.setColor(0, 0, 0, 0.15)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 1)
    end

    -- Draw asteroid warning signs for pending warnings with particle effects
    local t = love.timer.getTime()
    for _, w in ipairs(self.pendingWarnings) do
        local warningX = w.x + w.width / 2
        local warningY = 10
        local pulse = 1 + 0.15 * math.sin(t * 8)
        local alpha = 0.7 + 0.3 * math.abs(math.sin(t * 8))
        
        -- Add warning pulse particles occasionally
        if math.random() < 0.1 then
            self.particleSystem:addWarningPulse(warningX, warningY + 10)
        end
        
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.push()
        love.graphics.translate(warningX, warningY + 10)
        love.graphics.scale(pulse * 0.8, pulse * 0.8)
        love.graphics.polygon("fill", 0, -10, -10, 10, 10, 10)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print("!", -3, -5)
        love.graphics.pop()
    end
    
    -- Update and draw enhanced starfield with twinkling and depth
    for _, star in ipairs(self.stars) do
        star.twinkleTimer = star.twinkleTimer + love.timer.getDelta() * star.twinkleSpeed
        local twinkle = 0.8 + 0.2 * math.sin(star.twinkleTimer)
        local alpha = star.brightness * twinkle * (0.3 + 0.7 / star.depth)
        
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], alpha)
        love.graphics.circle("fill", star.x, star.y, star.size)
        
        -- Add subtle glow for brighter stars
        if star.brightness > 0.7 and star.depth == 1 then
            love.graphics.setColor(star.color[1], star.color[2], star.color[3], alpha * 0.3)
            love.graphics.circle("fill", star.x, star.y, star.size * 2)
        end
    end
    
    -- Draw game objects
    -- Draw main particle effects first (behind objects)
    self.particleSystem:draw()
    
    self.player:draw()
    
    for _, meteoroid in ipairs(self.meteoroids) do
        meteoroid:draw(self.scoreMultiplier)
    end
    
    if self.powerUp then
        self.powerUp:draw()
    end
    
    love.graphics.pop()
    
    -- Draw screen flash effects on top of everything
    self.particleSystem:drawScreenEffects()
    
    -- Draw popup notifications
    self:drawPopups()
    
    -- Minimal UI - only show current score in corner
    self:drawMinimalUI()
    
    -- Pixel-style Game Over screen with retro 2D theme
    if self.gameState == "gameOver" then
        -- Dark pixel-style overlay
        love.graphics.setColor(0.05, 0.05, 0.15, 0.95)
        love.graphics.rectangle("fill", 0, 0, self.windowWidth, self.windowHeight)
        
        -- Retro scanlines effect
        for y = 0, self.windowHeight, 4 do
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", 0, y, self.windowWidth, 1)
        end
        
        -- Pixel-style twinkling stars background
        local time = love.timer.getTime()
        math.randomseed(42) -- Fixed seed for consistent star positions
        for i = 1, 25 do
            local x = math.random(50, self.windowWidth - 50)
            local y = math.random(50, self.windowHeight - 50)
            local twinkle = math.sin(time * 3 + i) > 0.7
            if twinkle then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.rectangle("fill", x, y, 2, 2)
                love.graphics.rectangle("fill", x-1, y, 1, 1)
                love.graphics.rectangle("fill", x+2, y, 1, 1)
                love.graphics.rectangle("fill", x, y-1, 1, 1)
                love.graphics.rectangle("fill", x, y+2, 1, 1)
            end
        end

        -- Pixel-style main panel
        local panelW, panelH = 400, 320
        local panelX = (self.windowWidth - panelW) / 2
        local panelY = (self.windowHeight - panelH) / 2
        
        -- Main panel background with pixel borders
        love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)
        
        -- Pixel-style border (thick retro style)
        love.graphics.setColor(0.4, 0.4, 0.6)
        love.graphics.rectangle("fill", panelX - 4, panelY - 4, panelW + 8, 4) -- Top
        love.graphics.rectangle("fill", panelX - 4, panelY + panelH, panelW + 8, 4) -- Bottom
        love.graphics.rectangle("fill", panelX - 4, panelY, 4, panelH) -- Left
        love.graphics.rectangle("fill", panelX + panelW, panelY, 4, panelH) -- Right
        
        -- Inner highlight border (classic pixel UI style)
        love.graphics.setColor(0.6, 0.6, 0.8)
        love.graphics.rectangle("fill", panelX, panelY, panelW, 2) -- Top highlight
        love.graphics.rectangle("fill", panelX, panelY, 2, panelH) -- Left highlight
        
        -- Inner shadow border
        love.graphics.setColor(0.05, 0.05, 0.1)
        love.graphics.rectangle("fill", panelX, panelY + panelH - 2, panelW, 2) -- Bottom shadow
        love.graphics.rectangle("fill", panelX + panelW - 2, panelY, 2, panelH) -- Right shadow

        -- Retro pixelated title
        local title = "GAME OVER"
        love.graphics.setFont(self.titleFont)
        local titleY = panelY + 25
        
        -- Pixel-style drop shadow
        love.graphics.setColor(0.6, 0.1, 0.1)
        love.graphics.printf(title, panelX + 3, titleY + 3, panelW, "center")
        
        -- Main title
        love.graphics.setColor(1, 0.8, 0.8)
        love.graphics.printf(title, panelX, titleY, panelW, "center")
        
        -- Pixel-style separator line
        love.graphics.setColor(0.5, 0.5, 0.7)
        love.graphics.rectangle("fill", panelX + 40, titleY + 55, panelW - 80, 2)
        love.graphics.setColor(0.3, 0.3, 0.5)
        love.graphics.rectangle("fill", panelX + 40, titleY + 57, panelW - 80, 1)

        -- Pixel-style score displays
        love.graphics.setFont(self.font)
        local scoreStartY = panelY + 110
        
        -- Enhanced Final Score panel with modern pixel art styling
        local finalScoreY = scoreStartY
        local scoreBoxW, scoreBoxH = panelW - 60, 45
        local scoreBoxX = panelX + 30
        
        -- Score box with gradient-like layering and depth
        love.graphics.setColor(0.05, 0.08, 0.12) -- Darker outer shadow
        love.graphics.rectangle("fill", scoreBoxX - 3, finalScoreY - 3, scoreBoxW + 6, scoreBoxH + 6)
        
        love.graphics.setColor(0.12, 0.18, 0.3) -- Main background
        love.graphics.rectangle("fill", scoreBoxX, finalScoreY, scoreBoxW, scoreBoxH)
        
        -- Inner highlight for 3D depth effect
        love.graphics.setColor(0.2, 0.28, 0.4)
        love.graphics.rectangle("fill", scoreBoxX + 2, finalScoreY + 2, scoreBoxW - 4, 2) -- Top inner highlight
        love.graphics.rectangle("fill", scoreBoxX + 2, finalScoreY + 2, 2, scoreBoxH - 4) -- Left inner highlight
        
        -- Enhanced pixel border with better colors
        love.graphics.setColor(0.4, 0.55, 0.75)
        love.graphics.rectangle("fill", scoreBoxX - 2, finalScoreY - 2, scoreBoxW + 4, 2) -- Top
        love.graphics.rectangle("fill", scoreBoxX - 2, finalScoreY + scoreBoxH, scoreBoxW + 4, 2) -- Bottom
        love.graphics.rectangle("fill", scoreBoxX - 2, finalScoreY, 2, scoreBoxH) -- Left
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW, finalScoreY, 2, scoreBoxH) -- Right
        
        -- Corner accents for modern pixel art look
        love.graphics.setColor(0.6, 0.75, 0.9)
        love.graphics.rectangle("fill", scoreBoxX - 2, finalScoreY - 2, 4, 4) -- Top-left corner
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, finalScoreY - 2, 4, 4) -- Top-right corner
        love.graphics.rectangle("fill", scoreBoxX - 2, finalScoreY + scoreBoxH - 2, 4, 4) -- Bottom-left corner
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, finalScoreY + scoreBoxH - 2, 4, 4) -- Bottom-right corner
        
        love.graphics.setColor(0.85, 0.9, 1)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("FINAL SCORE", scoreBoxX, finalScoreY + 8, scoreBoxW, "center")
        
        love.graphics.setColor(1, 0.95, 0.7)
        love.graphics.setFont(self.font)
        love.graphics.printf(math.floor(self.score), scoreBoxX, finalScoreY + 25, scoreBoxW, "center")
        
        -- Enhanced High Score panel with modern pixel art styling
        local highScoreY = finalScoreY + 55
        
        -- High score box with gradient-like layering and depth
        love.graphics.setColor(0.08, 0.06, 0.03) -- Darker outer shadow
        love.graphics.rectangle("fill", scoreBoxX - 3, highScoreY - 3, scoreBoxW + 6, scoreBoxH + 6)
        
        love.graphics.setColor(0.25, 0.2, 0.1) -- Main background
        love.graphics.rectangle("fill", scoreBoxX, highScoreY, scoreBoxW, scoreBoxH)
        
        -- Inner highlight for 3D depth effect
        love.graphics.setColor(0.35, 0.28, 0.15)
        love.graphics.rectangle("fill", scoreBoxX + 2, highScoreY + 2, scoreBoxW - 4, 2) -- Top inner highlight
        love.graphics.rectangle("fill", scoreBoxX + 2, highScoreY + 2, 2, scoreBoxH - 4) -- Left inner highlight
        
        -- Enhanced pixel border with better colors
        love.graphics.setColor(0.7, 0.55, 0.35)
        love.graphics.rectangle("fill", scoreBoxX - 2, highScoreY - 2, scoreBoxW + 4, 2) -- Top
        love.graphics.rectangle("fill", scoreBoxX - 2, highScoreY + scoreBoxH, scoreBoxW + 4, 2) -- Bottom
        love.graphics.rectangle("fill", scoreBoxX - 2, highScoreY, 2, scoreBoxH) -- Left
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW, highScoreY, 2, scoreBoxH) -- Right
        
        -- Corner accents for modern pixel art look
        love.graphics.setColor(0.9, 0.7, 0.45)
        love.graphics.rectangle("fill", scoreBoxX - 2, highScoreY - 2, 4, 4) -- Top-left corner
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, highScoreY - 2, 4, 4) -- Top-right corner
        love.graphics.rectangle("fill", scoreBoxX - 2, highScoreY + scoreBoxH - 2, 4, 4) -- Bottom-left corner
        love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, highScoreY + scoreBoxH - 2, 4, 4) -- Bottom-right corner
        
        love.graphics.setColor(1, 0.95, 0.8)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("HIGH SCORE", scoreBoxX, highScoreY + 8, scoreBoxW, "center")
        
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.setFont(self.font)
        love.graphics.printf(math.floor(self.highScore), scoreBoxX, highScoreY + 25, scoreBoxW, "center")

        -- Enhanced new high score celebration with modern styling
        if self.score >= self.highScore and self.score > 0 then
            local celebrationY = highScoreY + 55
            local blink = math.floor(time * 4) % 2 == 0
            
            if blink then
                -- Celebration box with enhanced pixel art styling
                love.graphics.setColor(0.1, 0.08, 0.02) -- Darker outer shadow
                love.graphics.rectangle("fill", scoreBoxX - 3, celebrationY - 3, scoreBoxW + 6, 30)
                
                love.graphics.setColor(0.3, 0.25, 0.1) -- Main background
                love.graphics.rectangle("fill", scoreBoxX, celebrationY, scoreBoxW, 25)
                
                -- Inner highlight for depth
                love.graphics.setColor(0.4, 0.35, 0.18)
                love.graphics.rectangle("fill", scoreBoxX + 2, celebrationY + 2, scoreBoxW - 4, 2) -- Top inner highlight
                love.graphics.rectangle("fill", scoreBoxX + 2, celebrationY + 2, 2, 21) -- Left inner highlight
                
                -- Enhanced border with celebration colors
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.rectangle("fill", scoreBoxX - 2, celebrationY - 2, scoreBoxW + 4, 2) -- Top
                love.graphics.rectangle("fill", scoreBoxX - 2, celebrationY + 25, scoreBoxW + 4, 2) -- Bottom
                love.graphics.rectangle("fill", scoreBoxX - 2, celebrationY, 2, 25) -- Left
                love.graphics.rectangle("fill", scoreBoxX + scoreBoxW, celebrationY, 2, 25) -- Right
                
                -- Bright corner accents for celebration
                love.graphics.setColor(1, 0.9, 0.4)
                love.graphics.rectangle("fill", scoreBoxX - 2, celebrationY - 2, 4, 4) -- Top-left corner
                love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, celebrationY - 2, 4, 4) -- Top-right corner
                love.graphics.rectangle("fill", scoreBoxX - 2, celebrationY + 23, 4, 4) -- Bottom-left corner
                love.graphics.rectangle("fill", scoreBoxX + scoreBoxW - 2, celebrationY + 23, 4, 4) -- Bottom-right corner
                
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(1, 0.95, 0.5)
                love.graphics.printf("*** NEW HIGH SCORE! ***", scoreBoxX, celebrationY + 7, scoreBoxW, "center")
            end
        end
        
        -- Pixel-style retro buttons
        local buttonW, buttonH = 120, 36
        local buttonSpacing = 40
        local totalButtonWidth = buttonW * 2 + buttonSpacing
        local button1X = panelX + (panelW - totalButtonWidth) / 2
        local button2X = button1X + buttonW + buttonSpacing
        local buttonY = panelY + panelH - 55
        
        -- Store button positions for mouse detection
        self.retryButton = {x = button1X, y = buttonY, width = buttonW, height = buttonH}
        self.menuButton = {x = button2X, y = buttonY, width = buttonW, height = buttonH}
        
        -- Retry button with enhanced pixel-style 3D effect
        love.graphics.setColor(0.2, 0.4, 0.8)
        love.graphics.rectangle("fill", button1X, buttonY, buttonW, buttonH)
        
        -- Enhanced pixel-style button borders and highlights
        love.graphics.setColor(0.5, 0.7, 1) -- Bright highlight
        love.graphics.rectangle("fill", button1X, buttonY, buttonW, 4) -- Top highlight (thicker)
        love.graphics.rectangle("fill", button1X, buttonY, 4, buttonH) -- Left highlight (thicker)
        
        love.graphics.setColor(0.05, 0.1, 0.3) -- Dark shadow
        love.graphics.rectangle("fill", button1X, buttonY + buttonH - 4, buttonW, 4) -- Bottom shadow (thicker)
        love.graphics.rectangle("fill", button1X + buttonW - 4, buttonY, 4, buttonH) -- Right shadow (thicker)
        
        -- Add inner border for more definition
        love.graphics.setColor(0.1, 0.2, 0.5)
        love.graphics.rectangle("line", button1X + 2, buttonY + 2, buttonW - 4, buttonH - 4)
        
        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("RETRY", button1X, buttonY + (buttonH - self.font:getHeight()) / 2, buttonW, "center")
        
        -- Menu button with enhanced pixel-style 3D effect
        love.graphics.setColor(0.7, 0.3, 0.3)
        love.graphics.rectangle("fill", button2X, buttonY, buttonW, buttonH)
        
        -- Enhanced pixel-style button borders and highlights
        love.graphics.setColor(1, 0.6, 0.6) -- Bright highlight
        love.graphics.rectangle("fill", button2X, buttonY, buttonW, 4) -- Top highlight (thicker)
        love.graphics.rectangle("fill", button2X, buttonY, 4, buttonH) -- Left highlight (thicker)
        
        love.graphics.setColor(0.3, 0.1, 0.1) -- Dark shadow
        love.graphics.rectangle("fill", button2X, buttonY + buttonH - 4, buttonW, 4) -- Bottom shadow (thicker)
        love.graphics.rectangle("fill", button2X + buttonW - 4, buttonY, 4, buttonH) -- Right shadow (thicker)
        
        -- Add inner border for more definition
        love.graphics.setColor(0.5, 0.2, 0.2)
        love.graphics.rectangle("line", button2X + 2, buttonY + 2, buttonW - 4, buttonH - 4)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("MENU", button2X, buttonY + (buttonH - self.font:getHeight()) / 2, buttonW, "center")
    end
end

function Game:drawMinimalUI()
    -- Only show current score in a small corner display
    local scoreText = math.floor(self.score)
    love.graphics.setFont(self.font)
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 10, 10, 120, 35, 5, 5)
    
    -- Score text with glow
    love.graphics.setColor(0.3, 0.8, 1, 0.6)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(scoreText, 20 + dx, 20 + dy)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(scoreText, 20, 20)
    
    love.graphics.setColor(1, 1, 1) -- Reset color
end

function Game:mousepressed(x, y, button)
    if button == 1 then
        if self.gameState == "menu" then
            -- Play button
            if x >= self.playButton.x and x <= self.playButton.x + self.playButton.width and
               y >= self.playButton.y and y <= self.playButton.y + self.playButton.height then
                self:reset()
                self.gameState = "playing"
            end
            
            -- Tutorial button
            if x >= self.tutorialButton.x and x <= self.tutorialButton.x + self.tutorialButton.width and
               y >= self.tutorialButton.y and y <= self.tutorialButton.y + self.tutorialButton.height then
                self.gameState = "tutorial"
            end
            
            -- Credits button
            if x >= self.creditsButton.x and x <= self.creditsButton.x + self.creditsButton.width and
               y >= self.creditsButton.y and y <= self.creditsButton.y + self.creditsButton.height then
                self.gameState = "credits"
            end
            
            -- Exit button
            if x >= self.exitButton.x and x <= self.exitButton.x + self.exitButton.width and
               y >= self.exitButton.y and y <= self.exitButton.y + self.exitButton.height then
                love.event.quit()
            end
            
        elseif self.gameState == "tutorial" then
            -- Any click returns to menu
            self.gameState = "menu"
            
        elseif self.gameState == "credits" then
            -- Any click returns to menu
            self.gameState = "menu"
            
        elseif self.gameState == "gameOver" then
            -- Retry button
            if x >= self.retryButton.x and x <= self.retryButton.x + self.retryButton.width and
               y >= self.retryButton.y and y <= self.retryButton.y + self.retryButton.height then
                self:reset()
                self.gameState = "playing"
            end
            
            -- Menu button
            if x >= self.menuButton.x and x <= self.menuButton.x + self.menuButton.width and
               y >= self.menuButton.y and y <= self.menuButton.y + self.menuButton.height then
                self.gameState = "menu"
            end
        end
    end
end

-- Credits screen update
function Game:updateCredits(dt)
    -- Update background stars for credits screen
    for _, star in ipairs(self.stars) do
        star.y = star.y + star.speed * dt / star.depth
        if star.y > self.windowHeight + star.size then
            star.y = -star.size - math.random(0, 20)
            star.x = math.random(0, self.windowWidth)
        end
        star.twinkleTimer = star.twinkleTimer + dt * star.twinkleSpeed
    end
end

-- Menu update
function Game:updateMenu(dt)
    -- Update background stars
    for _, star in ipairs(self.stars) do
        star.y = star.y + star.speed * dt / star.depth
        if star.y > self.windowHeight + star.size then
            star.y = -star.size - math.random(0, 20)
            star.x = math.random(0, self.windowWidth)
        end
        star.twinkleTimer = star.twinkleTimer + dt * star.twinkleSpeed
    end
end

-- Explosion animation update
function Game:updateExplosion(dt)
    self.explosionTimer = self.explosionTimer + dt
    
    -- Continue updating particles and visual effects during explosion
    self.particleSystem:update(dt)
    
    -- Continue screen shake
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.shakeIntensity = self.shakeIntensity * 0.95
    end
    
    -- Keep updating stars in background
    for _, star in ipairs(self.stars) do
        star.y = star.y + star.speed * dt / star.depth
        if star.y > self.windowHeight + star.size then
            star.y = -star.size - math.random(0, 20)
            star.x = math.random(0, self.windowWidth)
        end
        star.twinkleTimer = star.twinkleTimer + dt * star.twinkleSpeed
    end
    
    -- Keep meteoroids moving during explosion for realism
    for _, meteoroid in ipairs(self.meteoroids) do
        meteoroid:update(dt, self.scoreMultiplier)
    end
    
    -- After explosion duration, transition to game over
    if self.explosionTimer >= self.explosionDuration then
        self.gameState = "gameOver"
    end
end

-- High score management
function Game:loadHighScore()
    local file = love.filesystem.read("highscore.txt")
    if file then
        return tonumber(file) or 0
    end
    return 0
end

function Game:saveHighScore(score)
    love.filesystem.write("highscore.txt", tostring(math.floor(score)))
end

-- Popup system functions
function Game:addPopup(text, x, y, duration, color, size)
    -- Ensure popup stays within screen bounds
    local popupWidth = 400
    local margin = 20
    
    -- Default to center if no position provided
    x = x or self.windowWidth / 2
    y = y or self.windowHeight / 2
    
    -- Constrain X position to keep popup on screen
    if x - popupWidth / 2 < margin then
        x = margin + popupWidth / 2
    elseif x + popupWidth / 2 > self.windowWidth - margin then
        x = self.windowWidth - margin - popupWidth / 2
    end
    
    -- Constrain Y position to keep popup on screen
    local estimatedTextHeight = 50 * (size or 1)  -- Rough estimate
    if y - estimatedTextHeight / 2 < margin then
        y = margin + estimatedTextHeight / 2
    elseif y + estimatedTextHeight / 2 > self.windowHeight - margin then
        y = self.windowHeight - margin - estimatedTextHeight / 2
    end
    
    table.insert(self.popups, {
        text = text,
        x = x,
        y = y,
        startX = x,
        startY = y,
        duration = duration or 3,
        maxDuration = duration or 3,
        color = color or {1, 1, 1},
        size = size or 1,
        alpha = 1,
        scale = 0.1,
        targetScale = size or 1,
        velocity = {x = 0, y = -50}
    })
end

function Game:addScorePopup(points, x, y)
    local color = {0.2, 1, 0.3}
    if points >= 1000 then
        color = {1, 0.8, 0.2}
    elseif points >= 500 then
        color = {1, 0.5, 0.2}
    end
    
    self:addPopup("+" .. points, x, y, 2, color, 1.5)
end

function Game:addMilestonePopup(milestone)
    local centerX = self.windowWidth / 2
    local centerY = self.windowHeight / 3
    
    if milestone >= 5000 then
        self:addPopup("LEGENDARY PILOT!", centerX, centerY, 4, {1, 0.8, 0.2}, 2.5)
    elseif milestone >= 2000 then
        self:addPopup("ACE PILOT!", centerX, centerY, 3.5, {1, 0.6, 0.3}, 2.2)
    elseif milestone >= 1000 then
        self:addPopup("VETERAN PILOT!", centerX, centerY, 3, {1, 0.4, 0.4}, 2)
    elseif milestone >= 500 then
        self:addPopup("SKILLED PILOT!", centerX, centerY, 2.5, {0.8, 0.8, 1}, 1.8)
    else
        self:addPopup("GOOD FLYING!", centerX, centerY, 2, {0.6, 1, 0.8}, 1.5)
    end
end

function Game:addBoostPopup()
    local centerX = self.windowWidth / 2
    local centerY = self.windowHeight / 2.5
    
    self:addPopup("BOOST ACTIVE!", centerX, centerY, 2.5, {1, 0.5, 0.1}, 2)
    
    -- Add multiplier popup
    local multText = "x" .. self.scoreMultiplier .. " MULTIPLIER"
    self:addPopup(multText, centerX, centerY + 40, 2, {1, 0.8, 0.3}, 1.5)
end

function Game:addCloseCallPopup(streak)
    local centerX = self.windowWidth / 2
    local centerY = self.windowHeight / 2.5
    
    local messages = {
        "CLOSE CALL!",
        "NEAR MISS!",
        "DODGED IT!",
        "CLOSE SHAVE!",
        "BARELY MADE IT!"
    }
    
    local streakMessages = {
        [2] = "DOUBLE DODGE!",
        [3] = "TRIPLE DODGE!",
        [4] = "QUAD DODGE!",
        [5] = "AMAZING DODGING!",
        [6] = "INCREDIBLE SKILLS!",
        [7] = "LEGENDARY PILOT!"
    }
    
    local message = messages[math.random(1, #messages)]
    local color = {1, 0.8, 0.3}
    local size = 1.5
    
    if streak >= 2 then
        message = streakMessages[streak] or ("x" .. streak .. " DODGING STREAK!")
        color = {1, 0.5, 0.2}
        size = 1.8
        
        if streak >= 5 then
            color = {1, 0.3, 0.1}
            size = 2.2
        end
    end
    
    self:addPopup(message, centerX, centerY, 1.5, color, size)
    
    -- Add bonus score for close calls
    local bonusScore = 10 + (streak * 5)
    self.score = self.score + bonusScore
    self:addScorePopup(bonusScore, centerX, centerY + 50)
end

function Game:updatePopups(dt)
    for i = #self.popups, 1, -1 do
        local popup = self.popups[i]
        
        -- Update position with velocity
        popup.x = popup.x + popup.velocity.x * dt
        popup.y = popup.y + popup.velocity.y * dt
        
        -- Update scale with smooth animation
        popup.scale = popup.scale + (popup.targetScale - popup.scale) * 5 * dt
        
        -- Update alpha based on remaining life
        popup.duration = popup.duration - dt
        local lifeFactor = popup.duration / popup.maxDuration
        
        if lifeFactor > 0.7 then
            popup.alpha = 1
        else
            popup.alpha = lifeFactor / 0.7
        end
        
        -- Apply drag to velocity
        popup.velocity.x = popup.velocity.x * 0.98
        popup.velocity.y = popup.velocity.y * 0.98
        
        -- Remove expired popups
        if popup.duration <= 0 then
            table.remove(self.popups, i)
        end
    end
end

function Game:drawPopups()
    for _, popup in ipairs(self.popups) do
        love.graphics.push()
        
        -- Calculate actual position taking text width into account
        local textWidth = 400
        local actualX = popup.x - (textWidth * popup.scale) / 2
        local actualY = popup.y
        
        -- Ensure the scaled popup doesn't go off screen
        if actualX < 10 then
            actualX = 10
        elseif actualX + (textWidth * popup.scale) > self.windowWidth - 10 then
            actualX = self.windowWidth - 10 - (textWidth * popup.scale)
        end
        
        love.graphics.translate(actualX, actualY)
        love.graphics.scale(popup.scale, popup.scale)
        
        -- Text shadow
        love.graphics.setColor(0, 0, 0, popup.alpha * 0.8)
        for dx = -2, 2 do
            for dy = -2, 2 do
                if dx ~= 0 or dy ~= 0 then
                    love.graphics.printf(popup.text, dx, dy, textWidth, "center")
                end
            end
        end
        
        -- Main text
        love.graphics.setColor(popup.color[1], popup.color[2], popup.color[3], popup.alpha)
        love.graphics.printf(popup.text, 0, 0, textWidth, "center")
        
        love.graphics.pop()
    end
end

-- Draw credits screen with pixel art theme
function Game:drawCredits()
    -- Pixel-style space background
    love.graphics.setColor(0.05, 0.08, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.windowWidth, self.windowHeight)
    
    -- Retro scanlines
    for y = 0, self.windowHeight, 4 do
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 1)
    end
    
    -- Pixel-style twinkling stars
    math.randomseed(789) -- Different seed for credits
    for i = 1, 30 do
        local x = math.random(0, self.windowWidth)
        local y = math.random(0, self.windowHeight)
        local twinkle = math.sin(love.timer.getTime() * 1.8 + i) > 0.4
        if twinkle then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("fill", x, y, 2, 2)
        else
            love.graphics.setColor(0.7, 0.8, 1, 0.5)
            love.graphics.rectangle("fill", x, y, 1, 1)
        end
    end
    
    -- Credits title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    local title = "CREDITS"
    local titleWidth = self.titleFont:getWidth(title)
    
    -- Pixel drop shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2 + 3, 80)
    
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2, 77)
    
    -- Credits content
    love.graphics.setFont(self.font)
    local credits = {
        "GAME DEVELOPMENT",
        "Nathan Tr",
        "",
        "FRAMEWORK",
        "Love2D",
        "",
        "PIXEL ART",
        "Custom Procedural Graphics",
        "",
        "Thank you for playing!",
        "",
        "Click anywhere to return to menu"
    }
    
    local startY = 180
    local lineHeight = 25
    
    for i, line in ipairs(credits) do
        local y = startY + (i - 1) * lineHeight
        
        if line == "" then
            -- Skip empty lines
        elseif line == "GAME DEVELOPMENT" or line == "FRAMEWORK" or line == "PIXEL ART" or 
               line == "MUSIC & SOUND" or line == "SPECIAL THANKS" then
            -- Section headers
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        elseif line == "Thank you for playing!" then
            -- Special message
            love.graphics.setColor(1, 0.8, 0.6)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        elseif line == "Click anywhere to return to menu" then
            -- Instructions
            love.graphics.setColor(0.6, 0.7, 0.9)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
            love.graphics.setFont(self.font)
        else
            -- Regular credits
            love.graphics.setColor(0.7, 0.8, 0.9)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        end
    end
    
    love.graphics.setColor(1, 1, 1) -- Reset color
end

-- Draw tutorial screen with instructions
function Game:drawTutorial()
    -- Same background as menu
    love.graphics.setColor(0.05, 0.08, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.windowWidth, self.windowHeight)
    
    -- Retro scanlines
    for y = 0, self.windowHeight, 4 do
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 1)
    end
    
    -- Twinkling stars
    math.randomseed(789) -- Different seed for tutorial
    for i = 1, 20 do
        local x = math.random(0, self.windowWidth)
        local y = math.random(0, self.windowHeight)
        local twinkle = math.sin(love.timer.getTime() * 1.5 + i) > 0.3
        if twinkle then
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.rectangle("fill", x, y, 2, 2)
        else
            love.graphics.setColor(0.7, 0.8, 1, 0.3)
            love.graphics.rectangle("fill", x, y, 1, 1)
        end
    end
    
    -- Tutorial title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    local title = "HOW TO PLAY"
    local titleWidth = self.font:getWidth(title)
    
    -- Title shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2 + 3, 50)
    
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2, 47)
    
    -- Tutorial content
    local instructions = {
        "CONTROLS:",
        "",
        "WASD or Arrow Keys - Move your spaceship",
        "Mouse - Navigate menus",
        "",
        "OBJECTIVE:",
        "",
        "• Dodge the falling meteoroids",
        "• Collect star power-ups to boost your ship",
        "• Survive as long as possible",
        "• Beat your high score!",
        "",
        "TIPS:",
        "",
        "• Meteoroids get faster over time",
        "• Power-ups make you faster and change color",
        "• Your ship tilts when you move left/right",
        "• Watch for warning signs at the top",
        "",
        "",
        "Click anywhere to return to menu"
    }
    
    love.graphics.setFont(self.smallFont)
    local startY = 120
    local lineHeight = 25
    
    for i, line in ipairs(instructions) do
        local y = startY + (i - 1) * lineHeight
        
        if line == "CONTROLS:" or line == "OBJECTIVE:" or line == "TIPS:" then
            -- Section headers
            love.graphics.setColor(0.4, 0.8, 1)
            love.graphics.setFont(self.font)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
            love.graphics.setFont(self.smallFont)
        elseif line == "Click anywhere to return to menu" then
            -- Instructions
            love.graphics.setColor(0.6, 0.7, 0.9)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        elseif line:sub(1, 1) == "•" then
            -- Bullet points
            love.graphics.setColor(0.8, 0.9, 1)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        elseif line ~= "" then
            -- Regular instructions
            love.graphics.setColor(0.7, 0.8, 0.9)
            love.graphics.printf(line, 0, y, self.windowWidth, "center")
        end
    end
    
    -- Draw a mini spaceship demonstration
    local shipX = self.windowWidth / 2 - 150
    local shipY = 200
    love.graphics.setColor(0.8, 0.9, 1, 0.8)
    self:drawMenuSpaceship(shipX, shipY)
    
    -- Draw a star power-up demonstration
    local starX = self.windowWidth / 2 + 150
    local starY = 200
    love.graphics.push()
    love.graphics.translate(starX, starY)
    love.graphics.rotate(love.timer.getTime() * 2)
    local starPoints = {}
    local outerRadius = 15
    local innerRadius = outerRadius * 0.4
    for i = 0, 9 do
        local angle = (i / 10) * math.pi * 2
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        table.insert(starPoints, math.cos(angle) * radius)
        table.insert(starPoints, math.sin(angle) * radius)
    end
    love.graphics.setColor(0.1, 0.9, 0.3, 0.9)
    love.graphics.polygon("fill", starPoints)
    love.graphics.pop()
    
    love.graphics.setColor(1, 1, 1) -- Reset color
end

-- Draw menu screen with pixel art theme
function Game:drawMenu()
    -- Pixel-style space background
    love.graphics.setColor(0.05, 0.08, 0.2)
    love.graphics.rectangle("fill", 0, 0, self.windowWidth, self.windowHeight)
    
    -- Retro scanlines
    for y = 0, self.windowHeight, 4 do
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 1)
    end
    
    -- Pixel-style twinkling stars
    math.randomseed(456) -- Different seed for menu
    for i = 1, 30 do
        local x = math.random(0, self.windowWidth)
        local y = math.random(0, self.windowHeight)
        local twinkle = math.sin(love.timer.getTime() * 1.5 + i) > 0.3
        if twinkle then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("fill", x, y, 2, 2)
        else
            love.graphics.setColor(0.7, 0.8, 1, 0.5)
            love.graphics.rectangle("fill", x, y, 1, 1)
        end
    end

    -- Game title with pixel-style shadow
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    local title = "DODGE THE METEOROIDS"
    local titleWidth = self.font:getWidth(title)
    
    -- Pixel drop shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2 + 3, 103)
    
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(title, (self.windowWidth - titleWidth) / 2, 100)

    -- High score display with pixel-style background (moved down to avoid overlap)
    love.graphics.setFont(self.smallFont)
    local highScoreText = "Best Score: " .. math.floor(self.highScore)
    local highScoreWidth = self.smallFont:getWidth(highScoreText)
    local highScoreX = (self.windowWidth - highScoreWidth) / 2
    local highScoreY = 180  -- Moved down from 150 to avoid title overlap
    
    -- Score background panel
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", highScoreX - 10, highScoreY - 5, highScoreWidth + 20, 25)
    
    -- Pixel border for score
    love.graphics.setColor(0.4, 0.5, 0.7)
    love.graphics.rectangle("fill", highScoreX - 12, highScoreY - 7, highScoreWidth + 24, 2) -- Top
    love.graphics.rectangle("fill", highScoreX - 12, highScoreY + 20, highScoreWidth + 24, 2) -- Bottom
    love.graphics.rectangle("fill", highScoreX - 12, highScoreY - 5, 2, 25) -- Left
    love.graphics.rectangle("fill", highScoreX + highScoreWidth + 10, highScoreY - 5, 2, 25) -- Right
    
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print(highScoreText, highScoreX, highScoreY)

    -- Display spaceship in the middle area
    local shipX = self.windowWidth / 2
    local shipY = self.windowHeight / 2 - 30  -- Position it in the middle space
    
    -- Add a subtle glow effect around the ship
    love.graphics.setColor(0.4, 0.6, 0.9, 0.3)
    for i = 1, 5 do
        love.graphics.circle("fill", shipX, shipY, 35 + i*3)
    end
    
    -- Draw the pixel art spaceship (using the same method from player.lua)
    self:drawMenuSpaceship(shipX, shipY)

    -- Pixel-style play button
    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", self.playButton.x, self.playButton.y, self.playButton.width, self.playButton.height)
    
    -- Pixel-style 3D button effect
    love.graphics.setColor(0.4, 0.6, 1) -- Highlight
    love.graphics.rectangle("fill", self.playButton.x, self.playButton.y, self.playButton.width, 3)
    love.graphics.rectangle("fill", self.playButton.x, self.playButton.y, 3, self.playButton.height)
    
    love.graphics.setColor(0.1, 0.2, 0.4) -- Shadow
    love.graphics.rectangle("fill", self.playButton.x, self.playButton.y + self.playButton.height - 3, self.playButton.width, 3)
    love.graphics.rectangle("fill", self.playButton.x + self.playButton.width - 3, self.playButton.y, 3, self.playButton.height)
    
    love.graphics.setColor(1, 1,  1)
    love.graphics.printf("PLAY", self.playButton.x, self.playButton.y + (self.playButton.height - self.font:getHeight()) / 2, self.playButton.width, "center")

    -- Pixel-style tutorial button
    love.graphics.setColor(0.6, 0.4, 0.8)
    love.graphics.rectangle("fill", self.tutorialButton.x, self.tutorialButton.y, self.tutorialButton.width, self.tutorialButton.height)
    
    -- Pixel-style 3D button effect
    love.graphics.setColor(0.9, 0.6, 1) -- Highlight
    love.graphics.rectangle("fill", self.tutorialButton.x, self.tutorialButton.y, self.tutorialButton.width, 3)
    love.graphics.rectangle("fill", self.tutorialButton.x, self.tutorialButton.y, 3, self.tutorialButton.height)
    
    love.graphics.setColor(0.3, 0.2, 0.4) -- Shadow
    love.graphics.rectangle("fill", self.tutorialButton.x, self.tutorialButton.y + self.tutorialButton.height - 3, self.tutorialButton.width, 3)
    love.graphics.rectangle("fill", self.tutorialButton.x + self.tutorialButton.width - 3, self.tutorialButton.y, 3, self.tutorialButton.height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("TUTORIAL", self.tutorialButton.x, self.tutorialButton.y + (self.tutorialButton.height - self.font:getHeight()) / 2, self.tutorialButton.width, "center")

    -- Pixel-style credits button
    love.graphics.setColor(0.4, 0.6, 0.4)
    love.graphics.rectangle("fill", self.creditsButton.x, self.creditsButton.y, self.creditsButton.width, self.creditsButton.height)
    
    -- Pixel-style 3D button effect
    love.graphics.setColor(0.6, 0.9, 0.6) -- Highlight
    love.graphics.rectangle("fill", self.creditsButton.x, self.creditsButton.y, self.creditsButton.width, 3)
    love.graphics.rectangle("fill", self.creditsButton.x, self.creditsButton.y, 3, self.creditsButton.height)
    
    love.graphics.setColor(0.2, 0.3, 0.2) -- Shadow
    love.graphics.rectangle("fill", self.creditsButton.x, self.creditsButton.y + self.creditsButton.height - 3, self.creditsButton.width, 3)
    love.graphics.rectangle("fill", self.creditsButton.x + self.creditsButton.width - 3, self.creditsButton.y, 3, self.creditsButton.height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CREDITS", self.creditsButton.x, self.creditsButton.y + (self.creditsButton.height - self.font:getHeight()) / 2, self.creditsButton.width, "center")

    -- Pixel-style exit button
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", self.exitButton.x, self.exitButton.y, self.exitButton.width, self.exitButton.height)
    
    -- Pixel-style 3D button effect
    love.graphics.setColor(1, 0.5, 0.5) -- Highlight
    love.graphics.rectangle("fill", self.exitButton.x, self.exitButton.y, self.exitButton.width, 3)
    love.graphics.rectangle("fill", self.exitButton.x, self.exitButton.y, 3, self.exitButton.height)
    
    love.graphics.setColor(0.4, 0.15, 0.15) -- Shadow
    love.graphics.rectangle("fill", self.exitButton.x, self.exitButton.y + self.exitButton.height - 3, self.exitButton.width, 3)
    love.graphics.rectangle("fill", self.exitButton.x + self.exitButton.width - 3, self.exitButton.y, 3, self.exitButton.height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("EXIT", self.exitButton.x, self.exitButton.y + (self.exitButton.height - self.font:getHeight()) / 2, self.exitButton.width, "center")

    love.graphics.setColor(1, 1, 1) -- Reset color
end

function Game:drawExploding()
    -- Enhanced screen shake with multiple directions
    local shakeX, shakeY = 0, 0
    if self.shakeTimer > 0 then
        shakeX = (math.random() - 0.5) * self.shakeIntensity
        shakeY = (math.random() - 0.5) * self.shakeIntensity
    end
    
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Enhanced space-themed gradient background with explosion tinting
    local bgColor1 = {0.08, 0.02, 0.05}    -- Deep red
    local bgColor2 = {0.12, 0.03, 0.08}    -- Red-purple
    local bgColor3 = {0.15, 0.05, 0.12}    -- Lighter red-purple
    
    -- Multi-layer gradient for depth with explosion coloring
    for y = 0, self.windowHeight, 2 do
        local factor1 = y / self.windowHeight
        local factor2 = math.sin(factor1 * math.pi) * 0.3
        
        local r = bgColor1[1] + (bgColor2[1] - bgColor1[1]) * factor1 + (bgColor3[1] - bgColor2[1]) * factor2
        local g = bgColor1[2] + (bgColor2[2] - bgColor1[2]) * factor1 + (bgColor3[2] - bgColor2[2]) * factor2
        local b = bgColor1[3] + (bgColor2[3] - bgColor1[3]) * factor1 + (bgColor3[3] - bgColor2[3]) * factor2
        
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, y, self.windowWidth, 2)
    end

    -- Draw enhanced starfield with twinkling and depth
    for _, star in ipairs(self.stars) do
        star.twinkleTimer = star.twinkleTimer + love.timer.getDelta() * star.twinkleSpeed
        local twinkle = 0.8 + 0.2 * math.sin(star.twinkleTimer)
        local alpha = star.brightness * twinkle * (0.3 + 0.7 / star.depth)
        
        love.graphics.setColor(star.color[1], star.color[2], star.color[3], alpha)
        love.graphics.circle("fill", star.x, star.y, star.size)
        
        -- Add subtle glow for brighter stars
        if star.brightness > 0.7 and star.depth == 1 then
            love.graphics.setColor(star.color[1], star.color[2], star.color[3], alpha * 0.3)
            love.graphics.circle("fill", star.x, star.y, star.size * 2)
        end
    end
    
    -- Draw main particle effects (explosion particles)
    self.particleSystem:draw()
    
    -- Draw meteoroids (they continue falling during explosion)
    for _, meteoroid in ipairs(self.meteoroids) do
        meteoroid:draw(self.scoreMultiplier)
    end
    
    -- Don't draw the exploding player ship - hide the texture completely
    -- The explosion particles will represent the destroyed ship
    
    love.graphics.pop()
    
    -- Draw screen flash effects on top of everything
    self.particleSystem:drawScreenEffects()
    
    -- Draw popup notifications
    self:drawPopups()
    
    -- Draw minimal UI during explosion
    self:drawMinimalUI()
end

function Game:drawMenuSpaceship(centerX, centerY)
    -- Static display of the pixel art spaceship for menu
    -- Using the same design as the player ship but without any animation
    
    -- Exact colors from the pixel art image
    local darkBlue = {0.1, 0.2, 0.4}       -- Dark blue for main body
    local mediumBlue = {0.2, 0.4, 0.7}     -- Medium blue for body
    local lightBlue = {0.4, 0.6, 0.9}      -- Light blue highlights
    local veryLightBlue = {0.6, 0.8, 1.0}  -- Very light blue accents
    local whiteGray = {0.85, 0.9, 0.95}    -- White-gray for wings
    local darkGray = {0.3, 0.35, 0.4}      -- Dark details
    
    -- Scale factor for menu display (slightly larger than in-game)
    local scale = 1.2
    
    -- CENTER MAIN BODY (Dark blue triangle core)
    love.graphics.setColor(darkBlue)
    love.graphics.polygon("fill",
        centerX, centerY - 28*scale,        -- Top point
        centerX - 12*scale, centerY + 8*scale,    -- Bottom left
        centerX + 12*scale, centerY + 8*scale     -- Bottom right
    )
    
    -- MEDIUM BLUE BODY SECTIONS (Main fuselage)
    love.graphics.setColor(mediumBlue)
    -- Left body section
    love.graphics.polygon("fill",
        centerX - 8*scale, centerY - 20*scale,
        centerX - 12*scale, centerY - 5*scale,
        centerX - 8*scale, centerY + 8*scale,
        centerX - 4*scale, centerY - 8*scale
    )
    -- Right body section
    love.graphics.polygon("fill",
        centerX + 8*scale, centerY - 20*scale,
        centerX + 12*scale, centerY - 5*scale,
        centerX + 8*scale, centerY + 8*scale,
        centerX + 4*scale, centerY - 8*scale
    )
    
    -- LIGHT BLUE HIGHLIGHTS (Upper sections)
    love.graphics.setColor(lightBlue)
    -- Center top highlight
    love.graphics.polygon("fill",
        centerX, centerY - 28*scale,
        centerX - 6*scale, centerY - 12*scale,
        centerX + 6*scale, centerY - 12*scale
    )
    
    -- WHITE-GRAY WING EXTENSIONS
    love.graphics.setColor(whiteGray)
    -- Left wing
    love.graphics.polygon("fill",
        centerX - 12*scale, centerY - 5*scale,
        centerX - 20*scale, centerY + 2*scale,
        centerX - 16*scale, centerY + 8*scale,
        centerX - 8*scale, centerY + 8*scale
    )
    -- Right wing
    love.graphics.polygon("fill",
        centerX + 12*scale, centerY - 5*scale,
        centerX + 20*scale, centerY + 2*scale,
        centerX + 16*scale, centerY + 8*scale,
        centerX + 8*scale, centerY + 8*scale
    )
    
    -- VERY LIGHT BLUE ACCENTS (Top highlights)
    love.graphics.setColor(veryLightBlue)
    -- Top accent line
    love.graphics.polygon("fill",
        centerX, centerY - 28*scale,
        centerX - 3*scale, centerY - 20*scale,
        centerX + 3*scale, centerY - 20*scale
    )
    
    -- DARK GRAY DETAILS (Cockpit/details)
    love.graphics.setColor(darkGray)
    -- Cockpit window
    love.graphics.polygon("fill",
        centerX, centerY - 24*scale,
        centerX - 2*scale, centerY - 16*scale,
        centerX + 2*scale, centerY - 16*scale
    )
    
    -- Wing tip details
    love.graphics.rectangle("fill", centerX - 20*scale, centerY + 2*scale, 2*scale, 3*scale)
    love.graphics.rectangle("fill", centerX + 18*scale, centerY + 2*scale, 2*scale, 3*scale)
    
    -- Add engine glow effect for menu display
    love.graphics.setColor(0.3, 0.7, 1, 0.6)
    love.graphics.circle("fill", centerX - 8*scale, centerY + 8*scale, 3*scale)
    love.graphics.circle("fill", centerX + 8*scale, centerY + 8*scale, 3*scale)
    
    love.graphics.setColor(0.6, 0.9, 1, 0.8)
    love.graphics.circle("fill", centerX - 8*scale, centerY + 8*scale, 1.5*scale)
    love.graphics.circle("fill", centerX + 8*scale, centerY + 8*scale, 1.5*scale)
end

return Game
