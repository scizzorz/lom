function love.conf(t)
  t.version = "11.5"
  t.window.title = "Heroes of Might & Mango"
  t.window.width = 1200
  t.window.height = 675
  t.window.fullscreen = false
end

-- you can touch these
WIDTH = 400
HEIGHT = 225

ACTOR_LINEAR_DAMPING = 30

-- game play config
PLAYER_SPEED = 8
HAND_SIZE = 5
DECK_SIZE = 25
DRAW_TIMER = 8

-- temp
MELEE_RANGE = 25

-- health config
MAX_HEALTH = 100

-- mana config
-- under the hood, each mana crystal is made up of fractional mana pieces. it
-- makes it easier to work with fractional values that we may want later.
MAX_MANA = 5
MANA_PARTS = 60

-- state transition speed
-- bigger is slower
TRANSITION_SPEED = 4

-- SCT scroll speed
-- bigger is slower
SCT_SPEED = 10
SCT_FADE_START = 0.25
SCT_DURATION = 1

SCT_Y_OFFSET = -10

SCT_BUFF = {r=0.7, g=0.5, b=0.2}
SCT_DEBUFF = {r=0.2, g=0.7, b=0.5}
SCT_DAMAGE = {r=0.7, g=0.2, b=0.2}
SCT_HEAL = {r=0.2, g=0.7, b=0.2}
SCT_MANA = {r=0.2, g=0.2, b=0.7}
SCT_MANABURN = {r=0.7, g=0.2, b=0.7}
SCT_COLORS = {
  buff=SCT_BUFF,
  debuff=SCT_DEBUFF,
  heal=SCT_HEAL,
  damage=SCT_DAMAGE,
  mana=SCT_MANA,
  manaburn=SCT_MANABURN,
}

-- menu cursor fade
-- bigger is slower
MENU_OPTION_SPEED = 4

-- card animation speeds
-- bigger is slower
CARD_FADE_SPEED = 7
CARD_FLIP_SPEED = 7
CARD_MOVE_SPEED = 7

-- deck / discard pile positioning
DECK_SPACING = 4
DECK_DEPTH = -17

-- reshuffle speeds
SHUFFLE_DELAY = 0

-- hand positioning
HAND_DEPTH = 6
SELECTED_DEPTH = -18
HAND_SPACING = 30
HAND_ANGLE = 3

-- slime behavior
SLIME_WALK_SPEED = 4
SLIME_WALK_MIN = 2
SLIME_WALK_MAX = 4

SLIME_STAND_MIN = 1
SLIME_STAND_MAX = 3

SLIME_CHASE_SPEED = 7
SLIME_CHASE_RANGE = 75

SLIME_ATTACK_RANGE = 25

-- set to 0 for full 360 aiming; otherwise, it's the number lock steps
AIMING_STEPS = 8

KEYBINDINGS = {
  card1 = "1",
  card2 = "2",
  card3 = "3",
  card4 = "4",
  card5 = "5",
  card6 = "6",
  card7 = "7",
  card8 = "8",
  card9 = "9",
  up = "w",
  down = "s",
  left = "a",
  right = "d",
  menu = "escape",
}

-- don't touch these
CANVAS_SCALE = 1
GAME_ASPECT = WIDTH / HEIGHT
