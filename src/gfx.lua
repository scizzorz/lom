framesets = {
  dummy = {
    tile_width = 25,
    tile_height = 25,
    tex_width = 175,
    tex_height = 100,
  },
}

animations = {
  dummy = {
    stand_down = {0},
    walk_down = {0, 1, 2, 3, 4, 5, 6, fps=10},
    stand_up = {7},
    walk_up = {7, 8, 9, 10, 11, 12, 13, fps=10},
    stand_left = {14},
    walk_left = {14, 15, 16, 17, 18, 19, 20, fps=10},
    stand_right = {21},
    walk_right = {21, 22, 23, 24, 25, 26, 27, fps=10},
  },
}

atlas = {
  dummy = {
    texture = "actor_dummy",
    frameset = framesets.dummy,
    anims = animations.dummy,
  },

  mana = {
    texture = "ui_mana",
    frameset = {
      tile_width = 16,
      tile_height = 16,
      tex_width = 32,
      tex_height = 16,
    },
    anims = {
      filled = {0},
      empty = {1},
    },
  },

  ui_health_frame = {
    texture = "ui_health_frame",
    frameset = {
      tile_width = 80,
      tile_height = 16,
      tex_width = 80,
      tex_height = 16,
    },
  },

  ui_health_fill = {
    texture = "ui_health_fill",
    frameset = {
      tile_width = 66,
      tile_height = 10,
      tex_width = 66,
      tex_height = 10,
    },
  },
}

local textures = {}

local quads = {}

function build_quad(frameset, frame)
  local x = (frame * frameset.tile_width) % frameset.tex_width
  local y = math.floor(frame * frameset.tile_width / frameset.tex_width) * frameset.tile_height
  return love.graphics.newQuad(x, y, frameset.tile_width, frameset.tile_height, frameset.tex_width, frameset.tex_height)
end

function load_texture(id)
  if textures[id] == nil then
    print("loading tex: " .. id)
    textures[id] = love.graphics.newImage("gfx/" .. id .. ".png")
  end

  return textures[id]
end


Anim = Object:extend()

function Anim:init(data)
  self.data = data
  self.frame = 1
  self.fc = 0
end

function Anim:cur()
  return self.data[self.frame]
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
  return self:cur()
end
