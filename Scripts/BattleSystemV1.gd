extends Node
class_name BattleSystemV1
#Battle System v1:
#Flip a coin. Only here as a placeholder and to work out the rough interface for doing this

var thisBattle
var results = {
	battle = thisBattle,
	winner = 0 # 1 or 2 when done.
}

func AutoBattle(battle):
	thisBattle = battle
	results.battle = thisBattle
	var battleComplete = false
	while battleComplete == false:
		RunTurn()
		battleComplete = CheckForWin()
	return results

func CheckForWin():
	var team1win = true
	var team2win = true
	for p in thisBattle.team1:
		if p.hp > 0:
			team2win = false
			break
	for p in thisBattle.team2:
		if p.hp > 0:
			team1win = false
			break
	
	if (team1win or team2win):
		if team1win:
			results.winner = 1
		if team2win:
			results.winner = 2
		return true
	
	return false

func RunTurn():
	#This is much more important in future cases. Here we just want it to exist.
	#results = thisBattle.duplicate(true)
	#flip a coin. Heads, fighter 1/left wins. Tails, fighter 2/right wins.
	for i in 6:
		var winner = randi() % 2
		if winner == 0:
			thisBattle.team1[i].hp = 0
		else:
			thisBattle.team2[i].hp = 0
			
