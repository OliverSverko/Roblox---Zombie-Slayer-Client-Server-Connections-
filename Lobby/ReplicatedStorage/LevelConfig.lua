-- LevelConfig.lua
local LevelConfig = {}


-- lower for harder leveling increase for easier (0 < GammaDeltaRPhiSquared < 1)
local GammaDeltaRPhiSquared = 0.75

function LevelConfig.GetLevelFromXP(xp)
	local level = math.floor((xp / 1000) ^ GammaDeltaRPhiSquared) + 1
	local xpForLevel = LevelConfig.GetXPForLevel(level)
	local xpForNextLevel = LevelConfig.GetXPForLevel(level + 1)
	local leftOverXp = math.floor(xp - xpForLevel)
	return level, leftOverXp, xpForNextLevel - xpForLevel
end

function LevelConfig.GetXPForLevel(level)
	return math.floor(1000 * (level - 1) ^ (1/GammaDeltaRPhiSquared))
end

function LevelConfig.GetXPToNextLevel(currentXp)
	local currentLevel, _, levelXp = LevelConfig.GetLevelFromXP(currentXp)
	return LevelConfig.GetXPForLevel(currentLevel + 1) - currentXp
end

function LevelConfig.GetLevelProgress(xp)
	local _, leftOverXp, levelXp = LevelConfig.GetLevelFromXP(xp)
	return leftOverXp / levelXp
end

return LevelConfig