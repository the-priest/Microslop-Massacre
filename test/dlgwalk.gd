extends Node
## Pure-logic dialogue fuzzer: walks every convo, executes every effect and
## evaluates every condition against real GameState, in every branch, across
## several game states. No UI, no 3D — pure runtime execution of content.
var problems: Array = []
var rng := RandomNumberGenerator.new()
var stub

func _ready():
	rng.seed = 7
	DB.load_all(); DialogueManager.load_all()
	stub = WorldStub.new()
	DialogueManager.game = stub
	for pass_i in 4:
		_state(pass_i)
		var convos := DialogueManager.convos.keys(); convos.sort()
		for cid in convos:
			for run in 4:
				_walk(str(cid), pass_i)
	print("=== DLGWALK problems=%d ===" % problems.size())
	var seen := {}
	for p in problems:
		if not seen.has(p): seen[p]=0
		seen[p]+=1
	for k in seen: print("PROBLEM (x%d) %s" % [seen[k], k])
	print("DLGWALK DONE unique=%d total=%d" % [seen.size(), problems.size()])
	get_tree().quit()

func _state(p):
	GameState.new_game(); GameState.set_tags(["hacking","sneak","speech"])
	if p==1:
		for f in ["knows_ron_secret","found_ron_code","joined_fsociety","rootkit_planted","met_tyrell_invite","ecorp_door_tyrell","ecorp_foothold","fbi_contact","knows_darlene_sister","darlene_bond","krista_truth","shayla_out","has_lenny_phone","five_nine_done","lenny_gone","township_resolved","vera_deal","tyrell_ally","knows_whiterose_game","fbi_open","overlap_unlocked"]:
			GameState.set_flag(f)
		for it in ["stalker_db","colby_archive","raspberry_pi","deus_invite","lenny_phone","cd_mixtape","rose_package","flipper_leash","pistol_9mm","bobby_pin"]: GameState.give(it)
		for q in ["mq_rootkit","mq_fsociety","mq_steel","mq_darkarmy","mq_ecorp","mq_fbi","mq_finale","sq_ron","sq_shayla","sq_krista","sq_colby","sq_cat","sq_courier","sq_busker","sq_super"]: GameState.set_quest_stage(q, 30)
		for s in DB.SKILLS: GameState.raise_skill(s, 70)
		GameState.add_fame("darkarmy",30); GameState.add_fame("fbi",30); GameState.add_cash(500)
		GameState.trust["darlene"]=8; GameState.trust["robot"]=-5; GameState.trust["tyrell"]=5
	elif p==2:
		GameState.stability=8
		for s in DB.SKILLS: GameState.base_skills[s]=3
	elif p==3:
		# everything maxed + all quests done
		for s in DB.SKILLS: GameState.raise_skill(s, 90)
		for q in DB.QUESTS: GameState.set_quest_stage(q, 30)
		GameState.set_flag("joined_fsociety"); GameState.set_flag("five_nine_done"); GameState.set_flag("darlene_bond"); GameState.set_flag("krista_truth"); GameState.set_flag("knows_darlene_sister"); GameState.stability=80

func _walk(cid, passid):
	var c = DialogueManager.convos.get(cid); if c==null: return
	var nid = str(c["entry"]); var guard=0
	while nid != "" and guard < 300:
		guard+=1
		var node = DialogueManager.node(cid, nid)
		if node.is_empty(): problems.append("missing node %s.%s"%[cid,nid]); return
		var nxt := ""
		for st in node["stmts"]:
			var k = str(st["k"])
			if k=="if":
				if _safe_eval(st["cond"], cid): nxt = _resolve(cid, str(st["to"])); 
			elif k=="do": _run_fx(st["fx"], cid)
			elif k=="goto": nxt = _resolve(cid, str(st["to"]))
			if nxt != "END_SENTINEL" and nxt != "": break
		if nxt=="": 
			var chs = DialogueManager.visible_choices(node)
			# also stress: force-evaluate EVERY choice cond+label
			for ch in node["choices"]:
				_safe_eval(ch["cond"], cid)
				DialogueManager.choice_label(ch)
			if chs.is_empty(): nxt="END_SENTINEL"
			else:
				var pick = chs[rng.randi()%chs.size()]
				DialogueManager.mark_seen(pick)
				if pick["check"]!=null:
					var ck=pick["check"]; GameState.last_won = GameState.skill(str(ck["skill"]))>=int(ck["dc"])
				_run_fx(pick["fx"], cid)
				var ok = pick["check"]==null or GameState.last_won
				nxt = _resolve(cid, str(pick["to"]) if ok else str(pick["fail"]))
		if nxt=="END_SENTINEL": return
		# nxt is "cid|nid"
		var parts = nxt.split("|")
		if parts[0] != cid: return  # jumped to another convo; stop (it gets walked on its own)
		nid = parts[1]

func _resolve(cid, tgt) -> String:
	if tgt=="" or tgt=="END": return "END_SENTINEL"
	var r = DialogueManager.resolve_target(cid, tgt)
	if str(r[0])=="": return "END_SENTINEL"
	return "%s|%s" % [r[0], r[1]]

func _safe_eval(cond, where) -> bool:
	return DialogueManager.eval_cond(cond)

func _run_fx(fx, where):
	for e in fx:
		var cmd=str(e["cmd"])
		if cmd in DialogueManager.WORLD_EFFECTS:
			# route to stub synchronously (no await)
			stub.dlg_world_effect_sync(cmd, e["args"])
		else:
			# state effect: call apply_effect but it may await for world; state ones don't
			DialogueManager.apply_effect(cmd, e["args"])

class WorldStub:
	extends Node
	func dlg_world_effect_sync(cmd, args): pass
	func dlg_world_effect(cmd, args): pass
	func discover_location(l): GameState.discover(l)
	func push_ui(): pass
	func pop_ui(): pass
	func after_dialogue(): pass
