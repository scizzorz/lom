-- Returns the distance between two points.
function math.dist(x1, y1, x2, y2)
  return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- Returns the angle between two points.
function math.angle(x1, y1, x2, y2)
  return math.atan2(y2 - y1, x2 - x1)
end

-- pixels to screen
function p2s(v)
  return v * CANVAS_SCALE
end

-- screen to pixels
function s2p(v)
  return v / CANVAS_SCALE
end

function choose(from)
  return from[love.math.random(#from)]
end

function tween(from, to, speed, tolerance)
  from = from + (to - from) / (speed or 5)
  if math.abs(from - to) <= (tolerance or 0.01) then
    from = to
  end
  return from
end


DIR_TO_ANGLE = {
 left = math.pi * 4 / 4,
 up_left = -math.pi * 3 / 4,
 up = -math.pi * 2 / 4,
 up_right = -math.pi * 1 / 4,
 right = math.pi * 0 / 4,
 down_right = math.pi * 1 / 4,
 down = math.pi * 2 / 4,
 down_left = math.pi * 3 / 4,
}
