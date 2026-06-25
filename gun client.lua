

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player     = Players.LocalPlayer
local camera     = workspace.CurrentCamera
local gunSystem  = ReplicatedStorage:WaitForChild("GunSystem")
local GunConfig  = require(gunSystem:WaitForChild("GunConfig"))
local gunRemote  = gunSystem:WaitForChild("GunRemote")
local hitRemote  = gunSystem:WaitForChild("HitRemote")
local fxRemote   = gunSystem:WaitForChild("FXRemote")
local killRemote = gunSystem:WaitForChild("KillRemote")

local currentGun      = "Pistol"    -- swap this when the player equips a weapon
local isADS           = false
local localAmmo       = {}          
local isReloading     = {}
local currentRecoilUp   = 0
local currentRecoilSide = 0


local playerGui = player:WaitForChild("PlayerGui")

local function makeHUD()
	local sg = Instance.new("ScreenGui")
	sg.Name = "GunHUD"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui


	local ammoLabel = Instance.new("TextLabel")
	ammoLabel.Name = "AmmoLabel"
	ammoLabel.Size = UDim2.new(0, 150, 0, 40)
	ammoLabel.Position = UDim2.new(1, -160, 1, -60)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.TextColor3 = Color3.new(1, 1, 1)
	ammoLabel.TextStrokeTransparency = 0.5
	ammoLabel.Font = Enum.Font.GothamBold
	ammoLabel.TextSize = 24
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
	ammoLabel.Text = "12 / 12"
	ammoLabel.Parent = sg


	local reloadBG = Instance.new("Frame")
	reloadBG.Name = "ReloadBG"
	reloadBG.Size = UDim2.new(0, 200, 0, 6)
	reloadBG.Position = UDim2.new(0.5, -100, 1, -30)
	reloadBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	reloadBG.BorderSizePixel = 0
	reloadBG.Visible = false
	reloadBG.Parent = sg

	local reloadFill = Instance.new("Frame")
	reloadFill.Name = "ReloadFill"
	reloadFill.Size = UDim2.new(0, 0, 1, 0)
	reloadFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	reloadFill.BorderSizePixel = 0
	reloadFill.Parent = reloadBG


	local hitmarker = Instance.new("Frame")
	hitmarker.Name = "Hitmarker"
	hitmarker.Size = UDim2.new(0, 20, 0, 20)
	hitmarker.Position = UDim2.new(0.5, -10, 0.5, -10)
	hitmarker.BackgroundTransparency = 1
	hitmarker.Parent = sg

	
	local function makeLine(isVertical)
		local l = Instance.new("Frame")
		l.BackgroundColor3 = Color3.new(1, 1, 1)
		l.BorderSizePixel = 0
		l.BackgroundTransparency = 1
		if isVertical then
			l.Size = UDim2.new(0, 2, 0, 8)
			l.AnchorPoint = Vector2.new(0.5, 0.5)
		else
			l.Size = UDim2.new(0, 8, 0, 2)
			l.AnchorPoint = Vector2.new(0.5, 0.5)
		end
		l.Position = UDim2.new(0.5, 0, 0.5, 0)
		l.Parent = hitmarker
		return l
	end
	makeLine(true); makeLine(false)

	local killfeed = Instance.new("Frame")
	killfeed.Name = "KillFeed"
	killfeed.Size = UDim2.new(0, 300, 0, 200)
	killfeed.Position = UDim2.new(1, -310, 0, 10)
	killfeed.BackgroundTransparency = 1
	killfeed.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = killfeed

	return sg
end

local hud = makeHUD()

local function updateAmmoHUD(ammo, maxAmmo)
	local label = hud:FindFirstChild("AmmoLabel")
	if label then
		label.Text = tostring(ammo) .. " / " .. tostring(maxAmmo)
		label.TextColor3 = ammo == 0 and Color3.fromRGB(255, 80, 80) or Color3.new(1,1,1)
	end
end

local function showReloadBar(duration)
	local bg   = hud:FindFirstChild("ReloadBG")
	local fill = bg and bg:FindFirstChild("ReloadFill")
	if not bg or not fill then return end
	bg.Visible = true
	fill.Size = UDim2.new(0, 0, 1, 0)
	TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
	task.delay(duration, function()
		bg.Visible = false
		fill.Size = UDim2.new(0, 0, 1, 0)
	end)
end

local function flashHitmarker(hitType)
	local hm = hud:FindFirstChild("Hitmarker")
	if not hm then return end

	local color = Color3.new(1, 1, 1)
	if hitType == "Headshot" then
		color = Color3.fromRGB(255, 80, 80)
	end

	for _, line in hm:GetChildren() do
		if line:IsA("Frame") then
			line.BackgroundTransparency = 0
			line.BackgroundColor3 = color
		end
	end

	task.delay(0.1, function()
		for _, line in hm:GetChildren() do
			if line:IsA("Frame") then
				TweenService:Create(line, TweenInfo.new(0.15), {
					BackgroundTransparency = 1
				}):Play()
			end
		end
	end)
end


local function addKillFeedEntry(killer, victim, weapon, isHeadshot)
	local kf = hud:FindFirstChild("KillFeed")
	if not kf then return end

	local entry = Instance.new("TextLabel")
	entry.Size = UDim2.new(1, 0, 0, 24)
	entry.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	entry.BackgroundTransparency = 0.4
	entry.TextColor3 = Color3.new(1, 1, 1)
	entry.Font = Enum.Font.GothamSemibold
	entry.TextSize = 13
	entry.TextXAlignment = Enum.TextXAlignment.Right
	entry.Text = string.format("%s ⟶ %s [%s]%s",
		killer, victim, weapon, isHeadshot and " 💥" or "")
	entry.Parent = kf
	task.delay(3.5, function()
		TweenService:Create(entry, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.delay(0.5, function() entry:Destroy() end)
	end)
end

local function createTracer(origin, hitPosition, color)
	local tracer = Instance.new("Part")
	tracer.Anchored   = true
	tracer.CanCollide = false
	tracer.CastShadow = false
	tracer.Material   = Enum.Material.Neon
	tracer.Color      = color or Color3.fromRGB(255, 230, 100)

	local dist = (hitPosition - origin).Magnitude
	tracer.Size  = Vector3.new(0.07, 0.07, dist)
	tracer.CFrame = CFrame.lookAt(origin, hitPosition) * CFrame.new(0, 0, -dist / 2)
	tracer.Parent = workspace


	local tween = TweenService:Create(tracer,
		TweenInfo.new(0.08, Enum.EasingStyle.Linear),
		{ Transparency = 1, Size = Vector3.new(0.02, 0.02, dist) }
	)
	tween:Play()
	Debris:AddItem(tracer, 0.12)
end


local function createMuzzleFlash(muzzleAttachment)
	if not muzzleAttachment then return end
	local flash = Instance.new("Part")
	flash.Anchored   = true
	flash.CanCollide = false
	flash.CastShadow = false
	flash.Material   = Enum.Material.Neon
	flash.Color      = Color3.fromRGB(255, 220, 100)
	flash.Size       = Vector3.new(0.4, 0.4, 0.4)
	flash.Shape      = Enum.PartType.Ball
	flash.CFrame     = muzzleAttachment.WorldCFrame
	flash.Parent     = workspace

	TweenService:Create(flash, TweenInfo.new(0.05), { Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }):Play()
	Debris:AddItem(flash, 0.07)
end


local function createBulletHole(position, normal, decalId)
	local hole = Instance.new("Part")
	hole.Anchored   = true
	hole.CanCollide = false
	hole.CastShadow = false
	hole.Size       = Vector3.new(0.3, 0.3, 0.01)
	hole.Material   = Enum.Material.SmoothPlastic
	hole.Color      = Color3.fromRGB(20, 20, 20)
	hole.CFrame     = CFrame.new(position, position + normal) * CFrame.Angles(math.pi / 2, 0, 0)
	hole.Parent     = workspace

	if decalId and decalId ~= "rbxassetid://0" then
		local decal = Instance.new("Decal")
		decal.Face    = Enum.NormalId.Front
		decal.Texture = decalId
		decal.Parent  = hole
	end

	Debris:AddItem(hole, 10)  
end


local function applyRecoil(recoilData)
	if not recoilData then return end
	currentRecoilUp   = currentRecoilUp   + math.rad(recoilData.Up)
	currentRecoilSide = currentRecoilSide + math.rad(recoilData.Side)
end


RunService.RenderStepped:Connect(function(dt)
	if currentRecoilUp ~= 0 or currentRecoilSide ~= 0 then
		local recovery = 6 * dt   -- recovery speed
		local upApply   = math.min(math.abs(currentRecoilUp),   recovery) * math.sign(currentRecoilUp)
		local sideApply = math.min(math.abs(currentRecoilSide), recovery) * math.sign(currentRecoilSide)

		camera.CFrame = camera.CFrame
			* CFrame.Angles(-upApply, -sideApply, 0)

		currentRecoilUp   = currentRecoilUp   - upApply
		currentRecoilSide = currentRecoilSide - sideApply
	end
end)


local function getGunConfig()
	return GunConfig.Guns[currentGun]
end

local function shoot()
	local cfg = getGunConfig()
	if not cfg then return end

	-- Init local ammo tracking
	if localAmmo[currentGun] == nil then
		localAmmo[currentGun] = cfg.MaxAmmo
	end
	if isReloading[currentGun] then return end
	if localAmmo[currentGun] <= 0 then
		-- Auto-reload when empty
		reload()
		return
	end

	localAmmo[currentGun] -= 1
	updateAmmoHUD(localAmmo[currentGun], cfg.MaxAmmo)

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	
	local muzzleOrigin = hrp.Position + hrp.CFrame.LookVector * 2.5 + Vector3.new(0, 0.5, 0)
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		local muzzleAtt = tool:FindFirstChild("MuzzleAttachment", true)
		if muzzleAtt then
			muzzleOrigin = muzzleAtt.WorldPosition
			createMuzzleFlash(muzzleAtt)
		end
	end

	local aimOrigin    = camera.CFrame.Position
	local aimDirection = camera.CFrame.LookVector

	gunRemote:FireServer("Shoot", currentGun, muzzleOrigin, aimOrigin, aimDirection)
end

local function reload()
	local cfg = getGunConfig()
	if not cfg then return end
	if isReloading[currentGun] then return end
	if localAmmo[currentGun] == cfg.MaxAmmo then return end

	isReloading[currentGun] = true
	showReloadBar(cfg.ReloadTime)
	gunRemote:FireServer("Reload", currentGun)

	task.delay(cfg.ReloadTime, function()
		isReloading[currentGun] = false
		localAmmo[currentGun] = cfg.MaxAmmo
		updateAmmoHUD(localAmmo[currentGun], cfg.MaxAmmo)
	end)
end

local isShooting = false
local shootConnection

local function startShooting()
	if isShooting then return end
	local cfg = getGunConfig()
	if not cfg then return end
	isShooting = true

	local function doShoot()
		while isShooting do
			shoot()
			if cfg.BurstCount == 1 then break end  
			task.wait(cfg.FireRate)
		end
	end

	task.spawn(doShoot)
end

local function stopShooting()
	isShooting = false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startShooting()
	elseif input.KeyCode == Enum.KeyCode.R then
		reload()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		isADS = true
		gunRemote:FireServer("SetADS", currentGun, nil, nil, nil, true)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopShooting()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		isADS = false
		gunRemote:FireServer("SetADS", currentGun, nil, nil, nil, false)
	end
end)


hitRemote.OnClientEvent:Connect(function(hitType, isHeadshot, recoilData, ammo)
	if hitType == "ReloadDone" then
		return
	end
	if hitType ~= "None" then
		flashHitmarker(hitType)
	end
	applyRecoil(recoilData)
end)


fxRemote.OnClientEvent:Connect(function(fxType, ...)
	if fxType == "Tracer" then
		local origin, hitPos, color = ...
		createTracer(origin, hitPos, color)
	elseif fxType == "BulletHole" then
		local pos, normal, decalId = ...
		createBulletHole(pos, normal, decalId)
	end
end)


killRemote.OnClientEvent:Connect(function(killer, victim, weapon, isHeadshot)
	addKillFeedEntry(killer, victim, weapon, isHeadshot)
end)


local cfg = getGunConfig()
if cfg then
	localAmmo[currentGun] = cfg.MaxAmmo
	updateAmmoHUD(cfg.MaxAmmo, cfg.MaxAmmo)
end
