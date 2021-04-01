function love.conf(t)
  t.version = "11.3"
  t.window.title = "Heroes of Might & Mango"
  t.window.width = 1200
  t.window.height = 675
  t.window.fullscreen = true
end

-- you can touch these
WIDTH = 400
HEIGHT = 225

PLAYER_SPEED = 1

MAX_HAND_SIZE = 8
DECK_SIZE = 25

-- bigger is slower
TRANSITION_SPEED = 4
CARD_FLIP_SPEED = 7
CARD_MOVE_SPEED = 4

DECK_SPACING = 2
DECK_DEPTH = -19

SHUFFLE_DELAY = 3

HAND_DEPTH = 8
SELECTED_DEPTH = -20
HAND_SPACING = 34
HAND_ANGLE = 4

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
SCALE = 5
CANVAS_SCALE = 1
GAME_ASPECT = WIDTH / HEIGHT
