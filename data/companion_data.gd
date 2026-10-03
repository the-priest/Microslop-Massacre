class_name CompanionData
extends RefCounted
## Companions: who they are on the road. Their conversations live in
## data/dialogue/companions.dlg (comp_<id>); this is what they do between them.
##
## bonus      skill bonuses while they're with you
## perk       the permanent bonus their last heart-to-heart unlocks (flag cperk_<id>)
## leave_when a condition: when it holds they walk out on you (once, for good)
## react      flag -> a one-time line when that flag is set while they're with you
## cells      cell id (or prefix ending in *) -> a line the first time you enter it together
## regions    map id -> a line the first time you're out on that map together
## barks      idle / combat / kill_innocent / steal_car / fly / low_hp / night

const C := {
	"darlene_n": {
		"name": "Darlene", "bonus": {"hacking": 10}, "perk": {"hacking": 5}, "perk_name": "Family Business",
		"bonus_desc": "+10 HACKING while she's with you. She types over your shoulder and tells you you're doing it wrong.",
		"leave_when": "flag.sold_out_fsociety | flag.fbi_informant | flag.fsociety_raided | innocents>=4 | flag.kingpin_dirty",
		"leave_line": "No. No, I'm not doing this. Whatever you're turning into, you're doing it without me. I've buried enough family.",
		"react": {
			"tw_paper_rain": "You made it snow paper on the township. On the FESTIVAL. Mom would've been out in the street catching them.",
			"pr_machine_drowned": "You drowned Whiterose's thing. In the pond. I don't know if I want to hug you or move to another country.",
			"gy_strike": "Two hundred trucks on the shoulder with their hazards on. That's the most beautiful thing I've ever seen on a highway.",
			"rent_heat": "Seventy degrees in forty-one buildings. Default admin password, I bet. It's always the default admin password.",
			"rootkit_planted": "Ron's server is ours. God, that's beautiful. Do you know how long I've wanted a door into that honeypot?",
			"lien_killed": "You deleted an old man's airport debt. For free. Okay, that one's going on my fridge.",
			"heat_on": "You fixed the heat for a whole building with a default password. This is why I keep you around.",
			"ecorp_jet_gone": "We stole E Corp's jet. We STOLE E CORP'S JET. I'm putting this on my tombstone.",
			"candy_busted": "Cuffs on the Candyman. Clean. I hate cops, but I hate that guy more.",
			"tyrell_ally": "You're making friends with Tyrell Wellick. Wash your hands after. Twice.",
		},
		"regions": {
			"highway": "Pennsylvania. Cows. Billboards with opinions. I feel like we're in the opening credits of something bad.",
			"chicago": "Chicago. Respawn's got a cell here. Don't tell Ansel I said 'cell,' she hates it. She says 'chapter.'",
			"township": "...This is it, isn't it. The township. Dad used to drive us past the plant on the way to the lake and tell us not to look. I always looked.",
			"port": "A lighthouse. An actual lighthouse. If you push me into the ocean I'm haunting you specifically.",
			"gary": "Look at those furnaces. Somebody built all of that, and somebody else paused it like a video. That's the whole country right there.",
		},
		"cells": {
			"arcade": "Home sweet broken home. Mind the wiring, it bites.",
			"ecorp_lobby": "Smell that? That's what seventy percent of the world's debt smells like. Carpet cleaner and fear.",
			"elliot_apt": "You still don't have a single chair. You have four monitors and zero chairs. That's a cry for help, Elliot.",
			"allsafe": "Allsafe. Your day job. You protect E Corp from people like us. Do you ever think about how funny that is? I do. Constantly.",
			"steel_mountain": "Analog backups in a mountain. The most expensive filing cabinet on Earth. Let's set it on fire.",
			"rose_garden": "Dark Army. Don't drink the tea. I'm serious, don't drink the tea.",
			"airfield_office": "An airport. You know I've never been on a plane? Not once. Tell nobody.",
			"subway*": "Every time we come down here I think about how many people are under the city right now, just waiting to be somewhere else.",
		},
		"barks": {
			"idle": ["You walk like you're late to something. You're never late to anything. You're just running.", "Mobley says hi. Mobley didn't say hi. I'm saying hi for him. He'd want me to. Probably.", "When this is over I'm sleeping for a week. Then I'm starting something worse.", "You ever notice how every billboard in this city is an apology for something?", "Remember the beach? No, you don't. That's fine. I remember it for both of us.", "If you're talking to him right now, tell him I said he can go to hell. Politely."],
			"combat": ["Okay! Okay okay okay. Shooting now!", "I code! I don't do this!", "Behind you! No, your other behind!"],
			"kill_innocent": ["What the hell was that? They didn't do anything!", "Elliot. Elliot, look at me. That wasn't him. That was you."],
			"steal_car": ["Grand theft auto. Very fsociety. Very subtle.", "I call the radio. You don't get a vote."],
			"fly": ["Oh my God. Oh my God, we're flying. Don't talk to me. Don't talk to me, I'm being brave.", "Okay this is sick. This is so sick. Do NOT do a loop."],
			"low_hp": ["You're bleeding. Why are you always bleeding?", "Stay up. Stay UP, Elliot."],
			"night": ["Night. Finally. The city's honest after midnight."],
		},
	},
	"leon": {
		"name": "Leon", "bonus": {"guns": 10}, "perk": {"guns": 5}, "perk_name": "The Number Four",
		"bonus_desc": "+10 GUNS while he's with you, and when you're badly hurt in a fight he hands you a sandwich. It helps more than it should.",
		"leave_when": "hostile.darkarmy",
		"leave_line": "Ah, man. You went and made it personal with the people who sign my checks. I liked you, my man. I still like you. That's gonna make the next part real awkward. Walk fast.",
		"react": {
			"pr_machine_on": "You finished it for her. Okay. Okay. I'm not gonna judge. I'm gonna watch every clock I own real close, but I'm not gonna judge.",
			"licenses_back": "Fishermen back on the water. That's a good day, my man. Nobody gets enough good days.",
			"slop_returned": "You gave the game people their games back. That's like returning a stolen bike, but the bike is somebody's whole life.",
			"five_nine_done": "You did it, man. The whole thing. Lights out on the debt. Feels like the last episode of a show, when they turn on the lights in the studio and you see it was all plywood.",
			"ecorp_jet_gone": "You stole a jet. A corporate jet. My man, that is a season finale.",
			"kingpin": "Corners, huh? Lot of overhead in corners. Lot of funerals. Just saying, as a friend who eats a lot of sandwiches next to a lot of funerals.",
			"candy_dead": "Candyman, gone. I won't miss the jacket.",
		},
		"regions": {
			"highway": "Open road, man. You know what this needs? A soundtrack. Something with a lot of saxophone and regret.",
			"chicago": "Chicago, man. Deep dish is a casserole, and I'll die on that hill. I'll die on it with a fork in my hand.",
			"township": "Small towns, man. Everybody knows everybody. Everybody knows everybody's business. Everybody's business is the plant.",
			"port": "I spent a summer on a boat once. Long story. Ends with me knowing how to gut a fish and never wanting to.",
			"gary": "Steel town. My uncle worked a mill like this in Bangkok. Different mill. Same tired faces at the end of a shift.",
		},
		"cells": {
			"arcade": "This place smells like ozone and ambition. And nachos. Somebody's got nachos.",
			"rose_garden": "I'm gonna wait by the door. Not 'cause I'm scared. 'Cause it's polite.",
			"ecorp_lobby": "Big lobby. You know what big lobbies are for? So you feel small before you meet the man upstairs.",
			"steel_mountain": "A mountain full of tapes. Hoo. Somebody's dad really loved backups.",
			"precinct": "Cops. Smile. Not too much. Too much is suspicious. Yeah, like that. No. Less.",
			"airfield_office": "Small planes. You know the thing about small planes? Nobody ever asks where they went.",
		},
		"barks": {
			"idle": ["You ever watch 'Knots Landing'? Gary and Abby, man. That's love. That's war. That's Tuesday.", "Here's my philosophy, short version: everybody's the main character, and everybody's wrong about the plot.", "You walk, I walk. You run, I run faster, 'cause I got longer legs and a shorter list of regrets.", "This city's a sitcom with a really dark writers' room.", "My grandmother said: never trust a man who doesn't eat lunch. You don't eat lunch, my man. Think about it.", "I'm watching your back. Also your front. Also the guy on the corner. Mostly the guy on the corner."],
			"combat": ["Get down. Let Leon cook.", "Ooh, wrong guy, wrong day, wrong sandwich.", "Stay behind the big man."],
			"kill_innocent": ["Hey. That guy had a mother, man. I'm not your conscience. But somebody oughta be.", "That wasn't a bad guy. You know that, right? I need you to know that."],
			"steal_car": ["Nice ride. Who's it belong to? Never mind. Don't tell me. Plausible deniability, my man.", "Put on something with a saxophone."],
			"fly": ["Ho-ho! Look at that! Little tiny city. Little tiny problems.", "You know how to land this, right? Right? Say right."],
			"low_hp": ["You're looking pale. Paler. Eat this.", "Breathe, man. In through the nose."],
			"night": ["Night shift. My favorite. Everybody tells the truth after two a.m."],
		},
	},
	"trenton_n": {
		"name": "Trenton", "bonus": {"sneak": 10, "speech": 5}, "perk": {"speech": 5}, "perk_name": "Keep the Number",
		"bonus_desc": "+10 SNEAK and +5 SPEECH while she's with you. She notices the cameras before you do, and the lies before they land.",
		"leave_when": "flag.fbi_informant | flag.sold_out_fsociety | flag.fsociety_raided | innocents>=2 | flag.kingpin",
		"leave_line": "I said I'd keep the number. I didn't say I'd watch you add to it. I'm going home, Elliot. Don't follow me.",
		"react": {
			"gy_told": "You gave them their own data. That's the most fsociety thing anyone's done in months, and nobody even had to wear a mask.",
			"tw_claims_all": "Two hundred and twelve claims approved at three in the morning. My mother would have cried. I'm not crying. It's the dust.",
			"rent_refunded": "One point nine million dollars in junk fees, back where it came from. That's a beautiful number when it's going the right direction.",
			"five_nine_done": "It's done. Somewhere, someone just checked their balance and cried. I hope it's the good kind of crying. I really hope.",
			"lien_killed": "One debt. One real person. That's the version of this I signed up for.",
			"township_public": "The Township emails, public. My mother would've lit a candle for every name. I'm going to.",
			"keller_arrested": "Seven boys testified. Seven. That's the kind of courage we don't have a word for in English.",
		},
		"regions": {
			"highway": "My father drove trucks before he drove a cab. He said I-80 at night is the loneliest road in America. He said it like it was a compliment.",
			"chicago": "E Corp Midwest. Their security posture is famously worse than New York's. I've read their incident reports. They're very long.",
			"township": "The memorial has twenty-six names. I looked up the settlement. Eleven thousand dollars each. I'm not going to say anything else, because I'll start yelling.",
			"port": "Container ships carry ninety percent of everything. Nobody inspects most of it. That's not a fact, that's an invitation.",
			"gary": "FreightOS remote operators are classified as 'mobility supervisors' so they don't count as drivers. Somebody got a bonus for that sentence.",
		},
		"cells": {
			"arcade": "Home. Watch the third step, it's soft. Mobley says it's 'character'.",
			"fbi_office": "Cameras in every corner. Walk like you're bored. Bored people are invisible.",
			"ecorp_floor": "Four hundred cubicles and every one of them has a family photo. Remember that when we press the button.",
			"st_nicholas": "This is a good place. Let's not bring anything bad into it.",
			"airfield_office": "I've only ever been on one plane. Coming here, when I was nine. I don't remember the sky. Only the waiting.",
		},
		"barks": {
			"idle": ["I keep a list. Names of people the hack might hurt. Not to stop us. Just so somebody remembers.", "My brother would like you. He likes people who don't talk much. He says it's restful.", "Every system has a person at the end of it. Every one. That's the part people forget.", "Do you ever think about what we do the morning after? Not the hack. The morning after.", "Walk slower. You look like you're casing the street. You are, but you shouldn't look like it."],
			"combat": ["Down! Get down!", "I don't want to do this. I'm doing it."],
			"kill_innocent": ["No. No, no, no. They weren't part of this.", "That's a name now. I'm writing it down."],
			"steal_car": ["We're returning this. Eventually. Somehow.", "Seatbelt. I mean it."],
			"fly": ["It's so quiet up here. You can't hear any of it. Is that what it's like for them? The people at the top?", "I'm fine. I'm fine. I'm holding the door handle for emotional reasons."],
			"low_hp": ["You need a hospital. Or at least a bandage and a better plan.", "Sit. Sit down for a second. Please."],
			"night": ["It's late. My mother used to say nothing good happens after midnight. She also said nothing good happens before it."],
		},
	},
	"shayla_n": {
		"name": "Shayla", "bonus": {"medicine": 10, "barter": 5}, "perk": {"medicine": 5}, "perk_name": "Neighbor",
		"bonus_desc": "+10 MEDICINE and +5 BARTER while she's with you, and once a day she quietly slips you something from her bag.",
		"leave_when": "innocents>=3 | flag.kingpin_dirty",
		"leave_line": "I sell people a way to feel nothing. I know what it looks like when somebody wants it too much. You're scaring me, Elliot. I'm going home. Lock your door.",
		"react": {
			"moss_box_given": "You took Angela her box? From her old house? Elliot. That's the sweetest thing I've ever heard and I've heard Qwerty eat.",
			"silas_lamp": "You fixed an old man's lighthouse. I'm going to tell everyone that. I'm going to tell people who didn't ask.",
			"vera_dead": "He's dead. Vera's dead. I thought I'd feel lighter. I just feel tired.",
			"heat_on": "The heat's on in the building! Mrs. Ortiz is going to knit you something hideous. Brace.",
			"candy_busted": "Candy cut with fentanyl. Those kids. God. Good. Good, he's done.",
			"lien_killed": "You're secretly the nicest person I know and you hide it under the hoodie like it's contraband.",
		},
		"regions": {
			"highway": "Road trip! I brought snacks. They're mostly pills. Kidding. Mostly kidding. They're gummies.",
			"chicago": "I had a boyfriend from Chicago once. He was the worst. The city's nice though. The city's not his fault.",
			"township": "It's so quiet. I don't trust it. Places this quiet are always holding their breath about something.",
			"port": "Fish market! Bars with names like the Barnacle! Old men in raincoats! I love it here. I'm moving here. I'm not moving here.",
			"gary": "This place looks like it got dumped and is pretending it's fine. I know that look. Hi, Gary. Same.",
		},
		"cells": {
			"elliot_apt": "Your place is so clean it's creepy. Like nobody lives here. Like you're a ghost who pays rent.",
			"vera_stash": "I don't want to be here. I really, really don't want to be here.",
			"pharmacy": "I used to work in one of these. Long story. Boring story. Okay, medium story.",
			"rabbit_hole": "The Rabbit Hole. I've done some of my best bad decisions here.",
			"airfield_office": "A plane. We could just go. Pick a direction. Florida. Ohio. Anywhere with a beach and no Vera.",
		},
		"barks": {
			"idle": ["I'm proud of you, by the way. For whatever it is you're doing. I can tell it's big. You've got your big-thing face.", "Qwerty misses you. That's your fish. You have a fish. You forget sometimes.", "You know what I want? A normal Tuesday. Laundry. A bad movie. A boring boyfriend. Just one.", "If anyone asks, I'm your cousin. Second cousin. Distant. Very distant.", "I've got painkillers, sleeping pills, and gum. The gum is the strongest thing in this bag.", "You talk to yourself at night. Through the wall. I don't mind. It's company."],
			"combat": ["Oh, I hate this! I hate this so much!", "I'm not a fighter, I'm a pharmacist with a past!"],
			"kill_innocent": ["Why would you— they were just standing there!", "That's not you. Tell me that's not you."],
			"steal_car": ["You stole a car. I'm in a stolen car. Okay. Okay, this is my life now.", "Can I pick the music? I'm picking the music."],
			"fly": ["We're in the SKY. Elliot. We're in the sky in a tiny box.", "Look, you can see our building! Okay you can't. But it's down there. Somewhere. Being ugly."],
			"low_hp": ["Hold still. I know where to press. Trust me.", "You're bleeding on my shoes. I'm not mad. I'm a little mad."],
			"night": ["This is my shift. Night people are my people."],
		},
	},
}


static func has(id: String) -> bool:
	return C.has(id)


static func get_def(id: String) -> Dictionary:
	return C.get(id, {})
