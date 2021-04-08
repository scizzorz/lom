require("data")
require("sprite")
require("util")
require("world")

Overworld = State:extend()

local library = {}

for name, data in pairs(card_db) do
  table.insert(library, name)
end

function choose(from)
  return from[math.random(#from)]
end

function Overworld:init()
  local map_size = 240
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  self.char = Sprite("dummy")
  self.char.x = WIDTH / 2 - self.char.size / 2
  self.char.y = HEIGHT / 2 - self.char.size / 2

  self.aiming = Aiming("ui_aiming", 31, 34, 15.5, 18.5)

  self.map = World("map", map_width, map_height, map_size)
  self.map.x = -WIDTH / 2
  self.map.y = -HEIGHT / 2

  self.max_mana = MAX_MANA * MANA_PARTS
  self.mana = 0

  self.max_health = MAX_HEALTH
  self.health = 0

  self.card_sel = 0
  self.hand = {}
  self.deck = {}
  self.discard = {}

  self.ui_health = HealthBar(self.health, self.max_health)
  self.ui_health.x = 0
  self.ui_health.y = 0

  self.ui_mana = {}
  for n=1, (self.max_mana / MANA_PARTS) do
    local crystal = Sprite("mana")
    crystal.x = (n - 1) * crystal.size
    crystal.y = 16
    table.insert(self.ui_mana, crystal)
  end

  for n=1, DECK_SIZE do
    local card = Card(choose(library))
    card.x = WIDTH
    card.y = HEIGHT
    card.tx = WIDTH
    card.ty = HEIGHT - n * DECK_SPACING + DECK_DEPTH
    card.flip = 1
    card.tflip = 1
    table.insert(self.deck, card)
  end

  -- prep graphics so they don't jump during the transition state
  self.map:update()
  self:aim()
  self:update_mana_ui()
end

function Overworld:aim()
  -- scaling mouse coordinates is annoying
  local mx, my = love.mouse.getPosition()
  mx = s2p(mx - SCISSOR.x)
  my = s2p(my - SCISSOR.y)

  -- finding char center is annoying
  self.aiming.x = self.char.x + self.char.size / 2
  self.aiming.y = self.char.y + self.char.size / 2

  -- lock angle to eighth-turns (pi / 4 radians)
  local angle = math.angle(self.char.x + self.char.size / 2, self.char.y + self.char.size / 2, mx, my)
  if AIMING_STEPS > 0 then
    local rnd = (2 * math.pi) / AIMING_STEPS
    angle = math.floor(angle / rnd + 0.5) * rnd
  end
  self.aiming.angle =  angle + math.pi / 2
end

function Overworld:update_mana_ui()
  for i, crystal in ipairs(self.ui_mana) do
    if i * MANA_PARTS > self.mana then
      crystal.frame = 1
    else
      crystal.frame = 0
    end
  end
end

function Overworld:update(top, dt)
  self.map:update()
  self:update_mana_ui()
  self.ui_health:update(self.health)
  self.char:update()

  if self.health < self.max_health then
    self.health = self.health + 1
  end

  if self.mana < self.max_mana then
    self.mana = self.mana + 1
  end

  for i, card in ipairs(self.deck) do
    card:update(self)
  end

  for i, card in ipairs(self.discard) do
    card:update()
  end

  for i, card in ipairs(self.hand) do
    local depth = 0

    card.tx = (WIDTH / 2) - (HAND_SPACING / 2 * (#self.hand - 1)) + (HAND_SPACING * (i - 1))
    card.ty = HEIGHT
    if i == self.card_sel then
      depth = SELECTED_DEPTH
    else
      depth = HAND_DEPTH
    end

    local angle = math.angle(card.x, card.y, WIDTH / 2, HEIGHT * HAND_ANGLE)
    card.tx = card.tx + math.cos(angle) * depth
    card.ty = card.ty + math.sin(angle) * depth

    card.angle = angle - math.pi / 2

    if not card:castable(self) then
      card.tfade = 1
    else
      card.tfade = 0
    end

    card:update()
  end

  -- handle movement
  local ds = dt * 60 * PLAYER_SPEED
  local dx = 0
  local dy = 0

  if love.keyboard.isDown(KEYBINDINGS.left) then
    self.char:set_anim(self.char.anims.walk_left)
    dx = dx - 1
  end
  if love.keyboard.isDown(KEYBINDINGS.right) then
    self.char:set_anim(self.char.anims.walk_right)
    dx = dx + 1
  end

  if love.keyboard.isDown(KEYBINDINGS.up) then
    self.char:set_anim(self.char.anims.walk_up)
    dy = dy - 1
  end
  if love.keyboard.isDown(KEYBINDINGS.down) then
    self.char:set_anim(self.char.anims.walk_down)
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
  self.char:draw()
  self.aiming:draw()
  self.ui_health:draw()

  for i, crystal in ipairs(self.ui_mana) do
    crystal:draw()
  end

  for i, card in ipairs(self.hand) do
    card:draw(card:castable(self))
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
    [KEYBINDINGS.card1]=1,
    [KEYBINDINGS.card2]=2,
    [KEYBINDINGS.card3]=3,
    [KEYBINDINGS.card4]=4,
    [KEYBINDINGS.card5]=5,
    [KEYBINDINGS.card6]=6,
    [KEYBINDINGS.card7]=7,
    [KEYBINDINGS.card8]=8,
    [KEYBINDINGS.card9]=9,
  }

  if keymap[key] ~= nil and keymap[key] <= #self.hand then
    self.card_sel = keymap[key]
  end
end

function Overworld:draw_card()
  if #self.hand == MAX_HAND_SIZE then
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
  local card = self.hand[self.card_sel]
  if card:castable(self) then
    card:cast(self)
    card.angle = 0
    card.tx = 0
    card.ty = HEIGHT - (#self.discard + 1) * DECK_SPACING + DECK_DEPTH

    table.remove(self.hand, self.card_sel)
    if self.card_sel > #self.hand then
      self.card_sel = #self.hand
    end

    table.insert(self.discard, card)
  end
end

function Overworld:reshuffle()
  -- FIXME because this moves things over to `deck` while they're still in the
  -- discard pile, for a brief moment they're shown in reshuffled deck order
  -- instead of discard order.

  for n=1, #self.discard do
    local card = table.remove(self.discard, math.random(#self.discard))
    table.insert(self.deck, card)
    card.tx = WIDTH
    card.ty = HEIGHT - n * DECK_SPACING + DECK_DEPTH
    card.tflip = 1
    card.delay = n * SHUFFLE_DELAY
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

function Overworld:move_selection(dir)
  self.card_sel = self.card_sel + dir

  if self.card_sel == 0 then
    self.card_sel = #self.hand
  end

  if self.card_sel > #self.hand then
    self.card_sel = 1
  end
end

function Overworld:wheelmoved(top, x, y)
  self:move_selection(-y)
end

function Overworld:move(x, y)
  local hspace = WIDTH / 3
  local vspace = HEIGHT / 3

  -- move the char
  self.char.x = self.char.x + x
  self.char.y = self.char.y + y

  -- lock the char within the center third of the screen by scrolling the map
  -- inversely with the char when he steps over the edge

  if self.char.x < hspace then
    self.map.x = self.map.x - (self.char.x - hspace)
    self.char.x = hspace
  end

  if self.char.x > WIDTH - self.char.size - hspace then
    self.map.x = self.map.x - (self.char.x - (WIDTH - self.char.size - hspace))
    self.char.x = (WIDTH - self.char.size - hspace)
  end

  if self.char.y < vspace then
    self.map.y = self.map.y - (self.char.y - vspace)
    self.char.y = vspace
  end

  if self.char.y > HEIGHT - self.char.size - vspace then
    self.map.y = self.map.y - (self.char.y - (HEIGHT - self.char.size - vspace))
    self.char.y = (HEIGHT - self.char.size - vspace)
  end

  -- compute the tile under the char
  local sx = math.floor((self.char.x - self.map.x_off) / self.map.tile_size)
  local sy = math.floor((self.char.y - self.map.y_off) / self.map.tile_size)

  -- check collision with the char's top left, top right, bottom left, and
  -- bottom right corners, shifting his position appropriately
  self:collide(sx, sy)
  self:collide(sx, sy + 1)
  self:collide(sx + 1, sy)
  self:collide(sx + 1, sy + 1)
end

function Overworld:collide(x, y)
  -- get the char's position within the map
  local bx = self.char.x - self.map.x_off
  local by = self.char.y - self.map.y_off

  -- decide if the tile is blocked
  local blocked = self.map:get_blocked(self.map.x_start + x, self.map.y_start + y)

  if blocked then

    -- compute the tile's coordinates within the map
    local tx = x * self.map.tile_size
    local ty = y * self.map.tile_size

    -- compute the char's angle from the tile
    local dx = bx - tx
    local dy = by - ty
    local angle = math.atan2(dy, dx) / math.pi / 2

    -- depending on the direction from the tile, shift the char away from it

    -- char is below
    if angle >= 1 / 8 and angle <= 3 / 8 then
      self.char.y = (y + 1) * self.map.tile_size + self.map.y_off
    end

    -- char is above
    if angle >= -3 / 8 and angle <= -1 / 8 then
      self.char.y = (y - 1) * self.map.tile_size + self.map.y_off
    end

    -- char is right
    if angle >= -1 / 8 and angle <= 1 / 8 then
      self.char.x = (x + 1) * self.map.tile_size + self.map.x_off
    end

    -- char is left
    if angle <= -3 / 8 or angle >= 3 / 8 then
      self.char.x = (x - 1) * self.map.tile_size + self.map.x_off
    end
  end
end
