local Gun = {}
Gun.__index = Gun

function Gun.new(config)
	local self = setmetatable({}, Gun)

	self.Name = config.Name or "Gun"
	self.Damage = config.Damage or 10
	self.MaxAmmo = config.MaxAmmo or 10
	self.Ammo = self.MaxAmmo
	self.FireRate = config.FireRate or 0.3
	self.ReloadTime = config.ReloadTime or 2
	self.Range = config.Range or 300
	self.RecoilUp = config.RecoilUp or 0.3
	self.RecoilSide = config.RecoilSide or 0.1
	self.RecoilRecovery = config.RecoilRecovery or 0.15

	self.Reloading = false
	self.LastShotTime = 0

	return self
end

function Gun:CanShoot()
	if self.Reloading then
		return false
	end

	if self.Ammo <= 0 then
		return false
	end

	local now = os.clock()
	if now - self.LastShotTime < self.FireRate then
		return false
	end

	return true
end

function Gun:Shoot()
	if not self:CanShoot() then
		return false
	end

	self.Ammo -= 1
	self.LastShotTime = os.clock()

	return true
end

function Gun:CanReload()
	if self.Reloading then
		return false
	end

	if self.Ammo >= self.MaxAmmo then
		return false
	end

	return true
end

function Gun:Reload()
	if not self:CanReload() then
		return false
	end

	self.Reloading = true

	task.wait(self.ReloadTime)

	self.Ammo = self.MaxAmmo
	self.Reloading = false

	return true
end

return Gun
