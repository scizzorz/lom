require("conf")
require("engine")
require("gfx")
require("util")

Map = Object:extend()

function Map:init(world, tex, width, height, polies)
  self.world = world
  self.polies = polies
  self.tex = load_gfx(tex)
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

Char = Object:extend()

function Char:init(world, size, sprite)
  self.world = world
  self.sprite = sprite
  self.size = size
  self.shape = love.physics.newCircleShape(0, 0, size)
  self.body = love.physics.newBody(self.world, 0, 0, "dynamic")
  self.fixture = love.physics.newFixture(self.body, self.shape)

  self:update()
end

function Char:update(dt)
  self.x = self.body:getX()
  self.y = self.body:getY()
  self.sprite.x = self.body:getX()
  self.sprite.y = self.body:getY()

  self.sprite:update()
end

function Char:draw()
  love.graphics.setColor(0, 0, 1, 0.5)
  love.graphics.circle("fill", S(self.body:getX()), S(self.body:getY()), S(self.shape:getRadius()))

  self.sprite:draw()
end
