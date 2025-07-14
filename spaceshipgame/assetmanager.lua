-- AssetManager.lua
-- Comprehensive texture and asset management system for Dodge the Meteoroids

local AssetManager = {}
AssetManager.__index = AssetManager

function AssetManager.new()
    local self = setmetatable({}, AssetManager)
    
    -- Asset containers
    self.textures = {}
    self.sounds = {}
    self.fonts = {}
    self.shaders = {}
    
    -- Asset paths
    self.assetPaths = {
        textures = {},
        fonts = {},
        sounds = {}
    }
    
    -- Default fallback settings
    self.defaultSettings = {
        textureFilter = "linear",
        soundVolume = 0.7,
        musicVolume = 0.5
    }
    
    return self
end

-- Load all textures with error handling
function AssetManager:loadTextures()
    for name, path in pairs(self.assetPaths.textures) do
        local success, texture = pcall(love.graphics.newImage, path)
        if success then
            texture:setFilter(self.defaultSettings.textureFilter, self.defaultSettings.textureFilter)
            self.textures[name] = texture
        else
            self.textures[name] = self:createFallbackTexture(name)
        end
    end
end

-- Create procedural fallback textures when files are missing
function AssetManager:createFallbackTexture(textureName)
    local canvas, fallbackTexture
    
    if textureName == "spaceship" then
        canvas = love.graphics.newCanvas(50, 20)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw a simple spaceship shape
        love.graphics.setColor(0.7, 0.8, 1, 1)
        love.graphics.polygon("fill", 25, 0, 45, 20, 35, 15, 15, 15, 5, 20)
        love.graphics.setColor(0.2, 0.6, 1, 1)
        love.graphics.polygon("fill", 25, 5, 35, 15, 15, 15)
        love.graphics.setColor(1, 0.8, 0.2, 1)
        love.graphics.circle("fill", 25, 8, 3)
        
    elseif string.find(textureName, "meteoroid") then
        canvas = love.graphics.newCanvas(60, 60)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw a rough meteoroid shape
        love.graphics.setColor(0.6, 0.4, 0.3, 1)
        love.graphics.circle("fill", 30, 30, 25)
        love.graphics.setColor(0.8, 0.5, 0.3, 1)
        love.graphics.circle("fill", 25, 25, 8)
        love.graphics.circle("fill", 35, 35, 6)
        love.graphics.setColor(0.4, 0.2, 0.1, 1)
        love.graphics.circle("fill", 20, 35, 4)
        love.graphics.circle("fill", 40, 20, 5)
        
    elseif textureName == "energy_orb" then
        canvas = love.graphics.newCanvas(30, 30)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0, 0, 0, 0)
        
        -- Draw energy orb
        love.graphics.setColor(0.2, 1, 0.4, 0.8)
        love.graphics.circle("fill", 15, 15, 12)
        love.graphics.setColor(0.5, 1, 0.7, 1)
        love.graphics.circle("fill", 15, 15, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", 15, 15, 4)
        
    else
        -- Generic fallback
        canvas = love.graphics.newCanvas(32, 32)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(1, 0, 1, 1) -- Magenta to indicate missing texture
    end
    
    love.graphics.setCanvas()
    fallbackTexture = love.graphics.newImage(canvas:newImageData())
    return fallbackTexture
end

-- Load fonts with fallback to system fonts
function AssetManager:loadFonts()
    local fontSizes = {
        small = 16,
        medium = 24,
        large = 36,
        title = 48
    }
    
    for size, pixels in pairs(fontSizes) do
        local success, font = pcall(love.graphics.newFont, pixels)
        if success then
            self.fonts[size] = font
        end
    end
    
    for name, path in pairs(self.assetPaths.fonts) do
        local success, font = pcall(love.graphics.newFont, path, 24)
        if success then
            self.fonts[name] = font
        end
    end
end

-- Load sounds with error handling
function AssetManager:loadSounds()
    for name, path in pairs(self.assetPaths.sounds) do
        local success, sound = pcall(love.audio.newSource, path, "static")
        if success then
            if name == "background_music" then
                sound:setLooping(true)
                sound:setVolume(self.defaultSettings.musicVolume)
            else
                sound:setVolume(self.defaultSettings.soundVolume)
            end
            self.sounds[name] = sound
        end
    end
end

-- Get texture safely
function AssetManager:getTexture(name)
    return self.textures[name] or self.textures["default"]
end

-- Get font safely
function AssetManager:getFont(name)
    return self.fonts[name] or self.fonts["medium"] or love.graphics.getFont()
end

-- Get sound safely
function AssetManager:getSound(name)
    return self.sounds[name]
end

function AssetManager:createAssetDirectories()
    local directories = {
        "assets",
        "assets/fonts",
        "assets/sounds"
    }
    
    for _, dir in ipairs(directories) do
        if not love.filesystem.getInfo(dir) then
            love.filesystem.createDirectory(dir)
        end
    end
end

-- Generate a detailed asset report
function AssetManager:cleanup()
    for name, sound in pairs(self.sounds) do
        sound:stop()
    end
    
    self.textures = {}
    self.sounds = {}
    self.fonts = {}
end

return AssetManager
