-- LevelConfig.lua
local LevelConfig = {}

-- Calculate level and leftover XP from total XP
function LevelConfig.GetLevelFromXP(xp)
	local level = math.floor(xp / 1000) + 1
	local leftOverXp = xp % 1000
	return level, leftOverXp
end

-- Calculate XP required for a specific level
function LevelConfig.GetXPForLevel(level)
	return (level - 1) * 1000
end

-- Calculate total XP needed to reach the next level
function LevelConfig.GetXPToNextLevel(currentXp)
	local currentLevel = LevelConfig.GetLevelFromXP(currentXp)
	local nextLevelXp = LevelConfig.GetXPForLevel(currentLevel + 1)
	return nextLevelXp - currentXp
end

-- Get progress percentage to next level (0-1)
function LevelConfig.GetLevelProgress(xp)
	local _, leftOverXp = LevelConfig.GetLevelFromXP(xp)
	return leftOverXp / 1000
end

return LevelConfig