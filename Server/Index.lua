-- Required modules
Package.Require("CameraManager.lua")
Package.Require("Database.lua")
Package.Require("Admin.lua")
Package.Require("Callback.lua")

CURRENT_PLAYERS = {}

local customSettings = Server.GetCustomSettings()
print(customSettings.spawn_point)

local function ProcessSpawnPoint(spawnPoint)
    if type(spawnPoint) == "string" then
        -- Extract numbers from Vector string format
        local x, y, z = spawnPoint:match("Vector%(([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)%)")
        if x and y and z then
            -- Convert string numbers to actual numbers
            x = tonumber(x)
            y = tonumber(y) 
            z = tonumber(z)
            if x and y and z then
                return Vector(x, y, z)
            end
        end
    end
    -- Return a default spawn point if parsing fails
    return Vector(0, 0, 0)
end
-- Function to spawn a character for a player
function SpawnCharacter(player, location)
	if type(location) == "string" then
		location = ProcessSpawnPoint(location)
	end 
    print(location)
	local new_character = HCharacter(location, Rotator(0, 0, 0), player)

	new_character:AddSkeletalMeshAttached("legs", "helix::SK_Delivery_Lower")
	new_character:AddSkeletalMeshAttached("top", "helix::SK_Delivery_Top")
	new_character:AddSkeletalMeshAttached("shoes", "helix::SK_Police_Shoes")

	-- Possess the new character
	player:Possess(new_character)

	new_character:Subscribe(
		"Death",
		function(self, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator, causer)
			-- Respawn the player after a delay
			Timer.SetTimeout(function()
				if self:IsValid() then
					self:Respawn()
				end
			end, 5000)
		end
	)

	-- Check if the player is already in the list before adding
	if CURRENT_PLAYERS[player:GetAccountID()] then
		CURRENT_PLAYERS[player:GetAccountID()] = nil
	end

	local player_name = player:GetAccountName()
	local is_dev = false

	-- Check if the player is a developer
	for _, dev_name in pairs(Config.Admins) do
		if dev_name == player_name then
			is_dev = true
			break
		end
	end

	print("Player is dev: " .. tostring(is_dev))

	-- Add the player to the list of current players
	CURRENT_PLAYERS[player:GetAccountID()] = {
		character = new_character,
		cinematic_timer = nil,
		is_dev = is_dev,
	}

	print("New character spawned for player: " .. player:GetName())
	Events.CallRemote("UpdateCameras", player, CameraManager.cameras)
    return new_character
end

-- Subscribe to the spawn event for players joining the server
Player.Subscribe("Spawn", function (player)
    local spawnPoint = customSettings.spawn_point or Config.SpawnPoint
    SpawnCharacter(player, spawnPoint)
end)

Events.SubscribeRemote("Server::SpawnCharacter", function (player, location, relocate)
    print(player, location, relocate)
    local new_character = SpawnCharacter(player, location)
    -- if relocate and new_character then
    --     new_character:SetLocation(CURRENT_PLAYERS[player:GetAccountID()].last_location)
    --     new_character:SetRotation(CURRENT_PLAYERS[player:GetAccountID()].last_rotation)
    -- end
    CameraManager.setFOVMultiplier(player, 1)
    CURRENT_PLAYERS[player:GetAccountID()].is_noclipping = false
end)

-- Ensure characters are spawned for all connected players when the package is loaded
Package.Subscribe("Load", function()
	for _, player in pairs(Player.GetAll()) do
	local spawnPoint = customSettings.spawn_point or Config.SpawnPoint
	SpawnCharacter(player, spawnPoint)
	end
end)

Events.SubscribeRemote("ToggleCharInput", function(player, state)
    local character = player:GetControlledCharacter()
    if character then
        character:SetInputEnabled(state)
    end
end)

-- Handle player disconnect
Player.Subscribe("Destroy", function(player)
	local character = player:GetControlledCharacter()
	if character then
		character:Destroy()
	end

	-- Check if the player is in the list before removing
	if CURRENT_PLAYERS[player:GetAccountID()] then
		CURRENT_PLAYERS[player:GetAccountID()] = nil
	end
end)
