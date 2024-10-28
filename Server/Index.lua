-- Required modules
Package.Require("CameraManager.lua")
Package.Require("Database.lua")
Package.Require("Admin.lua")
Package.Require("Callback.lua")

CURRENT_PLAYERS = {}

-- Function to spawn a character for a player
function SpawnCharacter(player)
    local new_character = HCharacter(Config.SpawnPoint, Rotator(0, 0, 0), player)

    new_character:AddSkeletalMeshAttached("legs", "helix::SK_Delivery_Lower")
    new_character:AddSkeletalMeshAttached("top", "helix::SK_Delivery_Top")
    new_character:AddSkeletalMeshAttached("shoes", "helix::SK_Police_Shoes")

    -- Possess the new character
    player:Possess(new_character)

    new_character:Subscribe(
        "Death",
        function(self, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator, causer)
            -- Respawn the player after a delay
            Timer.SetTimeout(
                function()
                    if self:IsValid() then
                        self:Respawn()
                    end
                end,
                5000
            )
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
        is_dev = is_dev
    }

    print("New character spawned for player: " .. player:GetName())
    Events.CallRemote("UpdateCameras", player, CameraManager.cameras)
end

-- Subscribe to the spawn event for players joining the server
Player.Subscribe("Spawn", SpawnCharacter)

-- Ensure characters are spawned for all connected players when the package is loaded
Package.Subscribe(
    "Load",
    function()
        for _, player in pairs(Player.GetAll()) do
            SpawnCharacter(player)
        end
    end
)

-- Handle player disconnect
Player.Subscribe(
    "Destroy",
    function(player)
        local character = player:GetControlledCharacter()
        if character then
            character:Destroy()
        end

        -- Check if the player is in the list before removing
        if CURRENT_PLAYERS[player:GetAccountID()] then
            CURRENT_PLAYERS[player:GetAccountID()] = nil
        end
    end
)
