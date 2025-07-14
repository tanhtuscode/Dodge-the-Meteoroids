-- AssetInitializer.lua
-- Complete asset initialization and setup script for Dodge the Meteoroids

local AssetManager = require("assetmanager")
local TextureGenerator = require("texturegenerator")

local AssetInitializer = {}

function AssetInitializer.initializeAllAssets()
    local assetManager = AssetManager.new()
    
    assetManager:createAssetDirectories()
    assetManager:loadTextures()
    assetManager:loadFonts()
    assetManager:loadSounds()
    
    local generatedTextures = TextureGenerator.generateAllTextures()
    
    for name, texture in pairs(generatedTextures) do
        if not assetManager.textures[name] or name:find("generated") then
            assetManager.textures[name] = texture
        end
    end
    
    for i = 1, 4 do
        local meteoroidName = "meteoroid" .. i
        if not assetManager.textures[meteoroidName] then
            local size = math.random(40, 80)
            assetManager.textures[meteoroidName] = TextureGenerator.generateMeteoroidTexture(size)
        end
    end
    
    for i = 1, 3 do
        local starName = "star" .. i
        local size = i + 1
        assetManager.textures[starName] = TextureGenerator.generateStarTexture(size)
    end
    
    return assetManager
end

function AssetInitializer.quickDevSetup()
    local assetManager = AssetManager.new()
    local generatedTextures = TextureGenerator.generateAllTextures()
    
    for name, texture in pairs(generatedTextures) do
        assetManager.textures[name] = texture
    end
    
    for i = 1, 6 do
        local size = 30 + i * 10
        assetManager.textures["meteoroid" .. i] = TextureGenerator.generateMeteoroidTexture(size)
    end
    
    assetManager:loadFonts()
    
    return assetManager
end

return AssetInitializer
