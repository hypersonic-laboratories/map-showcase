Admin = {}

-- Function to check if a player is a developer based on player name
function Admin.IsDev(player)
    local ply_name = player:GetAccountName()
    local isDev = false

    for k, v in pairs(Config.Admins) do
        if v == ply_name then
            isDev = true
            break
        end
    end

    return isDev
end

-- Function to add a player to the list of admins based on player name
function Admin.AddDev(player)
    local ply_name = player:GetAccountName()
    table.insert(Config.Admins, ply_name)
    -- pending / save to database
end

-- Function to remove a player from the list of admins based on player name
function Admin.RemoveDev(player)
    local ply_name = player:GetAccountName()
    for i, v in ipairs(Config.Admins) do
        if v == ply_name then
            table.remove(Config.Admins, i)
            break
        end
    end
    -- pending / remove from database
end
