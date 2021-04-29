status_db = {
  sprint = {
    name = "Sprint",
    kind = "buff",
    art = "status_sprint",
    effect = 2,
  },

  cold_blood = {
    name = "Cold Blood",
    kind = "buff",
    art = "status_cold_blood",
  },

  deadly_poison_coating = {
    name = "Deadly Poison",
    kind = "buff",
  },

  instant_poison_coating = {
    name = "Instant Poison",
    kind = "buff",
  },

  mindnumbing_poison_coating = {
    name = "Mind-numbing Poison",
    kind = "buff",
  },

  slice_and_dice = {
    name = "Slice and Dice",
    kind = "buff",
  },

  bleed = {
    name = "Bleed",
    kind = "debuff",
  },

  deadly_poison = {
    name = "Deadly Poison",
    kind = "debuff",
  },
}

effect_db = {
  manaburn = function(amt)
    return function(self, target, fix)
      self.state:add_sct(amt, target.x, target.y + SCT_Y_OFFSET, SCT_MANABURN)
    end
  end,

  damage = function(amt)
    return function(self, target, fix)
      self.state:add_sct(amt, target.x, target.y + SCT_Y_OFFSET, SCT_DAMAGE)
    end
  end,

  knockback = function(amt)
    return function(self, target, fix)
      local dist = math.sqrt((self.x - target.x)^2 + (self.y - target.y)^2)
      local dir = math.angle(self.x, self.y, target.x, target.y)

      target.body:applyLinearImpulse(math.cos(dir) * amt, math.sin(dir) * amt)
    end
  end,

  apply = function(status, duration, stacks)
    return function(self, target, fix)
      target:apply(status, duration, stacks)
    end
  end,

  chopped = function(self, target, fix)
    self.state:add_particle(Slash, target.x, target.y)
  end
}

attack_db = {
  rogue_aa = {
    effect_db.chopped,
    effect_db.damage(2),
    effect_db.knockback(60),
  },

  lacerate = {
    effect_db.chopped,
    effect_db.apply("bleed", 3, 3),
  },

  hemorrhage = {
    effect_db.chopped,
    effect_db.apply("bleed", 1, 1),
    effect_db.damage(1),
  },

  garrote = {
    effect_db.chopped,
    effect_db.apply("bleed", 5, 5),
    effect_db.manaburn(4),
  },

  ambush = {
    effect_db.chopped,
    effect_db.damage(5),
    effect_db.knockback(240),
  },
}

cast_db = {
  slash = function(effects)
    return function(caster, x, y)
      OVERWORLD:aim()
      OVERWORLD:add_attack(SlashAttack, effects, OVERWORLD.char.x, OVERWORLD.char.y, DIR_TO_ANGLE[OVERWORLD.char.dir])
    end
  end,
}

card_db = {
  eviscerate = {
    name = "Eviscerate",
    art = "card_eviscerate",
    cost = 1,
  },

  lacerate = {
    name = "Lacerate",
    art = "card_lacerate",
    cost = 4,
    cast = cast_db.slash(attack_db.lacerate),
  },

  hemorrhage = {
    name = "Hemorrhage",
    art = "card_hemo",
    cost = 2,
    cast = cast_db.slash(attack_db.hemorrhage),
  },

  garrote = {
    name = "Garrote",
    art = "card_garrote",
    cost = 4,
    cast = cast_db.slash(attack_db.garrote),
  },

  ambush = {
    name = "Ambush",
    art = "card_ambush",
    cost = 4,
    cast = cast_db.slash(attack_db.ambush),
  },

  sprint = {
    name = "Sprint",
    art = "card_sprint",
    cost = 2,
    cast = function(caster, x, y)
      caster:apply("sprint", 3)
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

  thistle_tea = {
    name = "Thistle Tea",
    art = "card_blank",
    cost = 0,
    cast = function(caster, x, y)
      OVERWORLD.mana = OVERWORLD.max_mana
    end
  },

  deadly_poison = {
    name = "Deadly Poison",
    art = "card_blank",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("deadly_poison_coating", 60)
    end
  },

  instant_poison = {
    name = "Instant Poison",
    art = "card_blank",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("instant_poison_coating", 60)
    end
  },

  mindnumbing_poison = {
    name = "Mind-numbing Poison",
    art = "card_blank",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("mindnumbing_poison_coating", 60)
    end
  },

  slice_and_dice = {
    name = "Slice and Dice",
    art = "card_blank",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("slice_and_dice", 10)
    end
  },
}
