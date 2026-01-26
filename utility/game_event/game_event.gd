class_name GameEvent
extends RefCounted

enum event_type {CARD_DRAWN}

var priority := 0
var consumed := false
var type: event_type

var card
