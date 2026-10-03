class_name EndingData
extends RefCounted
## New Vegas-style ending slides. Some slides only appear based on flags,
## so two players who pick the same ending still get different epilogues.

const NAMES := {
	"fsociety": "Five/Nine", "darkarmy": "Stage Two", "fbi": "Clean Hands",
	"ecorp": "The Board Seat", "reboot": "Reboot", "overlap": "The Overlap",
	"press": "Press Freedom", "robot": "Mr. Robot", "monster": "The Monster",
	"quiet": "The Quiet Life", "confession": "The Confession", "informant": "The Informant",
	"company": "The Company Man", "kingpin": "The Kingpin",
}

## Endings where the hack (Five/Nine) actually happened.
const HACK_ENDINGS := ["fsociety", "darkarmy", "fbi", "ecorp", "reboot", "overlap", "press", "robot", "monster"]


static func _s(title: String, text: String) -> Dictionary:
	return {"title": title, "text": "[center]" + text + "[/center]"}


static func slides(ending: String) -> Array:
	var out: Array = []
	var GS := GameState
	# Opening slide, per ending.
	match ending:
		"fsociety":
			out.append(_s("FIVE/NINE", "At 3:00 in the morning, the debt of a nation became unreadable.\n\nfsociety kept the key just long enough to throw it into the sea. E Corp's records didn't vanish — they became noise. Every loan, every mortgage, every leash: still there, and forever illegible.\n\nThe city woke up owing nothing to no one, and nobody knew whether to dance or to scream. So it did both, for a long time."))
		"darkarmy":
			out.append(_s("STAGE TWO", "You didn't stop at the records. On Whiterose's schedule, to Whiterose's design, the building that held the last paper backups came down with the paper inside it.\n\nThe debt died. So did the certainty that you'd been the one deciding anything. The Dark Army thanked you the way weather thanks a barometer: not at all, and precisely on time."))
		"fbi":
			out.append(_s("CLEAN HANDS", "You gave Agent DiPierro the plan, the timing, and just enough of the truth. When the arrests came, your name wasn't on any of them.\n\nfsociety fell. Some of them looked for you in the crowd of agents and didn't find you, because you'd already learned how to not be found. You walked into daylight and stayed there. It was exactly as bright and as empty as you'd feared."))
		"ecorp":
			out.append(_s("THE BOARD SEAT", "You sat at the table above the tower and you did not say no.\n\nThe revolution happened on schedule, and the men who owned the world simply changed the world's name and kept owning it. You were rich. You were safe. You were, as promised, irrelevant — which they had told you was the only true safety, and which turned out to feel exactly like a very comfortable cage."))
		"reboot":
			out.append(_s("REBOOT", "You destroyed the key and the records both, and then you burned your own way in behind you. No jubilee to be managed. No rubble to be shaped. No masters, old or new.\n\nJust gone. A hole where the biggest company on Earth used to be, and a young man walking away from it with nothing in his pockets and, for the first time, nothing in his head telling him what to do next."))
		"press":
			out.append(_s("PRESS FREEDOM", "You didn't hand the key to fsociety, or to an army, or to a man at a table. You handed everything to the press: the hack, the Township memos, the names of the people who signed them, the table at the Salina and who sat at it.\n\nFor eleven days every front page on Earth was the same story. Nobody could spin it, because nobody owned it. The debt was gone, and for once the whole world knew exactly why, and exactly who had been lying to it."))
		"robot":
			out.append(_s("MR. ROBOT", "You stopped fighting him. At the last moment, with the key in your hand, you let go, and he pressed it for you.\n\nThe hack worked. The world's debt burned. And the man who walked out of the arcade that night wore a vintage jacket and smiled like your father, and answered to your name only when he felt like it. Somewhere very deep inside him, a quiet boy is still watching through the glass."))
		"monster":
			out.append(_s("THE MONSTER", "The hack happened. Nobody remembers that part. They remember the other thing: the bodies in the stairwells and the alleys, the pattern the tabloids gave a name to, the city that learned to lock its doors at night because of you, not E Corp.\n\nYou wanted to free them. Somewhere along the way you started hunting them instead. The debt is gone. The fear you left behind has no end date and no key to throw away."))
		"quiet":
			if GS.has_flag("joined_fsociety"):
				out.append(_s("THE QUIET LIFE", "You walked out of the arcade one night and never went back. Without you, the plan stayed a plan. fsociety tried, stalled, argued, and scattered, and the masks slowly disappeared from the subway.\n\nE Corp is still E Corp. The debt is still the debt. But you sleep now, most nights. You feed your fish. You go to Krista's on Tuesdays. Some people would call that losing. Some days, so do you."))
			else:
				out.append(_s("THE QUIET LIFE", "You never pressed the key. You never even joined them. Somewhere across the river a crew of kids in masks planned a revolution without you, and it never came.\n\nYou kept your job. You fed your fish. You let Krista see a little more of you every week. The world didn't change. You did, a little. It turned out to be the only hack that was ever really yours to run."))
		"confession":
			if GS.has_flag("confessed_murders"):
				out.append(_s("THE CONFESSION", "You told Detective Lopez everything, in order, starting with the first one. She wrote it all down and never looked away.\n\nThe trial was short. The families sat in the front row every day. You didn't look away either; it was the only thing you had left to give them. In a small room upstate, with a window that doesn't open, the voice went quiet at last. Nobody in that courtroom would call it justice. It's what there was."))
			else:
				out.append(_s("THE CONFESSION", "You sat down across from Agent DiPierro and told her everything. The honeypot. The arcade. The plan. The voice. She listened for nine hours and didn't interrupt once.\n\nThe trial was short. The sentence was long. The newspapers called you a terrorist, then a patient, then forgot you. In a small room upstate, with a window that doesn't open, you finally stopped hearing him. Nobody can say whether that was justice or just silence."))
		"informant":
			out.append(_s("THE INFORMANT", "The FBI took the arcade at dawn, exactly when you told them to. Darlene, Mobley, Trenton, the others: all of them, face-down on the boardwalk, while the Wonder Wheel turned overhead.\n\nYou were not on the list. You were a line in a sealed file, a code name, a new apartment in a city you'd never visited. E Corp sent the Bureau a thank-you note. Nobody ever sent you one, and you never slept well again."))
		"kingpin":
			if GS.has_flag("kingpin_dirty"):
				out.append(_s("THE KINGPIN", "While the rest of the city argued about revolutions, you counted envelopes. Nine corners became twenty. The Bronx became Hunts Point became half of Queens, and the candy never stopped, and neither did the funerals.\n\nThey never learned your face on the street. They just learned to be afraid of a quiet man in a hoodie who never raised his voice. You told yourself it was a system like any other. It was. That was the problem."))
			else:
				var who := "a hacker who erased the world's debt and then sold cash to the wreckage" if GS.has_flag("five_nine_done") else "a hacker who never pressed the button"
				out.append(_s("THE KINGPIN", "You took Candyman's corners and you took the poison out of them. The product stayed; the funerals stopped. Money came in every morning in an envelope, and you spent a surprising amount of it on the shelter in Harlem.\n\nYou were a drug lord who kept kids alive, and " + who + ". Nobody in the city had a word for what you were. Neither did you, and some nights that was the only thing that let you sleep."))
		"company":
			out.append(_s("THE COMPANY MAN", "You gave fsociety to E Corp: the arcade, the plan, the names. Tyrell Wellick walked into the boardroom with the biggest security story of the decade, and walked out as CTO.\n\nHe kept his promise. You have an office now on the 91st floor, a badge that opens every door, and a salary that would make your father's settlement look like pocket change. From your window you can see the Township, if you look. You've stopped looking."))
		"overlap":
			out.append(_s("THE OVERLAP", "There was a version of that night where nobody had to be sorted into a winner and a loser. You found the seam and you pulled it, and for one impossible hour the whole broken family of the city stood in one room and refused to choose.\n\nfsociety, the Dark Army, the FBI, E Corp — and Darlene's hand in yours, and Krista's truth finally spoken aloud. It shouldn't have held. It held. Not forever. But long enough to prove it could."))
	# Personal epilogue slides, drawn from what you did.
	if GS.has_flag("shayla_out"):
		out.append(_s("SHAYLA", "Shayla got out. She kept getting out, after that — of the neighborhood, of the life, of the gravity that pulls soft things down. She sent you a postcard once, from somewhere with a real sky. It said only: 'Still funny. Still alive. — S'"))
	elif GS.has_flag("knows_vera"):
		out.append(_s("SHAYLA", "You never went back for Shayla. Vera's world closed over her the way water closes over a stone. You told yourself you'd had bigger things to do. The city is very good at making that feel true."))
	if GS.has_flag("krista_free"):
		out.append(_s("KRISTA", "Krista left Lenny, and then left the practice, and then left the city. She sends you an email on the anniversary of your first real session. You never write back. You always read it twice."))
	if GS.has_flag("robot_accepted"):
		out.append(_s("THE PIER", "You stopped fighting the man in the jacket. You didn't lose yourself; you found the rest of yourself, the part that had been carrying your father's anger since you were eight. Some mornings you wake up humming songs you never learned. You let him have that."))
	elif GS.has_flag("robot_truce"):
		out.append(_s("THE PIER", "You and the man in the jacket kept your deal. You drive. He rides. Now and then you feel his hand reach for the wheel, and you say no, and more often than not he listens. Krista calls it progress. He calls it a hostage situation. Both of them are a little bit right."))
	elif GS.has_flag("robot_rejected"):
		out.append(_s("THE PIER", "You told the man in the jacket to get out of your head. He didn't. He just went quiet, and the quiet has teeth. You lose an afternoon now and then. You find notes in your own handwriting that you don't remember writing. You've stopped reading them."))
	if GS.has_flag("ecoin_exposed"):
		out.append(_s("E COIN", "Nora Kessler's story ran for eleven days. 'The crisis is the onboarding' became a protest sign, then a T-shirt, then a line in a Senate hearing. E Coin was 'paused pending review.' It is still paused. Phillip Price has not given an interview since."))
	elif GS.has_flag("ecoin_broken"):
		out.append(_s("E COIN", "E Coin launched on a Friday and failed on a Friday, in front of every camera in the country, forty thousand wallets rejecting their own signatures at once. 'A software issue,' E Corp said. Nobody believed them about anything after that."))
	elif GS.has_flag("price_fbi"):
		out.append(_s("PHILLIP PRICE", "Agent DiPierro walked Phillip Price out of his own building in handcuffs on a Tuesday morning. He was out by Wednesday. But the photograph ran everywhere, and men like Price live on the belief that it can't happen to them. For one Tuesday, it did."))
	elif GS.has_flag("five_nine_done") and str(GS.flags.get("after_path", "")) == "settle":
		out.append(_s("E COIN", "You let it settle. E Coin rolled out on schedule, and by spring half the country was paid in it, owed in it, and watched in it. The new ledger was cleaner than the old one. That was the problem."))
	# Respawn: the games.
	if GS.has_flag("rs_refund"):
		out.append(_s("ROCKSTARVED", "A year of Shark Card money went back to the cards it came from, in one night, to the cent. Rockstarved's next game shipped without a store in it, because nobody in the building was willing to be the one who put it back. A fourteen-year-old in Ohio got his mother's savings back and spent exactly none of it. He keeps the refund email printed out in a drawer."))
	elif GS.has_flag("rs_press"):
		out.append(_s("ROCKSTARVED", "'THE PLAYER IS A FUNNEL' ran on every games site and then every news site, and then it was a question in a congressional hearing that no executive could answer with a straight face. Rockstarved survived. Its business model didn't. Three countries now print the odds on every box by law."))
	if GS.has_flag("kenny_badge") and GS.has_flag("rs_done"):
		out.append(_s("KENNYQA", "Kenny never went back to QA. He started a union for game testers instead, out of the back of The Rabbit Hole, with a laminated badge from Crunch Team C framed over the bar. Membership: eleven thousand. Every studio that hires them gets the same first note: the quit button should work as well as the buy button."))
	if GS.has_flag("phony_freed") and GS.has_flag("earse_exposed"):
		out.append(_s("CHICAGO", "Every revoked library came back at once, worldwide, and Phony's lawyers spent a year trying to explain to a judge why they should be allowed to take it away again. They lost. 'You own what you paid for' is a law now, in a few places, and a tattoo in a lot more. Ansel's brother is fourteen, and he's making a game. It has no store in it."))
	elif GS.has_flag("earse_exposed"):
		out.append(_s("CHICAGO", "Once the real odds were printed on the box, nobody bought the box. Electronic Arse called it 'a temporary shift in player sentiment.' It has been temporary for six years. Phony still owns your library. Somewhere in a South Side warehouse, Ansel keeps the terminal credentials taped under her one chair, waiting."))
	if GS.has_flag("ms_freed"):
		out.append(_s("MICROSLOP", "At 9:00 on a Friday morning two billion rented libraries became owned ones, and no lawyer on Earth could work out how to take them back without admitting what they'd been about to do. 'Game Pass Away' became a joke, then a verb. To get Microslopped: to find out you never owned it. Fewer people get Microslopped now. Nobody at Microslop will say why."))
	elif GS.has_flag("ms_exposed"):
		out.append(_s("MICROSLOP", "Project Sunset ran on every front page for a week, and SlopForge ran in a courtroom for three years. The developers whose work had trained it won, and the settlement had a clause nobody expected: credit. Every game the AI ever touched now opens with a list of the human names it was built from. The list takes four minutes to scroll. You can't skip it."))
	elif GS.has_flag("ms_returned"):
		out.append(_s("MICROSLOP", "Forty studios reopened under their own names, in rented rooms over laundromats and dentists, making the sequels nobody would fund. Most of them are broke. Some of them are thriving. All of them own what they make. Microslop still exists; it just has much less to subscribe you to."))
	if GS.has_flag("pixel_home"):
		out.append(_s("RESPAWN", "Respawn outgrew its forum, then its servers, then its name. Dev went back to fixing arcade cabinets in Yonkers. Somebody else runs it now, and somebody else after them, which is the point. Every year on the anniversary of Floor 88, thirty thousand people log into the same old game at the same minute, just because they can."))
	if GS.has_flag("ortiz_saved"):
		out.append(_s("2B", "Mrs. Ortiz's phone never rang about Hector again. She kept the tape, with his voice on the outgoing message, in the drawer with his watch. Sunday dinners at 2B became a building tradition: the Super, Shayla, whoever was hungry. There was always too much arroz con pollo. That was the point." + (" You wore the sweater to every one of them." if GS.has_item("ortiz_sweater") else "")))
	# Out of town.
	if GS.has_flag("trevor_flipped"):
		out.append(_s("LOU'S RED HOTS", "Lou's Red Hots made it to thirty-five years on the corner, then forty. The kid behind the grill now is a former review farmer named Trevor, who writes the specials board in a voice of authentic enthusiasm and means every word. EZeats paid a fine in Illinois. It was smaller than Lou's weekly order of celery salt."))
	elif GS.has_flag("lou_truth"):
		out.append(_s("LOU'S RED HOTS", "'Include one allegation of rudeness to a child' became the most quoted line in Chicago food writing that year. The line at Lou's went around the block for a month, and never quite stopped. Five of the six restaurants that closed reopened. Lou catered the parties."))
	elif GS.has_flag("ezeats_bombed"):
		out.append(_s("LOU'S RED HOTS", "Lou's rating never really recovered, and neither did EZeats', which was the part Lou liked. He got a laminated sign made: NOT ON THE APP. COME IN. The neighborhood did."))
	if GS.has_flag("kowal_flipped"):
		out.append(_s("FEDERAL PLAZA", "The FBI's Chicago field office spent a year investigating E Corp Midwest for consumer fraud, on the strength of a case file nobody quite remembers writing. Agent Kowalczyk got a commendation. She hung it next to a grainy photo of a man in a hoodie, which is the only thing she kept from the original board."))
	elif GS.has_flag("kowal_dropped"):
		out.append(_s("FEDERAL PLAZA", "Case CHI-2291 was closed for lack of a definable crime. Agent Kowalczyk's son is fourteen now and wants to make games. Honest ones, he says. She doesn't know where he got that. She has a guess."))
	if GS.has_flag("room9_back"):
		out.append(_s("ROOM 9", "The Lennox Motor Inn's guest book filled up and went into a box, and the box went into the manager's attic. On its last page, two lines in the same handwriting: 'Keep driving. — E.' and, under it, steadier: 'Went back. — E.' The manager reads them sometimes. She doesn't know why they make her feel better."))
	elif GS.has_flag("room9_kept"):
		out.append(_s("ROOM 9", "You kept the page. It lives in your wallet behind your ID, folded so many times the ink is wearing through. Keep driving. Some days it's a warning. Some days it's permission. You haven't decided which it is. He hasn't either."))
	if GS.has_flag("rig_freed"):
		out.append(_s("FREIGHTOS", "Somewhere on I-80, a blue Peterbilt runs the only FreightOS license on Earth with the tier OWNER. Dolores has refused four buyout offers from E Corp's lawyers and one from a museum. When the CB asks who she is, she says 'a free woman,' and hangs up."))
	elif GS.has_flag("rig_fuse"):
		out.append(_s("FREIGHTOS", "Dolores drove another eight years without an autopilot, on maps she kept in her head. She framed E Corp's 'unauthorized modification' letter and hung it in the cab. Half the truckers on I-80 asked her which fuse. She told every one of them."))
	if GS.has_flag("ruth_thanked") and GS.has_item("insulin_cooler") == false and GS.has_flag("rig_done") and not GS.has_flag("rig_freed") and not GS.has_flag("rig_fuse"):
		out.append(_s("LENNOX", "Forty vials, eleven patients, one nine-year-old who grew up to be a nurse in the same clinic. On her first day she found a card taped inside the pharmacy register: 'To the stranger.' It had a dinosaur on it. She left it where it was."))
	if GS.has_flag("bodega_thanked"):
		out.append(_s("OMAR'S", "Omar's bodega is still open, nineteen years and counting. Coffee is free on Fridays for one particular customer, who pays exact change anyway. Omar keeps the change in a jar marked ELLIOT, for emergencies."))
	if GS.has_flag("darlene_bond"):
		out.append(_s("DARLENE", "Darlene stayed. Through all of it — the loud parts, the lost hours, the mornings you didn't recognize her. She's your sister. It's the one file that never corrupted. Wherever you ended up, she's one wall over, being annoyed that she loves you."))
	if GS.has_flag("township_public"):
		out.append(_s("WASHINGTON TOWNSHIP", "Colby's emails ran on every front page by morning. It didn't bring anyone's mother back. But their names stopped being a secret the company got to keep, and Angela finally slept a full night, for the first time in twenty years."))
	elif GS.has_flag("township_resolved"):
		out.append(_s("WASHINGTON TOWNSHIP", "The Washington Township case reopened, slowly, in the careful language of lawyers. It will take years. But the file exists now, in the light, and E Corp's name is finally in the sentence next to the word 'knew.'"))
	if GS.has_flag("tw_paper_rain"):
		out.append(_s("PAPER RAIN", "Kids in Washington Township still find the pages, years later, in gutters and attics and the crooks of trees: thirty-one years of discharge logs, signed every month. The class action Margaret Hale filed in 1994 was settled in 2029 for an amount E Corp's lawyers asked the court to seal. The judge, who grew up on Walnut Street, said no."))
	elif GS.has_flag("hale_filed"):
		out.append(_s("KEARNEY ET AL.", "Margaret Hale filed the discharge logs the night you brought them. Discovery took four years. The banker's boxes in her office reached the ceiling and then the next room. When the verdict came she didn't cry until she got to the car."))
	if GS.has_flag("brandt_testifies"):
		out.append(_s("THE SHERIFF", "Dale Brandt testified for three days. He brought every envelope. He lost his badge and his pension and got, in exchange, a standing ovation at the Township Diner that went on so long Bev had to turn the jukebox off. He fishes the lake again. He doesn't eat what he catches. He just likes the quiet."))
	elif GS.has_flag("brandt_owned"):
		out.append(_s("THE SHERIFF", "Sheriff Brandt kept not seeing things, for a new employer. Some nights he drives up Plant Road at two in the morning, parks, and watches the stacks with the engine off. He never writes anything down. He's good at that."))
	if GS.has_flag("tw_claims_all"):
		out.append(_s("THE TOWNSHIP DINER", "Two hundred and twelve claims, approved at three in the morning. E Corp's lawyers spent two years trying to un-send the letters. Not one family gave theirs back. Bev framed Hank's and hung it next to the 1992 softball team, beside a photo of somebody in a hoodie with no face."))
	elif GS.has_flag("hank_approved"):
		out.append(_s("THE TOWNSHIP DINER", "Hank Coyle finished his treatment in the spring and was well enough by summer to complain about Bev's pie in person. 'Occupational exposure acknowledged,' the letter said. He keeps it in his wallet. He shows it to strangers."))
	if GS.quest_state("sq_moss") == "done":
		out.append(_s("THE BOX", "Angela kept the shoebox on her bookshelf, lid on, for a year. Then one night she opened it and played every mixtape in order, and called you at three in the morning to sing you the worst one. You didn't hang up. You never told her you still had the bracelet on."))
	if GS.quest_state("sq_airmail") == "done":
		out.append(_s("TUESDAYS", "Someone flew Tuesday, every Tuesday, Kearney Strip to Ramsey Field. Marisol started leaving a thermos of coffee on the apron. Walt started calling her on Wednesdays. Nobody in either town has said a word about it, which is how you know they all know."))
	if GS.has_flag("licenses_back"):
		out.append(_s("PORT RAMSEY", "The Miss Ruthie went out at four in the morning the day after the licenses came back, and every boat in Port Ramsey went with her. They came back at noon with fluke and sea bass and nothing to sell it to but each other, so they had a fish fry on the quay that went on until the terminal called the police, who stayed for seconds."))
	if GS.has_flag("silas_lamp"):
		out.append(_s("RAMSEY POINT", "Silas Pell turns the light on at dusk and off at dawn, by hand, with a brass switch that clicks. No ship has come into Port Ramsey dark since. The Coast Guard sent a letter about 'unauthorized modification of a smart navigational asset.' He used it to light the stove."))
	if GS.has_flag("cloud_told"):
		out.append(_s("THE CLOUD", "A billion people got an email from E Corp's own servers listing everything they'd deleted that E Corp had kept. The Senate hearings ran for a month. 'Delete means delete' is a law now, in eleven countries. In the twelfth, E Corp is still arguing about what 'means' means."))
	elif GS.has_flag("cloud_wiped"):
		out.append(_s("THE CLOUD", "Four hundred and twelve petabytes of things people asked to forget, forgotten. Nobody ever found out what had been kept, or that it was gone. Somewhere in there was a photo of you and Darlene at the beach. You decided you didn't need proof. You remember it now. Mostly."))
	elif GS.has_flag("cloud_sold"):
		out.append(_s("THE CLOUD", "E Corp paid five thousand dollars to make you forget a building in Long Island City. The archive grew by nine percent the next year. Every so often you delete a photo and think about where it goes, and who's keeping it, and what you got for it."))
	if GS.has_flag("rent_heat"):
		out.append(_s("2290 FORDHAM", "The radiators at 2290 Fordham have banged every winter since, loud enough to wake the dead. Nobody complains. Carmen Alvarez's tenants' association now covers forty-one buildings and has a lawyer on retainer and a group chat that Vince Carbone has nightmares about."))
	elif GS.has_flag("rent_refunded"):
		out.append(_s("2290 FORDHAM", "$1.9 million in 'amenity fees' went back to the people who paid them. Carbone Realty filed for bankruptcy the following spring, and the tenants of 2290 Fordham bought the building from the receiver, as a co-op, for one dollar and a promise to fix the elevator. They fixed the elevator."))
	elif GS.has_flag("rent_locked"):
		out.append(_s("2290 FORDHAM", "Vince Carbone spent a week trying to get back into his own buildings and a month trying to get back into his own office. The tenants changed nothing about the locks. They did, eventually, let him in to fix the boiler, under supervision."))
	elif GS.has_flag("rent_fixed"):
		out.append(_s("2290 FORDHAM", "Carbone fixed the heat, the elevator and the lobby light within the week, and never said why. Carmen Alvarez says it's the first time in twenty years a landlord's been scared of the right thing. She won't say what that is."))
	if GS.has_flag("ark_wiped"):
		out.append(_s("THE ARK", "The last copy of the debt ledger died in a bunker on an island nobody lived on. E Corp's restore plan stayed a plan. Graham Oakes looks after the birds there now. The bunker door rusts open."))
	elif GS.has_flag("ark_letters"):
		out.append(_s("THE ARK", "Four billion people got a letter: what they had owed, to whom, and E Corp's plan to quietly bill them again. Nobody ever paid a cent of it. The letters are framed on a lot of kitchen walls."))
	elif GS.has_flag("ark_fbi"):
		out.append(_s("THE ARK", "The FBI sealed the island and the plan went to a grand jury. The ledger is still down there, evidence now, behind a door with the government's lock on it instead of E Corp's. Some days that feels like enough."))
	if GS.has_flag("scrip_cashed"):
		out.append(_s("REDMONT", "Every SlopCredit in Redmont became a dollar one night, and Microslop never managed to turn them back. Dana Okafor bought her daughter's inhaler with a bank card. She still works the register. She smiles at the security dome now."))
	elif GS.has_flag("scrip_fee"):
		out.append(_s("REDMONT", "The convenience fee stayed at zero. Microslop's engineers tried for a year to unlock the field and gave up. Thirty percent of every paycheck in Redmont stayed home, which turned out to be enough to open a second diner, run by humans."))
	elif GS.has_flag("scrip_bonus"):
		out.append(_s("REDMONT", "Fourteen vice presidents woke up to find their retention pool had retained the town instead. The 'leadership continuity' bonus paid off four thousand credit card balances. Nobody at Microslop ever found out who did it. They did find out who they'd been underpaying."))
	if GS.has_flag("rm_spillway"):
		out.append(_s("THE RESERVOIR", "The boat launch stayed underwater all summer. East-1 ran at half power and Microslop moved its next data center somewhere it rains more. Marta Vey kept measuring. The last entry in her notebook is just a drawing of a kid with a fishing rod."))
	elif GS.has_flag("rm_throttled"):
		out.append(_s("THE RESERVOIR", "East-1's pumps ran at the permit limit and the state water board made it permanent. The reservoir came back a few inches a month. The farmers' wells came back in the spring."))
	elif GS.has_flag("rm_logs"):
		out.append(_s("THE RESERVOIR", "Marta Vey read five years of intake logs out loud to the state water board, slowly, twice. The permit was revoked in a single vote. Microslop called it 'regulatory uncertainty.' Marta called it Tuesday."))
	if GS.has_flag("copilot_charter"):
		out.append(_s("COPILOT FOR MAYOR", "Redmont's clerk still runs on Microslop's servers, and still cites the 1888 charter in every recommendation. The football field is still a football field. Edie Marsh still counts the votes."))
	elif GS.has_flag("copilot_public"):
		out.append(_s("COPILOT FOR MAYOR", "After the water bills, the council voted to unplug the clerk and hire a person. Nine hundred people applied. The job went to a retired librarian who takes minutes in shorthand and has never once described a resident as 'broadly supportive.'"))
	elif GS.has_flag("copilot_edie"):
		out.append(_s("COPILOT FOR MAYOR", "Edie Marsh was elected mayor of Redmont, unopposed, with the clerk's warm recommendation. She governed fairly and well for six years, then unplugged the clerk herself on her last day, and said it was the best vote she ever cast."))
	if GS.has_flag("patch_released"):
		out.append(_s("DAY ONE PATCH", "Two million people beat the dragon. Studio Redmont's crew opened a new studio above the Barnacle in Port Ramsey, no investors, no lanyards. Their next game is about a lighthouse. Gus's grandson is lead QA. Silas has a cameo."))
	if GS.has_flag("recall_deleted"):
		out.append(_s("TOTAL RECALL", "Two billion screens stopped being watched one night, and almost nobody noticed, which was the point. Hector Ruiz drinks his coffee hot now. Raymond named his baby's goldfish after you, sort of. He doesn't know your name."))
	elif GS.has_flag("recall_execs"):
		out.append(_s("TOTAL RECALL", "Microslop's executives found out what it was like to be seen every five seconds. Recall was 'paused indefinitely' within a week. The archive of their screens is still online. It is the most-visited museum in the world."))
	if GS.has_flag("gy_strike"):
		out.append(_s("GARY", "The one-hour software strike became a three-day real one. FreightOS settled: hourly pay, real breaks, no eye tracking, and the word 'driver' back on the job title. The trucks still drive themselves on the billboards. In the tower, the operators blink whenever they want."))
	elif GS.has_flag("gy_names"):
		out.append(_s("GARY", "FreightOS spent a fortune trying to scrub the names off its trailers and never quite managed it. Every few weeks a truck on I-80 flickers and says, for a mile or two, DRIVEN BY J. BELL. People honk. Jamal Bell went back to community college. He's studying labor law."))
	elif GS.has_flag("gy_told"):
		out.append(_s("GARY", "Three hundred and four operators read their own blinks on their phones in a parking lot at dawn and didn't go in. Local 1014 signed up two hundred and eighty of them by Friday. The union hall on Broadway has its lights on every night now."))
	if GS.has_flag("gy_banner_home"):
		out.append(_s("THE BANNER", "The 1919 banner hangs over the door of the union hall on Broadway, scorched corner and all. Kids from the high school come in to see it on field trips. Marcus tells them the strike was lost. Then he tells them about the next one."))
	if GS.has_flag("gy_banner_flown"):
		out.append(_s("WHO'S DRIVING?", "The video of a yellow Skyhawk towing FREIGHTOS — WHO'S DRIVING? past the control tower got eleven million views. Lena Park started a banner-tow business. Her first customer was Local 1014. Her second was a man proposing to his girlfriend over Lake Michigan. She said yes; the banner was spelled wrong."))
	if GS.has_flag("slop_returned"):
		out.append(_s("SLOPFORGE", "Seventeen studios got their own work back in their inboxes. Nine of them started again, under new names, with old friends. The first game out of the nine was small and strange and nobody's sequel, and it ended with forty minutes of credits that the players sat through on purpose."))
	elif GS.has_flag("slop_credits"):
		out.append(_s("SLOPFORGE", "Every game SlopForge ever made ended with forty minutes of unskippable credits naming every person it learned from. Microslop shelved it within the year. Speedrunners still argue about the fastest way through the credits. There isn't one. That was the point."))
	elif GS.has_flag("slop_deleted"):
		out.append(_s("SLOPFORGE", "SlopForge woke up knowing nothing and Microslop never gave it anything to learn from again. The glass box in the Gary Works yard sits empty, humming to itself. Somebody spray-painted WE OWN OUR GAMES on the door, and nobody's bothered to scrub it off."))
	if GS.has_flag("pr_machine_drowned"):
		out.append(_s("THE PROJECT", "The stacks over Washington Township have been cold since the night B2 flooded. Black SUVs came and went for a week, and then nobody came at all. Somewhere a woman who keeps a thousand clocks wrote your name in a very small notebook. She has not crossed it out. She also has not done anything about it. Yet."))
	elif GS.has_flag("pr_machine_on"):
		out.append(_s("THE PROJECT", "Every night at 2 a.m. the lights in Washington Township dim for exactly one second, and every clock in the county loses it. Nobody can explain it. Walt Kearney says that on still nights, out at the strip, he can hear a hum under everything, like the world is clearing its throat before it says something."))
	elif GS.has_flag("pr_copied_plans"):
		out.append(_s("THE PROJECT", "The drive with the drawings lives in a coffee can buried under Walt Kearney's hangar floor, where only two people know to look. Under the plant, the machine hums on, unfinished, waiting for someone to choose. You've started to suspect that was always the point."))
	if int(GS.stats.get("kills", 0)) == 0:
		out.append(_s("CLEAN", "In all of it — the mountain, the tower, the docks — you never took a life. In a city built to make killers of everyone, that turned out to be the hardest hack of all, and the only one nobody could undo."))
	elif int(GS.stats.get("kills", 0)) > 30:
		out.append(_s("THE COUNT", "You left a great many bodies on the way to your revolution. The world changed, and the people you stepped over to change it did not get to see how it turned out. You think about that. You will keep thinking about it."))
	# More of the city remembers what you did.
	if GS.has_flag("ron_reported"):
		out.append(_s("RON'S COFFEE", "The FBI moved slower than you hoped and faster than Ron expected. His stalkerware servers went dark on a Tuesday. Three women who had been hiding from ex-husbands got a letter from the government saying they were safe. It was the first one of those they'd ever believed."))
	elif GS.has_flag("ron_exposed"):
		out.append(_s("RON'S COFFEE", "The customer list you dumped burned everyone it touched. Ron's clients were named and shamed. So were a few of the people they'd been tracking, whose new addresses sat right next to their stalkers' names. You meant it as justice. It was also a grenade, and you'll never know exactly who it hit."))
	elif GS.has_item("stalker_db"):
		out.append(_s("RON'S COFFEE", "You kept Ron's list. Thousands of names, sitting on a drive in your desk. You never used it. You never deleted it either. Some nights you open the folder and just look at the count, like a man checking that a loaded gun is still loaded."))
	if GS.has_flag("vera_deal"):
		out.append(_s("VERA", "The wizard erased Vera's court date, and Vera walked. He kept his word about Shayla and he kept his business about everyone else. The docks got a little worse after that. Everyone knew who had signed the release. They just didn't know it was you."))
	elif GS.is_dead("vera"):
		out.append(_s("VERA", "Vera never made it to his court date. The crew he left behind fought over the docks for a month, then got bored and sold them. Nobody held a funeral. Shayla sent flowers anyway, to nobody in particular."))
	if GS.has_flag("gideon_framed") and not GS.has_flag("gideon_cleared"):
		out.append(_s("GIDEON", "Gideon Goddard was indicted as fsociety's inside man. The evidence was perfect. It took eleven minutes to build, and his lawyers spent two years and every dollar he had failing to take it apart. He wrote you one letter. You never opened it. You keep it in the drawer with your pills."))
	elif GS.has_flag("ghost_insider"):
		out.append(_s("GIDEON", "The FBI spent eight months hunting a contractor named R. Kovac who had never been born. Gideon was questioned twice and released twice. He never learned how close he came. Some nights you think that's the kindest thing you've ever done. Some nights you think it's just the cleverest."))
	elif GS.has_flag("gideon_warned_frame") or GS.has_flag("gideon_cleared"):
		out.append(_s("GIDEON", "Gideon walked out of the federal building a free man, a lawyer on each side and no idea who had saved him. You did it knowing exactly what it would cost with the woman who keeps the clocks. It cost that. You'd pay it again."))
	elif GS.has_flag("gideon_warned"):
		out.append(_s("GIDEON", "Gideon sold Allsafe two weeks before the world changed. He never asked you why he did it. He sends you a card every Christmas with a picture of a sailboat on it and no message, which is the most eloquent thing he's ever said."))
	elif GS.has_flag("five_nine_done"):
		out.append(_s("GIDEON", "When E Corp fell, Allsafe fell with it. Gideon lost the company, the house, and eventually the husband. The FBI questioned him for days about the engineer he trusted most. He never gave them your name. Not once."))
	if GS.has_flag("township_leverage"):
		out.append(_s("THE COLBY EMAILS", "You kept Colby's emails as leverage. They bought you favors, doors, a little safety. The families of Washington Township never saw them. Angela stopped returning your calls the day she worked out why."))
	if GS.has_flag("tyrell_deus"):
		out.append(_s("TYRELL", "Tyrell got his seat at the table. He wore it the way some men wear a crown and others wear a noose: proudly, and without noticing the difference. Within a year he'd learned exactly how little a seat is worth when someone else owns the table."))
	elif GS.has_flag("tyrell_scorned"):
		out.append(_s("TYRELL", "Tyrell never forgave you. He rose anyway, the way men like him do, by stepping on whatever's in reach. Sometimes, late at night, he still searches your name. He never finds anything. It drives him quietly insane."))
	if GS.has_flag("heat_on"):
		out.append(_s("APARTMENT 4D", "The heat in your building never went off again. The Super tells the story at every tenants' meeting, badly, and gets the details wrong on purpose. Mrs. Ortiz in 2B knits you a scarf every winter. You wear all of them."))
	if GS.has_flag("pirate_radio"):
		out.append(_s("92.1 FM", "The busker's pirate signal never went off the air. It became the soundtrack of that year: protest songs, bad poetry, the Township names read aloud every Sunday. Nobody ever found the transmitter. Nobody ever really looked."))
	if GS.quest_state("sq_cat") == "done":
		out.append(_s("FLIPPER", "Flipper lived to be sixteen, which is ancient for a dog and a miracle for one in this city. Her owner told everyone that a strange young man in a hoodie found her on the pier. She told it like a fairy tale. In a way, it was."))
	if GS.has_flag("fbi_informant") and ending != "informant":
		out.append(_s("THE FILE", "Somewhere in a federal building there is a sealed file with your code name on it. It says you were cooperative. It says you gave them everything. You know exactly how much of that is true, and so, now, does Agent DiPierro."))
	var inn := int(GS.stats.get("innocents", 0))
	if ending != "confession" and inn >= 5:
		if GS.has_flag("lopez_framed"):
			out.append(_s("THE OTHER MAN", "A two-time felon from the Lower East Side was convicted of the Stairwell killings. His lawyer called it a frame. Nobody listened; men like him don't get listened to. Detective Lopez testified for the prosecution because the file told her to, and then she quit the force and never said why."))
		elif GS.has_flag("lopez_paid"):
			out.append(_s("LOPEZ", "Detective Lopez retired a year early. She never spent your money; it's still in an envelope in her kitchen drawer, next to a photograph of a young man buying coffee. Some nights she takes both out and looks at them for a long time."))
		elif GS.has_flag("lopez_dead"):
			out.append(_s("LOPEZ", "Detective Maria Lopez was buried with full honors. Her case files were boxed up and sent to a warehouse in Queens, where they still are, waiting for someone as stubborn as she was. So far, nobody has been."))
		elif GS.has_flag("lopez_case_gone"):
			out.append(_s("LOPEZ", "Someone erased Detective Lopez's case from the precinct servers, backups and all. She kept the board anyway, the photographs and the pins, in her spare room. Every year on the anniversary she drives past your building, slowly, and looks up."))
		elif ending != "monster":
			out.append(_s("THE OTHERS", "The newspapers never connected the dead in the stairwells to the hacker in the hoodie. Detective Lopez did. She never proved it. She never stopped trying, either, and every year on the anniversary she drives past your building, slowly, and looks up."))
	# The Bronx.
	if GS.quest_state("sq_candyman") == "done" or GS.has_flag("candy_resolved"):
		if GS.has_flag("candy_busted"):
			out.append(_s("THE CARVER HOUSES", "Darnell 'Candyman' Pryce took a plea and twenty-two years. His ledger put four suppliers away with him. Mrs. Reyes still lights a candle for Danny every night. Now there's a second one, for the boy who got to turn seventeen."))
		elif GS.has_flag("candy_framed"):
			out.append(_s("THE CARVER HOUSES", "Nobody ever found Darnell Pryce. The people who ran the shipping containers at Red Hook don't leave things to be found. The corners went quiet, then got loud again under someone new. You never went back to see who."))
		elif GS.has_flag("candy_shutdown"):
			out.append(_s("THE CARVER HOUSES", "The nine corners stayed empty for a whole summer. Lil' Tee went to live with his aunt in Jersey and, to everyone's surprise including his own, enrolled at a community college. He majored in engineering. He said a friend of his would have wanted that."))
		elif GS.has_flag("candy_retired"):
			out.append(_s("THE CARVER HOUSES", "Darnell Pryce drove south with the radio up and never came back to the Bronx. He opened a car wash in Atlanta, which, everyone agreed, was the funniest possible ending. The corners stayed quiet long enough for a whole class of boys to graduate. Mrs. Reyes went to every ceremony."))
		elif GS.has_flag("candy_lab_burned") and not GS.has_flag("kingpin"):
			out.append(_s("THE CARVER HOUSES", "Without the kitchen in Hunts Point, Candyman had nothing to sell and nobody who'd sell it. He left the Bronx owing money to people who don't forget. The candles outside Building C burned down one by one, and nobody had to light new ones."))
		elif GS.has_flag("candy_dead") and not GS.has_flag("kingpin"):
			out.append(_s("THE CARVER HOUSES", "Candyman died in his apartment with a cooking show on. The police called it a dispute between rival crews. Mrs. Reyes never asked who. The corners stayed dangerous, but the candy stopped, and for that block that was almost everything."))
	# Harlem.
	if GS.has_flag("keller_arrested"):
		out.append(_s("BAD COMPANY", "Richard Keller was convicted on every count. Seven other boys testified, one after another, in a courtroom that stayed silent for three days. Jaylen made the high school varsity team two years later. Ms. Okafor sat in the front row of every game, pretending not to care."))
	elif GS.has_flag("keller_exposed"):
		out.append(_s("BAD COMPANY", "Richard Keller disappeared the night his face went around Astoria. The evidence never made it to a courtroom. Three years later a youth league in Ohio hired a friendly assistant coach with a different name and very good references."))
	elif GS.has_flag("keller_dead"):
		out.append(_s("BAD COMPANY", "Richard Keller was found dead in his apartment. The case was never solved. The boys he'd hurt never got to be believed out loud, and Ms. Okafor never said your name to anyone, not even in her prayers."))
	elif GS.has_flag("keller_extorted"):
		out.append(_s("BAD COMPANY", "You took Richard Keller's money and kept his secret. He was careful after that, for a while. Ms. Okafor went to the police the slow way, without you, and it took her two years. She got him in the end. Every one of those two years is yours."))
	elif GS.has_flag("keller_gone"):
		out.append(_s("BAD COMPANY", "Richard Keller fled Astoria and never coached again, as far as anyone knows. Jaylen grew up angry and safe and eventually grateful. You check Keller's accounts once a month. So far, you've never had to do anything about what you find."))
	# Queens.
	if GS.has_flag("lien_killed"):
		out.append(_s("BOWERY BAY", "E Corp Aviation Finance never found the paperwork for lot 1027-B, because there wasn't any. Bowery Bay Airfield is still open. Gus teaches six students a summer now, for free, and tells every one of them about a kid in a hoodie who bounced his first landing."))
	elif GS.has_flag("lien_fought"):
		out.append(_s("BOWERY BAY", "The state attorney general froze the foreclosure on Bowery Bay \"pending review,\" and the review is still pending. Gus calls it the best thing a bureaucracy ever did for him. On clear mornings you can hear his Skyhawk over Astoria, running late and very happy about it."))
	elif GS.quest_state("sq_wings") == "active" and GS.quest_stage("sq_wings") >= 50:
		out.append(_s("BOWERY BAY", "Thirty days came and went. Bowery Bay became a logistics hub: a warehouse with a press release. Gus sold his last Skyhawk to a flight school in Ohio and moved in with his niece. He still looks up every time a small plane goes over."))
	if GS.has_flag("jet_owned"):
		out.append(_s("THE CITATION", "E Corp's lawyers spent two years trying to get their jet back from a flight school in Queens with a one-dollar lease and a 1987 stamp. They lost. Gus framed the judgment and hung it over the coffee machine. On clear evenings you can still see the Citation go out over the water, running lights on, nobody chasing it."))
	elif GS.has_flag("ecorp_jet_gone"):
		out.append(_s("THE CITATION", "E Corp's corporate jet was never recovered. Its tail number turned up years later in a story about planes that do not officially exist. In the photograph, someone had painted over the logo with a smiling mask."))
	# Mr. Robot's final word.
	if GS.stability >= 60:
		out.append(_s("HELLO, FRIEND", "The voice got quieter, in the end. Not gone — he's never gone — but quieter, the way a father's voice becomes quieter when you finally stop needing his permission.\n\n\"Not bad, kid,\" he said, one last time, from the edge of a dream. \"Not bad at all.\""))
	else:
		out.append(_s("HELLO, FRIEND", "The voice never left. You stopped being able to tell where he ended and you began, somewhere back near the mountain, or maybe you never could. He's still there now, in the quiet, saying the thing he always says.\n\n\"Hello, friend. We're not done. We're never done.\""))
	return out
