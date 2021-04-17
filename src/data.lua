card_db = {
  eviscerate = {
    name = "Eviscerate",
    art = "card_eviscerate",
    cost = 1,
  },

  ambush = {
    name = "Ambush",
    art = "card_ambush",
    cost = 4,
  },

  sprint = {
    name = "Sprint",
    art = "card_sprint",
    cost = 2,
    startlag = 0.5,
    endlag = 2,
    cast = function(caster, x, y)
      local dir = math.angle(caster.x, caster.y, x, y)
      local dx = math.cos(dir) * 200
      local dy = math.sin(dir) * 200
      caster.body:applyLinearImpulse(dx, dy)
    end
  },

  cold_blood = {
    name = "Cold Blood",
    art = "card_cold_blood",
    cost = 0,
  },
}
