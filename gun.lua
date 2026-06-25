
local Gun = {}
Gun.__index = Gun

function Gun.new(config)
	local self = setmetatable({}, Gun)
	self.Name        = config.Name
	self.Config      = config
	self.Ammo        = config.MaxAmmo
	self.IsReloading = false
	self.LastShotTime = 0
	self.ShotCount   = 0   -- tracks shots fired for recoil escalation
	self.IsADS       = false
	return self
end

function Gun:CanShoot()
	if self.IsReloading then return false end
	if self.Ammo <= 0 then return false end
	local now = os.clock()
	if (now - self.LastShotTime) < self.Config.FireRate then return false end
	return true
end

function Gun:Shoot()
	if not self:CanShoot() then return false end
	self.Ammo -= 1
	self.LastShotTime = os.clock()
	self.ShotCount += 1
	return true
end


function Gun:Reload()
	if self.IsReloading then return end
	if self.Ammo == self.Config.MaxAmmo then return end
	self.IsReloading = true
	task.delay(self.Config.ReloadTime, function()
		self.Ammo = self.Config.MaxAmmo
		self.IsReloading = false
		self.ShotCount = 0
	end)
end

-- Calculate current spread in radians given ADS state
function Gun:GetSpread()
	local spreadDeg = self.IsADS and self.Config.ADSSpread or self.Config.Spread
	return math.rad(spreadDeg)
end

-- Calculate damage with range falloff
function Gun:CalcDamage(distance)
	local cfg = self.Config
	local dmg = cfg.Damage
	if distance > cfg.FalloffStart then
		local t = math.clamp(
			(distance - cfg.FalloffStart) / (cfg.FalloffEnd - cfg.FalloffStart),
			0, 1
		)
		local mult = 1 - t * (1 - cfg.FalloffMin)
		dmg = dmg * mult
	end
	return dmg
end

function Gun:GetRecoil()
	
	local ramp = 1 + math.min(self.ShotCount * 0.04, 0.6)
	return {
		Up   = self.Config.RecoilUp   * ramp,
		Side = self.Config.RecoilSide * ramp * (math.random() > 0.5 and 1 or -1),
	}
end

return Gun
