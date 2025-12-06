local PathfindingService = game:GetService("PathfindingService")
local hum = script.Parent:WaitForChild("Humanoid")
local hrp = script.Parent:WaitForChild("HumanoidRootPart")
local attackanim = script.Parent:WaitForChild("AttackAnim")

local AttackanimTrack = hum:LoadAnimation(attackanim)

local Debounce = false

local ATTACK_RADIUS = 7
local NORMAL_SPEED = 15
local SLOW_SPEED = 1
local LERP_RATE = 0.7
local Damage = 5

hum.WalkSpeed = NORMAL_SPEED

local function ComputeDistance(targetHum)
	if not targetHum or not targetHum.Parent then return math.huge end
	local targetHRP = targetHum.Parent:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return math.huge end
	return (hrp.Position - targetHRP.Position).Magnitude
end

local function findnearesthumanoid()
	local closestDist = math.huge
	local closestHumanoid = nil
	for _, plr in pairs(game.Players:GetPlayers()) do
		if plr.Character then
			local hum = plr.Character:FindFirstChild("Humanoid")
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local dist = (hrp.Position - script.Parent.HumanoidRootPart.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestHumanoid = hum
				end
			end
		end
	end
	return closestHumanoid
end

while task.wait(0.05) do
	local targetHum = findnearesthumanoid()
	if not targetHum then continue end

	local targetHRP = targetHum.Parent:FindFirstChild("HumanoidRootPart")
	if not targetHRP then continue end

	local dist = ComputeDistance(targetHum)

	if dist <= ATTACK_RADIUS then
		hum.WalkSpeed = hum.WalkSpeed + (SLOW_SPEED - hum.WalkSpeed) * LERP_RATE
		Debounce = true
		if Debounce == true then
			targetHum.Health = targetHum.Health - Damage
			AttackanimTrack:Play()
			task.wait(0.5)
			Debounce = false
		end
	else
		hum.WalkSpeed = hum.WalkSpeed + (NORMAL_SPEED - hum.WalkSpeed) * LERP_RATE
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 6,
		AgentCanJump = true,
		AgentJumpHeight = 10,
		AgentMaxSlope = 45
	})

	path:ComputeAsync(hrp.Position, targetHRP.Position)

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints > 1 then
			local wp = waypoints[2]
			hum:MoveTo(wp.Position)
			if wp.Action == Enum.PathWaypointAction.Jump then
				hum.Jump = true
			end
		end
	end
end
