require("conf")
require("engine")
require("gfx")
require("util")

Sprite = Object:extend()

function Sprite:init(id)
  self.x = 0
  self.y = 0
  self.size = framesets[atlas[id].frameset].size
  self.sx = 1
  self.sy = 1
  self.ox = 0
  self.oy = 0
  self.angle = 0
  self.frame = 0
  self.visible = true

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
end

function Sprite:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.gfx, self.quads[self.frame],
                      S(self.x), S(self.y), self.angle,
                      SCALE * self.sx, SCALE * self.sy,
                      self.ox, self.oy)
  end
end

Card = Object:extend()

function Card:init(tex)
  self.x = 0
  self.y = 0
  self.tx = 0
  self.w = 30
  self.h = 42
  self.ty = 0
  self.ox = 15
  self.oy = 21
  self.angle = 0
  self.quad = love.graphics.newQuad(0, 0, 30, 42, 30, 42)
  self.tex = load_gfx(tex)
end

function Card:update()
  self.x = self.x + (self.tx - self.x) / 4
  self.y = self.y + (self.ty - self.y) / 4
end

function Card:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.tex, self.quad, S(self.x), S(self.y), self.angle, SCALE, SCALE, self.ox, self.oy)
end

function Card:castable()
  return true
end

function Card:cast()
  return true
end

Aiming = Object:extend()

function Aiming:init(tex, w, h, ox, oy)
  self.tex = load_gfx(tex)
  self.w = w
  self.h = h
  self.ox = ox
  self.oy = oy
  self.angle = 0
  self.x = 0
  self.y = 0
  self.quad = love.graphics.newQuad(0, 0, w, h, w, h)
end

function Aiming:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.tex, self.quad, S(self.x), S(self.y), self.angle, SCALE, SCALE, self.ox, self.oy)
end
