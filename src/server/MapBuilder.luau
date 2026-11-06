-- MapBuilder (ModuleScript in ServerScriptService)
-- Builds a bright, colorful candy-space world out of plain Parts when the server starts.
-- Uses a fixed random seed, so the map looks the same every time.

local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local rng = Random.new(2026)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		if key ~= "Parent" then
			p[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function hue(h, s, v)
	return Color3.fromHSV(h % 1, s or 0.55, v or 1)
end

-- Vertical cylinder (Roblox cylinders point along X, so we tip them up).
local function upright(position)
	return CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

-- Keeps decorations off the plaza and the four paths.
local function isOpenSpot(x, z)
	if math.sqrt(x * x + z * z) < 32 then
		return false
	end
	return math.abs(x) > 10 and math.abs(z) > 10
end

local function randomOpenSpot(minRadius, maxRadius)
	for _ = 1, 50 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(minRadius, maxRadius)
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		if isOpenSpot(x, z) then
			return x, z
		end
	end
	return maxRadius, maxRadius
end

local function buildGround(folder)
	local base = workspace:FindFirstChild("Baseplate")
	if not base then
		base = part({ Name = "Baseplate", Size = Vector3.new(600, 20, 600), Position = Vector3.new(0, -10, 0), Parent = workspace })
	end
	for _, child in ipairs(base:GetChildren()) do
		if child:IsA("Texture") or child:IsA("Decal") then
			child:Destroy() -- remove the default grid texture
		end
	end
	base.Material = Enum.Material.Grass
	base.Color = Color3.fromRGB(130, 215, 170)

	if not workspace:FindFirstChildOfClass("SpawnLocation") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = Vector3.new(0, 0.5, 0)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Color = Color3.fromRGB(255, 255, 255)
		spawn.Material = Enum.Material.Neon
		spawn.Parent = workspace
	end

	-- Round plaza with a glowing rainbow ring
	part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 46, 46),
		CFrame = upright(Vector3.new(0, 0.3, 0)),
		Color = Color3.fromRGB(255, 244, 228),
		Parent = folder,
	})
	local tiles = 32
	for i = 1, tiles do
		local angle = (i / tiles) * math.pi * 2
		part({
			Name = "RingTile",
			Size = Vector3.new(3.4, 0.3, 3.4),
			CFrame = CFrame.new(math.cos(angle) * 19.5, 0.75, math.sin(angle) * 19.5) * CFrame.Angles(0, -angle, 0),
			Color = hue(i / tiles, 0.6, 1),
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
end

local function buildArch(folder, center, direction)
	local side = Vector3.new(-direction.Z, 0, direction.X)
	local pieces = 11
	for k = 0, pieces - 1 do
		local theta = math.pi * k / (pieces - 1)
		local pos = center + side * math.cos(theta) * 9 + Vector3.new(0, math.sin(theta) * 9 + 1, 0)
		part({
			Name = "ArchBlock",
			Size = Vector3.new(2.6, 2.6, 2.6),
			CFrame = CFrame.lookAt(pos, pos + direction),
			Color = hue(k / pieces, 0.65, 1),
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
end

local function buildPaths(folder)
	local directions = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
	for d, direction in ipairs(directions) do
		local index = 0
		for distance = 26, 120, 6 do
			index = index + 1
			local pos = direction * distance + Vector3.new(0, 0.2, 0)
			part({
				Name = "PathTile",
				Size = Vector3.new(7, 0.4, 5),
				CFrame = CFrame.lookAt(pos, pos + direction),
				Color = hue(d * 0.25 + index * 0.04, 0.45, 1),
				Parent = folder,
			})
		end
		buildArch(folder, direction * 45, direction)
	end
end

local function buildTree(folder, x, z, baseY)
	baseY = baseY or 0
	local height = rng:NextNumber(6, 11)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.8, 1.8),
		CFrame = upright(Vector3.new(x, baseY + height / 2, z)),
		Color = Color3.fromRGB(205, 155, 115),
		Parent = folder,
	})
	local crownColor = hue(rng:NextNumber(), 0.5, 1)
	local size = rng:NextNumber(7, 10)
	part({
		Name = "Crown",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size, size, size),
		Position = Vector3.new(x, baseY + height + size * 0.3, z),
		Color = crownColor,
		Parent = folder,
	})
	if rng:NextNumber() < 0.5 then
		local small = size * 0.6
		part({
			Name = "Crown",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(small, small, small),
			Position = Vector3.new(x + size * 0.35, baseY + height + size * 0.75, z),
			Color = crownColor:Lerp(Color3.new(1, 1, 1), 0.3),
			Parent = folder,
		})
	end
end

local function buildCrystals(folder, count)
	for _ = 1, count do
		local x, z = randomOpenSpot(35, 210)
		local color = hue(rng:NextNumber(), 0.55, 1)
		for _ = 1, 3 do
			local h = rng:NextNumber(5, 11)
			part({
				Name = "Crystal",
				Size = Vector3.new(1.8, h, 1.8),
				CFrame = CFrame.new(x + rng:NextNumber(-2, 2), h / 2 - 0.5, z + rng:NextNumber(-2, 2))
					* CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-20, 20))),
				Color = color,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = folder,
			})
		end
	end
end

local function buildFloatingIslands(folder)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + 0.3
		local x, z = math.cos(angle) * 150, math.sin(angle) * 150
		local y = 45 + rng:NextNumber(0, 35)
		part({
			Name = "IslandTop",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3, 30, 30),
			CFrame = upright(Vector3.new(x, y, z)),
			Color = hue(i / 6, 0.35, 1),
			Material = Enum.Material.Grass,
			Parent = folder,
		})
		part({
			Name = "IslandRock",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(22, 22, 22),
			Position = Vector3.new(x, y - 8, z),
			Color = Color3.fromRGB(160, 130, 200),
			Parent = folder,
		})
		buildTree(folder, x, z, y + 1.5)
	end
end

local function buildPlanets(folder)
	local planets = {
		{ Position = Vector3.new(-380, 260, -420), Size = 150, Color = Color3.fromRGB(255, 140, 200), Ring = true },
		{ Position = Vector3.new(450, 320, -150), Size = 110, Color = Color3.fromRGB(120, 220, 255) },
		{ Position = Vector3.new(120, 380, 480), Size = 170, Color = Color3.fromRGB(255, 190, 90) },
	}
	for _, info in ipairs(planets) do
		part({
			Name = "Planet",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(info.Size, info.Size, info.Size),
			Position = info.Position,
			Color = info.Color,
			CanCollide = false,
			CastShadow = false,
			Parent = folder,
		})
		if info.Ring then
			part({
				Name = "PlanetRing",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(2, info.Size * 1.9, info.Size * 1.9),
				CFrame = CFrame.new(info.Position) * CFrame.Angles(math.rad(20), 0, math.rad(90)),
				Color = Color3.fromRGB(255, 240, 160),
				Material = Enum.Material.Neon,
				Transparency = 0.35,
				CanCollide = false,
				CastShadow = false,
				Parent = folder,
			})
		end
	end
end

local function setupLighting()
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(120, 100, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(175, 155, 205)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Haze = 1
	atmosphere.Glare = 0.2
	atmosphere.Color = Color3.fromRGB(255, 200, 235)
	atmosphere.Decay = Color3.fromRGB(160, 130, 255)
	atmosphere.Parent = Lighting

	local color = Lighting:FindFirstChild("MapColor") or Instance.new("ColorCorrectionEffect")
	color.Name = "MapColor"
	color.Saturation = 0.25
	color.Contrast = 0.05
	color.Parent = Lighting

	local bloom = Lighting:FindFirstChild("MapBloom") or Instance.new("BloomEffect")
	bloom.Name = "MapBloom"
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

function MapBuilder.Build()
	if workspace:FindFirstChild("StardustMap") then
		return -- already built
	end
	local folder = Instance.new("Folder")
	folder.Name = "StardustMap"

	buildGround(folder)
	buildPaths(folder)
	for _ = 1, 45 do
		local x, z = randomOpenSpot(35, 230)
		buildTree(folder, x, z)
	end
	buildCrystals(folder, 18)
	buildFloatingIslands(folder)
	buildPlanets(folder)
	setupLighting()

	folder.Parent = workspace
end

return MapBuilder
