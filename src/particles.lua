require("conf")
require("engine")
require("gfx")
require("util")

Particle = Object:extend()

function Particle:done()
  return false
end

function Particle:deinit()
end

-- scrolling combat text

SCT = Particle:extend()

function SCT:init(text, x, y, color)
  self.text = tostring(text)
  self.x = x
  self.y = y
  self.ty = y - 12
  self.a = 1
  self.ta = 1
  self.color = color
  self.timer = SCT_DURATION
end

function SCT:update(dt)
  self.timer = self.timer - dt

  if self.timer <= SCT_FADE_START then
    self.ta = 0
  end

  self.y = self.y + (self.ty - self.y) / SCT_SPEED
  self.a = self.a + (self.ta - self.a) / SCT_SPEED
end

function SCT:box()
  local x = self.x - 4 * #self.text
  local w = 8 * #self.text
  local y = self.y
  local h = 10
  return x, y, w, h
end

function SCT:overlaps(other)
  local sx, sy, sw, sh = self:box()
  local ox, oy, ow, oh = other:box()
  return (
    (sx + sw >= ox) and (ox + ow >= sx)
    and
    (sy + sh >= oy) and (oy + oh >= sy)
  )
end

function SCT:done()
  return self.timer <= 0
end

function SCT:deinit()
end

function SCT:draw()
  love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.a)
  draw_text(self.text, self.x - 4 * #self.text, self.y)
end

function draw_text(text, x, y)
  text = tostring(text):lower()
  local tex = load_texture("card_text")
  local c, f, quad

  for i=1, #text do
    c = text:sub(i, i):byte()
    if c >= 97 and c <= 122 then
      -- a..z start at f10
      f = c - 87
    elseif c >= 48 and c <= 57 then
      -- 0..9 start at f0
      f = c - 48
    elseif c >= 42 and c <= 45 then
      -- *+,- start at f36
      f = c - 6
    else
      -- ?
      f = 38
    end

    -- don't even try drawing a space, okay
    if c == 32 then
      x = x + 4
    else
      quad = build_quad(atlas.text.frameset, f)

      love.graphics.draw(
        tex, quad,
        S(x), S(y),
        angle,
        SCALE, SCALE
      )

      x = x + 8
    end

    -- special case I and T because their characters are 1px narrower
    if c == 105 or c == 116 then
      x = x - 1
    end
  end

  return x
end

function draw_cd(cd, x, y, w, h, r, g, b, a)
  r = r or 1
  g = g or 1
  b = b or 1
  a = a or 0.5

  local angle = cd * math.pi * 2 - math.pi / 2
  local dx = math.cos(angle)
  local dy = math.sin(angle)

  local cx = x + w / 2
  local cy = y + h / 2

  while cx < x + w and cy < y + h and cx > x and cy > y do
    cx = cx + dx
    cy = cy + dy
  end

  cx = math.min(math.max(cx, x), x + w)
  cy = math.min(math.max(cy, y), y + h)

  local vertices = {}

  -- center
  table.insert(vertices, S(x + w / 2))
  table.insert(vertices, S(y + h / 2))

  -- top middle
  table.insert(vertices, S(x + w / 2))
  table.insert(vertices, S(y))

  if cd > 0.125 then
    -- top right corner
    table.insert(vertices, S(x + w))
    table.insert(vertices, S(y))
  end

  if cd > 0.375 then
    -- bottom right corner
    table.insert(vertices, S(x + w))
    table.insert(vertices, S(y + h))
  end

  if cd > 0.625 then
    -- bottom left corner
    table.insert(vertices, S(x))
    table.insert(vertices, S(y + h))
  end

  if cd > 0.875 then
    -- top left
    table.insert(vertices, S(x))
    table.insert(vertices, S(y))
  end

  -- cooldown point
  table.insert(vertices, S(cx))
  table.insert(vertices, S(cy))

  love.graphics.setColor(r or 1, g or 1, b or 1, a or 0.5)
  love.graphics.polygon("fill", vertices)

  love.graphics.setColor(1 - r, 1 - g, 1 - b, 1 - a)
  love.graphics.setLineWidth(2)
  love.graphics.line(S(x + w / 2), S(y + w / 2), S(cx), S(cy))
end

-- the slash icon that appears on the enemy after taking a hit

SLASH_DURATION = 0.5
SLASH_FADE_SPEED = 8

Slash = Particle:extend()

function Slash:init(state, x, y)
  self.fade = 1
  self.tfade = 0
  self.x = x
  self.y = y

  self.tex = load_texture("atk_slash")
  self.quad = build_quad(atlas.slash.frameset, love.math.random(0, 7))
end

function Slash:update(dt)
  self.fade = self.fade + (self.tfade - self.fade) / SLASH_FADE_SPEED
end

function Slash:done()
  return self.fade <= 0.01
end

function Slash:deinit()
end

function Slash:draw()
  love.graphics.setColor(1, 1, 1, self.fade)
  love.graphics.draw(self.tex, self.quad, S(self.x), S(self.y), nil, SCALE, SCALE, 12.5, 12.5)
end
