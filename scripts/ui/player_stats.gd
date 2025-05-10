extends Control
class_name PlayerStatsPanel

var player: MultiplayerPlayer
var has_player: bool = false

func init(player: MultiplayerPlayer) -> PlayerStatsPanel:
	self.player = player
	return self

func _process(delta: float) -> void:
	if not player and has_player:
		queue_free()
	if not player:
		return
	
	has_player = true
	%PlayerName.text = player.name
	%Kills.text = str(player.kill_count)
	%Deaths.text = str(player.death_count)
	var kdr = (player.kill_count/player.death_count) if player.death_count > 0 else player.kill_count
	%KDR.text = str(kdr)
