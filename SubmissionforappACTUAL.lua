--PLEASE NOTE THAT THE GAME THAT USED THIS CODE IS NO LONGER BEING WORKED ON!

-- Main module table
local DemogranSpawner = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

-- Constants
local NPC_NAME = "Demogran"
local SPAWN_DISTANCE = 30
local DEMOGRAN_SPEED = 16
local PATH_UPDATE_DELAY = 0.05
local CHASE_TIME = 5
local BLEND_SPEED = 6          -- How fast animation weight blends (lerp speed)
local TURN_SPEED = 8           -- How fast the NPC rotates (lerp speed)

-- Animation ID
local ANIM_ID_WALK = "rbxassetid://118173691116990"

---------------------------------------------------------------------
-- Utility Functions
---------------------------------------------------------------------

-- Clamp a number between min and max
local function clamp(x,min,max)
	return x < min and min or x > max and max or x
end

-- Linear interpolation between numbers
local function lerp(a,b,t)
	return a + (b - a) * t
end

-- Lerp between two Vector3 values
local function lerpVector3(a,b,t)
	return Vector3.new(
		lerp(a.X,b.X,t),
		lerp(a.Y,b.Y,t),
		lerp(a.Z,b.Z,t)
	)
end

-- Returns player's HRP safely
local function getRoot(player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

-- Safely performs a raycast ignoring certain instances
local function safeRay(origin,dir,ignore)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Blacklist
	return workspace:Raycast(origin,dir,params)
end

-- Raycast down to find the ground
local function getGround(pos,ignore)
	return safeRay(pos + Vector3.new(0,50,0), Vector3.new(0,-200,0), ignore)
end

-- Random flat direction on the XZ plane
local function randomDirection()
	local a = math.random() * math.pi * 2
	return Vector3.new(math.cos(a),0,math.sin(a))
end

-- Determines a spawn position near the player
local function getSpawnPos(player)
	local hrp = getRoot(player)
	if not hrp then return nil end

	local dir = randomDirection() * SPAWN_DISTANCE
	local result = getGround(hrp.Position + dir, {player.Character})

	-- Prefer ground hit
	if result then
		return result.Position + Vector3.new(0,3,0)
	end

	-- Fallback
	return hrp.Position + dir
end

-- Computes a Roblox path
local function computePath(a,b)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 10,
		AgentMaxSlope = 45
	})
	path:ComputeAsync(a,b)
	return path
end

-- Smoothly rotates the NPC toward a target using vector lerp
local function smoothRotate(npc,targetPos,dt)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Current look direction
	local currentLook = hrp.CFrame.LookVector
	-- Desired direction
	local desired = (targetPos - hrp.Position).Unit
	-- Lerp between current and target direction
	local blended = lerpVector3(currentLook, desired, clamp(dt * TURN_SPEED, 0, 1))

	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + blended)
end

-- Direct movement (no pathfinding)
local function moveDirect(npc,targetPos,dt)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local dir = (targetPos - hrp.Position)
	if dir.Magnitude > 0 then
		local move = dir.Unit * DEMOGRAN_SPEED * dt
		smoothRotate(npc, targetPos, dt)
		hrp.CFrame = hrp.CFrame + move
	end
end

-- Move using pathfinding if possible
local function moveTo(npc,targetPos,dt)
	local humanoid = npc:FindFirstChild("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	local path = computePath(hrp.Position, targetPos)

	-- Successful path → follow waypoint 2
	if path.Status == Enum.PathStatus.Success then
		local w = path:GetWaypoints()
		if #w > 1 then
			smoothRotate(npc, w[2].Position, dt)
			humanoid:MoveTo(w[2].Position)
		end
	else
		-- Path failed → fallback to direct movement
		moveDirect(npc,targetPos,dt)
	end
end

-- Selects a random escape point
local function getEscapeTarget(npc)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return hrp.Position end

	local dir = randomDirection() * 100
	local pos = hrp.Position + dir

	local g = getGround(pos,{npc})

	if g then
		return g.Position + Vector3.new(0,3,0)
	end

	return pos
end

-- Checks if player is dead
local function playerDead(player)
	local c = player.Character
	if not c then return true end
	local h = c:FindFirstChild("Humanoid")
	if not h then return true end
	return h.Health <= 0
end

-- Loads and plays an animation track
local function playAnim(humanoid,id)
	local a = Instance.new("Animation")
	a.AnimationId = id

	local track = humanoid:LoadAnimation(a)
	track:Play()
	return track
end

-- Smoothly updates animation blend weight using lerp
local function updateBlend(track,targetWeight,dt)
	local current = track.WeightCurrent
	local newWeight = lerp(current, targetWeight, clamp(dt * BLEND_SPEED, 0, 1))
	track:AdjustWeight(newWeight)
end

---------------------------------------------------------------------
-- Main AI Loop (Chasing → Escaping)
---------------------------------------------------------------------
local function chaseLoop(npc,player)
	local humanoid = npc:FindFirstChild("Humanoid")
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	humanoid.WalkSpeed = DEMOGRAN_SPEED

	-- Start walk animation
	local track = playAnim(humanoid, ANIM_ID_WALK)

	local t0 = tick()
	local chasing = true

	while npc.Parent do
		local dt = RunService.Heartbeat:Wait()
		local root = getRoot(player)

		-------------------------------
		-- Chasing state
		-------------------------------
		if chasing then
			updateBlend(track,1,dt) -- Full animation weight (running)

			-- Switch to escape mode if timer expires or player dies
			if playerDead(player) or tick() - t0 >= CHASE_TIME then
				chasing = false
				local e = getEscapeTarget(npc)
				npc:SetAttribute("EscapeTarget", e)
			end

		-------------------------------
		-- Escape state
		-------------------------------
		else
			updateBlend(track,0.2,dt) -- Lower animation weight (calmer)
			local e = npc:GetAttribute("EscapeTarget")

			if e then
				moveTo(npc,e,dt)

				-- NPC despawns after reaching escape point
				if (hrp.Position - e).Magnitude < 4 then
					npc:Destroy()
					return
				end
			end
		end

		-- Movement during chase
		if chasing and root then
			moveTo(npc, root.Position, dt)
		end
	end
end

---------------------------------------------------------------------
-- Spawner Function
---------------------------------------------------------------------
function DemogranSpawner.spawnForPlayer(player)
	local template = ReplicatedStorage:FindFirstChild(NPC_NAME)
	if not template then return end

	local pos = getSpawnPos(player)
	if not pos then return end

	local npc = template:Clone()
	npc.Parent = workspace
	npc:PivotTo(CFrame.new(pos))

	-- Run AI loop in a separate thread
	task.spawn(function()
		chaseLoop(npc,player)
	end)
end

return DemogranSpawner
