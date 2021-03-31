require('conf')
require('engine')
require('gfx')
require('util')


Sprite = Object:extend()

function Sprite:init(id)
  self.x = 0
  self.y = 0
  self.size = framesets[atlas[id].frameset].size
  self.sx = 1
  self.sy = 1
  self.angle = 0
  self.frame = 0
  self.visible = true

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
end

function Sprite:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.gfx, self.quads[self.frame],
                      S(self.x), S(self.y), self.angle,
                      SCALE * self.sx, SCALE * self.sy)
  end
end
