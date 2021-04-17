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
    cast = function(caster, x, y)
      caster:apply("sprint", 5)
    end
  },

  cold_blood = {
    name = "Cold Blood",
    art = "card_cold_blood",
    cost = 0,
    cast = function(caster, x, y)
      caster:apply("cold_blood")
    end
  },
}

status_db = {
  sprint = {
    name = "Sprint",
    kind = "buff",
    effect = 1.5,
  },
  cold_blood = {
    name = "Cold Blood",
    kind = "buff",
  },
}
