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
    art = "status_deadly_poison",
  },

  instant_poison_coating = {
    name = "Instant Poison",
    kind = "buff",
    art = "status_instant_poison",
  },

  mindnumbing_poison_coating = {
    name = "Mind-numbing Poison",
    kind = "buff",
    art = "status_mind-numbing_poison",
  },

  slice_and_dice = {
    name = "Slice and Dice",
    kind = "buff",
    art = "status_slice_and_dice",
  },

  bleed = {
    name = "Bleed",
    kind = "debuff",
  },

  deadly_poison = {
    name = "Deadly Poison",
    kind = "debuff",
    art = "status_deadly_poison",
  },
}

effect_db = {
  manaburn = function(amt)
    return function(self, caster, target, fix)
      self.state:add_sct(amt, target.x, target.y + SCT_Y_OFFSET, SCT_MANABURN)
    end
  end,

  damage = function(amt)
    return function(self, caster, target, fix)
      self.state:add_sct(amt, target.x, target.y + SCT_Y_OFFSET, SCT_DAMAGE)
    end
  end,

  knockback = function(amt)
    return function(self, caster, target, fix)
      local dist = math.sqrt((self.x - target.x)^2 + (self.y - target.y)^2)
      local dir = math.angle(self.x, self.y, target.x, target.y)

      target.body:applyLinearImpulse(math.cos(dir) * amt, math.sin(dir) * amt)
    end
  end,

  apply = function(status, duration, stacks)
    return function(self, caster, target, fix)
      target:apply(status, duration, stacks)
    end
  end,

  chopped = function(self, caster, target, fix)
    self.state:add_particle(Slash, target.x, target.y)
  end
}

attack_db = {
  rogue_aa = {
    effect_db.chopped,
    effect_db.damage(3),
    effect_db.knockback(60),
  },

  lacerate = {
    effect_db.chopped,
    effect_db.apply("bleed", 3, 3),
  },

  hemorrhage = {
    effect_db.chopped,
    effect_db.apply("bleed", 1, 1),
    effect_db.damage(2),
  },

  garrote = {
    effect_db.chopped,
    effect_db.apply("bleed", 5, 5),
    effect_db.manaburn(5),
  },

  ambush = {
    effect_db.chopped,
    effect_db.damage(7),
    effect_db.knockback(240),
  },

  shiv = {
    effect_db.chopped,
    effect_db.damage(1),
  },
}

cast_db = {
  slash = function(effects)
    return function(caster, x, y)
      OVERWORLD:aim()
      OVERWORLD:add_attack(SlashAttack, effects, OVERWORLD.char.x, OVERWORLD.char.y, DIR_TO_ANGLE[OVERWORLD.char.dir])
    end
  end,

  double_slash = function(effects)
    return function(caster, x, y)
      OVERWORLD:aim()
      OVERWORLD:add_attack(SlashAttack, effects, OVERWORLD.char.x, OVERWORLD.char.y, DIR_TO_ANGLE[OVERWORLD.char.dir])
      OVERWORLD:add_attack(SlashAttack, effects, OVERWORLD.char.x, OVERWORLD.char.y, DIR_TO_ANGLE[OVERWORLD.char.dir], -1)
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

  roll_the_bones = {
    name = "Roll the Bones",
    art = "card_roll_the_bones",
    cost = 2,
  },

  envenom = {
    name = "Envenom",
    art = "card_envenom",
    cost = 3,
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
    art = "card_thistle_tea",
    cost = 0,
    cast = function(caster, x, y)
      OVERWORLD.mana = OVERWORLD.max_mana
    end
  },

  deadly_poison = {
    name = "Deadly Poison",
    art = "card_deadly_poison",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("deadly_poison_coating", 60)
    end
  },

  instant_poison = {
    name = "Instant Poison",
    art = "card_instant_poison",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("instant_poison_coating", 60)
    end
  },

  mindnumbing_poison = {
    name = "Mind-numbing Poison",
    art = "card_mind-numbing_poison",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("mindnumbing_poison_coating", 60)
    end
  },

  slice_and_dice = {
    name = "Slice and Dice",
    art = "card_slice_and_dice",
    cost = 1,
    cast = function(caster, x, y)
      caster:apply("slice_and_dice", 10)
    end
  },

  shiv = {
    name = "Shiv",
    art = "card_shiv",
    cost = 0,
    cast = cast_db.slash(attack_db.shiv),
  },

  infected_wounds = {
    name = "Infected Wounds",
    art = "card_infected_wounds",
    cost = 5,
  },

  mutilate = {
    name = "Mutilate",
    art = "card_mutilate",
    cost = 1,
    cast = cast_db.double_slash(attack_db.rogue_aa),
  },

  rupture = {
    name = "Rupture",
    art = "card_rupture",
    cost = 4,
  },
}
