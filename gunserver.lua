

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local gunSystem  = ReplicatedStorage:WaitForChild("GunSystem")
local GunModule  = require(gunSystem:WaitForChild("Gun"))
local GunConfig  = require(gunSystem:WaitForChild("GunConfig"))
local gunRemote  = gunSystem:WaitForChild("GunRemote")
local hitRemote  = gunSystem:WaitForChild("HitRemote")
local fxRemote   = gunSystem:WaitForChild("FXRemote")    
local killRemote = gunSystem:WaitForChild("KillRemote")  

local guns = {}          -- [player][gunName] = Gun instance
local shotLog = {}       -- [player] = { times } for anti-cheat rate limiting

local MAX_SHOTS_PER_SECOND = 20  
local MAX_AIM_ANGLE = 45         

local function getGun(player, gunName)
	guns[player] = guns[player] or {}
	if not guns[player][gunName] then
		local config = GunConfig.Guns[gunName]
		if not config then return nil end
		guns[player][gunName] = GunModule.new(config)
	end
	return guns[player][gunName]
end

local function getCharacterFromHit(part)
	local m = part
	while m do
		if m:FindFirstChildOfClass("Humanoid") then
			return m, m:FindFirstChildOfClass("Humanoid")
		end
		m = m.Parent
	end
	return nil, nil
end


local function isRateLimited(player)
	local now = os.clock()
	shotLog[player] = shotLog[player] or {}
	local log = shotLog[player]
	-- Remove entries older than 1 second
	for i = #log, 1, -1 do
		if now - log[i] > 1 then table.remove(log, i) end
	end
	if #log >= MAX_SHOTS_PER_SECOND then
		warn("[AntiCheat] " .. player.Name .. " is firing too fast — blocked.")
		return true
	end
	table.insert(log, now)
	return false
end


local function isValidAimDirection(player, aimDirection)
	local char = player.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local playerForward = hrp.CFrame.LookVector
	local dot = playerForward:Dot(aimDirection.Unit)
	return dot > -0.5  
end

local function applySpread(direction, spreadRadians)
	if spreadRadians <= 0 then return direction end
	local yaw   = (math.random() - 0.5) * 2 * spreadRadians
	local pitch = (math.random() - 0.5) * 2 * spreadRadians
	local cf = CFrame.new(Vector3.zero, direction)
		* CFrame.Angles(pitch, yaw, 0)
	return cf.LookVector
end


local function processPellet(player, gun, muzzleOrigin, direction, rayParams)
	local cfg = gun.Config
	local results = {}    

	local origin = muzzleOrigin
	local remaining = cfg.Penetration + 1  -- +1 for the initial shot

	while remaining > 0 do
		local result = workspace:Raycast(origin, direction * cfg.Range, rayParams)
		if not result then break end

		local hitChar, humanoid = getCharacterFromHit(result.Instance)
		local dist = (result.Position - muzzleOrigin).Magnitude
		local damage = gun:CalcDamage(dist)
		local isHeadshot = result.Instance.Name == "Head"
		local hitType = "None"

		if humanoid and hitChar ~= player.Character then
			if isHeadshot then
				damage = damage * cfg.HeadshotMult
			end
			damage = math.round(damage)
			humanoid:TakeDamage(damage)
			hitType = isHeadshot and "Headshot" or "Player"

			-- Track kill for kill-feed
			local victim = Players:GetPlayerFromCharacter(hitChar)
			if humanoid.Health <= 0 then
				local victimName = victim and victim.Name or hitChar.Name
				killRemote:FireAllClients(player.Name, victimName, gun.Name, isHeadshot)
				print(string.format("[Kill] %s killed %s with %s%s",
					player.Name, victimName, gun.Name,
					isHeadshot and " (HEADSHOT)" or ""))
			end
		else
			hitType = "Object"
			fxRemote:FireAllClients("BulletHole", result.Position, result.Normal, cfg.HitDecal)
		end

		table.insert(results, {
			position = result.Position,
			normal   = result.Normal,
			hitType  = hitType,
			isHeadshot = isHeadshot,
			instance = result.Instance,
		})


		remaining -= 1
		if remaining > 0 then
			origin = result.Position + direction * 0.1
			if hitChar then break end  
		end
	end

	return results
end

local function performShot(player, gun, muzzleOrigin, aimOrigin, aimDirection)
	local character = player.Character
	if not character then return end

	-- Type guards
	if typeof(muzzleOrigin)  ~= "Vector3" then return end
	if typeof(aimOrigin)     ~= "Vector3" then return end
	if typeof(aimDirection)  ~= "Vector3" then return end
	if aimDirection.Magnitude <= 0         then return end

	aimDirection = aimDirection.Unit

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character }
	rayParams.FilterType  = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true


	local camResult   = workspace:Raycast(aimOrigin, aimDirection * gun.Config.Range, rayParams)
	local targetPos   = camResult and camResult.Position or (aimOrigin + aimDirection * gun.Config.Range)

	local hitTypeResult = "None"
	local isHeadshot    = false
	local hitPosition   = targetPos

	
	for _ = 1, gun.Config.PelletsPerShot do
		local spread       = gun:GetSpread()
		local trueDir      = applySpread((targetPos - muzzleOrigin).Unit, spread)
		local pelletResults = processPellet(player, gun, muzzleOrigin, trueDir, rayParams)

		if #pelletResults > 0 then
			local first = pelletResults[1]
			hitPosition = first.position
			if first.hitType ~= "None" then
				hitTypeResult = first.hitType
				if first.isHeadshot then isHeadshot = true end
			end
		else
			hitPosition = muzzleOrigin + trueDir * gun.Config.Range
		end

	
		fxRemote:FireAllClients("Tracer", muzzleOrigin, hitPosition, gun.Config.TracerColor)
	end


	hitRemote:FireClient(player, hitTypeResult, isHeadshot, gun:GetRecoil())
end

gunRemote.OnServerEvent:Connect(function(player, action, gunName, muzzleOrigin, aimOrigin, aimDirection, extraData)

	if type(gunName) ~= "string" then return end

	if action == "Shoot" then
		if isRateLimited(player) then return end
		if not isValidAimDirection(player, aimDirection or Vector3.zero) then return end

		local gun = getGun(player, gunName)
		if not gun then return end

		local didShoot = gun:Shoot()
		if not didShoot then return end

		performShot(player, gun, muzzleOrigin, aimOrigin, aimDirection)

	elseif action == "Reload" then
		local gun = getGun(player, gunName)
		if not gun then return end
		gun:Reload()
		task.delay(gun.Config.ReloadTime, function()
			if player and player.Parent then
				hitRemote:FireClient(player, "ReloadDone", false, nil, gun.Ammo)
			end
		end)

	elseif action == "SetADS" then
		local gun = getGun(player, gunName)
		if not gun then return end
		gun.IsADS = extraData == true

	end
end)

Players.PlayerRemoving:Connect(function(player)
	guns[player] = nil
	shotLog[player] = nil
end)
