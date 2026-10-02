class_name Whispers
extends RefCounted
## Mr. Robot's unprompted commentary when your stability frays.

const LINES := [
	"You're sweating, kid. They can smell it.",
	"Keep walking. Don't look at the camera on the corner.",
	"Nobody's coming to save this city. That's why we're here.",
	"You forgot something. I didn't.",
	"Every one of these people owes E Corp money. Every single one.",
	"You call that sneaking? My grandmother sneaks better, and she's dead.",
	"We had a deal. Don't make me remind you what it was.",
	"Take the pills and I disappear. Is that what you want? Really?",
	"Look at the lights up there. Every window is a debt statement.",
	"You don't trust me. Good. Don't trust anyone. Start with yourself.",
	"The fish is judging you. I'm judging the fish.",
	"Somebody's been in the apartment. You feel it too.",
	"Control is an illusion. Except mine. Mine's real.",
	"Breathe. In. Out. Now stop acting like a victim.",
	"Tick tock. Five/Nine doesn't write itself.",
	"That guy just looked at you twice. Twice.",
]


static func pick() -> String:
	return LINES[randi() % LINES.size()]
