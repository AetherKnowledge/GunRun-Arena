extends CharacterBody2D
class_name Player

var can_jump = false
var jump_buffer = false
var looking_at: Vector2
var direction: int = 1

const WEAPON_POSITION := Vector2(3,-4)
const WEAPON_SCALE := Vector2(0.313, 0.313)
const MAX_MOVEMENT_SPEED = 150
const MAX_FALL_SPEED = 300
const APEX_GRAVITY_MULTIPLIER = 0.5  # Lower gravity at apex
const APEX_VELOCITY_THRESHOLD = 20.0  # How close to zero Y velocity counts as apex
const DASH_SPEED = MAX_MOVEMENT_SPEED * 2.5
const MAX_DASH_SPEED = DASH_SPEED * 2
const MOVEMENT_SPEED = 40
const JUMP_VELOCITY = 300.0
var alive = true
var holding_attack: bool = false

signal took_damage
signal died
