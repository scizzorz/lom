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

  love.window.setFullscreen(true)

  local screen_width, screen_height = love.graphics.getDimensions()
  if screen_width < screen_height then
    WIDTH = MIN_WIDTH
    HEIGHT = math.ceil(screen_height / screen_width * MIN_WIDTH)
    CANVAS_SCALE = screen_width / MIN_WIDTH / SCALE
  else
    HEIGHT = MIN_HEIGHT
    WIDTH = math.ceil(screen_width / screen_height * MIN_HEIGHT)
    CANVAS_SCALE = screen_height / MIN_HEIGHT / SCALE
  end

  canvas = love.graphics.newCanvas(WIDTH * SCALE, HEIGHT * SCALE)

  print("window:  " .. screen_width .. " x " .. screen_height)
  print("canvas:  " .. WIDTH .. " x " .. HEIGHT)
  print("scale:   " .. SCALE)
  print("c scale: " .. CANVAS_SCALE)

  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineStyle("rough")

  ENGINE = Engine()
  OVERWORLD = Overworld()
  ENGINE:push_state(OVERWORLD)
end

function love.draw()
  love.graphics.setCanvas(canvas)

  ENGINE:ctl("draw")

  love.graphics.print("fps " .. math.floor(fps + 0.5), 0, 0)

  love.graphics.setCanvas()
  love.graphics.draw(canvas, 0, 0, 0, CANVAS_SCALE, CANVAS_SCALE)
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

function love.keypressed(key)
  if key == "r" and love.keyboard.isDown("lctrl") then
    love.event.quit("restart")
  elseif key == "escape" then
    love.event.quit()
  end
end
