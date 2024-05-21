local DB = nil

-- Initialize the database connection
if Config.UsingHUB then
    -- Retrieve database connection details from server custom settings
    local secret = Server.GetCustomSettings()
    local db_ip = secret.DB_IP
    local db_port = secret.DB_PORT
    local db_user = secret.DB_USER
    local db_password = secret.DB_PASSWORD
    local db_name = secret.DB_NAME

    -- Establish connection to PostgreSQL database
    DB = Database(
        DatabaseEngine.PostgreSQL,
        " hostaddr=" .. db_ip ..
        " port=" .. db_port ..
        " user=" .. db_user ..
        " password=" .. db_password ..
        " dbname=" .. db_name
    )

    -- Create cameras table if it doesn't exist
    DB:Execute([[
        CREATE TABLE IF NOT EXISTS cameras (
            id SERIAL PRIMARY KEY,
            uuid VARCHAR(255),
            name VARCHAR(100),
            location VARCHAR(255),
            rotation VARCHAR(255),
            img VARCHAR(255),
            FOV FLOAT
        );
    ]])
else
    -- Retrieve database connection details from local config
    local db_ip = Config.LocalDB.IP
    local db_port = Config.LocalDB.PORT
    local db_user = Config.LocalDB.USER
    local db_password = Config.LocalDB.PASSWORD
    local db_name = Config.LocalDB.NAME

    -- Establish connection to MySQL database
    DB = Database(DatabaseEngine.MySQL, " host=" .. db_ip ..
                  " port=" .. db_port ..
                  " user=" .. db_user ..
                  " dbname=" .. db_name)

    -- Create cameras table if it doesn't exist
    DB:Execute([[
        CREATE TABLE IF NOT EXISTS cameras (
            id INT AUTO_INCREMENT PRIMARY KEY,
            uuid VARCHAR(255),
            name VARCHAR(100),
            location VARCHAR(255),
            rotation VARCHAR(255),
            img VARCHAR(255),
            FOV FLOAT
        );
    ]])

    -- Close the database connection when the package unloads
    Package.Subscribe('Unload', function()
        DB:Close()
    end)
end

-- Load cameras from the database
function CameraManager.loadCamerasFromDatabase()
    local result = DB:Select('SELECT * FROM cameras')
    if result then
        CameraManager.cameras = {}
        for _, camera in ipairs(result) do
            table.insert(CameraManager.cameras, {
                id = camera.uuid,
                name = camera.name,
                location = camera.location,
                rotation = camera.rotation,
                img = camera.img,
                FOV = camera.FOV
            })
        end
        Events.BroadcastRemote("UpdateCameras", CameraManager.cameras)
    else
        print("Failed to load cameras from the database.")
    end
end

-- Save a camera to the database
function CameraManager.saveCameraToDatabase(camera)
    if not camera then
        print("Failed to save camera to the database. No camera provided.")
        return
    end

    local db_location = camera.location.X .. ',' .. camera.location.Y .. ',' .. camera.location.Z
    local db_rotation = camera.rotation.Pitch .. ',' .. camera.rotation.Yaw .. ',' .. camera.rotation.Roll

    local query = 'INSERT INTO cameras (uuid, name, location, rotation, img, FOV) VALUES (:0, :1, :2, :3, :4, :5)'
    local success = DB:Execute(query, camera.id, camera.name, db_location, db_rotation, camera.img, camera.FOV)

    if not success then
        print("Failed to save camera to the database.")
    else
        print("Camera successfully saved to the database.")
    end
end

-- Remove a camera from the database
function CameraManager.removeCameraFromDB(camera_id)
    print('Removing camera from db', camera_id)
    local query = 'DELETE FROM cameras WHERE uuid = :0'
    local success = DB:Execute(query, camera_id)

    if not success then
        print("Failed to remove camera from the database.")
        return
    end

    print("Camera successfully removed from the database.")

    for i, camera in ipairs(CameraManager.cameras) do
        if camera.id == camera_id then
            table.remove(CameraManager.cameras, i)
            break
        end
    end

    Events.BroadcastRemote("UpdateCameras", CameraManager.cameras)
end

-- Export the database object for use in other modules
Package.Export('DB', DB)
