-- TextureGenerator.lua
-- Script to generate all missing textures for the space game

local TextureGenerator = {}

function TextureGenerator.generateSpaceshipTexture(width, height)
    local canvas = love.graphics.newCanvas(width or 50, height or 20)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local w, h = canvas:getDimensions()
    local centerX, centerY = w/2, h/2
    
    -- Main hull (silver/white)
    love.graphics.setColor(0.8, 0.85, 0.9, 1)
    love.graphics.polygon("fill", 
        centerX, 2,                    -- nose
        w-5, h-2,                      -- right back
        w-8, h-1,                      -- right inner
        centerX+3, centerY,            -- right center
        centerX-3, centerY,            -- left center
        8, h-1,                        -- left inner
        5, h-2                         -- left back
    )
    
    -- Engine exhausts (blue glow)
    love.graphics.setColor(0.2, 0.6, 1, 0.8)
    love.graphics.circle("fill", 7, h-1, 2)
    love.graphics.circle("fill", w-7, h-1, 2)
    
    -- Cockpit (bright blue)
    love.graphics.setColor(0.3, 0.8, 1, 1)
    love.graphics.circle("fill", centerX, 6, 3)
    
    -- Wing details (darker blue)
    love.graphics.setColor(0.4, 0.5, 0.8, 1)
    love.graphics.rectangle("fill", 10, h-4, 8, 2)
    love.graphics.rectangle("fill", w-18, h-4, 8, 2)
    
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function TextureGenerator.generateMeteoroidTexture(size)
    local canvas = love.graphics.newCanvas(size or 60, size or 60)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local radius = (size or 60) / 2
    local centerX, centerY = radius, radius
    
    -- Base rock (dark brown/gray)
    love.graphics.setColor(0.3, 0.25, 0.2, 1)
    love.graphics.circle("fill", centerX, centerY, radius * 0.9)
    
    -- Craters and surface details
    love.graphics.setColor(0.2, 0.15, 0.1, 1)
    for i = 1, 5 do
        local x = centerX + math.random(-radius*0.6, radius*0.6)
        local y = centerY + math.random(-radius*0.6, radius*0.6)
        local craterSize = math.random(3, 8)
        love.graphics.circle("fill", x, y, craterSize)
    end
    
    -- Hot spots (glowing parts)
    love.graphics.setColor(0.8, 0.4, 0.2, 0.8)
    for i = 1, 3 do
        local x = centerX + math.random(-radius*0.4, radius*0.4)
        local y = centerY + math.random(-radius*0.4, radius*0.4)
        local hotSize = math.random(2, 5)
        love.graphics.circle("fill", x, y, hotSize)
    end
    
    -- Bright lava veins
    love.graphics.setColor(1, 0.6, 0.2, 0.9)
    love.graphics.setLineWidth(2)
    for i = 1, 3 do
        local startX = centerX + math.random(-radius*0.5, radius*0.5)
        local startY = centerY + math.random(-radius*0.5, radius*0.5)
        local endX = startX + math.random(-15, 15)
        local endY = startY + math.random(-15, 15)
        love.graphics.line(startX, startY, endX, endY)
    end
    
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function TextureGenerator.generatePowerUpTexture(size)
    local canvas = love.graphics.newCanvas(size or 30, size or 30)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local radius = (size or 30) / 2
    local centerX, centerY = radius, radius
    
    -- Outer energy ring
    love.graphics.setColor(0.2, 1, 0.4, 0.6)
    love.graphics.circle("fill", centerX, centerY, radius * 0.9)
    
    -- Middle energy layer
    love.graphics.setColor(0.4, 1, 0.6, 0.8)
    love.graphics.circle("fill", centerX, centerY, radius * 0.6)
    
    -- Inner core
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", centerX, centerY, radius * 0.3)
    
    -- Energy spikes
    love.graphics.setColor(0.6, 1, 0.8, 0.7)
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2
        local x1 = centerX + math.cos(angle) * radius * 0.4
        local y1 = centerY + math.sin(angle) * radius * 0.4
        local x2 = centerX + math.cos(angle) * radius * 0.8
        local y2 = centerY + math.sin(angle) * radius * 0.8
        love.graphics.line(x1, y1, x2, y2)
    end
    
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function TextureGenerator.generateStarTexture(size)
    local canvas = love.graphics.newCanvas(size or 4, size or 4)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local centerX, centerY = (size or 4) / 2, (size or 4) / 2
    
    -- Main star
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", centerX, centerY, (size or 4) / 4)
    
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function TextureGenerator.generateExplosionTexture(size)
    local canvas = love.graphics.newCanvas(size or 64, size or 64)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local centerX, centerY = (size or 64) / 2, (size or 64) / 2
    local radius = (size or 64) / 2
    
    -- Outer explosion (red/orange)
    love.graphics.setColor(1, 0.3, 0.1, 0.8)
    love.graphics.circle("fill", centerX, centerY, radius * 0.9)
    
    -- Middle explosion (orange/yellow)
    love.graphics.setColor(1, 0.6, 0.2, 0.9)
    love.graphics.circle("fill", centerX, centerY, radius * 0.6)
    
    -- Inner explosion (white/yellow)
    love.graphics.setColor(1, 1, 0.8, 1)
    love.graphics.circle("fill", centerX, centerY, radius * 0.3)
    
    -- Explosion fragments
    love.graphics.setColor(1, 0.8, 0.4, 0.7)
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local distance = radius * 0.7
        local x = centerX + math.cos(angle) * distance
        local y = centerY + math.sin(angle) * distance
        love.graphics.circle("fill", x, y, 3)
    end
    
    love.graphics.setCanvas()
    return love.graphics.newImage(canvas:newImageData())
end

function TextureGenerator.generateAllTextures()
    local textures = {}
    
    textures.spaceship = TextureGenerator.generateSpaceshipTexture(50, 20)
    
    textures.meteoroid1 = TextureGenerator.generateMeteoroidTexture(60)
    textures.meteoroid2 = TextureGenerator.generateMeteoroidTexture(80)
    textures.meteoroid3 = TextureGenerator.generateMeteoroidTexture(45)
    textures.meteoroid4 = TextureGenerator.generateMeteoroidTexture(70)
    
    textures.energy_orb = TextureGenerator.generatePowerUpTexture(30)
    textures.star = TextureGenerator.generateStarTexture(4)
    textures.explosion = TextureGenerator.generateExplosionTexture(64)
    
    return textures
end

return TextureGenerator
