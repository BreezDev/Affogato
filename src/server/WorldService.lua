--!strict

local WorldService = {}

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
	}
	for _, info in stations do
		local station = part(cafe, info[1] .. "Station", info[2], Vector3.new(6, 2, 3), info[3])
		station:SetAttribute("Station", info[1])
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = info[1] == "Serve" and "Serve next order" or "Prepare item"
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
