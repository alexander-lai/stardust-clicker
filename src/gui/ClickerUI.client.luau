-- ClickerUI (LocalScript inside StarterGui > MainUI, a ScreenGui)
-- Builds the whole interface in code, so you don't have to design UI by hand.
-- The client only DISPLAYS numbers and ASKS the server to do things.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClickRemote = Remotes:WaitForChild("Click")
local BuyUpgradeRemote = Remotes:WaitForChild("BuyUpgrade")
local HatchEggRemote = Remotes:WaitForChild("HatchEgg")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local RequestStateRemote = Remotes:WaitForChild("RequestState")
local StateUpdateRemote = Remotes:WaitForChild("StateUpdate")
local NotifyRemote = Remotes:WaitForChild("Notify")

-- Use the ScreenGui we live in; if pasted somewhere else, make one.
local screenGui = script.Parent
if not screenGui:IsA("ScreenGui") then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
end

local COLORS = {
	Panel = Color3.fromRGB(30, 24, 60),
	PanelLight = Color3.fromRGB(55, 45, 105),
	Gold = Color3.fromRGB(255, 205, 60),
	Text = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(60, 190, 100),
	Red = Color3.fromRGB(210, 60, 70),
	Gray = Color3.fromRGB(90, 85, 110),
	Purple = Color3.fromRGB(150, 90, 255),
	Pink = Color3.fromRGB(240, 90, 170),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 210),
	Uncommon = Color3.fromRGB(110, 220, 120),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Mythic = Color3.fromRGB(255, 80, 160),
}

---------------------------------------------------------------------------
-- Tiny helper for making UI objects
---------------------------------------------------------------------------
local function make(className, props, children)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(color, thickness)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(px)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function sortedKeys(dict)
	local keys = {}
	for key in pairs(dict) do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return dict[a].Order < dict[b].Order
	end)
	return keys
end

---------------------------------------------------------------------------
-- Top bar: Stardust counter
---------------------------------------------------------------------------
local topBar = make("Frame", {
	Name = "TopBar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0, 380, 0, 84),
	BackgroundColor3 = COLORS.Panel,
	Parent = screenGui,
}, { corner(16), stroke(COLORS.Gold, 3) })

local currencyLabel = make("TextLabel", {
	Position = UDim2.new(0, 10, 0, 4),
	Size = UDim2.new(1, -20, 0, 48),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	TextColor3 = COLORS.Gold,
	Text = "⭐ 0",
	Parent = topBar,
})

local statsLabel = make("TextLabel", {
	Position = UDim2.new(0, 10, 0, 54),
	Size = UDim2.new(1, -20, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = COLORS.Text,
	Text = "Loading...",
	Parent = topBar,
})

---------------------------------------------------------------------------
-- Toast notifications
---------------------------------------------------------------------------
local toast = make("TextLabel", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 104),
	Size = UDim2.new(0, 460, 0, 40),
	BackgroundColor3 = COLORS.Panel,
	BackgroundTransparency = 1,
	TextTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = COLORS.Text,
	Text = "",
	Parent = screenGui,
}, { corner(10), padding(6) })

local toastId = 0
local function showToast(message, kind)
	toastId = toastId + 1
	local myId = toastId
	toast.Text = message
	if kind == "error" then
		toast.BackgroundColor3 = COLORS.Red
	elseif kind == "success" then
		toast.BackgroundColor3 = COLORS.Green
	else
		toast.BackgroundColor3 = COLORS.PanelLight
	end
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.1
	task.delay(2.5, function()
		if myId == toastId then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end

---------------------------------------------------------------------------
-- The big CLICK button
---------------------------------------------------------------------------
local CLICK_SIZE = 170
local clickButton = make("TextButton", {
	Name = "ClickButton",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -30),
	Size = UDim2.new(0, CLICK_SIZE, 0, CLICK_SIZE),
	BackgroundColor3 = COLORS.Gold,
	Font = Enum.Font.FredokaOne,
	Text = "CLICK!",
	TextSize = 42,
	TextColor3 = Color3.fromRGB(90, 55, 0),
	Parent = screenGui,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(COLORS.Text, 4) })

local function floatText(text, color)
	local label = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-90, 90), 1, -CLICK_SIZE - 50),
		Size = UDim2.new(0, 180, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		Text = text,
		TextColor3 = color,
		TextStrokeTransparency = 0.3,
		Parent = screenGui,
	})
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = label.Position - UDim2.new(0, 0, 0, 100), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local state = nil
local lastClick = 0
local MIN_CLICK_GAP = 1 / Config.ClicksPerSecondLimit

clickButton.Activated:Connect(function()
	local now = os.clock()
	if now - lastClick < MIN_CLICK_GAP then
		return
	end
	lastClick = now
	ClickRemote:FireServer()

	-- Juice: squish the button and pop a "+X" number.
	clickButton.Size = UDim2.new(0, CLICK_SIZE - 18, 0, CLICK_SIZE - 18)
	TweenService:Create(clickButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, CLICK_SIZE, 0, CLICK_SIZE),
	}):Play()
	if state then
		floatText("+" .. Util.FormatNumber(state.ClickGain), COLORS.Gold)
	end
end)

---------------------------------------------------------------------------
-- Shop panel (right side): upgrades, eggs, rebirth
---------------------------------------------------------------------------
local shop = make("Frame", {
	Name = "Shop",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.new(0, 250, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLORS.Panel,
	Parent = screenGui,
}, {
	corner(14),
	stroke(COLORS.Purple, 3),
	padding(10),
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local layoutOrder = 0
local function nextOrder()
	layoutOrder = layoutOrder + 1
	return layoutOrder
end

local function header(text, parent)
	return make("TextLabel", {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = COLORS.Gold,
		Text = text,
		Parent = parent,
	})
end

local function shopButton(parent)
	return make("TextButton", {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = COLORS.Gray,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextWrapped = true,
		RichText = true,
		TextColor3 = COLORS.Text,
		Text = "...",
		Parent = parent,
	}, { corner(10) })
end

header("UPGRADES", shop)
local upgradeButtons = {}
for _, id in ipairs(sortedKeys(Config.Upgrades)) do
	local button = shopButton(shop)
	button.Activated:Connect(function()
		BuyUpgradeRemote:FireServer(id)
	end)
	upgradeButtons[id] = button
end

header("EGGS", shop)
local eggButtons = {}
for _, id in ipairs(sortedKeys(Config.Eggs)) do
	local button = shopButton(shop)
	button.Activated:Connect(function()
		HatchEggRemote:FireServer(id)
	end)
	eggButtons[id] = button
end

header("REBIRTH", shop)
local rebirthButton = shopButton(shop)
rebirthButton.Activated:Connect(function()
	RebirthRemote:FireServer()
end)

---------------------------------------------------------------------------
-- Pets panel (left side)
---------------------------------------------------------------------------
local petsPanel = make("Frame", {
	Name = "Pets",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 220, 0, 320),
	BackgroundColor3 = COLORS.Panel,
	Parent = screenGui,
}, { corner(14), stroke(COLORS.Pink, 3), padding(10) })

local petsTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.FredokaOne,
	TextScaled = true,
	TextColor3 = COLORS.Gold,
	Text = "PETS",
	Parent = petsPanel,
})

local petsBoost = make("TextLabel", {
	Position = UDim2.new(0, 0, 0, 28),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = COLORS.Text,
	Text = "Hatch an egg to get pets!",
	Parent = petsPanel,
})

local petList = make("ScrollingFrame", {
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 1, -54),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = petsPanel,
}, { make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

local lastPetsKey = nil
local function refreshPets(pets, equippedCount)
	local sorted = {}
	for _, name in ipairs(pets) do
		if Config.Pets[name] then
			table.insert(sorted, name)
		end
	end
	table.sort(sorted, function(a, b)
		return Config.Pets[a].Multiplier > Config.Pets[b].Multiplier
	end)

	local key = table.concat(sorted, ",")
	if key == lastPetsKey then
		return -- nothing changed, skip rebuilding
	end
	lastPetsKey = key

	for _, child in ipairs(petList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, name in ipairs(sorted) do
		local info = Config.Pets[name]
		local equipped = i <= equippedCount
		make("TextLabel", {
			LayoutOrder = i,
			Size = UDim2.new(1, -8, 0, 26),
			BackgroundColor3 = equipped and COLORS.PanelLight or COLORS.Panel,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = RARITY_COLORS[info.Rarity] or COLORS.Text,
			Text = string.format(
				"  %s%s  x%s",
				equipped and "★ " or "",
				name,
				Util.FormatMultiplier(info.Multiplier)
			),
			Parent = petList,
		}, { corner(6) })
	end
end

---------------------------------------------------------------------------
-- Update everything when the server sends new numbers
---------------------------------------------------------------------------
local function updateUI(newState)
	state = newState
	local stardust = state.Stardust
	local F = Util.FormatNumber

	currencyLabel.Text = "⭐ " .. F(stardust) .. " " .. Config.CurrencyName
	statsLabel.Text = string.format(
		"+%s per click  •  +%s/sec  •  x%s boost",
		F(state.ClickGain),
		F(state.AutoGain),
		Util.FormatMultiplier(state.PetMultiplier * state.RebirthMultiplier)
	)

	for id, button in pairs(upgradeButtons) do
		local upgrade = Config.Upgrades[id]
		local level = state.Upgrades[id] or 0
		local cost = state.UpgradeCosts[id]
		local maxed = level >= upgrade.MaxLevel
		button.Text = string.format(
			"<b>%s</b> (Lv %d)\n%s\n%s",
			upgrade.DisplayName,
			level,
			upgrade.Description,
			maxed and "MAXED" or ("⭐ " .. F(cost))
		)
		button.BackgroundColor3 = (not maxed and stardust >= cost) and COLORS.Green or COLORS.Gray
	end

	for id, button in pairs(eggButtons) do
		local egg = Config.Eggs[id]
		button.Text = string.format("<b>🥚 %s</b>\nHatch for ⭐ %s", egg.DisplayName, F(egg.Cost))
		button.BackgroundColor3 = stardust >= egg.Cost and COLORS.Purple or COLORS.Gray
	end

	local nextMult = Util.FormatMultiplier(Config.GetRebirthMultiplier(state.Rebirths + 1))
	rebirthButton.Text = string.format(
		"<b>🔁 Rebirth (%d so far)</b>\nNeed ⭐ %s → x%s forever\nResets Stardust + upgrades",
		state.Rebirths,
		F(state.RebirthCost),
		nextMult
	)
	rebirthButton.BackgroundColor3 = stardust >= state.RebirthCost and COLORS.Pink or COLORS.Gray

	petsTitle.Text = string.format("PETS (%d/%d)", #state.Pets, Config.MaxPets)
	if #state.Pets > 0 then
		petsBoost.Text = "Pet boost: x" .. Util.FormatMultiplier(state.PetMultiplier)
	end
	refreshPets(state.Pets, #state.Equipped)
end

StateUpdateRemote.OnClientEvent:Connect(updateUI)
NotifyRemote.OnClientEvent:Connect(showToast)

RequestStateRemote:FireServer() -- ask for our numbers in case we missed the first update
