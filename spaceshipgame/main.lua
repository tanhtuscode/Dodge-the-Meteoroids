local Game = require("game")
local GameSetup = require("gamesetup")

local game

function love.load()
    GameSetup.initializeGame()
    game = Game.new()
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.mousepressed(x, y, button)
    if game then
        game:mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f11" then
        -- Toggle fullscreen
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    elseif key == "r" and game and game.gameState == "gameOver" then
        game:reset()
    end
end
