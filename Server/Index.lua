Package.Require("CameraManager.lua")

CURRENT_PLAYERS = {}

-- Function to spawn a Character to a player
function SpawnCharacter(player)
    Console.Log("Spawn player")
    local new_character = HCharacter(Vector(0, 0, 0), Rotator(0, 0, 0), player)
    -- Possess the new Character
    player:Possess(new_character)

    -- Check if the player is already in the list before adding
    if CURRENT_PLAYERS[player:GetAccountID()] then
        CURRENT_PLAYERS[player:GetAccountID()] = nil
    end

    -- Add the player to the list of current players
    CURRENT_PLAYERS[player:GetAccountID()] = new_character

    print("New character spawned for player: " .. player:GetName())
end

-- Subscribes to an Event which is triggered when Players join the server (i.e. Spawn)
Player.Subscribe("Spawn", SpawnCharacter)

-- Iterates for all already connected players and give them a Character as well
-- This will make sure you also get a Character when you reload the package
Package.Subscribe("Load", function()
    for k, player in pairs(Player.GetAll()) do
        SpawnCharacter(player)
    end
end)

-- When Player leaves the server, destroy it's Character
Player.Subscribe("Destroy", function(player)
    local character = player:GetControlledCharacter()
    if (character) then
        character:Destroy()
    end

    --Check if the player is in the list before removing
    if CURRENT_PLAYERS[player:GetAccountID()] then
        -- Remove the player from the list of current players
        CURRENT_PLAYERS[player:GetAccountID()] = nil
    end
end)
