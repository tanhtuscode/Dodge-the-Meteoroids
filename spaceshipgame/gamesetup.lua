
local AssetInitializer = require("assetinitializer")

local GameSetup = {}

function GameSetup.initializeGame()
    love.window.setTitle("Dodge the Meteoroids")
    local assetManager = AssetInitializer.initializeAllAssets()
    return assetManager
end


return GameSetup
