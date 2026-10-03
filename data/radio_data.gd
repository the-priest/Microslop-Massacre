class_name RadioData
extends RefCounted
## E NEWS 24: the talk station in the phone's radio. Every half minute or so
## it reads one item: a headline about something you did (when its condition
## holds), local traffic and weather for whichever map you're on, or an ad.
## "region" limits an item to one map; "when" is a dialogue condition.

const HEADLINES := [
	# Ads and filler, any time.
	{"text": "E Coin. The future of money is ours. Terms and conditions are also ours."},
	{"text": "This hour of E News 24 is brought to you by E Corp Health: your prescriptions, now by subscription."},
	{"text": "Live service, never finished, never yours. Microslop Game Pass Away. Coming Friday."},
	{"text": "FreightOS. The road drives itself. Please do not ask who is driving."},
	{"text": "RentTrack: pay rent, request repairs and unlock premium amenities like heat, all in one app."},
	{"text": "EZeats: dinner in thirty minutes or your second dinner is also thirty minutes."},
	{"text": "A reminder from E Corp Consumer Credit: your debt is not a burden. It's a relationship."},
	# Local traffic and weather.
	{"region": "nyc", "text": "Traffic on the FDR is a parking lot, the Queensboro is a suggestion, and the Bronx is the Bronx. It's a beautiful day to stay home."},
	{"region": "nyc", "text": "Weather for the five boroughs: humid, then more humid, with a chance of the subway breaking down."},
	{"region": "highway", "text": "I-80 traffic: clear between the Big Rig Diner and Lennox, a stalled truck reported on the west shoulder, and deer. Always deer."},
	{"region": "highway", "text": "Exits 41 and 42 open for the township and Port Ramsey. The county roads are dark at night, so are the deer."},
	{"region": "chicago", "text": "Lake Shore Drive is moving. The Dan Ryan is not. Winds off the lake at fifteen gusting twenty-five; hold on to your hat and your hot dog."},
	{"region": "township", "text": "WTWP community bulletin: the fall festival is Saturday on Main Street, sponsored by E Corp. Free hot dogs. Bring your own water."},
	{"region": "township", "text": "Township traffic: State Road 912 north to Gary is clear. Somebody's crop duster is buzzing Main Street again."},
	{"region": "port", "text": "Port Ramsey marine forecast: ten knots off the water, seas two feet, and the light at Ramsey Point is working, which is news."},
	{"region": "gary", "text": "Gary traffic: I-90 east to Chicago is clear, the FreightOS depot exit is jammed with trucks that have nobody in them, and the lake is choppy."},
	# The story, as the news tells it.
	{"when": "flag.five_nine_done", "text": "Day three after the Five/Nine hack: ATMs are dark, the markets are closed, and E Corp's Phillip Price says a new currency will 'restore confidence.'"},
	{"when": "flag.rs_done", "text": "Rockstarved Games shares fell another eleven percent today after a leaked internal deck called its players, quote, 'a funnel.'"},
	{"when": "flag.rs_refund", "text": "Rockstarved confirms a year of Shark Card purchases has been refunded 'due to a payment processing event.' Parents across the country are confused and delighted."},
	{"when": "flag.earse_exposed", "text": "Electronic Arse loot boxes now display their odds. One in nine thousand two hundred and fourteen. Analysts call it 'a catastrophic outbreak of honesty.'"},
	{"when": "flag.phony_freed", "text": "Every game Phony Interactive ever revoked is back in its owners' libraries this morning. Phony's own admins are still locked out. A spokesperson could not log in to comment."},
	{"when": "flag.ms_done", "text": "Microslop's Game Pass Away showcase on Floor 101 of the North Tower ended early last night after what the company calls 'an unscheduled demonstration.'"},
	{"when": "flag.lou_saved | flag.ezeats_bombed", "text": "EZeats is under fire after a leaked brief told a review farm to accuse a Chicago hot dog stand of being 'rude to a child.' The stand, Lou's Red Hots, has a line around the block."},
	{"when": "flag.rig_freed | flag.rig_fuse", "text": "FreightOS says a truck on I-80 has been 'modified without authorization.' The driver says it's her truck. Truckers on the CB say a lot of things we can't repeat on air."},
	{"when": "flag.kowal_flipped", "text": "The FBI's Chicago field office has opened a consumer-fraud inquiry into E Corp Midwest, in what one agent called 'a surprising turn for a case where E Corp was the victim.'"},
	{"when": "flag.tw_paper_rain", "text": "Thousands of pages of what appear to be discharge logs from the Washington Township energy plant fell from a crop duster over the town's fall festival Saturday. E Corp says the documents are 'out of context.' Residents say the context is a graveyard."},
	{"when": "flag.hale_filed & !flag.tw_paper_rain", "text": "A Washington Township attorney has filed thirty-one years of discharge logs from the town's 'remediated' E Corp plant. E Corp has asked for a ninety-day extension. The judge said no."},
	{"when": "flag.tw_claims_all", "text": "Two hundred and twelve former Washington Township plant workers received approval letters for denied medical claims at three in the morning. E Corp is 'reviewing the incident.'"},
	{"when": "flag.brandt_testifies", "text": "Washington Township's sheriff has agreed to testify about ten years of payments from the town's power plant. He is the first E Corp employee, or whatever he was, to do so."},
	{"when": "flag.licenses_back", "text": "Port Ramsey's fishing fleet is back on the water after forty-four commercial licenses were reinstated overnight. The harbormaster could not be reached. He is believed to be on a cruise."},
	{"when": "flag.silas_lamp", "text": "The Ramsey Point lighthouse is back under manual control after its keeper, eighty-one, 'had a word' with the smart beacon. The Coast Guard has sent a letter. He used it to light the stove."},
	{"when": "flag.pr_machine_drowned", "text": "Firefighters were called to the shuttered Washington Township power plant before dawn after flooding in a sublevel that, according to every available drawing, does not exist."},
	{"when": "flag.pr_machine_on", "text": "Utilities across New Jersey report a one-second power dip at exactly two in the morning, every night this week. Residents report clocks running slow. Scientists report nothing, loudly."},
	{"when": "flag.gy_strike", "text": "Every FreightOS truck in four states pulled onto the shoulder at six this morning with the words 'ONE HOUR: SOLIDARITY' on its screens. The company's 'driverless' fleet, it turns out, had drivers."},
	{"when": "flag.gy_names", "text": "FreightOS trailers on I-80 are displaying the names and hourly wages of the remote operators driving them. FreightOS calls it 'a labor transparency incident.' The internet calls it the best thing on the highway."},
	{"when": "flag.gy_told", "text": "Three hundred FreightOS remote operators in Gary, Indiana didn't go in to work today after receiving their own eye-tracking data. Local 1014 says membership has never been higher."},
	{"when": "flag.gy_banner_flown", "text": "A light aircraft towing a banner reading 'FREIGHTOS: WHO'S DRIVING?' circled the company's Gary depot this week. The video has eleven million views. FreightOS says its trucks are 'driven by innovation.'"},
	{"when": "flag.slop_returned", "text": "Seventeen game studios closed by Microslop have received their own work back from an anonymous sender. Several say they're starting again. Microslop calls it 'a data incident.'"},
	{"when": "flag.slop_deleted | flag.slop_credits", "text": "Microslop's SlopForge AI, housed in a former steel mill in Gary, has suffered what the company calls 'a training setback.' Developers are calling it something else."},
	{"when": "flag.rent_done", "text": "Tenants in forty-one Bronx buildings managed by Carbone Realty say their heat is back on. Carbone Realty says its app is 'experiencing unexpected generosity.'"},
	{"when": "flag.race_won_lakeshore | flag.race_won_quay | flag.race_won_broadway", "text": "Police in three cities report a rise in late-night street racing complaints. Witnesses describe the same quiet driver in a borrowed sedan."},
	{"when": "flag.taxi_fares>=5", "text": "Cab dispatchers report a new driver who never talks, never takes the highway, and always gets there on time. Passengers describe him as 'unsettling, five stars.'"},
	{"when": "item.hidden_mask>=10", "text": "Plastic fsociety masks have been found zip-tied to street corners in New York, Chicago and several smaller towns. Police are calling it vandalism. Collectors are calling it a game."},
	{"when": "flag.township_public", "text": "Terry Colby's 1993 emails on the Washington Township leak continue to dominate headlines. 'Proceed with the cleanup. Do not disclose.' Mr. Colby's lawyers say he does not recall writing them."},
]
