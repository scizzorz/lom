require("conf")
require("engine")
require("gfx")
require("util")

Sprite = Object:extend()

function Sprite:init(data)
  self.x = 0
  self.y = 0
  self.sx = 1
  self.sy = 1
  self.ox = 0
  self.oy = 0
  self.angle = 0
  self.frame = 0

  self.anim = nil

  self.data = data
  self.tex = load_texture(self.data.texture)
  self.quad = build_quad(self.data.frameset, self.frame)
end

function Sprite:set_frame(to)
  if to ~= self.frame then
    self.frame = to
    self.quad = build_quad(self.data.frameset, self.frame)
  end
end

function Sprite:update()
  if self.anim then
    self:set_frame(self.anim:update())
  end
end

function Sprite:set_anim(label)
  if self.data.anims == nil then
    print("Attempting to set animation to " .. tostring(label))
  end


  local anim_table = self.data.anims[label]
  if (self.anim == nil) or (anim_table ~= self.anim.data) then
    self.anim = Anim(anim_table)
    self:set_frame(self.anim:cur())
  end
end

function Sprite:draw(no_color)
  if not no_color then
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.draw(self.tex, self.quad,
                    S(self.x), S(self.y), self.angle,
                    SCALE * self.sx, SCALE * self.sy,
                    self.ox, self.oy)
end

HealthBar = Object:extend()

function HealthBar:init(cur, max, border_data, fill_data)
  self.cur = cur or 50
  self.max = max or 100
  self.x = 0
  self.y = 0
  self.tx = 0
  self.w = 80
  self.h = 16
  self.ty = 0
  self.ox = 0
  self.oy = 0
  self.angle = 0

  self.border_tex = load_texture(border_data.texture)
  self.border_quad = build_quad(border_data.frameset, 0)

  self.fill_data = fill_data
  self.fill_tex = load_texture(fill_data.texture)
end

function HealthBar:update(cur)
  self.cur = cur
end

function HealthBar:draw()
  -- draw border
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.border_tex, self.border_quad, S(self.x), S(self.y), self.angle, SCALE, SCALE, self.ox, self.oy)

  -- draw fill if we have some value
  if self.cur > 0 then
    love.graphics.setColor(self.cur / self.max * 0.6 + 0.4, 0.1, 0.1)
    local width = math.max(1, math.floor(self.cur / self.max * 66))
    local fill_quad = love.graphics.newQuad(0, 0, width, 10, 66, 10)
    love.graphics.draw(self.fill_tex, fill_quad, S(self.x + 12), S(self.y + 3), self.angle, SCALE, SCALE, self.ox, self.oy)
  end
end

Card = Object:extend()

function Card:init(id)
  self.id = id
  self.data = card_db[id]
  self.x = 0
  self.y = 0
  self.tx = 0
  self.w = 30
  self.h = 42
  self.ty = 0
  self.ox = 15
  self.oy = 21
  self.angle = 0
  self.flip = 0
  self.tflip = 0
  self.delay = 0

  self.fade = 0
  self.tfade = 0

  self.quad = love.graphics.newQuad(0, 0, 30, 42, 30, 42)
  self.tex = load_texture(self.data.art)
  self.back = load_texture("card_back")

  self.digits = load_texture("card_text")
end

function Card:cost()
  return self.data.cost
end

function Card:update()
  if self.delay > 0 then
    self.delay = self.delay - 1
  else
    self.x = self.x + (self.tx - self.x) / CARD_MOVE_SPEED
    self.y = self.y + (self.ty - self.y) / CARD_MOVE_SPEED
    self.flip = self.flip + (self.tflip - self.flip) / CARD_FLIP_SPEED
    self.fade = self.fade + (self.tfade - self.fade) / CARD_FADE_SPEED
  end

  self.cost_quad = build_quad(atlas.text.frameset, self:cost())
end

function Card:draw(usable, castable)
  if usable == nil then
    usable = true
  end

  if castable == nil then
    castable = true
  end

  love.graphics.setColor(1, 1, 1)

  -- draw card back
  if self.flip > 0.5 then
    love.graphics.draw(self.back, self.quad, S(self.x), S(self.y), self.angle, SCALE * 2 * (self.flip - 0.5), SCALE, self.ox, self.oy)

  -- draw card face, faded for mana
  else
    -- fade uncastable costs to grey-blue
    love.graphics.setColor(1 - 0.6 * self.fade, 1 - 0.6 * self.fade, 1 - 0.5 * self.fade)

    -- draw card art
    love.graphics.draw(
      self.tex, self.quad,
      S(self.x), S(self.y),
      self.angle,
      SCALE * 2 * (0.5 - self.flip), SCALE,
      self.ox, self.oy
    )

    -- fade unusable costs to red
    if not usable then
      love.graphics.setColor(1 - 0.3 * self.fade, 1 - 0.8 * self.fade, 1 - 0.8 * self.fade)
    end

    -- FIXME placeholder to draw name if the card doesn't have art
    if self.tex == load_texture("card_blank") then
      draw_text(self.data.name:sub(1, 4), self.x - 15, self.y - 8)
    end

    -- draw mana cost
    -- the magic numbers for offsetting this are derived from offsetting the
    -- center of the cost by (-8.5, -13) from the center of the card.
    -- atan2(-13, -8.5) = -2.15
    -- sqrt(13^2 + 8.5^2) = 15.53
    love.graphics.draw(
      self.digits, self.cost_quad,
      S(self.x + 15.53 * math.cos(self.angle - 2.15)), S(self.y + 15.53 * math.sin(self.angle - 2.15)),
      self.angle,
      SCALE * 2 * (0.5 - self.flip), SCALE,
      3.5, 5
    )
  end
end

-- usable means this card _could_ be used, but something is temporarily
-- blocking it, like another animation
function Card:usable()
  return OVERWORLD.mana >= self:cost() * MANA_PARTS
end

-- castable means this card can currently be cast this frame
function Card:castable()
  return self:usable() and OVERWORLD.char.lag <= 0
end

-- FIXME this should take a caster
function Card:cast()
  -- consume mana
  OVERWORLD.mana = OVERWORLD.mana - self:cost() * MANA_PARTS

  if self.data.cast then
    -- get mouse target location
    local mx, my = love.mouse.getPosition()
    mx = s2p(mx - SCISSOR.x)
    my = s2p(my - SCISSOR.y)

    local action = function()
      -- consume Cold Blood for the first cast otherwise Cold Blood applies and
      -- then just consumes itself :(
      if OVERWORLD.char.status.cold_blood then
        self.data.cast(OVERWORLD.char, mx, my)
        OVERWORLD.char.status.cold_blood = nil
      end

      self.data.cast(OVERWORLD.char, mx, my)

      -- initiate end lag
      if (self.data.endlag or 0) > 0 then
        OVERWORLD.char.lag = self.data.endlag
      end
    end

    -- initiate start lag or cast instantly
    if (self.data.startlag or 0) > 0 then
      OVERWORLD.char.lag = self.data.startlag
      OVERWORLD.char.lag_action = action
    else
      action()
    end
  end

  return true
end

Aiming = Object:extend()

function Aiming:init(tex, w, h, ox, oy)
  self.tex = load_texture(tex)
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

SCT = Object:extend()

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
