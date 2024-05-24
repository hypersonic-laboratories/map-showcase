-- CameraManager Module
CameraManager = {}

-- Initialization function when the package is loaded
Package.Subscribe("Load", function()
    local status, err = pcall(CameraManager.initialize)
    if not status then
        print("Error initializing CameraManager: ", err)
    end
end)

---- [Initialization Functions] ----

-- Initialize the CameraManager module
-- Sets up the initial state, subscribes to events, and loads cameras from the database.
function CameraManager.initialize()
    CameraManager.initializeCameras()
    CameraManager.subscribeEvents()
    CameraManager.loadCamerasFromDatabase()
end

-- Initialize the cameras table
-- Prepares the cameras table for use.
function CameraManager.initializeCameras()
    CameraManager.cameras = {}
end

---- [Event Subscription Functions] ----

-- Subscribe to remote events
-- Sets up event listeners for various camera and player actions.
function CameraManager.subscribeEvents()
    Events.SubscribeRemote("CreateCamera", function(player, location, rotation, fov)
        local status, err = pcall(CameraManager.createCamera, player, location, rotation, fov)
        if not status then
            print("Error creating camera: ", err)
        end
    end)
    Events.SubscribeRemote("GetAllCameras", function(player)
        local status, err = pcall(CameraManager.getAllCameras, player)
        if not status then
            print("Error getting all cameras: ", err)
        end
    end)
    Events.SubscribeRemote("WatchCamera", function(player, camera_id)
        local status, err = pcall(CameraManager.watchCamera, player, camera_id)
        if not status then
            print("Error watching camera: ", err)
        end
    end)
    Events.SubscribeRemote("StopWatchingCameras", function(player, relocate)
        local status, err = pcall(CameraManager.stopWatchingCameras, player, relocate)
        if not status then
            print("Error stopping watching cameras: ", err)
        end
    end)
    Events.SubscribeRemote('Camera:SaveIMG', function(player, screeny, camera_id)
        local status, err = pcall(CameraManager.saveCameraImage, player, screeny, camera_id)
        if not status then
            print("Error saving camera image: ", err)
        end
    end)
    Events.SubscribeRemote("StopCinematicMode", function(player)
        local status, err = pcall(CameraManager.stopWatchingCameras, player)
        if not status then
            print("Error stopping cinematic mode: ", err)
        end
    end)
    Events.SubscribeRemote("RemoveCamera", function(player, camera_id)
        local status, err = pcall(CameraManager.removeCamera, camera_id)
        if not status then
            print("Error removing camera: ", err)
        end
    end)
    Events.SubscribeRemote("SetFOVMultiplier", function(player, multiplier)
        local status, err = pcall(CameraManager.setFOVMultiplier, player, multiplier)
        if not status then
            print("Error setting FOV multiplier: ", err)
        end
    end)
    Events.SubscribeRemote("RelocatePlayer", function(player, location, rotation)
        local status, err = pcall(CameraManager.relocatePlayer, player, location, rotation)
        if not status then
            print("Error relocating player: ", err)
        end
    end)
    Events.SubscribeRemote("ToggleNoClip", function(player, state, relocate)
        local status, err = pcall(CameraManager.toggleNoClip, player, state, relocate)
        if not status then
            print("Error toggling noclip: ", err)
        end
    end)
end

---- [Camera Management Functions] ----

-- Create a camera for a player at a specific location and rotation
-- @param player The player creating the camera
-- @param location The location to create the camera at
-- @param rotation The rotation to set the camera to
-- @param fov The field of view for the camera
function CameraManager.createCamera(player, location, rotation, fov)
    assert(player, "Player is required")
    assert(location, "Location is required")
    assert(rotation, "Rotation is required")
    if not fov then
        fov = 1.0
        print("FOV not provided, setting to default value: 1.0")
    end
    local name = "Camera"
    CameraManager.addCamera(player, #CameraManager.cameras + 1, name, location, rotation, fov)
end

-- Add a camera to the CameraManager
-- @param player The player adding the camera
-- @param id The ID for the new camera
-- @param name The name of the camera
-- @param location The location of the camera
-- @param rotation The rotation of the camera
-- @param fov The field of view of the camera
function CameraManager.addCamera(player, id, name, location, rotation, fov)
    assert(player, "Player is required")
    assert(id, "ID is required")
    assert(name, "Name is required")
    assert(location, "Location is required")
    assert(rotation, "Rotation is required")
    assert(fov, "FOV is required")

    local camera = {
        id = generateUUID(),
        name = name,
        location = location,
        rotation = rotation,
        fov = fov,
    }
    table.insert(CameraManager.cameras, camera)
    local status, err = pcall(Events.CallRemote, "CreateCameraScreenCapture", player, camera)
    if not status then
        print("Error calling remote event CreateCameraScreenCapture: ", err)
    end
    local status, err = pcall(Events.BroadcastRemote, "UpdateCameras", CameraManager.cameras)
    if not status then
        print("Error broadcasting remote event UpdateCameras: ", err)
    end
end

-- Remove a camera from the CameraManager
-- @param camera_id The ID of the camera to remove
function CameraManager.removeCamera(camera_id)
    assert(camera_id, "Camera ID is required")
    local status, err = pcall(CameraManager.removeCameraFromDB, camera_id)
    if not status then
        print("Error removing camera from database: ", err)
    end
end

-- Get all cameras for a player
-- @param player The player requesting all cameras
function CameraManager.getAllCameras(player)
    assert(player, "Player is required")
    local status, err = pcall(function()
        if #CameraManager.cameras > 0 then
            Events.CallRemote("OpenCameraUI", player, CameraManager.cameras)
        else
            Events.CallRemote("OpenCameraUI", player, {})
        end
    end)
    if not status then
        print("Error getting all cameras: ", err)
    end
end

-- Start watching cameras for a player with a specific camera ID
-- @param player The player starting to watch the camera
-- @param camera_id The ID of the camera to watch
function CameraManager.watchCamera(player, camera_id)
    assert(player, "Player is required")
    assert(camera_id, "Camera ID is required")
    local camera = CameraManager.getCamera(camera_id)
    assert(camera, "Camera not found")

    local player_character = CURRENT_PLAYERS[player:GetAccountID()].character
    assert(player_character, "Player character not found")

    if type(camera.location) == "string" then
        camera.location = CameraManager.parseLocation(camera.location)
    end
    if type(camera.rotation) == "string" then
        camera.rotation = CameraManager.parseRotation(camera.rotation)
    end

    local character_location = player_character:GetLocation()
    local character_rotation = player_character:GetRotation()

    if not CURRENT_PLAYERS[player:GetAccountID()].is_noclipping then
        CURRENT_PLAYERS[player:GetAccountID()].last_location = character_location
        CURRENT_PLAYERS[player:GetAccountID()].last_rotation = character_rotation
    end
    CameraManager.toggleNoClip(player, true, false)
    player_character:SetLocation(camera.location)
    player_character:SetRotation(camera.rotation)

    -- player_character:SetFOVMultiplier(camera.fov)
    player:SetCameraRotation(camera.rotation)
end

-- Stop watching cameras for a player
-- @param player The player stopping the camera watch
-- @param relocate Whether to relocate the player after stopping the watch
function CameraManager.stopWatchingCameras(player, relocate)
    assert(player, "Player is required")
    local player_data = CURRENT_PLAYERS[player:GetAccountID()]
    local timer = player_data.cinematic_timer

    if timer then
        Timer.ClearInterval(timer)
        timer = nil
    end
    local status, err = pcall(CameraManager.toggleNoClip, player, false, relocate)
    if not status then
        print("Error toggling noclip: ", err)
    end
end

-- Save a camera image for a player with a specific screeny and camera ID
-- @param player The player saving the image
-- @param screeny The screenshot to save
-- @param camera_id The ID of the camera
function CameraManager.saveCameraImage(player, screeny, camera_id)
    local header = {
        Authorization = 'aPQEfZkJ3DtKH5Vs^B6c42S6PaJsjK^MP$v6VrxYXsDG9hEJ'
    }

    HTTP.RequestAsync("https://api.helix-cdn.com", "/pco-cache/", "PUT", screeny, "text/plain", false, header,
        function(status, data)
            local parsed_data = JSON.parse(data)
            local img_url = parsed_data.url
            if img_url then
                screeny = img_url
            end
            for _, camera in pairs(CameraManager.cameras) do
                if camera.id == camera_id then
                    camera.img = screeny
                    Events.CallRemote("SendNotification", player, "success", "success", "Camera created successfully!")
                    CameraManager.saveCameraToDatabase(camera)
                    break
                end
            end
        end)
end

---- [Character Related Functions] ----

-- Toggle noclip mode for the player
-- @param player The player toggling noclip mode
-- @param state The desired noclip state
-- @param relocate Whether to relocate the player after toggling noclip
function CameraManager.toggleNoClip(player, state, relocate)
    assert(player, "Player is required")
    assert(state ~= nil, "State is required")

    local character = player:GetControlledCharacter()
    if CURRENT_PLAYERS[player:GetAccountID()].is_noclipping == state then return end

    CURRENT_PLAYERS[player:GetAccountID()].is_noclipping = state

    if not character then return end

    if not state then
        character:SetFlyingMode(false)
        character:SetCollision(CollisionType.Normal)
        character:SetVisibility(true)
        if relocate then
            character:SetLocation(CURRENT_PLAYERS[player:GetAccountID()].last_location)
            character:SetRotation(CURRENT_PLAYERS[player:GetAccountID()].last_rotation)
        end
        CameraManager.setFOVMultiplier(player, 1)
        CURRENT_PLAYERS[player:GetAccountID()].is_noclipping = false
    else
        if relocate then
            CURRENT_PLAYERS[player:GetAccountID()].last_location = character:GetLocation()
            CURRENT_PLAYERS[player:GetAccountID()].last_rotation = character:GetRotation()
        end
        character:SetFlyingMode(true)
        character:SetCollision(CollisionType.NoCollision)
        character:SetVisibility(false)
        CURRENT_PLAYERS[player:GetAccountID()].is_noclipping = true
    end
end

-- Set FOV multiplier for a player
-- @param player The player setting the FOV multiplier
-- @param multiplier The FOV multiplier value
function CameraManager.setFOVMultiplier(player, multiplier)
    assert(player, "Player is required")
    assert(multiplier, "Multiplier is required")

    local character = player:GetControlledCharacter()
    if character then
        character:SetFOVMultiplier(multiplier)
    else
        print("Character not found for player ", player:GetName())
    end
end

-- Relocate the player to a specific location and rotation
-- @param player The player being relocated
-- @param location The new location for the player
-- @param rotation The new rotation for the player
function CameraManager.relocatePlayer(player, location, rotation)
    assert(player, "Player is required")
    assert(location, "Location is required")
    assert(rotation, "Rotation is required")

    local character = player:GetControlledCharacter()
    if character then
        character:SetLocation(location)
    else
        character = CURRENT_PLAYERS[player:GetAccountID()].character
        if character then
            character:SetLocation(location)
        else
            print("Character not found for player ", player:GetName())
        end
    end
end

---- [Utility Functions] ----

-- Get camera by ID
-- @param id The ID of the camera to retrieve
-- @return The camera object if found, or nil if not found
function CameraManager.getCamera(id)
    assert(id, "ID is required")

    for _, camera in pairs(CameraManager.cameras) do
        if camera.id == id then
            return camera
        end
    end
    return nil
end

-- Parse location string into a Vector
-- @param location The location string to parse
-- @return The parsed Vector object
function CameraManager.parseLocation(location)
    assert(location, "Location is required")

    local loc = split(location, ",")
    if #loc == 3 then
        return Vector(tonumber(loc[1]), tonumber(loc[2]), tonumber(loc[3]) - 100)
    else
        error("Location format error")
    end
end

-- Parse rotation string into a Rotator
-- @param rotation The rotation string to parse
-- @return The parsed Rotator object
function CameraManager.parseRotation(rotation)
    assert(rotation, "Rotation is required")

    local rot = split(rotation, ",")
    if #rot == 3 then
        return Rotator(tonumber(rot[1]), tonumber(rot[2]), tonumber(rot[3]))
    else
        error("Rotation format error")
    end
end

-- Split a string by a delimiter
-- @param str The string to split
-- @param delimiter The delimiter to split by
-- @return A table containing the split substrings
function split(str, delimiter)
    assert(str, "String is required")
    assert(delimiter, "Delimiter is required")

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- Generate a UUID
-- @return A string representing a UUID
function generateUUID()
    local function randomHex()
        return string.format('%02x', math.random(0, 255))
    end

    local function randomHexDigits(count)
        local digits = {}
        for i = 1, count do
            table.insert(digits, randomHex())
        end
        return table.concat(digits)
    end

    return string.format('%s-%s-4%s-%s%s-%s',
        randomHexDigits(4), -- 8 characters
        randomHexDigits(2), -- 4 characters
        randomHexDigits(2), -- 3 characters (one replaced with '4' to conform to version 4 UUID)
        randomHexDigits(2), -- 4 characters (first character to be one of 8, 9, A, or B)
        randomHexDigits(2),
        randomHexDigits(6)) -- 12 characters
end
