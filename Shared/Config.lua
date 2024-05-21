Config = {}

Config.UsingHUB = false  -- Set to true if you are hosting this on the HUB and using an SQL database, false if hosting on your own server using MySQL database
Config.UseBlackScreen = true  -- Set to true if you want to use a black screen when switching cameras (recommended)
Config.SpawnPoint = Vector(6130, -1698, -209) -- The spawn point for players when they join the server

Config.Devs = { -- List of developer account names
    "HelixKravs",
}
Config.EnableFreeCamera = true -- Set to true if you want to enable free camera mode for users

-- Local Database configurations (used when not UsingHUB)
Config.LocalDB = {
    IP = "127.0.0.1",
    PORT = "3306",
    USER = "root",
    NAME = "cameras"
}