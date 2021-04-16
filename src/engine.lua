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

function Engine:change_state(to)
  self:replace_state(Transition(self.states[#self.states], to))
end

function Engine:ctl(event, ...)
  -- don't use ipairs in case states are manipulated during a ctl
  for i=1, #self.states do
    local state = self.states[i]
    if state[event] ~= nil then
      state[event](state, i == #self.states, ...)
    end
  end
end


-- transition state
Transition = State:extend()

function Transition:init(from, to)
  self.from = from
  self.to = to
  self.phase = 0
  self.a = 0
  self.ta = 1
end

function Transition:update(top)
  if not top then return end

  -- slow fade
  self.a = self.a + (self.ta - self.a) / TRANSITION_SPEED

  -- check if we're done with a transition, then move to the next
  -- phase 0: draw "from" state and fade out
  -- phase 1: draw "to" state and fade in
  -- end of phase 1: state change
  local dist = math.abs(self.a - self.ta)
  if dist < 0.01 then
    if self.phase == 0 then
      self.phase = 1
      self.ta = 0
    elseif self.phase == 1 then
      -- ew, global. oh well.
      ENGINE:replace_state(self.to)
    end
  end
end

function Transition:draw()
  if self.phase == 0 then
    self.from:draw()
  else
    self.to:draw()
  end

  -- black out the screen
  -- FIXME there's bug here sometimes?
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(0, 0, 0, self.a)
  love.graphics.rectangle("fill", 0, 0, w, h)
end
