-- CameraManager Module
local CameraManager = {
    freecam_mode = false,
    ui_state = false,
    cinematic_mode = false,
    web_ui = WebUI("CameraManager", "file:///UI/index.html"),
    current_camera = 1,
    ui_visibility = 1,
    cinematic_timer = nil,
    default_hotkeys = {},
    taking_screenshot = false,
    active_hotkeys = {},
    cameras = {},
    current_FOV_multiplier = 1.0
}

---- [Initialization Functions] ----

-- Initialize camera manager
-- Sets up initial state, default hotkeys, and updates the hotkeys configuration.
function CameraManager.Initialize()
    Input.SetMouseEnabled(false)
    CameraManager.default_hotkeys = Config.EnableFreeCamera and {
        { key = "F", actionName = "Toggle FreeCam Mode" },
        { key = "C", actionName = "Enter Cinematic Mode" },
        { key = "G", actionName = "Toggle Menu" },
        { key = "U", actionName = "Toggle UI" },
    } or {
        { key = "C", actionName = "Enter Cinematic Mode" },
        { key = "G", actionName = "Toggle Menu" },
        { key = "U", actionName = "Toggle UI" },
    }
    CameraManager.UpdateHotkeys()
end

-- Update hotkeys configuration
-- @param hotkeys Table of hotkeys to update, defaults to CameraManager.default_hotkeys
function CameraManager.UpdateHotkeys(hotkeys)
    CameraManager.web_ui:CallEvent("SetHotkeys", hotkeys or CameraManager.default_hotkeys)
    CameraManager.active_hotkeys = {}
    for _, hotkey in ipairs(hotkeys or CameraManager.default_hotkeys) do
        CameraManager.active_hotkeys[hotkey.key] = true
    end
end

---- [Input Management Functions] ----

-- Handle key down events
-- @param key_name The name of the key pressed
function CameraManager.HandleKeyDown(key_name)
    if not CameraManager.active_hotkeys[key_name] then
        return
    end

    local actions = {
        F = function() CameraManager.ToggleFreeCamMode() end,
        C = function() CameraManager.ToggleCinematicMode() end,
        H = function() CameraManager.CreateCamera() end,
        G = function() CameraManager.ToggleCameraMenu() end,
        A = function() CameraManager.SwitchCamera(-1) end,
        D = function() CameraManager.SwitchCamera(1) end,
        E = function() CameraManager.ExitCameraView(false) end,
        Q = function() CameraManager.MoveDown() end,
        R = function() CameraManager.ExitCameraView(true) end,
        U = function() CameraManager.ToggleAllUI() end,
        SHIFT = function() CameraManager.SetSpeedMultiplier(5) end,
    }

    if actions[key_name] then
        local status, err = pcall(actions[key_name])
        if not status then
            print("Error handling key down: ", err)
        end
    end
end

-- Handle KeyDown events
Input.Subscribe("KeyDown", function(key_name, delta)
    CameraManager.HandleKeyDown(key_name)
end)

-- Handle KeyUp events & Execute actions for Q and E keys
Input.Subscribe("KeyUp", function(key_name, delta)
    if key_name == "Q" and CameraManager.freecam_mode then
        Input.InputKey("LeftControl", 1)
    elseif key_name == "E" and CameraManager.freecam_mode then
        Input.InputKey("SpaceBar", 1)
    end
end)

---- [Camera Management Functions] ----

-- Toggle FreeCam mode
function CameraManager.ToggleFreeCamMode()
    if not Config.EnableFreeCamera then
        return
    end

    if CameraManager.freecam_mode then
        Events.CallRemote("LeavePlacingCameraMode")
        Events.CallRemote("ToggleNoClip", false, false)
        Input.SetInputEnabled(true)
        CameraManager.freecam_mode = false
        CameraManager.UpdateHotkeys()
    else
        TriggerCallback('player:IsAdmin', function(is_admin)
            if is_admin then
                Events.CallRemote("ToggleNoClip", true, true)
                CameraManager.freecam_mode = true
                CameraManager.UpdateHotkeys({
                    { key = "F",             actionName = "Toggle FreeCam Mode" },
                    { key = "Q",             actionName = "Move Down" },
                    { key = "E",             actionName = "Move UP" },
                    { key = "H",             actionName = "Create Camera" },
                    { key = "U",             actionName = "Toggle UI" },
                    { key = "MouseScrollUp", actionName = "Zoom" },
                })
            else
                Events.CallRemote("ToggleNoClip", true, true)
                CameraManager.freecam_mode = true
                CameraManager.UpdateHotkeys({
                    { key = "F",             actionName = "Toggle FreeCam Mode" },
                    { key = "U",             actionName = "Toggle UI" },
                    { key = "MouseScrollUp", actionName = "Zoom" },
                })
            end
        end)

        if CameraManager.ui_state then
            CameraManager.CloseUI()
        end
    end
end

-- Toggle UI visibility
function CameraManager.ToggleAllUI()
    CameraManager.ui_visibility = 1 - CameraManager.ui_visibility
    CameraManager.web_ui:SetVisibility(CameraManager.ui_visibility)
end

-- Create a camera at the player's location
function CameraManager.CreateCamera()
    TriggerCallback('player:IsAdmin', function(is_admin)
        if is_admin and CameraManager.freecam_mode and not CameraManager.taking_screenshot then
            local player = Client.GetLocalPlayer()
            local player_location = player:GetCameraLocation()
            local player_rotation = player:GetCameraRotation()
            Events.CallRemote("CreateCamera", player_location, player_rotation, CameraManager.current_FOV_multiplier)
            PostProcess.SetExposure(5)
            CameraManager.DisableInput()
            CameraManager.taking_screenshot = true
            Timer.SetTimeout(function()
                PostProcess.SetExposure(0)
                Input.SetInputEnabled(true)
            end, 3500)
        end
    end)
end

-- Toggle camera menu
function CameraManager.ToggleCameraMenu()
    if not CameraManager.ui_state then
        Events.CallRemote("GetAllCameras")
    else
        CameraManager.CloseUI()
    end
end

-- Switch camera view
-- @param direction The direction to switch camera (-1 for previous, 1 for next)
function CameraManager.SwitchCamera(direction)
    if not CameraManager.cinematic_mode or #CameraManager.cameras == 0 then return end

    CameraManager.SwitchCameraLogic(direction)
end

function CameraManager.MoveDown()
    if not CameraManager.freecam_mode then return end
    Input.InputKey("LeftControl", 0)
end

-- Logic to switch camera
-- @param direction The direction to switch camera (-1 for previous, 1 for next)
function CameraManager.SwitchCameraLogic(direction)
    local current_index = nil
    for index, camera in ipairs(CameraManager.cameras) do
        if camera.id == CameraManager.current_camera then
            current_index = index
            break
        end
    end

    if not current_index then
        print("Current camera not found.")
        return
    end

    local new_index = current_index + direction
    if new_index > #CameraManager.cameras then
        new_index = 1
    elseif new_index < 1 then
        new_index = #CameraManager.cameras
    end

    CameraManager.current_camera = CameraManager.cameras[new_index].id
    local status, err = pcall(Events.CallRemote, "WatchCamera", CameraManager.current_camera)
    if not status then
        print("Error switching camera: ", err)
    end
    CameraManager.DisableInput()
end

-- Check if a camera ID is valid
-- @param id The camera ID to check
-- @return true if the camera ID is valid, false otherwise
function CameraManager.IsValidCamera(id)
    for _, camera in pairs(CameraManager.cameras) do
        if camera.id == id then
            return true
        end
    end
    return false
end

-- Handle camera selection
CameraManager.web_ui:Subscribe("CameraClicked", function(camera)
    CameraManager.cinematic_mode = true
    CameraManager.freecam_mode = false
    CameraManager.ui_mode = true
    CameraManager.UpdateHotkeys({
        { key = "A", actionName = "Previous Camera" },
        { key = "D", actionName = "Next Camera" },
        { key = "U", actionName = "Toggle UI" },
        { key = "E", actionName = "Spawn Here" },
        { key = "R", actionName = "Go Back" },
    })

    local status, err = pcall(Events.CallRemote, "WatchCamera", camera)
    if not status then
        print("Error watching camera: ", err)
    end
    CameraManager.current_camera = camera
    CameraManager.CloseUI()
    CameraManager.DisableInput()
end)

-- Handle camera removal
CameraManager.web_ui:Subscribe("CameraRemoved", function(camera_id)
    if camera_id then
        local status, err = pcall(Events.CallRemote, "RemoveCamera", camera_id)
        if not status then
            print("Error removing camera: ", err)
        end
    end
end)

-- Disable input for a short period
function CameraManager.DisableInput()
    Timer.SetTimeout(function()
        Input.SetInputEnabled(false)
    end, 40)
end

-- Exit camera view mode
-- @param relocate Whether to relocate the player after exiting camera view
function CameraManager.ExitCameraView(relocate)
    if CameraManager.taking_screenshot then return end
    if CameraManager.cinematic_mode then
        CameraManager.ToggleCinematicMode(relocate)
        if CameraManager.ui_mode then
            CameraManager.ui_mode = false
            CameraManager.OpenUI(CameraManager.cameras)
        end
    elseif CameraManager.freecam_mode then
        Input.InputKey("SpaceBar", 0)
    end
end

-- Capture and send camera screenshots
-- @param location The location of the screenshot
-- @param rotation The rotation of the screenshot
-- @param camera_id The ID of the camera
function ScreenCapture(location, rotation, camera_id)
    local scene_capture = SceneCapture(location, rotation, 1024, 1024, 0.033, 50000, 90, false)
    Timer.SetTimeout(function()
        scene_capture:SetFreeze(true)
        local screeny = scene_capture:EncodeToBase64(0)
        local status, err = pcall(Events.CallRemote, 'Camera:SaveIMG', screeny, camera_id)
        if not status then
            print("Error saving camera image: ", err)
        end
        CameraManager.taking_screenshot = false
        scene_capture:Destroy()
    end, 2500)
end

-- Toggle cinematic mode
-- @param relocate Whether to relocate the player after toggling cinematic mode
function CameraManager.ToggleCinematicMode(relocate)
    if #CameraManager.cameras <= 0 then
        CameraManager.web_ui:CallEvent("ShowNotification", "warning", "warning", "No cameras available")
        return
    end
    if CameraManager.cinematic_mode then
        relocate = relocate or false
        CameraManager.cinematic_mode = false
        local status, err = pcall(Events.CallRemote, "StopWatchingCameras", relocate)
        if not status then
            print("Error stopping watching cameras: ", err)
        end
        Input.SetInputEnabled(true)
        CameraManager.UpdateHotkeys()
    else
        CameraManager.cinematic_mode = true
        CameraManager.UpdateHotkeys({
            { key = "A", actionName = "Previous Camera" },
            { key = "D", actionName = "Next Camera" },
            { key = "U", actionName = "Toggle UI" },
            { key = "E", actionName = "Spawn Here" },
            { key = "R", actionName = "Go Back " },
        })

        if CameraManager.ui_state then
            CameraManager.CloseUI()
        end

        local first_camera = CameraManager.cameras[1].id
        local status, err = pcall(Events.CallRemote, "WatchCamera", first_camera)
        if not status then
            print("Error watching camera: ", err)
        end
        CameraManager.current_camera = first_camera
        CameraManager.DisableInput()
    end
end

-- Close UI
function CameraManager.CloseUI()
    CameraManager.ui_state = false
    CameraManager.web_ui:CallEvent("ToggleCameraMonitor", false)
    Input.SetMouseEnabled(false)
end

---- [Utility Functions] ----

-- Subscribe to create a screen capture
Events.SubscribeRemote("CreateCameraScreenCapture", function(camera)
    if camera then
        ScreenCapture(camera.location, camera.rotation, camera.id)
    end
end)

-- Display notifications via web UI
Events.SubscribeRemote("SendNotification", function(type, title, text)
    CameraManager.web_ui:CallEvent("ShowNotification", type, title, text)
end)

-- Handle mouse scroll for FOV adjustment // REMOVED FOR NOW DUE TO BUGS
-- Input.Subscribe("MouseScroll", function(mouse_x, mouse_y, delta)
--     if CameraManager.freecam_mode then
--         local clamped_delta = math.max(-1, math.min(1, delta))
--         clamped_delta = -clamped_delta
--         local new_FOV = CameraManager.current_FOV_multiplier + (0.1 * clamped_delta)
--         CameraManager.current_FOV_multiplier = math.max(0.1, math.min(1.3, new_FOV))

--         local status, err = pcall(Events.CallRemote, "SetFOVMultiplier", CameraManager.current_FOV_multiplier)
--         if not status then
--             print("Error setting FOV multiplier: ", err)
--         end
--     end
-- end)

-- Handle the reception of camera data and UI update
Events.SubscribeRemote("OpenCameraUI", function(cameras)
    CameraManager.OpenUI(cameras)
end)

-- Open UI with camera data
-- @param cameras Table containing camera data
function CameraManager.OpenUI(cameras)
    for _, camera in pairs(cameras) do
        CameraManager.web_ui:CallEvent("AddCamera", {
            id = camera.id,
            name = camera.name,
            location = tostring(camera.location),
            rotation = tostring(camera.rotation),
            img = camera.img
        })
    end

    TriggerCallback('player:IsAdmin', function(is_admin)
        if is_admin then
            CameraManager.web_ui:CallEvent("AdminPermission", true)
        end
    end)

    CameraManager.web_ui:CallEvent("ToggleCameraMonitor", true)
    CameraManager.ui_state = true
    Input.SetMouseEnabled(true)
end

-- Update camera data
Events.SubscribeRemote("UpdateCameras", function(cameras)
    CameraManager.cameras = cameras
end)

-- Initialize Camera Manager
local status, err = pcall(CameraManager.Initialize)
if not status then
    print("Error initializing CameraManager: ", err)
end
