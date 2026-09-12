extends Node

## Network Manager for 2-Player Co-op (Solo / Duo).
## Built on Godot's high-level MultiplayerAPI and prepared for Steam Datagram Relay (SDR).

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

const MAX_PLAYERS: int = 2
const DEFAULT_PORT: int = 7777

var is_coop_active: bool = false
var is_host: bool = false

func start_singleplayer() -> void:
	is_coop_active = false
	is_host = true
	multiplayer.multiplayer_peer = null

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		is_coop_active = true
		is_host = true
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return error

func join_game(ip_address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip_address, port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		is_coop_active = true
		is_host = false
	return error

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

## RPC: Request by Client to pick up an egg from the boutique floor
@rpc("any_peer", "call_reliable")
func request_pick_egg(egg_path: NodePath) -> void:
	if not is_host:
		return
	var egg_node: Node = get_node_or_null(egg_path)
	if egg_node and egg_node.has_method("despawn_for_collection"):
		var sender_id: int = multiplayer.get_remote_sender_id()
		egg_node.despawn_for_collection(sender_id)

## RPC: Notify both players that an egg has snapped into a showcase
@rpc("call_local", "call_reliable")
func broadcast_egg_placed(showcase_id: int, dozen_idx: int) -> void:
	GameManager.showcase_state[showcase_id][dozen_idx] += 1
	GameManager.total_placed_eggs += 1
	AudioManager.play_snap()
