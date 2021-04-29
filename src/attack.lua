require("conf")
require("engine")
require("gfx")
require("util")
require("particles")

Attack = Object:extend()

ATTACK_DURATION = 0.125
ATTACK_LAG = 0.25
ATTACK_ARC = math.pi / 1
ATTACK_SIZE = 4
ATTACK_RANGE = 16

-- FIXME this needs to be generalized
function Attack:init(state, x, y, angle)
  -- physics
  self.state = state
  self.world = state.world
  self.shape = love.physics.newCircleShape(0, 0, ATTACK_SIZE)
  self.body = love.physics.newBody(self.world, 0, 0, "static")
  self.body:setBullet(true)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setSensor(true)

  state:register_hitbox(self.fixture, self)

  self.x = x
  self.y = y
  self.angle = angle
  self.elapsed = 0

  self:update()

  self.collisions = {}
end

function Attack:update(dt)
  dt = dt or 0
  self.elapsed = self.elapsed + dt

  local angle = self.angle - ATTACK_ARC / 2 + self.elapsed / ATTACK_DURATION * ATTACK_ARC
  self.body:setX(self.x + math.cos(angle) * ATTACK_RANGE)
  self.body:setY(self.y + math.sin(angle) * ATTACK_RANGE)
end

function Attack:hit(target, fix)
  if self.collisions[fix] then
    return
  end

  self.collisions[fix] = true
  local dist = math.sqrt((self.x - target.x)^2 + (self.y - target.y)^2)
  local dir = math.angle(self.x, self.y, target.x, target.y)

  target.body:applyLinearImpulse(math.cos(dir) * MELEE_ATTACK_WEIGHT, math.sin(dir) * MELEE_ATTACK_WEIGHT)
  self.state:add_sct(2, target.x, target.y + SCT_Y_OFFSET, SCT_DAMAGE)
  self.state:add_attack(Slash(self.state, target.x, target.y))
end

function Attack:deinit()
  self.body:destroy()
  self.state:deregister_hitbox(self.fixture)
end

function Attack:done()
  return self.elapsed > ATTACK_DURATION;
end

function Attack:draw()
  love.graphics.setColor(0, 0, 1, 0.5)
  love.graphics.circle("fill", S(self.body:getX()), S(self.body:getY()), S(self.shape:getRadius()))
end
