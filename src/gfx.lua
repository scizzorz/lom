framesets = {
  actor = {
    size = 16,
    num = 4,
  },

  dummy = {
    size = 25,
    num = 7,
  },

  map = {
    size = 16,
    num = 32,
  },

  mana = {
    size = 16,
    num = 2,
  },
}

atlas = {
  bare = {
    texture = "actor_bare",
    frameset = "actor",
  },

  dummy = {
    texture = "actor_dummy",
    frameset = "dummy",
    anims = {
      stand_down = {0},
      walk_down = {0, 1, 2, 3, 4, 5, 6, fps=10},
      stand_up = {7},
      walk_up = {7, 8, 9, 10, 11, 12, 13, fps=10},
      stand_left = {14},
      walk_left = {14, 15, 16, 17, 18, 19, 20, fps=10},
      stand_right = {21},
      walk_right = {21, 22, 23, 24, 25, 26, 27, fps=10},
    },
  },

  map = {
    texture = "map",
    frameset = "map",
  },

  mana = {
    texture = "ui_mana",
    frameset = "mana",
  }
}

local gfx = {}

local quads = {}

function load_quads(id)
  if quads[id] == nil then
    print("loading quads: " .. id)
    quads[id] = {}

    local num = framesets[id].num
    local size = framesets[id].size
    for x = 0, num - 1 do
      for y = 0, num - 1 do
        quads[id][y*num + x] = love.graphics.newQuad(size * x, size * y, size, size, size*num, size*num)
      end
    end
  end

  return quads[id]
end

function load_gfx(id)
  if gfx[id] == nil then
    print("loading gfx: " .. id)
    gfx[id] = love.graphics.newImage("gfx/" .. id .. ".png")
  end

  return gfx[id]
end


Anim = Object:extend()

function Anim:init(data)
  self.data = data
  self.frame = 1
  self.fc = 0
end

function Anim:update()
  self.fc = self.fc + 1
  if self.fc >= math.ceil(60 / (self.data.fps or 60)) then
    self.fc = 0
    self.frame = self.frame + 1
    if self.frame > #self.data then
      self.frame = self.data.loop or 1
    end
  end
  return self.data[self.frame]
end
