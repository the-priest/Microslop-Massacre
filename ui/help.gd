class_name Help
extends RefCounted

const CONTROLS := """[b]MOVEMENT[/b]
  WASD / arrows     move
  Mouse             look
  Shift             sprint
  Ctrl or C         sneak (toggle) — [HIDDEN] / [CAUTION] / [DANGER]
  Space             jump

[b]ACTION[/b]
  E                 talk / open / take / use
  Left mouse        shoot / swing
  Right mouse       aim down sights (tighter spread)
  R                 reload
  1-8 / wheel       weapon hotkeys (assign in phone: hover item, press 1-8)
  V or Q            EXPLOIT mode (targeting: time stops, queue shots with FOCUS)
  H                 quick-heal with your best aid item
  F                 flashlight

[b]MENUS[/b]
  TAB               phone: STATS  (level-up when pending)
  I                 phone: ITEMS
  J                 phone: DATA (quests, radio)
  M                 phone: MAP (fast travel)
  T                 wait
  F5 / F9           quicksave / quickload
  ESC               pause, save, load, settings

[b]EXPLOIT MODE[/b]
  A/D or Tab        cycle targets
  W/S               head / torso
  Space / click     queue a shot (costs FOCUS)
  Backspace         remove last shot
  E / Enter         execute
  V / Esc           cancel

[b]DIALOGUE[/b]
  Space / click     continue
  1-9, W/S + Enter  choose
  White [SKILL N]   you will pass.   Red [SKILL N] (you/need) — you will fail.

[b]CARS[/b]
  E on a parked car  steal it (LOCKPICK, or smash the window: loud)
  E on stopped traffic  carjack (the driver runs; somebody calls it in)
  W/S               gas / brake and reverse
  A/D               steer          Space  handbrake
  G                 horn (scatters people)
  Mouse             swing the camera
  E                 get out (slow down first)
  Every parked car in the city can be stolen. Taxis and vans too.

[b]PLANES[/b]  (Bowery Bay Airfield, Queens: north-east corner of the map)
  E on a plane      fly it (Gus's trainers once he says yes; E Corp's jet is a felony)
  W/S               throttle up / down
  A/D               bank (and steer on the ground)
  Mouse back / ↓    nose up (climb)      Mouse forward / ↑   nose down
  Mouse left/right  rudder               Space   wheel brakes
  Take-off: full throttle down the runway, pull back once she's light.
  Landing: line up early, throttle back, wings level, nose a hair up. Stop, then E.
  Too slow and the wing quits (STALL). Too steep near the ground and it's over.

[b]HELICOPTERS[/b]  (Bowery Bay's pad, Microslop Field in Redmont)
  W / S             climb / descend (hands off holds your height)
  A/D, mouse l/r    turn on the spot
  Mouse fwd / ↑     nose down: fly forward   Mouse back / ↓   nose up: slow, back off
  Space             brake
  Ease down onto a pad, a lot or a roof. Fast or moving, it's a crash.

[b]GAMEPAD[/b]  (Xbox / PlayStation / Steam Deck)
  Left stick        move / steer        Right stick   look
  A                 interact / select   B             phone / back
  X                 reload / take all   Y             jump
  RT / LT           fire / aim  ·  in a car: gas / brake
  LB                EXPLOIT  ·  in a car: horn        RB   quick-heal
  L3 / R3           sprint / sneak
  D-pad             up: flashlight · down: wait · left/right: weapons
  START / BACK      pause / map
  In a car: X handbrake, A get out. In EXPLOIT: A queue shot, X execute, Y undo, LB/RB target.
  In a plane: RT/LT throttle, left stick banks and pitches (pull back to climb),
  LB/RB rudder, X brakes, right stick looks around, A gets out once stopped.
  In a helicopter: RT/LT climb and descend, left stick turns and noses forward or back.
  Phone: LB/RB tabs, LT/RT sections. Map: stick picks a place, A fast-travels."""
