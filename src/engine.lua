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
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      proto[k] = v
    end
  end

  proto.__index = proto
  proto.__super = self

  return setmetatable(proto, self)
end

-- state machine
State = Object:extend()

-- called when this state is added to the stack
function State:start() end

-- called when this state is removed from the stack
function State:finish() end

-- called when this state is no longer the top state
function State:pause() end

-- called when this state becomes the top state
function State:resume() end


-- game engine
Engine = Object:extend()

function Engine:init()
  self.sprites = {}
  self.controls = {}
  self.states = {}
end

function Engine:push_state(to)
  if #self.states > 0 then
    self.states[#self.states]:pause()
  end
  table.insert(self.states, to)
  to:start()
end

function Engine:pop_state()
  self.states[#self.states]:finish()
  self.states[#self.states] = nil
  self.states[#self.states]:resume()
end

function Engine:replace_state(to)
  self.states[#self.states]:finish()
  self.states[#self.states] = to
  to:start()
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

function Engine:ctl(event, ...)
  for i, state in ipairs(self.states) do
    state[event](state, i == #self.states, ...)
  end
end

function Engine:update(...)
  self:ctl('update', ...)
end

function Engine:mousepressed(...)
  self:ctl('mousepressed', ...)
end

function Engine:mousereleased(...)
  self:ctl('mousereleased', ...)
end

function Engine:mousemoved(...)
  self:ctl("mousemoved", ...)
end

function Engine:draw(...)
  self:ctl("draw", ...)
end
