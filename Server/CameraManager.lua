-- CameraManager module
local CameraManager = {}

-- Initialization function when the package is loaded
Package.Subscribe("Load", function()
    CameraManager.Initialize()
end)

-- Initialize the CameraManager module
function CameraManager.Initialize()
    CameraManager.cameras = {}
    CameraManager.SubscribeEvents()
end

-- Subscribe to remote events
function CameraManager.SubscribeEvents()
    -- Enter placing camera mode for a player
    Events.SubscribeRemote("EnterPlacingCameraMode", function(player)
        CameraManager.EnterPlacingCameraMode(player)
    end)

    -- Leave placing camera mode for a player
    Events.SubscribeRemote("LeavePlacingCameraMode", function(player)
        CameraManager.LeavePlacingCameraMode(player)
    end)

    -- Create a camera for a player at a specific location and rotation
    Events.SubscribeRemote("CreateCamera", function(player, location, rotation)
        CameraManager.CreateCamera(player, location, rotation)
    end)

    -- Get all cameras for a player
    Events.SubscribeRemote("GetAllCameras", function(player)
        CameraManager.GetAllCameras(player)
    end)

    -- Start watching cameras for a player with a specific camera ID
    Events.SubscribeRemote("StartWatchingCameras", function(player, cameraId)
        CameraManager.StartWatchingCameras(player, cameraId)
    end)

    -- Stop watching cameras for a player
    Events.SubscribeRemote("StopWatchingCameras", function(player)
        CameraManager.StopWatchingCameras(player)
    end)

    -- Save a camera image for a player with a specific screeny and camera ID
    Events.SubscribeRemote('Camera:SaveIMG', function(player, screeny, cameraId)
        CameraManager.SaveCameraImage(player, screeny, cameraId)
    end)
end

-- Add a camera to the CameraManager
function CameraManager.AddCamera(player, id, name, location, rotation)
    local camera = {
        id = id,
        name = name,
        location = location,
        rotation = rotation
    }
    table.insert(CameraManager.cameras, camera)
    Events.CallRemote("CreateCameraScreenCapture", player, camera)
end

-- Remove a camera from the CameraManager
function CameraManager.RemoveCamera(id)
    for i, camera in ipairs(CameraManager.cameras) do
        if camera.id == id then
            table.remove(CameraManager.cameras, i)
            break
        end
    end
end

-- Get a camera from the CameraManager by ID
function CameraManager.GetCamera(id)
    for _, camera in ipairs(CameraManager.cameras) do
        if camera.id == id then
            return camera
        end
    end
    return nil
end

-- Enter placing camera mode for a player
function CameraManager.EnterPlacingCameraMode(player)
    local player_character = player:GetControlledCharacter()
    if player_character then
        player:UnPossess()
    end
end

-- Leave placing camera mode for a player
function CameraManager.LeavePlacingCameraMode(player)
    local player_character = CURRENT_PLAYERS[player:GetAccountID()]
    if player_character then
        player:Possess(player_character)
    end
end

-- Create a camera for a player at a specific location and rotation
function CameraManager.CreateCamera(player, location, rotation)
    if not location or not rotation then
        error("Location or rotation is missing")
        return
    end
    local name = "Camera " .. #CameraManager.cameras + 1
    CameraManager.AddCamera(player, #CameraManager.cameras + 1, name, location, rotation)
end

-- Get all cameras for a player
function CameraManager.GetAllCameras(player)
    if #CameraManager.cameras > 0 then
        Events.CallRemote("OpenCameraUI", player, CameraManager.cameras)
    else
        Events.CallRemote("OpenCameraUI", player, {})
    end
end

-- Start watching cameras for a player with a specific camera ID
function CameraManager.StartWatchingCameras(player, cameraId)
    local camera = CameraManager.GetCamera(cameraId)
    if camera then
        player:UnPossess()
        player:SetCameraLocation(camera.location)
        player:SetCameraRotation(camera.rotation)
    else
        error("Camera not found")
    end
end

-- Stop watching cameras for a player
function CameraManager.StopWatchingCameras(player)
    player:Possess(CURRENT_PLAYERS[player:GetAccountID()])
end

-- Save a camera image for a player with a specific screeny and camera ID
function CameraManager.SaveCameraImage(player, screeny, cameraId)
    local header = {
        Authorization = 'aPQEfZkJ3DtKH5Vs^B6c42S6PaJsjK^MP$v6VrxYXsDG9hEJ'
    }

    HTTP.RequestAsync("https://api.helix-cdn.com", "/pco-cache/", "PUT", screeny, "text/plain", false, header,
        function(status, data)
            local parsed_data = JSON.parse(data)
            local imgURL = parsed_data.url
            if imgURL then
                screeny = imgURL
            end
            for k, v in pairs(CameraManager.cameras) do
                if v.id == cameraId then
                    v.img = screeny
                    Events.CallRemote("SendNotification", player, "success", "success", "Camera created successfully!")
                    break
                end
            end
        end)
end
