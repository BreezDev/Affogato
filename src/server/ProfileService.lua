--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Affogato.Config)

export type Profile = {
	cash: number,
	xp: number,
	level: number,
	completedOrders: number,
}

local ProfileService = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles: { [Player]: Profile } = {}

local DEFAULT: Profile = { cash = Config.StartingCash, xp = 0, level = 1, completedOrders = 0 }

local function copyDefault(): Profile
	return table.clone(DEFAULT)
end

function ProfileService.Get(player: Player): Profile?
	return profiles[player]
end

function ProfileService.Load(player: Player): Profile
	local profile = copyDefault()
	local success, saved = pcall(function()
		return store:GetAsync(`player_{player.UserId}`)
	end)
	if success and type(saved) == "table" then
		profile.cash = math.max(0, tonumber(saved.cash) or profile.cash)
		profile.xp = math.max(0, tonumber(saved.xp) or profile.xp)
		profile.level = math.max(1, tonumber(saved.level) or profile.level)
		profile.completedOrders = math.max(0, tonumber(saved.completedOrders) or profile.completedOrders)
	elseif not success then
		warn(`Could not load profile for {player.Name}; using session defaults`)
	end
	profiles[player] = profile
	return profile
end

function ProfileService.Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then return true end
	local success, message = pcall(function()
		store:UpdateAsync(`player_{player.UserId}`, function()
			return profile
		end)
	end)
	if not success then warn(`Could not save {player.Name}: {tostring(message)}`) end
	return success
end

function ProfileService.Award(player: Player, cash: number, xp: number)
	local profile = profiles[player]
	if not profile then return end
	profile.cash += math.max(0, math.floor(cash))
	profile.xp += math.max(0, math.floor(xp))
	profile.completedOrders += 1
	profile.level = math.floor(profile.xp / 100) + 1
end

function ProfileService.Start()
	Players.PlayerRemoving:Connect(function(player)
		ProfileService.Save(player)
		profiles[player] = nil
	end)
	task.spawn(function()
		while task.wait(Config.AutoSaveSeconds) do
			for player in profiles do ProfileService.Save(player) end
		end
	end)
	game:BindToClose(function()
		for player in profiles do ProfileService.Save(player) end
	end)
end

return ProfileService
