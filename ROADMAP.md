# MICROSLOP MASSACRE — Master Roadmap

**The goal:** New Vegas-grade story, choice and consequence, with a sandbox that
plays like a modern crime open world, inside Mr. Robot's New York. Every path is
valid: hero, vigilante, kingpin, company man, true believer, monster. The main
story can be followed, ignored, or broken in a hundred ways and still reach an
ending. Everything must run on a **Ryzen 5 PRO 4650U iGPU** (GL Compatibility,
~40–70 draw calls, <8 GB RAM). Graphics stay stylized; the budget goes to
gameplay, story and systems.

Legend: `[x]` done · `[~]` in progress · `[ ]` to do

---

## 0. Already built

- [x] Continuous procedural NYC, day/night, weather, traffic, crowds, subways
- [x] FNV systems: 8 skills, traits, perks, EXPLOIT (V.A.T.S.), factions with fame/infamy,
      companions, barter, stability (sanity), 6 endings + hidden Overlap
- [x] Main quest (Five/Nine) with 4 parallel pillars, ~12 side quests
- [x] ~30 hand-built interiors; custom dialogue language (.dlg) and quests (.qst)
- [x] **Pass 1 (open world):** 2,527 enterable generic buildings (apartments, 8 store
      types, bars, diners, arcades, offices, warehouses, squats, gang hideouts) with
      hours, owners, guards and clerks; 6,300+ searchable props that restock;
      22 new weapons incl. 8 hidden uniques; ATM hacking + stolen cards;
      pickpocketing; job board (5 contract types); street encounters

- [x] **Pass 2 (this update):** every parked car in the city is stealable (glovebox
      included); Bowery Bay Airfield with flyable Skyhawks and E Corp's jet (arcade flight
      model, stall, landing, crash, chase camera, HUD instruments, pad support) and the
      side quest *Wings*; four recruitable companions (Darlene, Leon, Trenton, Shayla) with
      bonuses, barks, reactions, three heart-to-hearts each, permanent perks and breaking
      points; controller support everywhere (title screen, pause, phone, map, minigames,
      level-up, barter, terminals); load-state race fixed; saves store interior positions
      relative to the interior; dozens of placement, dialogue-gate and writing fixes

---

- [x] **Pass 3 (connected world + game war):** New York, I-80 and Chicago share one
      world (~3 km of farmland between cities, skylines on each other's horizons,
      planes fly straight across map edges, world view on the phone map); the Respawn
      arc repaired end to end (Rockstarved, Chicago's two hacks, the drive home) and a
      new closing chapter, **Microslop Massacre**, with its own epilogue slides;
      street lamps that really light the street at night, headlights, a Night
      brightness setting; validator clean on every map; `respawn_walk` plays the
      whole arc

## 1. World and exploration

- [x] **Map expansion ~2.1x:** 10 rows north (Inwood, Harlem, the Bronx), 7 avenues
      east (Astoria, Long Island City, Hunts Point). ~6.7 km² of dense city.
- [~] Fort Tryon Park (wooded hills) with **The Cloisters** landmark
- [~] **The Twin Towers** (this is an alternate universe; they stand). DONE: towers, plaza, lobby, express elevator, walkable roof. TODO: Lower Manhattan,
      visible from everywhere. Lobby, express elevator, **Top of the World** observation
      deck + Windows on the World bar. E Corp leases 40 floors: a heist target.
- [ ] New landmarks per district (each with a hand-built interior and a questline):
  - Harlem: St. Nicholas Shelter (church), the Apollo-style theater, a jazz club
  - Bronx: Candyman's corner and stash tower (the Carver Houses), the slumlord's office,
    a chop shop under the elevated train, a boxing gym
  - Hunts Point: Terminal Market warehouses (Candyman's lab), a scrapyard
  - Astoria: Greek diner (a fixer's office), Steinway piano factory ruin
  - Long Island City: **E Corp Data Center** (heist), "The Pit" underground fight club,
    a glass condo tower (whistleblower)
  - Inwood: The Cloisters, Dyckman marina
- [x] New subway stations in every new district (fast travel network)
- [ ] 40+ new map POIs; discovery XP; "explorer" achievement tiers
- [ ] Climbable fire escapes / rooftop routes (stealth approach to buildings)
- [ ] Ambient life: street vendors, preachers, buskers, dog walkers, protesters (E Corp),
      night-shift workers; neighborhoods feel different (music, crowd, language on signs)

## 2. Intro and onboarding (New Vegas style)

- [x] **Cold open on New Game:** narrated cinematic flyover of the city (camera sweeps
      from the Twin Towers to E Corp tower to Coney Island) with the world's premise in
      short text cards: E Corp owns 70% of consumer debt, the Washington Township leak,
      fsociety's masks, a boy named Elliot who talks to someone who isn't there.
      Skippable. Then Krista's office.
- [x] Intake session = character creation (tags, traits)
- [x] Early-game signposting: Elliot's computer (Gideon's email, fsociety's message, Shayla, the
      headlines that point at the Bronx and Harlem questlines, the jobs app)
- [x] Every quest objective says where to go and how; a story director keeps quests moving in any order

## 3. Vehicles and the crime sandbox

- [x] **Steal cars:** parked cars (lockpick or smash a window) and traffic (carjack)
- [x] Driving: arcade handling, handbrake, collisions, damage/smoke/explosion, running
      people over (crime), chase camera, engine sound, gamepad triggers
- [ ] In-car radio, first-person camera, fleeing drivers as NPCs
- [x] Police chases: heat levels 1–5, patrol cars pursue, roadblocks at heat 4+,
      FBI at 5; lose them by breaking line of sight, changing cars, masks, or laying low
- [x] Chop shop (Hunts Point): sell stolen cars; "wanted list" of models for bonus cash
- [ ] Garage: keep cars you like (your apartment's street, a rented garage)
- [x] Street races (Hunts Point)
- [ ] More race loops (LIC, Chicago), taxi fares as a job type

## 4. Morality and the paths you can take

- [ ] **Hidden "Soul" meter** (separate from Stability): cruelty and mercy both leave
      marks; companions, endings and Mr. Robot react
- [~] **The Monster path (serial killer):** DONE: civilian kill tracking, radio news, Detective
      Lopez questline (talk down, bribe, wipe/rewrite her case file, kill her, confess), Monster
      ending, epilogue slides. TODO: missing-person flyers, trophies, Mr. Robot reactions.
      Original plan: killing civilians is tracked (hidden count,
      pattern, district). The city reacts: news on the radio, missing-person flyers,
      an NYPD task force, and **Detective Lopez**, who starts hunting you (clues left at
      scenes: weapon type, time of night, district). Stability erodes; Mr. Robot either
      recoils or eggs you on. Trophies. A special epilogue slide, and **The Monster**
      ending if you reach the final act this way. Lopez can be outwitted, framed,
      paid, or killed, each with consequences.
- [~] **The Vigilante path:** hunt predators, bust dealers, protect the neighborhood. (Bad Company + Sugar done)
      Fame with locals, NYPD tolerance, press nicknames.
- [~] **The Kingpin path:** DONE: take Candyman's corners (clean or dirty product), daily income,
      Kingpin ending. TODO: laundering front, turf wars, expansion.
- [ ] **The Company Man path:** side with E Corp / Price the whole way.
- [ ] Heat/wanted upgrade: witnesses must survive and phone it in; masks and clothes
      change what they report; bribe cops; lay low in safehouses

## 5. Main story (non-linear, unbreakable)

Structure: 4 acts. Every main objective has **3+ routes** (stealth, social, violent,
hacking, faction help, money). Every essential character has a fallback if killed
(FNV-style: someone else can hand you the thread, or a terminal/holotape equivalent).

- **Act 1 — Hello, Friend.** Krista, Allsafe, the rootkit, Mr. Robot's pitch. Routes:
  join fsociety, report the hack to Gideon/E Corp, sell the rootkit to the Dark Army,
  or walk away and live in the sandbox (the story will come to you later).
- **Act 2 — The Pillars.** Steel Mountain, the faction (Dark Army / FBI), the inside man
  (Tyrell / keycard), the rootkit. Plus **new optional pillars** that change the
  endgame: the Twin Towers E Corp floors (evidence of Washington Township), the
  E Corp Data Center in LIC (a second backup site most players won't know exists),
  and the press (a journalist who can make the leak public).
- **Act 3 — Five/Nine.** The hack, from any combination of pillars. New: the fallout
  in the streets (riots, cash shortages, E Coin), which changes shops, prices and NPCs.
- **Act 4 — Stage Two / The Deus Group.** The table at the Salina, Whiterose's machine.
- **Endings: 14 now reachable** (fsociety, Stage Two, Clean Hands, Board Seat, Reboot, Overlap,
  Press Freedom, Mr. Robot, The Monster, The Quiet Life, The Confession, The Informant,
  The Company Man, The Kingpin). Original plan: Five/Nine, Stage Two, Clean Hands, The Board Seat,
  Reboot, The Overlap (hidden), **The Monster**, **Kingpin**, **The Quiet Life**
  (you never do the hack), **Press Freedom** (the journalist publishes everything).
  Each with per-faction/per-character epilogue slides (20+ slide variables).
- [ ] Main-quest fallback audit: kill every essential NPC in a test run; the story must
      still reach an ending

## 6. Side questlines (each with 3–4 real outcomes)

- [x] **Candyman / 'Sugar'** (Bronx/Hunts Point): a dealer flooding corners with cut product that's
      killing kids. Bust him (NYPD), burn the supply, rob him, frame him to the Dark
      Army, or **take over** (Kingpin path).
- [x] **Bad Company** (predator hunting, Harlem/Astoria): Elliot traces an online predator
      operating out of an apartment. Gather evidence from his machine, then: hand him to
      the FBI (clean arrest), expose him to the neighborhood, extort him, or end him.
      Handled like the show: never graphic, about stopping him.
- [ ] **The Landlord** (Bronx): a slumlord cutting heat in winter. Hack his books,
      redistribute his money, blackmail him, or burn his building (with or without
      warning the tenants).
- [ ] **The Pit** (LIC fight club): underground fights for cash, a champion to beat,
      a fixed fight you can take the dive in, or expose the promoter.
- [ ] **Whistleblower** (LIC): an E Corp analyst with proof about Township. Protect her,
      sell her to Price, or use her leak for fsociety.
- [ ] **Runaway** (Harlem shelter): find a missing teenager living in the squats; bring
      her home, respect her choice, or learn why she ran (and deal with that).
- [ ] **Debt Collector** (Astoria): an E Corp collector bleeding a family. Hack, scare,
      pay the debt, or become a collector yourself.
- [ ] **The Cloisters** (Inwood): a Dark Army dead drop in a medieval museum.
- [ ] **Top of the World** (Twin Towers): a gala, a keycard, an E Corp exec with secrets.
- [ ] **Chop Shop** (Bronx): steal specific cars to order.
- [ ] **Street Races**, **Taxi fares**, **Fight ladder**, **Gambling dens** (repeatables)
- [ ] 10+ small stories found in the generated buildings (notes, terminals, residents)

## 7. Factions

- [x] fsociety, E Corp, Dark Army, FBI, NYPD, locals, Allsafe, Vera's crew, Coney
- [ ] New: **Candyman's crew** (Bronx), **the Harlem block association**, **the press**,
      **LIC tech** (startups/E Corp contractors), **the chop-shop crews**
- [ ] Faction wars that play out in the streets based on your choices

## 8. Companions

- [x] Darlene (and recruit/dismiss plumbing)
- [ ] Leon, Shayla, Mobley, Trenton, a new Bronx fixer, a new LIC hacker; each with a
      perk, an affinity questline, and opinions on your choices (they can leave you)

## 9. Progression

- [ ] Level cap 30 → **50**; 30 new perks (hacking exploits, driving, crime, social)
- [ ] Skill magazines/books (temporary/permanent boosts) hidden in generated buildings
- [ ] Weapon mods (suppressors, scopes, extended mags) found or bought
- [ ] Apparel sets with bonuses (hacker, suit, street, security)

## 10. Economy and activities

- [x] Stores everywhere, ATMs, pickpocketing, jobs, fences
- [ ] Gambling: blackjack, poker, slots (bars, Coney, a back-room casino)
- [ ] Property: buy a safehouse (storage, bed, garage) in each borough
- [ ] Laundering: dirty money from crime has to be cleaned (laundromat front)
- [ ] Phone hacking: hack cameras, traffic lights, car locks, phones and doors from the
      phone at range (HACKING gated)

## 10b. Controls and feel

- [x] Full gamepad support (Fallout layout), every menu navigable, vibration, look sensitivity
- [x] Mr. Robot level-up / quest-complete / new-objective cards (the Vault Boy moment)

## 11. Technical and performance

- [x] Chunked merged meshes, far culling, LootIndex (no per-prop nodes)
- [ ] Profile the expanded map on the iGPU budget: chunk streaming if RAM or draw
      calls climb; LOD for distant towers
- [ ] Vehicle physics: cheap kinematic arcade model, not full rigid-body sim

## 12. Testing (every pass)

- [x] story_walk: plays every quest like a player (follow marker, walk through the door, talk,
      use terminals, pick choices by text) and fails if any stage can't be reached
- [x] ending_walk: reaches each ending through the dialogue that offers it
- [x] validate: every condition atom, data-side effect, quest stage setter, marker target and
      furniture type is checked

- [x] compile_all, validate, dlgwalk, fuzz_dlg, playthrough, dd_systems, dd_interiors,
      deepdebug, dd_world, smoke, screenshot harness
- [ ] Quest harness per new questline (every outcome reachable)
- [ ] "Kill everyone" run (main story still completable)
- [ ] Vehicle soak test (drive 10 km, no stuck/fall-through)
