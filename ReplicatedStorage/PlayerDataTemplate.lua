local Shared = {}

Shared.DEFEAULT_PLAYER_DATA = {
	gems = 0,
	xp = 0,
	selfRevives = 0,
	reviveAlls = 0,
	unlockedClasses = {},
	selectedClass = "default_class"
}

export type PlayerData = typeof(Shared.DEFEAULT_PLAYER_DATA)

return Shared
