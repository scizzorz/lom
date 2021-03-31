-- base class
Object = {}
Object.__index = Object

-- constructor
function Object:__call(...)
  local this = setmetatable({}, self)
  return this, this:init(...)
end

-- methods
function Object:init() end
function Object:update() end
function Object:draw() end

-- subclassing
function Object:extend()
  proto = {}

  -- copy meta values, since lua
  -- doesn't walk the prototype
  -- chain to find them
  for k, v in ipairs(self) do
    if k:sub(1, 2) == "__" then
      proto[k] = v
    end
  end

  proto.__index = proto
  proto.__super = self

  return setmetatable(proto, self)
end


-- game engine
Engine = Object:extend()

function Engine:init()
  self.sprites = {}
  self.controls = {}
end

function Engine:add_control(control)
  table.insert(self.controls, control)
  if control.add then
    control:add(self)
  end
end

function Engine:rm_control(control)
  for key, val in ipairs(self.controls) do
    if val == control then
      table.remove(self.controls, key)
      if control.drop then
        control:drop(self)
      end
      break
    end
  end
end

function Engine:add_sprite(sprite)
  table.insert(self.sprites, sprite)
end

function Engine:rm_sprite(sprite)
  for key, val in ipairs(self.sprites) do
    if val == sprite then
      table.remove(self.sprites, key)
      break
    end
  end
end

function Engine:control(event, ...)
  for key, val in ipairs(self.controls) do
    if val[event] and not val[event](val, ...) then
      break
    end
  end
end

function Engine:update(...)
  self:control('update', ...)
end

function Engine:mousepressed(...)
  self:control('mousepressed', ...)
end

function Engine:mousereleased(...)
  self:control('mousereleased', ...)
end

function Engine:mousemoved(...)
  self:control('mousemoved', ...)
end

function Engine:draw()
  for key, val in ipairs(self.sprites) do
    val:draw()
  end
end
