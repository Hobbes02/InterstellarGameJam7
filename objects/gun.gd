extends Node2D

const BULLET = preload("res://objects/bullet.tscn")


export(int) var bullet_amount = 1
export(int) var bullet_spread_degrees = 0

export(int) var bullet_speed = 100

export(bool) var random_fire = false

export(int) var bullets_per_mag = 5
export(float) var reload_time = 1.4



	

