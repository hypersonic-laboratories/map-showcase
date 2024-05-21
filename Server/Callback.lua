local callbacks = {}

function RegisterCallback(name, func)
    callbacks[name] = func
end

function HandleCallback(player, name, id, ...)
    local cb = callbacks[name]
    if cb then
        local result = { cb(player, ...) }
        Events.CallRemote("CallbackResponse:" .. name .. ":" .. id, player, table.unpack(result))
    else
        print("Callback not found: " .. name)
    end
end

function InitCallbackSystem()
    Events.SubscribeRemote("RequestCallback", function(player, name, id, ...)
        HandleCallback(player, name, id, ...)
    end)
end

Package.Subscribe("Load", function()
    InitCallbackSystem()
end)

-- use Example
RegisterCallback('player:IsAdmin', function(player)
    local is_player_admin = Admin.IsDev(player)
    return is_player_admin
end)
