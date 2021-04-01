require("sprite")
require("world")
require("util")

Overworld = State:extend()

local library = {
  "card_bite",
  "card_claw",
}

function choose(from)
  return from[math.random(#from)]
end

function Overworld:init()
  local map_size = 240
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  self.bare = Sprite("bare")
  self.bare.x = WIDTH / 2 - 8
  self.bare.y = HEIGHT / 2 - 8

  self.aiming = Aiming("ui_aiming", 31, 34, 15.5, 18.5)

  self.map = World("map", map_width, map_height, map_size)
  self.map.x = -WIDTH / 2
  self.map.y = -HEIGHT / 2

  self.card_sel = 0
  self.hand = {}
  self.deck = {}
  self.discard = {}

  for n=1, 25 do
    local card = Card(choose(library))
    card.x = WIDTH
    card.y = HEIGHT
    card.tx = WIDTH
    card.ty = HEIGHT - n * 2 - 19
    card.flip = 1
    card.tflip = 1
    table.insert(self.deck, card)
  end

  -- prep graphics so they don't jump during the transition state
  self.map:update()
  self:aim()
end

function Overworld:aim()
  -- scaling mouse coordinates is annoying
  local mx, my = love.mouse.getPosition()
  mx = s2p(mx - SCISSOR.x)
  my = s2p(my - SCISSOR.y)

  -- finding bare center is annoying
  self.aiming.x = self.bare.x + 8
  self.aiming.y = self.bare.y + 8

  -- lock angle to eighth-turns (pi / 4 radians)
  local angle = math.angle(self.bare.x + 8, self.bare.y + 8, mx, my)
  local rnd = math.pi / 4
  angle = math.floor(angle / rnd + 0.5) * rnd
  self.aiming.angle =  angle + math.pi / 2
end

function Overworld:update(top, dt)
  self.map:update()

  for i, card in ipairs(self.deck) do
    card:update()
  end

  for i, card in ipairs(self.discard) do
    card:update()
  end

  for i, card in ipairs(self.hand) do
    local depth = 0

    card.tx = WIDTH / 2 - 17 * (#self.hand - 1) + 34 * (i - 1)
    card.ty = HEIGHT
    if i == self.card_sel then
      depth = -20
    else
      depth = 8
    end

    local angle = math.angle(card.x, card.y, WIDTH / 2, HEIGHT * 4)
    card.tx = card.tx + math.cos(angle) * depth
    card.ty = card.ty + math.sin(angle) * depth

    card.angle = angle + math.pi / 2
    card:update()
  end

  -- handle movement
  local ds = dt * 60
  local dx = 0
  local dy = 0

  if love.keyboard.isDown("a") then
    dx = dx - 1
  end
  if love.keyboard.isDown("d") then
    dx = dx + 1
  end

  if love.keyboard.isDown("w") then
    dy = dy - 1
  end
  if love.keyboard.isDown("s") then
    dy = dy + 1
  end

  -- diagonal movement should be slower
  if dx ~= 0 and dy ~= 0 then
    ds = ds / math.sqrt(2)
  end

  if dx ~= 0 or dy ~= 0 then
    self:move(dx * ds, dy * ds)
  end

  self:aim()
end

function Overworld:draw(top)
  self.map:draw()
  self.bare:draw()
  self.aiming:draw()

  for i, card in ipairs(self.hand) do
    card:draw()
  end

  for i, card in ipairs(self.deck) do
    card:draw()
  end

  for i, card in ipairs(self.discard) do
    card:draw()
  end
end

function Overworld:keypressed(top, key)
  local keymap = {
    ["1"]=1,
    ["2"]=2,
    ["3"]=3,
    ["4"]=4,
    ["5"]=5,
    ["6"]=6,
    ["7"]=7,
    ["8"]=8,
    ["9"]=9,
  }

  if keymap[key] ~= nil and keymap[key] <= #self.hand then
    self.card_sel = keymap[key]
  end
end

function Overworld:draw_card()
  if #self.hand == 8 then
    -- FIXME what happens if you overdraw?
    return
  end

  if #self.deck == 0 then
    -- FIXME what happens if you have no deck left?
    return
  end

  local card = table.remove(self.deck)
  card.tflip = 0
  table.insert(self.hand, card)
  if self.card_sel == 0 then
    self.card_sel = 1
  end

  if #self.deck == 0 then
    self:reshuffle()
  end
end

function Overworld:use_card()
  local card = table.remove(self.hand, self.card_sel)
  if card:castable() then
    card:cast()
    if self.card_sel > #self.hand then
      self.card_sel = #self.hand
    end
    card.angle = 0
    card.tx = 0
    card.ty = HEIGHT - #self.discard * 2 - 19
  end
  table.insert(self.discard, card)
end

function Overworld:reshuffle()
  -- FIXME because this moves things over to `deck` while they're still in the
  -- discard pile, for a brief moment they're shown in reshuffled deck order
  -- instead of discard order.

  for n=1, #self.discard do
    local card = table.remove(self.discard, math.random(#self.discard))
    table.insert(self.deck, card)
    card.tx = WIDTH
    card.ty = HEIGHT - n * 2 - 19
    card.tflip = 1
    card.delay = n * 3
  end
end

function Overworld:mousepressed(top, x, y, button)
  -- left
  if button == 1 then
    self:draw_card()
  end

  -- right
  if button == 2 and #self.hand > 0 then
    self:use_card()
  end
end

function Overworld:wheelmoved(top, x, y)
  if y < 0 then
    self.card_sel = self.card_sel + 1
  elseif y > 0 then
    self.card_sel = self.card_sel - 1
  end

  if self.card_sel == 0 then
    self.card_sel = #self.hand
  end

  if self.card_sel > #self.hand then
    self.card_sel = 1
  end
end

function Overworld:move(x, y)
  local hspace = WIDTH / 3
  local vspace = HEIGHT / 3

  -- move the bare
  self.bare.x = self.bare.x + x
  self.bare.y = self.bare.y + y

  -- lock the bare within the center third of the screen by scrolling the map
  -- inversely with the bare when he steps over the edge

  if self.bare.x < hspace then
    self.map.x = self.map.x - (self.bare.x - hspace)
    self.bare.x = hspace
  end

  if self.bare.x > WIDTH - self.bare.size - hspace then
    self.map.x = self.map.x - (self.bare.x - (WIDTH - self.bare.size - hspace))
    self.bare.x = (WIDTH - self.bare.size - hspace)
  end

  if self.bare.y < vspace then
    self.map.y = self.map.y - (self.bare.y - vspace)
    self.bare.y = vspace
  end

  if self.bare.y > HEIGHT - self.bare.size - vspace then
    self.map.y = self.map.y - (self.bare.y - (HEIGHT - self.bare.size - vspace))
    self.bare.y = (HEIGHT - self.bare.size - vspace)
  end

  -- compute the tile under the bare
  local sx = math.floor((self.bare.x - self.map.x_off) / self.map.tile_size)
  local sy = math.floor((self.bare.y - self.map.y_off) / self.map.tile_size)

  -- check collision with the bare's top left, top right, bottom left, and
  -- bottom right corners, shifting his position appropriately
  self:collide(sx, sy)
  self:collide(sx, sy + 1)
  self:collide(sx + 1, sy)
  self:collide(sx + 1, sy + 1)
end

function Overworld:collide(x, y)
  -- get the bare's position within the map
  local bx = self.bare.x - self.map.x_off
  local by = self.bare.y - self.map.y_off

  -- decide if the tile is blocked
  local blocked = self.map:get_blocked(self.map.x_start + x, self.map.y_start + y)

  if blocked then

    -- compute the tile's coordinates within the map
    local tx = x * self.map.tile_size
    local ty = y * self.map.tile_size

    -- compute the bare's angle from the tile
    local dx = bx - tx
    local dy = by - ty
    local angle = math.atan2(dy, dx) / math.pi / 2

    -- depending on the direction from the tile, shift the bare away from it

    -- bare is below
    if angle >= 1 / 8 and angle <= 3 / 8 then
      self.bare.y = (y + 1) * self.map.tile_size + self.map.y_off
    end

    -- bare is above
    if angle >= -3 / 8 and angle <= -1 / 8 then
      self.bare.y = (y - 1) * self.map.tile_size + self.map.y_off
    end

    -- bare is right
    if angle >= -1 / 8 and angle <= 1 / 8 then
      self.bare.x = (x + 1) * self.map.tile_size + self.map.x_off
    end

    -- bare is left
    if angle <= -3 / 8 or angle >= 3 / 8 then
      self.bare.x = (x - 1) * self.map.tile_size + self.map.x_off
    end
  end
end
