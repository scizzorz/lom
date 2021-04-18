require("conf")
require("engine")
require("gfx")
require("util")

Attack = Object:extend()

ATTACK_DURATION = 0.125
ATTACK_ARC = math.pi / 2
ATTACK_SIZE = 4
ATTACK_RANGE = 16

-- FIXME this needs to be generalized
function Attack:init(state, x, y, angle)
  -- physics
  self.state = state
  self.world = state.world
  self.shape = love.physics.newCircleShape(0, 0, ATTACK_SIZE)
  self.body = love.physics.newBody(self.world, 0, 0, "dynamic")
  self.body:setBullet(true)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  self.fixture:setSensor(true)

  state:register_hitbox(self.fixture, self)

  self.x = x
  self.y = y
  self.angle = angle
  self.elapsed = 0

  self:update()
end

function Attack:update(dt)
  dt = dt or 0
  self.elapsed = self.elapsed + dt

  print("awake = " .. tostring(self.body:isAwake()))

  local angle = self.angle - ATTACK_ARC / 2 + self.elapsed / ATTACK_DURATION * ATTACK_ARC
  self.body:setX(self.x + math.cos(angle) * ATTACK_RANGE)
  self.body:setY(self.y + math.sin(angle) * ATTACK_RANGE)
end

function Attack:hit(target)
  local dist = math.sqrt((self.x - target.x)^2 + (self.y - target.y)^2)
  local dir = math.angle(self.x, self.y, target.x, target.y)
  if dist <= MELEE_RANGE then
    target.body:applyLinearImpulse(math.cos(dir) * MELEE_ATTACK_WEIGHT, math.sin(dir) * MELEE_ATTACK_WEIGHT)
    self.state:add_sct(2, target.x, target.y + SCT_Y_OFFSET, SCT_DAMAGE)
    self.state:add_attack(Slash(self.state, target.x, target.y))
  end
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

--

SLASH_DURATION = 0.5
SLASH_FADE_SPEED = 8

Slash = Object:extend()

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
