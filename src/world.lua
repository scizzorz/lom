require("conf")
require("engine")
require("gfx")
require("util")

Map = Object:extend()

function Map:init(world, tex, width, height, polies)
  self.world = world
  self.polies = polies
  self.tex = load_texture(tex)
  self.quad = love.graphics.newQuad(0, 0, width, height, width, height)

  self.body = love.physics.newBody(self.world, 0, 0)
  self.shapes = {}
  self.fixtures = {}

  for i, poly in ipairs(polies) do
    local shape = love.physics.newPolygonShape(poly)
    local fixture = love.physics.newFixture(self.body, shape)
    table.insert(self.shapes, shape)
    table.insert(self.fixtures, fixture)
  end
end

function Map:update(dt)
end

function Map:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.tex, self.quad, S(0), S(0), 0, SCALE, SCALE)

  love.graphics.setColor(1, 0, 0, 0.5)
  for i, shape in ipairs(self.shapes) do
    self:draw_shape(shape)
  end
end

function Map:draw_shape(shape)
  local points = {self.body:getWorldPoints(shape:getPoints())}
  for k, v in ipairs(points) do
    points[k] = S(v)
  end
  love.graphics.polygon("fill", points)
end


Actor = Object:extend()

function Actor:init(world, size, sprite)
  self.size = size
  self.sprite = sprite

  -- physics
  self.world = world
  self.shape = love.physics.newCircleShape(0, 0, size)
  self.body = love.physics.newBody(self.world, 0, 0, "dynamic")
  self.body:setLinearDamping(ACTOR_LINEAR_DAMPING)
  self.fixture = love.physics.newFixture(self.body, self.shape)

  -- state
  self.lag = 0
  self.status = {}

  self:update()
end

function Actor:update(dt)
  dt = dt or 0
  self.x = self.body:getX()
  self.y = self.body:getY()
  self.sprite.x = self.body:getX()
  self.sprite.y = self.body:getY()

  self.sprite:update(dt)

  -- update all buffs/debuffs
  for k, v in pairs(self.status) do
    local status = status_db[k]

    -- check if this status has an on-tick effect
    if status.update then
      status.update(v, dt, self)
    end

    -- only tick down time if this status has a duration
    if v.duration then
      v.duration = v.duration - dt

      if v.duration <= 0 then
        -- check if there's an on-fade effect
        if status.fade then
          status.fade(v, self)
        end

        self.status[k] = nil
      end
    end

  end

  -- tick down on a delayed action
  if self.lag > 0 then
    self.lag = self.lag - dt
    if self.lag <= 0 then
      self:cast()
    end
  end
end

-- perform a delayed action
function Actor:cast()
  if self.lag_action then
    self:lag_action()
    self.lag_action = nil
  end
end

-- apply a buff / debuff effect
function Actor:apply(status, duration, stacks)
  stacks = stacks or 1

  local max_stacks = status_db[status].max_stacks or 1
  local cur = self.status[status]

  if cur then
    if duration then
      if cur.duration and duration > cur.duration then
        cur.duration = duration
      end

      if cur.max_duration and duration > cur.max_duration then
        cur.max_duration = duration
      end
    end

    cur.stacks = math.min(max_stacks, cur.stacks + stacks)
  else
    self.status[status] = {
      max_duration=duration,
      duration=duration,
      stacks = math.min(max_stacks, stacks),
    }
  end
end

function Actor:draw()
  love.graphics.setColor(0, 0, 1, 0.5)
  love.graphics.circle("fill", S(self.body:getX()), S(self.body:getY()), S(self.shape:getRadius()))

  self.sprite:draw()
end

Behavior = Object:extend()

SlimeBehavior = Behavior:extend()

function SlimeBehavior:init(actor)
  self.actor = actor
  self.mode = "stand"
  self.timer = 4
end

function SlimeBehavior:update(dt)
  dt = dt or 0

  local dist = math.sqrt((self.actor.x - OVERWORLD.char.x) ^ 2 + (self.actor.y - OVERWORLD.char.y) ^ 2)

  if dist <= SLIME_ATTACK_RANGE then
    self.mode = "attack"
    self.timer = 1
  elseif dist <= SLIME_CHASE_RANGE then
    self.mode = "chase"
    self.timer = 1
  end

  self.timer = self.timer - dt
  if self.timer < 0 then
    self:choose_new()
  end

  if self.mode == "stand" then
    self.actor.sprite:set_anim("stand_" .. self.actor.dir)
  elseif self.mode == "attack" then
    self.actor.sprite:set_anim("stand_" .. self.actor.dir)
  elseif self.mode == "walk" then
    self.actor.body:applyLinearImpulse(self.dx, self.dy)
    self.actor.sprite:set_anim("walk_" .. self.actor.dir)
  elseif self.mode == "chase" then
    local dir = math.angle(self.actor.x, self.actor.y, OVERWORLD.char.x, OVERWORLD.char.y)
    self.dx = math.cos(dir) * SLIME_CHASE_SPEED
    self.dy = math.sin(dir) * SLIME_CHASE_SPEED
    self.actor.body:applyLinearImpulse(self.dx, self.dy)
    self.actor.sprite:set_anim("walk_" .. self.actor.dir)
  end
end

function SlimeBehavior:choose_new()
  local walk = love.math.random(2)

  if walk == 1 then
    local dir = love.math.random(0, 7) * math.pi / 4
    self.dx = math.cos(dir) * SLIME_WALK_SPEED
    self.dy = math.sin(dir) * SLIME_WALK_SPEED
    self.mode = "walk"
    self.timer = love.math.random(SLIME_WALK_MIN, SLIME_WALK_MAX)
  else
    self.mode = "stand"
    self.timer = love.math.random(SLIME_STAND_MIN, SLIME_STAND_MAX)
  end
end

Char = Actor:extend()

function Char:init(state)
  self.__super.init(self, state.world, 8, Sprite(atlas.dummy))
  self.state = state
  self.sprite.ox = 13
  self.sprite.oy = 19
  self.dir = "down"
end


Slime = Actor:extend()

function Slime:init(state)
  self.__super.init(self, state.world, 12, Sprite(atlas.slime))
  self.state = state
  self.sprite.ox = 13
  self.sprite.oy = 16
  self.dir = "down"

  self.behavior = SlimeBehavior(self)
end

function Slime:update(dt)
  if self.behavior and dt then
    self.behavior:update(dt)
  end

  self.__super.update(self, dt)
end
