require("attack")
require("data")
require("gfx")
require("particles")
require("sprite")
require("util")
require("world")

Overworld = State:extend()

local library = {}

for name, data in pairs(card_db) do
  table.insert(library, name)
end

function Overworld:init()
  self.world = love.physics.newWorld(0, 0, false)

  self.world:setCallbacks(
    function(...) self:begin_contact(...) end,
    function(...) self:end_contact(...) end
  )

  local map_size = 240
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  self.fade = 0
  self.tfade = 0

  -- draw the map and its obstacles
  self.map = Map(self.world, "map_arena", 400, 225, {
    {0, 0, 25, 0, 25, 225, 0, 225},
    {375, 0, 400, 0, 400, 225, 375, 225},
    {25, 0, 375, 0, 375, 25, 25, 25},
    {25, 200, 375, 200, 375, 225, 25, 225},
    {50, 50, 75, 50, 75, 75},
    {75, 75, 100, 50, 75, 50},
    {350, 200, 375, 175, 375, 200},
    {100, 100, 125, 100, 125, 125, 100, 125},
  })

  -- particles (SCT, attacks, floaties, etc)
  self.particles = {}
  self.sct = {}

  -- collision
  self.hurtboxes = {}
  self.hitboxes = {}

  self.max_mana = MAX_MANA * MANA_PARTS
  self.mana = 0

  self.max_health = MAX_HEALTH
  self.health = 0

  self.draw_timers = {}
  self.hand = {}
  self.deck = {}
  self.discard = {}

  self.ui_health = HealthBar(self.health, self.max_health, atlas.ui_health_frame, atlas.ui_health_fill)
  self.ui_health.x = 0
  self.ui_health.y = 0

  self.ui_mana = {}
  for n=1, (self.max_mana / MANA_PARTS) do
    local crystal = Sprite(atlas.mana)
    crystal.x = (n - 1) * crystal.data.frameset.tile_width
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

  -- init characters
  self.char = Char(self, 8, Sprite(atlas.dummy))
  self.char.body:setX(WIDTH / 2 - 60)
  self.char.body:setY(HEIGHT / 2)

  self.en = Slime(self)
  self.en.body:setX(WIDTH / 2 + 60)
  self.en.body:setY(HEIGHT / 2)

  -- prep graphics so they don't jump during the transition state
  self.map:update()
  self:aim()
  self:update_mana_ui()
  self:draw_hand()
end

function Overworld:add_sct(text, x, y, ...)
  local new = SCT(text, x, y, ...)
  while true do
    local safe = true
    for i, other in ipairs(self.sct) do
      if new:overlaps(other) then
        safe = false
        new.y = new.y + 12
        new.ty = new.ty + 12
      end
    end

    if safe then
      break
    end
  end
  table.insert(self.sct, new)
end

function Overworld:add_particle(kind, ...)
  table.insert(self.particles, kind(self, ...))
end

function Overworld:add_attack(kind, effects, ...)
  table.insert(self.particles, kind(self.char, self, effects, ...))
end

-- hurtboxes are offensive
function Overworld:register_hitbox(fixture, hitbox)
  self.hitboxes[fixture] = hitbox
end

function Overworld:deregister_hitbox(fixture)
  self.hitboxes[fixture] = nil
end

-- hitboxes are defensive
function Overworld:register_hurtbox(fixture, hurtbox)
  self.hurtboxes[fixture] = hurtbox
end

function Overworld:deregister_hurtbox(fixture)
  self.hurtboxes[fixture] = nil
end

-- physics callbacks
function Overworld:begin_contact(fix1, fix2, contact)
  -- fix1 is the offensive fixture
  if self.hitboxes[fix1] and self.hurtboxes[fix2] then
    self.hitboxes[fix1]:on_hit(self.hurtboxes[fix2], fix2)
    self.hurtboxes[fix2]:on_hurt(self.hitboxes[fix1], fix1)
  end

  -- fix2 is the offensive fixture
  if self.hitboxes[fix2] and self.hurtboxes[fix1] then
    self.hitboxes[fix2]:on_hit(self.hurtboxes[fix1], fix1)
    self.hurtboxes[fix1]:on_hurt(self.hitboxes[fix2], fix2)
  end
end

function Overworld:end_contact(fix1, fix2, contact)
end

function Overworld:aim()
  -- scaling mouse coordinates is annoying
  local mx, my = love.mouse.getPosition()
  mx = s2p(mx - SCISSOR.x)
  my = s2p(my - SCISSOR.y)

  local angle = math.angle(self.char.x, self.char.y, mx, my)

  local rnd = (2 * math.pi) / 8
  angle = math.floor(angle / rnd + 0.5) * rnd / (math.pi / 4)

  local dirs = {
    [-4] = "left",
    [-3] = "up_left",
    [-2] = "up",
    [-1] = "up_right",
    [0] = "right",
    [1] = "down_right",
    [2] = "down",
    [3] = "down_left",
    [4] = "left",
  }

  self.char.dir = dirs[angle]
end

function Overworld:update_mana_ui()
  for i, crystal in ipairs(self.ui_mana) do
    if i * MANA_PARTS > self.mana then
      crystal:set_anim("empty")
    else
      crystal:set_anim("filled")
    end
    crystal:update()
  end
end

function Overworld:update(top, dt)
  self.fade = self.fade + (self.tfade - self.fade) / TRANSITION_SPEED

  if not top then
    self.tfade = 0.5
    return
  end

  self.tfade = 0

  self.world:update(dt)

  self.map:update()
  self:update_mana_ui()
  self.ui_health:update(self.health)
  self.char:update(dt)
  self.en:update(dt)

  if self.health < self.max_health then
    self.health = self.health + 1
  end

  local i = 1
  while i <= #self.draw_timers do
    self.draw_timers[i] = self.draw_timers[i] - dt
    if self.draw_timers[i] <= 0 then
      table.remove(self.draw_timers, i)
      self:draw_card()
    else
      i = i + 1
    end
  end

  self:update_particles("particles", dt)
  self:update_particles("sct", dt)

  for i, card in ipairs(self.deck) do
    card:update(self)
  end

  for i, card in ipairs(self.discard) do
    card:update()
  end

  for i=1, HAND_SIZE do
    local card = self.hand[i]
    if card then
      local depth = SELECTED_DEPTH

      card.tx = (WIDTH / 2) - (HAND_SPACING / 2 * (HAND_SIZE - 1)) + (HAND_SPACING * (i - 1))
      card.ty = HEIGHT

      local angle = math.angle(card.x, card.y, WIDTH / 2, HEIGHT * HAND_ANGLE)
      card.tx = card.tx + math.cos(angle) * depth
      card.ty = card.ty + math.sin(angle) * depth

      card.angle = angle - math.pi / 2

      if not card:castable() then
        card.tfade = 1
      else
        card.tfade = 0
      end

      card:update()
    end
  end

  -- handle movement
  local ds = PLAYER_SPEED
  local dx = 0
  local dy = 0

  if self.char.lag <= 0 then
    if love.keyboard.isDown(KEYBINDINGS.left) then
      dx = dx - 1
    end
    if love.keyboard.isDown(KEYBINDINGS.right) then
      dx = dx + 1
    end

    if love.keyboard.isDown(KEYBINDINGS.up) then
      dy = dy - 1
    end
    if love.keyboard.isDown(KEYBINDINGS.down) then
      dy = dy + 1
    end
  end

  local dirs = {
    [-1] = {[-1] = "up_left", [0] = "left", [1] = "down_left"},
    [0] = {[-1] = "up", [0] = nil, [1] = "down"},
    [1] = {[-1] = "up_right", [0] = "right", [1] = "down_right"},
  }

  if dirs[dx][dy] then
    self.char.dir = dirs[dx][dy]
  end

  -- diagonal movement should be slower
  if dx ~= 0 and dy ~= 0 then
    ds = ds / math.sqrt(2)
  end

  if self.char.status.sprint then
    ds = ds * status_db.sprint.effect
  end

  self:move(dx * ds, dy * ds)
  if dx ~= 0 or dy ~= 0 then
    self.char.sprite:set_anim("walk_" .. self.char.dir)
  else
    self.char.sprite:set_anim("stand_" .. self.char.dir)
  end
end

function Overworld:update_particles(field, dt)
  local i = 1
  while i <= #self[field] do
    local particle = self[field][i]
    particle:update(dt)

    if particle:done() then
      particle:deinit()
      table.remove(self[field], i)
    else
      i = i + 1
    end
  end
end

function Overworld:draw(top)
  self.map:draw()
  self.char:draw()
  self.en:draw()
  self.ui_health:draw()

  for i, crystal in ipairs(self.ui_mana) do
    crystal:draw()
  end

  for i=1, HAND_SIZE do
    local card = self.hand[i]
    if card then
      card:draw(card:usable(), card:castable())
    end
  end

  for i, card in ipairs(self.deck) do
    card:draw()
  end

  for i, card in ipairs(self.discard) do
    card:draw()
  end

  for i, particle in ipairs(self.particles) do
    particle:draw()
  end

  for i, sct in ipairs(self.sct) do
    sct:draw()
  end

  local status_quad = love.graphics.newQuad(0, 0, 16, 16, 16, 16)
  local sx = WIDTH - 17
  local sy = 1
  for k, v in pairs(self.char.status) do
    local status = status_db[k]
    if status.art then
      local tex = load_texture(status.art)

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(tex, status_quad, S(sx), S(sy), 0, SCALE, SCALE)

      if v.duration then
        draw_cd(1 - v.duration / v.max_duration, sx, sy, 16, 16, 0, 0, 0, 0.5)
      end

      sx = sx - 18
    end
  end

  if self.fade > 0 then
    -- black out the screen
    -- FIXME there's bug here sometimes?
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, self.fade)
    love.graphics.rectangle("fill", 0, 0, w, h)
  end
end

function Overworld:draw_physics_circ(f)
  love.graphics.circle("fill", S(f.body:getX()), S(f.body:getY()), S(f.shape:getRadius()))
end

function Overworld:draw_physics_rect(f)
  local points = {f.body:getWorldPoints(f.shape:getPoints())}
  for k, v in ipairs(points) do
    points[k] = S(v)
  end
  love.graphics.polygon("fill", points)
end

function Overworld:keypressed(top, key)
  if not top then
    return
  end

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

  if keymap[key] ~= nil and keymap[key] <= HAND_SIZE then
    local slot = keymap[key]
    self:use_card(slot)

  elseif key == KEYBINDINGS.menu then
    ENGINE:push_state(Menu({
      {
        atlas=atlas.menu_options,
        anim="resume",
        call=function()
          ENGINE:pop_state()
        end,
      },
      {
        atlas=atlas.menu_options,
        anim="options",
        disabled=true,
        call=function()
        end,
      },
      {
        atlas=atlas.menu_options,
        anim="main_menu",
        disabled=true,
        call=function()
        end,
      },
      {
        atlas=atlas.menu_options,
        anim="exit_game",
        call=function()
          love.event.quit()
        end,
      },
    }))
  end
end

function Overworld:draw_card()
  if #self.deck == 0 then
    -- FIXME what happens if you have no deck left?
    return
  end

  local slot = nil

  for i=1, HAND_SIZE do
    if self.hand[i] == nil then
      slot = i
      break
    end
  end

  if slot == nil then
    -- FIXME what happens if you have no open slots?
    return
  end

  local card = table.remove(self.deck)
  card.tflip = 0
  self.hand[slot] = card
end

function Overworld:use_card(slot)
  local card = self.hand[slot]
  if card and card:castable(self) then
    card:cast(self.char)
    self:discard_card(card)
  end
end

function Overworld:discard_card(card)
  for i=1, HAND_SIZE do
    if card == self.hand[i] then
      self.hand[i] = nil
      break
    end
  end

  table.insert(self.draw_timers, DRAW_TIMER)

  card.angle = 0
  card.tx = 0
  card.ty = HEIGHT - (#self.discard + 1) * DECK_SPACING + DECK_DEPTH
  card.tfade = 0

  table.insert(self.discard, card)
end

function Overworld:ready_for_hand()
  for i=1, HAND_SIZE do
    local card = self.hand[i]
    if card and card:usable(self) then
      return false
    end
  end

  return true
end

function Overworld:draw_hand()
  self.mana = self.max_mana

  -- discard hand
  --[[
  while #self.hand > 0 do
    self:discard_card(self.hand[1])
  end
  ]]

  -- reshuffle if we need to
  if #self.deck == 0 then
    self:reshuffle()
  end

  -- draw a new hand
  for i=1, HAND_SIZE do
    self:draw_card()
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
    if self.char.lag <= 0 then
      cast_db.slash(attack_db.rogue_aa)(self.char, self.char.x, self.char.y)

      self.char.sprite:set_anim("stand_" .. self.char.dir)
      self.char.lag = ATTACK_LAG

      self.mana = self.mana + MANA_PARTS / 5
    end
  end

  -- right
  if button == 2 then
  end
end

function Overworld:move(x, y)
  self.char.body:applyLinearImpulse(x, y)
end


Menu = State:extend()

function Menu:init(options)
  self.bg = Sprite(atlas.menu)
  self.bg.ox = atlas.menu.frameset.tile_width / 2
  self.bg.x = (WIDTH) / 2
  self.bg.y = (HEIGHT - atlas.menu.frameset.tile_height) / 2

  self.label = Sprite(atlas.menu_options)
  self.label.ox = atlas.menu_options.frameset.tile_width / 2
  self.label.x = self.bg.x + 5
  self.label.y = self.bg.y

  self.label = Sprite(atlas.menu_options)
  self.label.ox = atlas.menu_options.frameset.tile_width / 2
  self.label.x = self.bg.x
  self.label.y = self.bg.y + 5

  self.options = options
  self.option_labels = {}

  for i, option in ipairs(options) do
    local label = Sprite(option.atlas)
    label.ox = label.data.frameset.tile_width / 2
    label.x = self.bg.x
    label.y = self.bg.y + 15 + 11 * i
    if option.disabled then
      label.tfade = 0.6
    elseif i == self.cursor then
      label.tfade = 0
    else
      label.tfade = 0.4
    end
    label.fade = label.tfade
    label:set_anim(option.anim)
    table.insert(self.option_labels, label)
  end

  self.cursor = 1
end

function Menu:keypressed(top, key)
  if key == KEYBINDINGS.menu then
    ENGINE:pop_state()
  end
end

function Menu:update()
  local mx, my = love.mouse.getPosition()
  mx = s2p(mx - SCISSOR.x)
  my = s2p(my - SCISSOR.y)

  for i, label in ipairs(self.option_labels) do
    if not self.options[i].disabled and my > label.y and my < label.y + label.data.frameset.tile_height then
      self.cursor = i
    end

    if self.options[i].disabled then
      label.tfade = 0.6
    elseif i == self.cursor then
      label.tfade = 0
    else
      label.tfade = 0.4
    end

    label.fade = label.fade + (label.tfade - label.fade) / MENU_OPTION_SPEED
  end
end

function Menu:mousepressed(top, x, y, button)
  if button == 1 then
    self.options[self.cursor]:call()
  end
end

function Menu:draw()
  self.bg:draw()
  self.label:draw()

  for i, label in ipairs(self.option_labels) do
    love.graphics.setColor(1 - label.fade, 1 - label.fade, 1 - label.fade)
    label:draw(true)
  end
end
