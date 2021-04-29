require("conf")
require("engine")
require("gfx")
require("util")
require("particles")

ATTACK_DURATION = 0.125
ATTACK_LAG = 0.25
ATTACK_ARC = math.pi / 1
ATTACK_SIZE = 4
ATTACK_RANGE = 16

Attack = Particle:extend()

function Attack:init(state, effects)
  self.state = state
  self.world = state.world
  self.effects = effects
  self.elapsed = 0
end

function Attack:update(dt)
  self.elapsed = self.elapsed + (dt or 0)
end

function Attack:on_hit(target, fix)
  for i, effect in ipairs(self.effects) do
    effect(self, target, fix)
  end
end

function Attack:deinit()
end

function Attack:done()
  return false
end

-- a piercing attack that only hits each hitbox once
PiercingAttack = Attack:extend()

-- FIXME this needs to be generalized
function PiercingAttack:init(state, effects)
  PiercingAttack.__super.init(self, state, effects)

  self.collisions = {}
end

function PiercingAttack:on_hit(target, fix)
  if self.collisions[fix] then
    return
  end

  self.collisions[fix] = true

  PiercingAttack.__super.on_hit(self, target, fix)
end

-- a slicing animation

SlashAttack = PiercingAttack:extend()

-- FIXME this needs to be generalized
function SlashAttack:init(state, effects, x, y, angle)
  SlashAttack.__super.init(self, state, effects)

  self.shape = love.physics.newCircleShape(0, 0, ATTACK_SIZE)
  self.body = love.physics.newBody(self.world, 0, 0, "static")
  self.body:setBullet(true)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setSensor(true)

  state:register_hitbox(self.fixture, self)

  self.x = x
  self.y = y
  self.angle = angle

  self:update()
end

function SlashAttack:update(dt)
  SlashAttack.__super.update(self, dt)

  local angle = self.angle - ATTACK_ARC / 2 + self.elapsed / ATTACK_DURATION * ATTACK_ARC
  self.body:setX(self.x + math.cos(angle) * ATTACK_RANGE)
  self.body:setY(self.y + math.sin(angle) * ATTACK_RANGE)
end

function SlashAttack:deinit()
  self.body:destroy()
  self.state:deregister_hitbox(self.fixture)
end

function SlashAttack:done()
  return self.elapsed > ATTACK_DURATION
end

function SlashAttack:draw()
  love.graphics.setColor(0, 0, 1, 0.5)
  love.graphics.circle("fill", S(self.body:getX()), S(self.body:getY()), S(self.shape:getRadius()))
end
