-- PetFollowers (LocalScript in StarterPlayer > StarterPlayerScripts)
-- Makes your equipped pets float in a circle around your character.
-- Note: these are created on YOUR screen only, so other players don't see them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdateRemote = Remotes:WaitForChild("StateUpdate")

local petParts = {}
local currentKey = nil

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function buildPets(equipped)
	for _, part in ipairs(petParts) do
		part:Destroy()
	end
	petParts = {}

	local root = getRoot()
	for _, name in ipairs(equipped) do
		local info = Config.Pets[name]
		local part = Instance.new("Part")
		part.Name = "Pet_" .. name
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.6, 1.6, 1.6)
		part.Material = Enum.Material.Neon
		part.Color = info.Color
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Position = root and root.Position or Vector3.new(0, 5, 0)

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 120, 0, 24)
		billboard.StudsOffset = Vector3.new(0, 1.6, 0)
		billboard.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = info.Color
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard

		part.Parent = workspace
		table.insert(petParts, part)
	end
end

StateUpdateRemote.OnClientEvent:Connect(function(state)
	local key = table.concat(state.Equipped, ",")
	if key ~= currentKey then
		currentKey = key
		buildPets(state.Equipped)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local root = getRoot()
	if not root or #petParts == 0 then
		return
	end
	local t = os.clock()
	for i, part in ipairs(petParts) do
		local angle = (i / #petParts) * math.pi * 2 + t * 0.8
		local offset = Vector3.new(math.cos(angle) * 4, 1.5 + math.sin(t * 3 + i) * 0.4, math.sin(angle) * 4)
		part.Position = part.Position:Lerp(root.Position + offset, math.min(1, dt * 8))
	end
end)
