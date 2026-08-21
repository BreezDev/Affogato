--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Affogato")
local Recipes = require(shared.Recipes)
local Economy = require(shared.Economy)
local RemoteNames = require(shared.Remotes)
local remotes = ReplicatedStorage:WaitForChild(RemoteNames.Folder)
local stateRemote = remotes:WaitForChild(RemoteNames.State) :: RemoteEvent
local actionRemote = remotes:WaitForChild(RemoteNames.Action) :: RemoteFunction
local prepRemote = remotes:WaitForChild(RemoteNames.Preparation) :: RemoteFunction
local notifyRemote = remotes:WaitForChild(RemoteNames.Notify) :: RemoteEvent

local cream = Color3.fromRGB(255, 248, 235)
local brown = Color3.fromRGB(82, 52, 42)
local rose = Color3.fromRGB(205, 121, 132)

local gui = Instance.new("ScreenGui")
gui.Name = "AffogatoHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent: Instance, name: string, size: UDim2, position: UDim2, text: string, textSize: number): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Size = size
	value.Position = position
	value.BackgroundColor3 = cream
	value.BackgroundTransparency = 0.08
	value.TextColor3 = brown
	value.Font = Enum.Font.GothamMedium
	value.TextSize = textSize
	value.TextWrapped = true
	value.Text = text
	value.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = value
	return value
end

local top = label(gui, "Status", UDim2.fromOffset(650, 70), UDim2.new(0.5, -325, 0, 18), "Loading café…", 17)
local ticket = label(gui, "Ticket", UDim2.fromOffset(290, 250), UDim2.new(1, -310, 0, 88), "Waiting for customers…", 17)
ticket.TextYAlignment = Enum.TextYAlignment.Top
ticket.TextXAlignment = Enum.TextXAlignment.Left
ticket.RichText = true
local inventory = label(gui, "Tray", UDim2.fromOffset(290, 130), UDim2.new(1, -310, 0, 350), "<b>Your tray</b>\nEmpty", 16)
inventory.TextYAlignment = Enum.TextYAlignment.Top
inventory.TextXAlignment = Enum.TextXAlignment.Left
inventory.RichText = true

local toast = label(gui, "Toast", UDim2.fromOffset(440, 54), UDim2.new(0.5, -220, 1, -80), "", 18)
toast.Visible = false

local modal = Instance.new("Frame")
modal.Name = "Preparation"
modal.Size = UDim2.fromOffset(520, 390)
modal.Position = UDim2.new(0.5, -260, 0.5, -195)
modal.BackgroundColor3 = cream
modal.Visible = false
modal.Parent = gui
Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)

local title = label(modal, "Title", UDim2.new(1, -40, 0, 55), UDim2.fromOffset(20, 15), "Choose a recipe", 24)
title.BackgroundTransparency = 1
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -40, 1, -100)
content.Position = UDim2.fromOffset(20, 75)
content.BackgroundTransparency = 1
content.Parent = modal

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 34)
close.Position = UDim2.new(1, -46, 0, 12)
close.Text = "×"
close.TextSize = 26
close.BackgroundColor3 = rose
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = modal
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

local connections: { RBXScriptConnection } = {}
local renderStep: (any) -> ()
local openSignatureEditor: () -> ()
local latestState: any = nil
local interactionLevel = 0
local placementItem: string? = nil
local movingPlacement: string? = nil
local function clearContent()
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	for _, child in content:GetChildren() do child:Destroy() end
end

local function showToast(message: string, positive: boolean)
	toast.Text = message
	toast.BackgroundColor3 = positive and Color3.fromRGB(203, 232, 196) or Color3.fromRGB(246, 194, 184)
	toast.Visible = true
	task.delay(3, function() toast.Visible = false end)
end

local function finishStep(quality: number)
	local success, result = prepRemote:InvokeServer("Step", quality)
	if not success then showToast(tostring(result), false) return end
	if result.completed then modal.Visible = false return end
	-- Continue directly into the next simple interaction.
	task.defer(function() renderStep(result) end)
end

local rapidSteps = { ScoopGelato = true, PortionDough = true, PortionBatter = true, ShapeDough = true }
local timingSteps = { PullEspresso = true, Bake = true }
local holdSteps = { AddMilk = true, PourEspresso = true }

renderStep = function(stepData)
	clearContent()
	title.Text = `{stepData.displayName}  •  {stepData.stepNumber}/{stepData.totalSteps}`
	local instruction = label(content, "Instruction", UDim2.new(1, 0, 0, 70), UDim2.fromOffset(0, 0), stepData.step, 21)
	instruction.BackgroundTransparency = 1

	if rapidSteps[stepData.step] then
		local clicks = 0
		local needed = math.max(4, 8 - interactionLevel)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(220, 100)
		button.Position = UDim2.new(0.5, -110, 0.5, -30)
		button.BackgroundColor3 = rose
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 22
		button.Text = `Rapid click! 0/{needed}`
		button.Parent = content
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 14)
		table.insert(connections, button.Activated:Connect(function()
			clicks += 1
			button.Text = `Rapid click! {clicks}/{needed}`
			if clicks >= needed then finishStep(math.clamp(0.7 + clicks / 40, 0, 1)) end
		end))
	elseif timingSteps[stepData.step] then
		local track = Instance.new("Frame")
		track.Size = UDim2.new(0.85, 0, 0, 46)
		track.Position = UDim2.new(0.075, 0, 0.42, 0)
		track.BackgroundColor3 = Color3.fromRGB(220, 203, 181)
		track.Parent = content
		local target = Instance.new("Frame")
		local targetWidth = math.min(0.42, 0.22 + interactionLevel * 0.035)
		target.Size = UDim2.new(targetWidth, 0, 1, 0)
		target.Position = UDim2.new(0.5 - targetWidth / 2, 0, 0, 0)
		target.BackgroundColor3 = Color3.fromRGB(135, 190, 131)
		target.Parent = track
		local marker = Instance.new("Frame")
		marker.Size = UDim2.fromOffset(8, 62)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BackgroundColor3 = brown
		marker.Parent = track
		local started = os.clock()
		local meterSpeed = latestState and latestState.event and latestState.event.name == "Espresso Machine Problem" and 2.1 or 3
		table.insert(connections, RunService.RenderStepped:Connect(function()
			local alpha = (math.sin((os.clock() - started) * meterSpeed) + 1) / 2
			marker.Position = UDim2.new(alpha, 0, 0.5, 0)
		end))
		local stop = Instance.new("TextButton")
		stop.Size = UDim2.fromOffset(180, 55)
		stop.Position = UDim2.new(0.5, -90, 0.68, 0)
		stop.Text = stepData.step == "Bake" and "Remove from oven" or "Stop meter"
		stop.BackgroundColor3 = rose
		stop.TextColor3 = Color3.new(1, 1, 1)
		stop.TextSize = 18
		stop.Parent = content
		table.insert(connections, stop.Activated:Connect(function()
			local alpha = marker.Position.X.Scale
			finishStep(1 - math.min(math.abs(alpha - 0.5) / 0.5, 1))
		end))
	elseif holdSteps[stepData.step] then
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(250, 100)
		button.Position = UDim2.new(0.5, -125, 0.5, -30)
		button.Text = "Hold, then release"
		button.TextSize = 21
		button.BackgroundColor3 = rose
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Parent = content
		local heldAt = 0
		table.insert(connections, button.MouseButton1Down:Connect(function() heldAt = os.clock() button.Text = "Keep holding…" end))
		table.insert(connections, button.MouseButton1Up:Connect(function()
			local duration = os.clock() - heldAt
			finishStep(1 - math.min(math.abs(duration - 1.4) / 1.4, 1))
		end))
	else
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(250, 80)
		button.Position = UDim2.new(0.5, -125, 0.5, -20)
		button.Text = "Click to add"
		button.TextSize = 21
		button.BackgroundColor3 = rose
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Parent = content
		table.insert(connections, button.Activated:Connect(function() finishStep(1) end))
	end
end

local function managementList(heading: string, rows: { any }, render: (any) -> (string, string?, any?))
	clearContent()
	title.Text = heading
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 7
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.Parent = scroll
	for _, row in rows do
		local text, action, payload = render(row)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -10, 0, 52)
		button.BackgroundColor3 = action and Color3.fromRGB(239, 216, 190) or Color3.fromRGB(235, 229, 216)
		button.TextColor3 = brown
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 15
		button.TextWrapped = true
		button.Text = text
		button.AutoButtonColor = action ~= nil
		button.Parent = scroll
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
		if action then
			table.insert(connections, button.Activated:Connect(function()
				if action == "LocalPlace" then
					placementItem = tostring(payload)
					movingPlacement = nil
					modal.Visible = false
					showToast("Build Mode: click a floor grid cell to place. Press Esc to cancel.", true)
				elseif action == "LocalMove" then
					movingPlacement = tostring(payload)
					placementItem = nil
					modal.Visible = false
					showToast("Build Mode: click a new floor grid cell.", true)
				elseif action == "LocalSignature" then openSignatureEditor()
				elseif action == "LocalPass" and tonumber(payload) and payload > 0 then MarketplaceService:PromptGamePassPurchase(player, payload)
				elseif action == "LocalProduct" and tonumber(payload) and payload > 0 then MarketplaceService:PromptProductPurchase(player, payload)
				else actionRemote:InvokeServer(action, payload) end
			end))
		end
	end
end

openSignatureEditor = function()
	clearContent()
	title.Text = "Create Signature Drink"
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.Parent = content
	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, 0, 0, 45)
	nameBox.PlaceholderText = "Drink name (3–28 characters)"
	nameBox.Text = "My Café Dream"
	nameBox.TextSize = 18
	nameBox.Parent = content
	local priceBox = Instance.new("TextBox")
	priceBox.Size = UDim2.new(1, 0, 0, 42)
	priceBox.PlaceholderText = "Price ($5–$18)"
	priceBox.Text = "10"
	priceBox.TextSize = 18
	priceBox.Parent = content
	local choices = {
		{ key = "baseId", values = { "Latte", "IcedLatte", "ClassicAffogato" } },
		{ key = "flavor", values = { "None", "Caramel", "Chocolate", "Pistachio", "Matcha" } },
		{ key = "topping", values = { "None", "WhippedCream", "CookieCrumb", "ChocolateDrizzle" } },
	}
	local selected = {}
	for _, choice in choices do
		local index = 1
		selected[choice.key] = choice.values[index]
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 42)
		button.Text = `{choice.key}: {choice.values[index]} (click to change)`
		button.TextSize = 17
		button.BackgroundColor3 = Color3.fromRGB(239, 216, 190)
		button.Parent = content
		table.insert(connections, button.Activated:Connect(function()
			index = index % #choice.values + 1
			selected[choice.key] = choice.values[index]
			button.Text = `{choice.key}: {choice.values[index]} (click to change)`
		end))
	end
	local create = Instance.new("TextButton")
	create.Size = UDim2.new(1, 0, 0, 48)
	create.Text = "Create & add to menu"
	create.TextSize = 19
	create.BackgroundColor3 = rose
	create.TextColor3 = Color3.new(1, 1, 1)
	create.Parent = content
	table.insert(connections, create.Activated:Connect(function()
		actionRemote:InvokeServer("CreateSignature", { name = nameBox.Text, price = tonumber(priceBox.Text), baseId = selected.baseId, flavor = selected.flavor, topping = selected.topping })
		modal.Visible = false
	end))
end

local function openManagement()
	clearContent()
	modal.Visible = true
	title.Text = "Café Management"
	local categoryScroll = Instance.new("ScrollingFrame")
	categoryScroll.Size = UDim2.fromScale(1, 1)
	categoryScroll.BackgroundTransparency = 1
	categoryScroll.BorderSizePixel = 0
	categoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	categoryScroll.CanvasSize = UDim2.new()
	categoryScroll.Parent = content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(225, 75)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.Parent = categoryScroll
	local function category(name: string, callback: () -> ())
		local button = Instance.new("TextButton")
		button.BackgroundColor3 = Color3.fromRGB(239, 216, 190)
		button.TextColor3 = brown
		button.TextSize = 19
		button.Font = Enum.Font.GothamBold
		button.Text = name
		button.Parent = categoryScroll
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		table.insert(connections, button.Activated:Connect(callback))
	end
	category("📦 Inventory", function()
		local rows = table.clone(latestState.inventory)
		for _, delivery in latestState.deliveries do table.insert(rows, { delivery = true, name = delivery.name, arrivesIn = delivery.arrivesIn }) end
		managementList("Inventory & Deliveries", rows, function(row)
			if row.delivery then return `🚚 {row.name} arrives in {row.arrivesIn}s`, nil, nil end
			return `{row.name}: {row.amount}  •  {math.floor(row.quality * 100)}% quality`, nil, nil
		end)
	end)
	category("🚚 Suppliers", function()
		local rows = {}
		for supplierId, supplier in Economy.Suppliers do
			for ingredientId, product in supplier.products do
				table.insert(rows, { supplierId = supplierId, ingredientId = ingredientId, supplier = supplier, product = product })
			end
		end
		managementList("Supplier Store", rows, function(row)
			return `{row.supplier.name} · {Economy.Ingredients[row.ingredientId].name} +{row.product.amount}  •  ${row.product.cost}  •  Lv.{row.supplier.unlockLevel}`, "OrderSupply", { supplierId = row.supplierId, ingredientId = row.ingredientId }
		end)
	end)
	category("⚙ Equipment", function()
		managementList("Equipment Upgrades", latestState.equipment, function(row)
			if not row.cost then return `{row.name}: {row.tier} (MAX)`, nil, nil end
			return `{row.name}: {row.tier} → {row.nextName}  •  ${row.cost}`, "UpgradeEquipment", row.id
		end)
	end)
	category("🏃 Player Skills", function()
		managementList("Player Upgrades", latestState.upgrades, function(row)
			if not row.cost then return `{row.name}: Lv.{row.level} (MAX)`, nil, nil end
			return `{row.name}: Lv.{row.level} → {row.level + 1}  •  ${row.cost}`, "UpgradePlayer", row.id
		end)
	end)
	category("👥 Staff", function()
		managementList("Hire & Train Staff", latestState.staff, function(row)
			if not row.hired then return `{row.name} · {row.role}  •  Hire ${row.hireCost} · Wage ${row.wage}/day`, "HireStaff", row.id end
			if not row.trainingCost then return `{row.name} · {row.role} · Training Lv.{row.training} (MAX) · ${row.wage}/day`, nil, nil end
			return `{row.name} · {row.role} · Training Lv.{row.training}  •  Train ${row.trainingCost}`, "TrainStaff", row.id
		end)
	end)
	category("🪑 Furniture", function()
		local rows = {}
		for _, row in latestState.furniture do
			table.insert(rows, { text = row.locked and `🔒 {row.name} · Premium Decor Pack` or `BUY · {row.name} [{row.theme}] +{row.ambience} ambience · ${row.cost}`, action = row.locked and nil or "BuyFurniture", payload = row.id })
			if row.owned > 0 then table.insert(rows, { text = `PLACE · {row.name} · {row.owned} stored`, action = "LocalPlace", payload = row.id }) end
		end
		for _, placed in latestState.placements do
			table.insert(rows, { text = `MOVE · {placed.name} ({placed.x}, {placed.z})`, action = "LocalMove", payload = placed.id })
			table.insert(rows, { text = `ROTATE · {placed.name} ({placed.rotation}°)`, action = "EditFurniture", payload = { edit = "Rotate", placementId = placed.id } })
			table.insert(rows, { text = `STORE · {placed.name}`, action = "EditFurniture", payload = { edit = "Store", placementId = placed.id } })
			table.insert(rows, { text = `SELL · {placed.name} (50% refund)`, action = "EditFurniture", payload = { edit = "Sell", placementId = placed.id } })
		end
		managementList(`Build Mode · Ambience {latestState.ambience}`, rows, function(row) return row.text, row.action, row.payload end)
	end)
	category("🏠 Expansion", function()
		local rows = { { current = true } }
		managementList("Café Expansion", rows, function()
			if latestState.nextExpansion then return `{latestState.expansion} → {latestState.nextExpansion.name} · ${latestState.nextExpansion.cost}`, "ExpandCafe", true end
			return `{latestState.expansion} · Fully expanded`, nil, nil
		end)
	end)
	category("⭐ Challenges", function()
		local unlockText = latestState.nextUnlock and ` · Next: Lv.{latestState.nextUnlock.level} {latestState.nextUnlock.name}` or " · All level rewards unlocked"
		managementList(`Daily Challenges · Login Day {latestState.loginStreak}{unlockText}`, latestState.challenges, function(row)
			local text = `{row.description} · {row.progress}/{row.target} · ${row.rewardCash} + {row.rewardXP} XP`
			if row.claimed then return text .. " · CLAIMED", nil, nil end
			return text, row.progress >= row.target and "ClaimChallenge" or nil, row.id
		end)
	end)
	category("🏆 Achievements", function()
		managementList("Achievements", latestState.achievements, function(row)
			return `{row.unlocked and "✓" or "○"} {row.name} · {row.description} · {row.progress}/{row.target}`, nil, nil
		end)
	end)
	category("🎁 Login Rewards", function()
		local rows = {}
		for day, reward in latestState.loginRewards do
			local detail = reward.itemId and reward.itemId or `{reward.amount} {reward.kind}`
			table.insert(rows, { day = day, detail = detail })
		end
		managementList(`Login Calendar · Current Day {latestState.loginStreak}`, rows, function(row)
			return `{row.day == latestState.loginStreak and "TODAY" or "Day " .. row.day} · {row.detail}`, nil, nil
		end)
	end)
	category("✨ Signature Drink", function()
		local rows = { { text = "CREATE · Choose a base, flavor, topping, name, and price", action = #latestState.signatures < 3 and "LocalSignature" or nil } }
		for _, recipe in latestState.signatures do
			table.insert(rows, { text = `{recipe.name} · {recipe.baseId} + {recipe.flavor} + {recipe.topping} · ${recipe.price} · {recipe.sold} sold`, action = nil })
			table.insert(rows, { text = `DELETE · {recipe.name}`, action = "DeleteSignature", payload = recipe.id })
		end
		managementList("Signature Drinks", rows, function(row) return row.text, row.action, row.payload end)
	end)
	category("📋 Menu", function()
		local active = {} for _, id in latestState.menu do active[id] = true end
		local rows = table.clone(Recipes.List)
		for _, signature in latestState.signatures do table.insert(rows, { id = signature.id, displayName = signature.name, price = signature.price }) end
		managementList("Café Menu", rows, function(row)
			local locked = row.unlockLevel and latestState.level < row.unlockLevel
			return `{locked and "🔒" or active[row.id] and "✓" or "○"} {row.displayName} · ${row.price}`, locked and nil or "ToggleMenuItem", row.id
		end)
	end)
	category("⚙ Settings", function()
		local rows = {}
		for key, value in latestState.settings do table.insert(rows, { key = key, value = value }) end
		managementList("Settings", rows, function(row)
			return `{row.key}: {row.value and "ON" or "OFF"}`, "UpdateSetting", { key = row.key, value = not row.value }
		end)
	end)
	category("🛍 Optional Shop", function()
		local rows = {}
		for name, id in latestState.store.gamepasses do table.insert(rows, { text = `{name} Gamepass · {id > 0 and "Open purchase prompt" or "Set ID in Meta.lua"}`, action = id > 0 and "LocalPass" or nil, payload = id }) end
		for name, id in latestState.store.products do table.insert(rows, { text = `{name} Product · {id > 0 and "Open purchase prompt" or "Set ID in Meta.lua"}`, action = id > 0 and "LocalProduct" or nil, payload = id }) end
		managementList("Optional Shop · Core progression uses café cash", rows, function(row) return row.text, row.action, row.payload end)
	end)
end

local function openStation(station: string)
	clearContent()
	modal.Visible = true
	title.Text = station .. " Station"
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = content
	for _, recipe in Recipes.List do
		if recipe.station == station then
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 52)
			button.BackgroundColor3 = Color3.fromRGB(239, 216, 190)
			button.TextColor3 = brown
			button.Font = Enum.Font.GothamMedium
			button.TextSize = 18
			local locked = latestState and latestState.level < (recipe.unlockLevel or 1)
			button.Text = locked and `🔒 Lv.{recipe.unlockLevel} · {recipe.displayName}` or `{recipe.displayName}  •  ${recipe.price}`
			button.BackgroundColor3 = locked and Color3.fromRGB(210, 205, 198) or button.BackgroundColor3
			button.Parent = content
			Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
			table.insert(connections, button.Activated:Connect(function()
				local success, result = prepRemote:InvokeServer("Start", { recipeId = recipe.id, station = station })
				if success then renderStep(result) else showToast(tostring(result), false) end
			end))
		end
	end
end

close.Activated:Connect(function()
	prepRemote:InvokeServer("Cancel")
	modal.Visible = false
	clearContent()
end)

local function connectPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("AffogatoConnected") then return end
	prompt:SetAttribute("AffogatoConnected", true)
	prompt.Triggered:Connect(function()
		local placementId = prompt:GetAttribute("BuildPlacementId")
		if placementId and prompt:GetAttribute("OwnerUserId") == player.UserId then actionRemote:InvokeServer("EditFurniture", { edit = "Rotate", placementId = placementId }) return end
		local stationPart = prompt.Parent
		local station = stationPart and stationPart:GetAttribute("Station")
		if station == "Serve" then actionRemote:InvokeServer("Serve") elseif station == "Management" then openManagement() elseif station then openStation(station) end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Escape then placementItem = nil movingPlacement = nil return end
	if processed or (not placementItem and not movingPlacement) then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local position = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(position.X, position.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500)
	if not result then return end
	local payload = { x = result.Position.X, z = result.Position.Z }
	if placementItem then
		payload.itemId = placementItem
		actionRemote:InvokeServer("PlaceFurniture", payload)
		placementItem = nil
	else
		payload.edit = "Move"
		payload.placementId = movingPlacement
		actionRemote:InvokeServer("EditFurniture", payload)
		movingPlacement = nil
	end
end)

for _, descendant in workspace:GetDescendants() do if descendant:IsA("ProximityPrompt") then connectPrompt(descendant) end end
workspace.DescendantAdded:Connect(function(descendant) if descendant:IsA("ProximityPrompt") then connectPrompt(descendant) end end)

local function renderState(state)
	latestState = state
	interactionLevel = state.interactionLevel or 0
	local eventText = state.event and ` · ⚡ {state.event.name} {state.event.endsIn}s` or ""
	top.Text = `☕ Day {state.day} · {state.period} · ⭐ {string.format("%.2f", state.reputation)} {state.fame} · ✿ {state.ambience}{eventText}\n${state.cash} · Level {state.level} ({state.xp} XP)`
	local lines = { "<b>ORDER TICKETS</b>" }
	for _, order in state.orders do
		table.insert(lines, `\n<b>#{order.id} · {order.customerType}</b> · ☺ {order.happiness}%`)
		for _, item in order.items do table.insert(lines, `  • {item}`) end
	end
	if #state.orders == 0 then table.insert(lines, "\nNo customers waiting") end
	ticket.Text = table.concat(lines, "\n")
	local trayLines = { "<b>YOUR TRAY</b>" }
	for _, item in state.held do table.insert(trayLines, `• {item.name} ({math.floor(item.quality * 100)}%)`) end
	if #state.held == 0 then table.insert(trayLines, "Empty") end
	inventory.Text = table.concat(trayLines, "\n")
end

stateRemote.OnClientEvent:Connect(renderState)

notifyRemote.OnClientEvent:Connect(showToast)
local ok, initial = actionRemote:InvokeServer("GetState")
if ok and initial then renderState(initial) end
