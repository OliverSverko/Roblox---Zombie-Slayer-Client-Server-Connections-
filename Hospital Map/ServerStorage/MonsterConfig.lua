-- ServerStorage/MonsterConfig.module.lua

return {
	RoundSettings = {
		BaseMonsters = 4,
		MonsterIncreasePerRound = 2,
		SpawnDelay = 0.5,
		TimeBetweenWaves = 2
	},

	MonsterTypeStats = {
		Zombie = {
			BaseHealth = 100,
			XP = 50,
			Coins = 50,
			Speed = 10,
			Damage = 15,
			StunDuration = 0.5,
			AttackCooldown = 1,
			StunEffect = 0.5
		},

		Skeleton = {
			BaseHealth = 200,
			XP = 75,
			Coins = 75,
			Speed = 10,
			Damage = 20,
			StunDuration = 0.6,
			AttackCooldown = 1.2,
			StunEffect = 0.5
		},

		LightningZombie = {
			BaseHealth = 150,
			XP = 150,
			Coins = 100,
			Speed = 15,
			Damage = 12,
			StunDuration = 0.3,
			AttackCooldown = 0.8,
			StunEffect = 0.5
		},

		StoneZombie = {
			BaseHealth = 500,
			XP = 200,
			Coins = 100,
			Speed = 8,
			Damage = 25,
			StunDuration = 0,
			AttackCooldown = 1.5,
			StunEffect = 0.5
		},

		ShinyZombie = {
			BaseHealth = 800,
			XP = 500,
			Coins = 200,
			Speed = 10,
			Damage = 30,
			StunDuration = 0.6,
			AttackCooldown = 1.3,
			StunEffect = 0.5
		},

		ShinySkeleton = {
			BaseHealth = 1000,
			XP = 600,
			Coins = 150,
			Speed = 10,
			Damage = 35,
			StunDuration = 0.7,
			AttackCooldown = 1.1,
			StunEffect = 0.5
		},

		ShinyLightningZombie = {
			BaseHealth = 500,
			XP = 1000,
			Coins = 250,
			Speed = 18,
			Damage = 28,
			StunDuration = 0.4,
			AttackCooldown = 0.9,
			StunEffect = 0.5
		},

		MetalZombie = {
			BaseHealth = 4000,
			XP = 1250,
			Coins = 200,
			Speed = 8,
			Damage = 40,
			StunDuration = 0,
			AttackCooldown = 1.8,
			StunEffect = 0.5
		},

		BossZombie = {
			BaseHealth = 25000,
			XP = 50000,
			Coins = 1000,
			Speed = 18,
			Damage = 80,
			StunDuration = 0,
			AttackCooldown = 1,
			StunEffect = 0.5
		}
	},


	MonsterTypeWeights = {
		-- Rounds 1–4
		{ Zombie = 100},

		-- Rounds 5–9
		{ Zombie = 70, Skeleton = 25, LightningZombie = 5 },

		-- Rounds 10–14
		{ Zombie = 60, Skeleton = 15, LightningZombie = 10,  ShinyZombie = 5, StoneZombie = 10},

		-- Rounds 15–19
		{ Zombie = 30, Skeleton = 20, LightningZombie = 20, StoneZombie = 10, ShinySkeleton = 10,  ShinyZombie = 10 },

		-- Rounds 20–24
		{ Zombie = 10, Skeleton = 10, LightningZombie = 15, StoneZombie = 15, ShinySkeleton = 20, ShinyLightningZombie = 20, MetalZombie = 10 },

		-- Rounds 25+
		{ Zombie = 10, Skeleton = 10, LightningZombie = 10, StoneZombie = 15, ShinySkeleton = 15, ShinyLightningZombie = 15, MetalZombie = 10, ShinyZombie = 10, BossZombie = 5 }
	}
}
