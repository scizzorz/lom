require("conf")
require("engine")
require("gfx")
require("overworld")
require("sprite")
require("util")
require("world")

local fps = 0

function love.load()
  print("love.load")

  local screen_width, screen_height = love.graphics.getDimensions()
  local screen_aspect = screen_width / screen_height

  if screen_aspect < GAME_ASPECT then
    -- less widescreen, means width is dominant and we need letterboxes
    CANVAS_SCALE = screen_width / WIDTH / SCALE
    SCISSOR = {
      x=0,
      y=(screen_height - p2s(HEIGHT)) / 2,
      width=p2s(WIDTH),
      height=p2s(HEIGHT),
    }
  else
    -- more widescreen, means height is dominant and we need pillarboxes
    CANVAS_SCALE = screen_height / HEIGHT / SCALE
    SCISSOR = {
      x=(screen_width - p2s(WIDTH)) / 2,
      y=0,
      width=p2s(WIDTH),
      height=p2s(HEIGHT),
    }
  end

  canvas = love.graphics.newCanvas(WIDTH * SCALE, HEIGHT * SCALE)

  print("window:  " .. screen_width .. " x " .. screen_height)
  print("canvas:  " .. WIDTH .. " x " .. HEIGHT)
  print("scale:   " .. SCALE)
  print("c scale: " .. CANVAS_SCALE)
  print("scissor: " .. SCISSOR.width .. " x " .. SCISSOR.height .. " @ " .. SCISSOR.x .. ", " .. SCISSOR.y)

  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineStyle("rough")

  ENGINE = Engine()
  OVERWORLD = Overworld()
  ENGINE:push_state(OVERWORLD)
end

function love.draw()
  love.graphics.clear(0, 0, 0)
  love.graphics.setScissor(SCISSOR.x, SCISSOR.y, SCISSOR.width, SCISSOR.height)
  love.graphics.translate(SCISSOR.x, SCISSOR.y)
  love.graphics.scale(CANVAS_SCALE, CANVAS_SCALE)

  ENGINE:ctl("draw")

  love.graphics.print("fps " .. math.floor(fps + 0.5), 0, 0)

  love.graphics.setScissor()
end

function love.update(dt, ...)
  fps = 1 / dt
  ENGINE:ctl("update", dt, ...)
end

function love.mousepressed(...)
  ENGINE:ctl("mousepressed", ...)
end

function love.mousereleased(...)
  ENGINE:ctl("mousereleased", ...)
end

function love.mousemoved(...)
  ENGINE:ctl("mousemoved", ...)
end

function love.wheelmoved(...)
  ENGINE:ctl("wheelmoved", ...)
end

function love.keypressed(key, ...)
  if key == "r" and love.keyboard.isDown("lctrl") then
    love.event.quit("restart")
  elseif key == "escape" then
    love.event.quit()
  elseif key == "enter" or key == "return" then
    OVERWORLD = Overworld()
    ENGINE:change_state(OVERWORLD)
  else
    ENGINE:ctl("keypressed", key, ...)
  end
end
