-- GunSystem/GunConfig.lua
-- All weapon stats live here. Add new guns by adding a new table entry.

local GunConfig = {}

GunConfig.Guns = {
	Pistol = {
		Name        = "Pistol",
		Damage      = 22,
		HeadshotMult = 2.0,    -- headshots deal 2× damage
		MaxAmmo     = 12,
		FireRate    = 0.25,
		ReloadTime  = 1.5,
		Range       = 300,
		FalloffStart = 100,    -- damage starts dropping here (studs)
		FalloffEnd   = 300,    -- damage at minimum beyond here
		FalloffMin   = 0.4,    -- minimum damage multiplier at max range
		Spread       = 0.5,    -- hip-fire spread in degrees
		ADSSpread    = 0.05,   -- ADS spread in degrees
		RecoilUp     = 0.8,    -- camera kick per shot (degrees up)
		RecoilSide   = 0.3,    -- random horizontal kick
		Penetration  = 0,      -- number of thin parts bullet passes through
		BurstCount   = 1,      -- shots per trigger pull (1 = semi, 3 = burst, 0 = auto)
		BurstDelay   = 0,
		PelletsPerShot = 1,    -- 1 for most, 6-9 for shotguns
		TracerColor  = Color3.fromRGB(255, 230, 100),
		HitDecal     = "rbxassetid://0",  -- bullet hole decal asset
	},

	SMG = {
		Name        = "SMG",
		Damage      = 14,
		HeadshotMult = 1.6,
		MaxAmmo     = 30,
		FireRate    = 0.09,
		ReloadTime  = 2.0,
		Range       = 200,
		FalloffStart = 60,
		FalloffEnd   = 180,
		FalloffMin   = 0.35,
		Spread       = 1.2,
		ADSSpread    = 0.4,
		RecoilUp     = 0.5,
		RecoilSide   = 0.5,
		Penetration  = 0,
		BurstCount   = 0,    -- 0 = full auto
		BurstDelay   = 0,
		PelletsPerShot = 1,
		TracerColor  = Color3.fromRGB(200, 255, 150),
		HitDecal     = "rbxassetid://0",
	},

	AssaultRifle = {
		Name        = "AssaultRifle",
		Damage      = 28,
		HeadshotMult = 2.0,
		MaxAmmo     = 30,
		FireRate    = 0.1,
		ReloadTime  = 2.5,
		Range       = 500,
		FalloffStart = 150,
		FalloffEnd   = 450,
		FalloffMin   = 0.5,
		Spread       = 0.8,
		ADSSpread    = 0.15,
		RecoilUp     = 1.2,
		RecoilSide   = 0.4,
		Penetration  = 1,   -- punches through 1 thin wall
		BurstCount   = 0,
		BurstDelay   = 0,
		PelletsPerShot = 1,
		TracerColor  = Color3.fromRGB(255, 200, 80),
		HitDecal     = "rbxassetid://0",
	},

	Shotgun = {
		Name        = "Shotgun",
		Damage      = 16,     -- per pellet
		HeadshotMult = 1.5,
		MaxAmmo     = 8,
		FireRate    = 0.9,
		ReloadTime  = 2.8,
		Range       = 80,
		FalloffStart = 20,
		FalloffEnd   = 70,
		FalloffMin   = 0.1,
		Spread       = 5.0,
		ADSSpread    = 3.0,
		RecoilUp     = 4.0,
		RecoilSide   = 0.5,
		Penetration  = 0,
		BurstCount   = 1,
		BurstDelay   = 0,
		PelletsPerShot = 7,   -- 7 pellets per shot
		TracerColor  = Color3.fromRGB(255, 120, 80),
		HitDecal     = "rbxassetid://0",
	},

	SniperRifle = {
		Name        = "SniperRifle",
		Damage      = 95,
		HeadshotMult = 3.0,   -- one-shot headshot potential
		MaxAmmo     = 5,
		FireRate    = 1.5,
		ReloadTime  = 3.5,
		Range       = 1500,
		FalloffStart = 800,
		FalloffEnd   = 1400,
		FalloffMin   = 0.75,  -- still hits hard at range
		Spread       = 0.01,
		ADSSpread    = 0.0,
		RecoilUp     = 6.0,
		RecoilSide   = 0.3,
		Penetration  = 2,     -- punches through 2 surfaces
		BurstCount   = 1,
		BurstDelay   = 0,
		PelletsPerShot = 1,
		TracerColor  = Color3.fromRGB(120, 200, 255),
		HitDecal     = "rbxassetid://0",
	},
}

return GunConfig
