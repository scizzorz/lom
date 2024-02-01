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

function Sprite:draw(r, g, b)
  -- no_color is used by the menu
  r = r or 1
  g = g or 1
  b = b or 1
  love.graphics.setColor(r, g, b)

  love.graphics.draw(
    self.tex, self.quad,
    self.x, self.y,
    self.angle,
    self.sx, self.sy,
    self.ox, self.oy
  )
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
  love.graphics.draw(self.border_tex, self.border_quad, self.x, self.y, self.angle, nil, nil, self.ox, self.oy)

  -- draw fill if we have some value
  if self.cur > 0 then
    love.graphics.setColor(self.cur / self.max * 0.6 + 0.4, 0.1, 0.1)
    local width = math.max(1, math.floor(self.cur / self.max * 66))
    local fill_quad = love.graphics.newQuad(0, 0, width, 10, 66, 10)
    love.graphics.draw(self.fill_tex, fill_quad, self.x + 12, self.y + 3, self.angle, nil, nil, self.ox, self.oy)
  end
end

Card = Object:extend()

CARD_QUAD = love.graphics.newQuad(0, 0, 30, 42, 30, 42)
ART_QUAD = love.graphics.newQuad(0, 0, 28, 40, 28, 40)

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

  self.art = load_texture(self.data.art)
  self.back = load_texture("card_back")
  self.border = load_texture("card_border")
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
    love.graphics.draw(
      self.back, CARD_QUAD,
      self.x, self.y,
      self.angle,
      2 * (self.flip - 0.5), nil,
      self.ox, self.oy
    )

  -- draw card face, faded for mana
  else
    -- fade uncastable costs to grey-blue
    love.graphics.setColor(1 - 0.6 * self.fade, 1 - 0.6 * self.fade, 1 - 0.5 * self.fade)

    -- draw card art
    love.graphics.draw(
      self.art, ART_QUAD,
      self.x, self.y,
      self.angle,
      2 * (0.5 - self.flip), nil,
      self.ox - 1, self.oy - 1
    )

    -- draw card border
    love.graphics.draw(
      self.border, CARD_QUAD,
      self.x, self.y,
      self.angle,
      2 * (0.5 - self.flip), nil,
      self.ox, self.oy
    )

    -- fade unusable costs to red
    if not usable then
      love.graphics.setColor(1 - 0.3 * self.fade, 1 - 0.8 * self.fade, 1 - 0.8 * self.fade)
    end

    -- FIXME placeholder to draw name if the card doesn't have art
    if self.art == load_texture("card_blank") then
      draw_text(self.data.name:sub(1, 4), self.x - 15, self.y - 8)
    end

    -- draw mana cost
    -- the magic numbers for offsetting this are derived from offsetting the
    -- center of the cost by (-8.5, -13) from the center of the card.
    -- atan2(-13, -8.5) = -2.15
    -- sqrt(13^2 + 8.5^2) = 15.53
    love.graphics.draw(
      self.digits, self.cost_quad,
      self.x + 15.53 * math.cos(self.angle - 2.15), self.y + 15.53 * math.sin(self.angle - 2.15),
      self.angle,
      2 * (0.5 - self.flip), nil,
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
        OVERWORLD.char:purge("cold_blood")
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
