local CameraManager = {
    camera_mode = false,
    ui_state = false,
    view_mode = false,
    web_ui = WebUI("CameraManager", "file:///UI/index.html"),
    current_camera = 0,
    cameras = {}
}

-- Initialize camera manager
function CameraManager.Initialize()
    Input.SetMouseEnabled(false)
    CameraManager.UpdateHotkeys()
    CameraManager.ToggleCameraMenu()
end

-- Default hotkeys configuration
local default_hotkeys = {
    { key = "1", actionName = "Enter FreeCam" },
    { key = "G", actionName = "Toggle Menu" },
}

-- Update hotkeys configuration
function CameraManager.UpdateHotkeys(hotkeys)
    CameraManager.web_ui:CallEvent("SetHotkeys", hotkeys or default_hotkeys)
end

-- Input management
function CameraManager.HandleKeyDown(key_name)
    local actions = {
        One = function() CameraManager.EnterCameraMode() end,
        Two = function() CameraManager.ExitCameraMode() end,
        F = function() CameraManager.CreateCamera() end,
        G = function() CameraManager.ToggleCameraMenu() end,
        E = function() CameraManager.ExitViewMode() end,
        Left = function() CameraManager.SwitchCamera(-1) end,
        Right = function() CameraManager.SwitchCamera(1) end
    }

    if actions[key_name] then
        actions[key_name]()
    end
end

Input.Subscribe("KeyDown", function(key_name, delta)
    CameraManager.HandleKeyDown(key_name)
end)

-- Camera Mode Operations
function CameraManager.EnterCameraMode()
    Events.CallRemote("EnterPlacingCameraMode")
    CameraManager.camera_mode = true
    CameraManager.UpdateHotkeys({
        { key = "2", actionName = "Exit FreeCam" },
        { key = "G", actionName = "Toggle Menu" },
        { key = "F", actionName = "Create Camera" },
    })
end

function CameraManager.ExitCameraMode()
    Events.CallRemote("LeavePlacingCameraMode")
    CameraManager.camera_mode = false
    CameraManager.UpdateHotkeys()
end

function CameraManager.CreateCamera()
    if CameraManager.camera_mode then
        local player = Client.GetLocalPlayer()
        local location = player:GetCameraLocation()
        local rotation = player:GetCameraRotation()
        Events.CallRemote("CreateCamera", location, rotation)
        Input.SetInputEnabled(false)
        PostProcess.SetExposure(5)

        Timer.SetTimeout(function()
            PostProcess.SetExposure(0)
            Input.SetInputEnabled(true)
            Events.CallRemote("StopWatchingCameras")
            CameraManager.UpdateHotkeys()
        end, 3500)
    end
end

-- UI Management
function CameraManager.ToggleCameraMenu()
    if not CameraManager.ui_state then
        Events.CallRemote("GetAllCameras")
    else
        Input.SetMouseEnabled(false)
        CameraManager.web_ui:CallEvent("ToggleCameraMonitor", false)
        CameraManager.ui_state = false
    end
end

function CameraManager.ExitViewMode()
    if CameraManager.view_mode then
        CameraManager.view_mode = false
        Input.SetInputEnabled(true)
        Events.CallRemote("StopWatchingCameras")
        CameraManager.UpdateHotkeys()
    end
end

function CameraManager.SwitchCamera(direction)
    local new_index = CameraManager.current_camera + direction
    new_index = math.max(1, math.min(new_index, #CameraManager.cameras))
    Events.CallRemote("StartWatchingCameras", new_index)
end

-- Handle camera selection and viewing mode
CameraManager.web_ui:Subscribe("CameraClicked", function(camera)
    CameraManager.view_mode = true
    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(false)
    CameraManager.UpdateHotkeys({
        { key = "←", actionName = "Previous Camera" },
        { key = "→", actionName = "Next Camera" },
        { key = "E", actionName = "Exit Camera View" },
    })

    Events.CallRemote("StartWatchingCameras", camera)
    CameraManager.current_camera = camera
    CameraManager.ui_state = false
    CameraManager.web_ui:CallEvent("ToggleCameraMonitor", false)
end)

-- Function to capture and send camera screenshots
function ScreenCapture(location, rotation, camera_id)
    local scene_capture = SceneCapture(location, rotation, 1920, 1080, 0.033, 50000, 90, false)

    Timer.SetTimeout(function()
        scene_capture:SetFreeze(true)
        local screeny = scene_capture:EncodeToBase64(0)
        Events.CallRemote('Camera:SaveIMG', screeny, camera_id)
        scene_capture:Destroy()
    end, 2500)
end

-- Subscription to create a screen capture of a specific camera
Events.SubscribeRemote("CreateCameraScreenCapture", function(camera)
    if camera then
        ScreenCapture(camera.location, camera.rotation, camera.id)
    end
end)

-- Function to display notifications via the web UI
Events.SubscribeRemote("SendNotification", function(type, title, text)
    CameraManager.web_ui:CallEvent("ShowNotification", type, title, text)
end)

-- Handle the reception of camera data and UI update
Events.SubscribeRemote("OpenCameraUI", function(cameras)
    CameraManager.cameras = cameras
    for _, camera in pairs(cameras) do
        CameraManager.web_ui:CallEvent("AddCamera", {
            id = camera.id,
            name = camera.name,
            location = tostring(camera.location),
            rotation = tostring(camera.rotation),
            img = camera.img
        })
    end
    CameraManager.web_ui:CallEvent("ToggleCameraMonitor", true)
    CameraManager.ui_state = true
    Input.SetMouseEnabled(true)
end)

-- Initialize Camera Manager
CameraManager.Initialize()
