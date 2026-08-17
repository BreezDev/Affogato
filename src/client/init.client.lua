--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Affogato")
local Recipes = require(shared.Recipes)
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

local top = label(gui, "Status", UDim2.fromOffset(500, 52), UDim2.new(0.5, -250, 0, 18), "Loading café…", 18)
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
		local needed = 8
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
		target.Size = UDim2.new(0.22, 0, 1, 0)
		target.Position = UDim2.new(0.39, 0, 0, 0)
		target.BackgroundColor3 = Color3.fromRGB(135, 190, 131)
		target.Parent = track
		local marker = Instance.new("Frame")
		marker.Size = UDim2.fromOffset(8, 62)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.BackgroundColor3 = brown
		marker.Parent = track
		local started = os.clock()
		table.insert(connections, RunService.RenderStepped:Connect(function()
			local alpha = (math.sin((os.clock() - started) * 3) + 1) / 2
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
			button.Text = `{recipe.displayName}  •  ${recipe.price}`
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
		local stationPart = prompt.Parent
		local station = stationPart and stationPart:GetAttribute("Station")
		if station == "Serve" then actionRemote:InvokeServer("Serve") elseif station then openStation(station) end
	end)
end

for _, descendant in workspace:GetDescendants() do if descendant:IsA("ProximityPrompt") then connectPrompt(descendant) end end
workspace.DescendantAdded:Connect(function(descendant) if descendant:IsA("ProximityPrompt") then connectPrompt(descendant) end end)

local function renderState(state)
	top.Text = `☕ Day {state.day} · {state.period} ({math.floor(state.timeLeft / 60)}:{state.timeLeft % 60 // 10}{state.timeLeft % 10})     ${state.cash} · Level {state.level} ({state.xp} XP)`
	local lines = { "<b>ORDER TICKETS</b>" }
	for _, order in state.orders do
		table.insert(lines, `\n<b>#{order.id}</b> · ☺ {order.happiness}%`)
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
