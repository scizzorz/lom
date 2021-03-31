require('sprite')
require('world')

Overworld = State:extend()

function Overworld:init()
  local map_size = 240
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  self.bare = sprite.new("bare")
  self.bare.x = WIDTH / 2 - 8
  self.bare.y = HEIGHT / 2 - 8

  self.map = world.new("map", map_width, map_height, map_size)
  self.map.x = -WIDTH / 2
  self.map.y = -HEIGHT / 2
end

function Overworld:update(top, dt)
  self.map:update()

  local ds = dt * 60
  local dx = 0
  local dy = 0

  if love.keyboard.isDown("a") then
    dx = dx - 1
  end
  if love.keyboard.isDown("d") then
    dx = dx + 1
  end

  if love.keyboard.isDown("w") then
    dy = dy - 1
  end
  if love.keyboard.isDown("s") then
    dy = dy + 1
  end

  if dx ~= 0 and dy ~= 0 then
    ds = ds / math.sqrt(2)
  end

  if dx ~= 0 or dy ~= 0 then
    self:move(dx * ds, dy * ds)
  end
end

function Overworld:draw(top)
  self.map:draw()
  self.bare:draw()
end

function Overworld:move(x, y)
  local hspace = WIDTH / 3
  local vspace = HEIGHT / 3

  -- move the bare
  self.bare.x = self.bare.x + x
  self.bare.y = self.bare.y + y

  -- lock the bare within the center third of the screen by scrolling the map
  -- inversely with the bare when he steps over the edge

  if self.bare.x < hspace then
    self.map.x = self.map.x - (self.bare.x - hspace)
    self.bare.x = hspace
  end

  if self.bare.x > WIDTH - self.bare.size - hspace then
    self.map.x = self.map.x - (self.bare.x - (WIDTH - self.bare.size - hspace))
    self.bare.x = (WIDTH - self.bare.size - hspace)
  end

  if self.bare.y < vspace then
    self.map.y = self.map.y - (self.bare.y - vspace)
    self.bare.y = vspace
  end

  if self.bare.y > HEIGHT - self.bare.size - vspace then
    self.map.y = self.map.y - (self.bare.y - (HEIGHT - self.bare.size - vspace))
    self.bare.y = (HEIGHT - self.bare.size - vspace)
  end

  -- compute the tile under the bare
  local sx = math.floor((self.bare.x - self.map.x_off) / self.map.tile_size)
  local sy = math.floor((self.bare.y - self.map.y_off) / self.map.tile_size)

  -- check collision with the bare's top left, top right, bottom left, and
  -- bottom right corners, shifting his position appropriately
  self:collide(sx, sy)
  self:collide(sx, sy + 1)
  self:collide(sx + 1, sy)
  self:collide(sx + 1, sy + 1)
end

function Overworld:collide(x, y)
  -- get the bare's position within the map
  local bx = self.bare.x - self.map.x_off
  local by = self.bare.y - self.map.y_off

  -- decide if the tile is blocked
  local blocked = self.map:get_blocked(self.map.x_start + x, self.map.y_start + y)

  if blocked then

    -- compute the tile's coordinates within the map
    local tx = x * self.map.tile_size
    local ty = y * self.map.tile_size

    -- compute the bare's angle from the tile
    local dx = bx - tx
    local dy = by - ty
    local angle = math.atan2(dy, dx) / math.pi / 2

    -- depending on the direction from the tile, shift the bare away from it

    -- bare is below
    if angle >= 1 / 8 and angle <= 3 / 8 then
      self.bare.y = (y + 1) * self.map.tile_size + self.map.y_off
    end

    -- bare is above
    if angle >= -3 / 8 and angle <= -1 / 8 then
      self.bare.y = (y - 1) * self.map.tile_size + self.map.y_off
    end

    -- bare is right
    if angle >= -1 / 8 and angle <= 1 / 8 then
      self.bare.x = (x + 1) * self.map.tile_size + self.map.x_off
    end

    -- bare is left
    if angle <= -3 / 8 or angle >= 3 / 8 then
      self.bare.x = (x - 1) * self.map.tile_size + self.map.x_off
    end
  end
end
