--!strict

local WorldService = {}
local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local function part(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3): Part
	local value = Instance.new("Part")
	value.Name = name
	value.Anchored = true
	value.Position = position
	value.Size = size
	value.Color = color
	value.Material = Enum.Material.SmoothPlastic
	value.Parent = parent
	return value
end

function WorldService.Build()
	if workspace:FindFirstChild("AffogatoCafe") then return end
	local cafe = Instance.new("Folder")
	cafe.Name = "AffogatoCafe"
	cafe.Parent = workspace
	part(cafe, "Floor", Vector3.new(0, -0.5, 0), Vector3.new(70, 1, 55), Color3.fromRGB(224, 204, 174))
	part(cafe, "BackWall", Vector3.new(0, 7, -27), Vector3.new(70, 15, 1), Color3.fromRGB(247, 236, 218))
	part(cafe, "Counter", Vector3.new(0, 2, -5), Vector3.new(30, 4, 4), Color3.fromRGB(106, 68, 46))

	local stations = {
		{ "Coffee", Vector3.new(-10, 5, -5), Color3.fromRGB(95, 70, 60) },
		{ "Affogato", Vector3.new(0, 5, -5), Color3.fromRGB(235, 188, 198) },
		{ "Bakery", Vector3.new(10, 5, -5), Color3.fromRGB(208, 126, 73) },
		{ "Serve", Vector3.new(0, 3, 0), Color3.fromRGB(105, 167, 116) },
		{ "Management", Vector3.new(14, 3, 0), Color3.fromRGB(91, 139, 157) },
	}
	for _, info in stations do
		local station = part(cafe, info[1] .. "Station", info[2], Vector3.new(6, 2, 3), info[3])
		station:SetAttribute("Station", info[1])
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = info[1] == "Serve" and "Serve next order" or "Prepare item"
		if info[1] == "Management" then prompt.ActionText = "Manage café" end
		prompt.ObjectText = info[1] .. " Station"
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = station
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CafeSpawn"
	spawn.Anchored = true
	spawn.Position = Vector3.new(0, 0.5, 17)
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Neutral = true
	spawn.Parent = cafe

	local queue = Instance.new("Folder")
	queue.Name = "Customers"
	queue.Parent = cafe
	return cafe
end

function WorldService.ShowDelivery(player: Player, ingredientName: string)
	local cafe = workspace:FindFirstChild("AffogatoCafe")
	if not cafe then return end
	local box = part(cafe, `Delivery_{player.UserId}`, Vector3.new(-24, 1.5, 15), Vector3.new(4, 3, 4), Color3.fromRGB(177, 126, 76))
	box:SetAttribute("OwnerUserId", player.UserId)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 55)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = box
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
	text.TextColor3 = Color3.fromRGB(82, 52, 42)
	text.TextScaled = true
	text.Text = `{player.DisplayName}: {ingredientName}`
	text.Parent = gui
	task.delay(8, function() if box.Parent then box:Destroy() end end)
end

local function ownerFolder(player: Player): Folder
	local cafe = workspace:WaitForChild("AffogatoCafe")
	local builds = cafe:FindFirstChild("PlayerBuilds") or Instance.new("Folder")
	builds.Name = "PlayerBuilds"
	builds.Parent = cafe
	local folder = builds:FindFirstChild(tostring(player.UserId)) or Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = builds
	return folder :: Folder
end

function WorldService.RenderFurniture(player: Player, placements: { any })
	local folder = ownerFolder(player)
	local old = folder:FindFirstChild("Furniture")
	if old then old:Destroy() end
	local furniture = Instance.new("Folder")
	furniture.Name = "Furniture"
	furniture.Parent = folder
	for _, placement in placements do
		local item = Meta.Furniture[placement.itemId]
		if item then
			local model = Instance.new("Model")
			model.Name = placement.id
			model:SetAttribute("PlacementId", placement.id)
			model:SetAttribute("OwnerUserId", player.UserId)
			local base = part(model, "Base", Vector3.new(placement.x, 1.5, placement.z + 9), Vector3.new(item.size[1] * 1.8, 3, item.size[2] * 1.8), Color3.fromRGB(item.color[1], item.color[2], item.color[3]))
			base.CFrame = CFrame.new(base.Position) * CFrame.Angles(0, math.rad(placement.rotation), 0)
			model.PrimaryPart = base
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Rotate"
			prompt.ObjectText = item.name
			prompt.MaxActivationDistance = 8
			prompt:SetAttribute("BuildPlacementId", placement.id)
			prompt:SetAttribute("OwnerUserId", player.UserId)
			prompt.Parent = base
			model.Parent = furniture
		end
	end
end

function WorldService.RenderExpansion(player: Player, expansionLevel: number)
	local folder = ownerFolder(player)
	local old = folder:FindFirstChild("ExpansionBoundary")
	if old then old:Destroy() end
	local expansion = Meta.Expansions[expansionLevel]
	local boundary = part(folder, "ExpansionBoundary", Vector3.new(0, 0.03, 9), Vector3.new(expansion.halfWidth * 2, 0.06, expansion.halfDepth * 2), Color3.fromRGB(236, 215, 183))
	boundary.Transparency = 0.65
	boundary.CanCollide = false
	boundary:SetAttribute("OwnerUserId", player.UserId)
end

function WorldService.CreateCustomer(id: number, queuePosition: number): Model
	local cafe = workspace:WaitForChild("AffogatoCafe")
	local model = Instance.new("Model")
	model.Name = `Customer_{id}`
	local body = part(model, "Body", Vector3.new(0, 3, 8 + queuePosition * 4), Vector3.new(2.5, 5, 2), Color3.fromHSV((id * 0.17) % 1, 0.45, 0.9))
	model.PrimaryPart = body
	local face = Instance.new("BillboardGui")
	face.Size = UDim2.fromOffset(150, 42)
	face.StudsOffset = Vector3.new(0, 3.5, 0)
	face.AlwaysOnTop = true
	face.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
	label.TextColor3 = Color3.fromRGB(75, 49, 40)
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.Text = `Order #{id}`
	label.Parent = face
	model.Parent = cafe:WaitForChild("Customers")
	return model
end

return WorldService
