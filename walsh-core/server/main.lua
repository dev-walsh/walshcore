-- Walsh Core Server Main
WalshCore = {}
WalshCore.Players = {}
WalshCore.Player_Buckets = {}
WalshCore.Entity_Buckets = {}
WalshCore.UsableItems = {}
WalshCore.Commands = {}
WalshCore.Callbacks = {}

-- Initialize Walsh Core
local function Initialize()
    if not WalshCore then return end
    
    print("^2[Walsh Core]^7 Initializing Walsh Core Framework...")
    
    -- Set default resource state
    SetConvar('wallet_defaultPrivateKey', 'walsh_core_private_key')
    
    -- Load shared data
    if GetResourceState('walsh-core') == 'started' then
        print("^2[Walsh Core]^7 Framework initialized successfully!")
    end
end

-- Database connection
WalshCore.Debug = function(resource, obj, depth)
    TriggerEvent('walsh:DebugSomething', resource, obj, depth)
end

-- Player Management Functions
WalshCore.Players = {}

WalshCore.GetPlayers = function()
    local sources = {}
    for k, _ in pairs(WalshCore.Players) do
        sources[#sources + 1] = k
    end
    return sources
end

WalshCore.GetPlayersCount = function()
    local count = 0
    for _ in pairs(WalshCore.Players) do
        count = count + 1
    end
    return count
end

WalshCore.GetBucketObjects = function(bucket)
    return WalshCore.Entity_Buckets[bucket]
end

WalshCore.GetPlayerBucket = function(source)
    return WalshCore.Player_Buckets[source]
end

WalshCore.SetPlayerBucket = function(source, bucket)
    if source and bucket then
        SetPlayerRoutingBucket(source, bucket)
        WalshCore.Player_Buckets[source] = bucket
    end
end

WalshCore.SetEntityBucket = function(entity, bucket)
    if entity and bucket then
        SetEntityRoutingBucket(entity, bucket)
        if not WalshCore.Entity_Buckets[bucket] then
            WalshCore.Entity_Buckets[bucket] = {}
        end
        WalshCore.Entity_Buckets[bucket][entity] = true
    end
end

-- Callback System
WalshCore.CreateCallback = function(name, cb)
    WalshCore.Callbacks[name] = cb
end

WalshCore.TriggerCallback = function(name, source, cb, ...)
    if not WalshCore.Callbacks[name] then return end
    WalshCore.Callbacks[name](source, cb, ...)
end

RegisterNetEvent('WalshCore:Server:TriggerCallback', function(name, ...)
    local src = source
    WalshCore.TriggerCallback(name, src, function(...)
        TriggerClientEvent('WalshCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

-- Command System
WalshCore.Commands.Add = function(name, help, arguments, argsrequired, callback, permission, ...)
    local restricted = true
    if permission then restricted = false end
    
    RegisterCommand(name, function(source, args, rawCommand)
        if argsrequired and #args < argsrequired then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Usage: /" .. name .. " " .. help}
            })
            return
        end
        
        if permission and not WalshCore.Functions.HasPermission(source, permission) then
            TriggerClientEvent('WalshCore:Notify', source, 'You don\'t have permission to use this command', 'error')
            return
        end
        
        callback(source, args, rawCommand)
    end, restricted)
    
    if arguments then
        if type(arguments) == "table" then
            for _, v in pairs(arguments) do
                if v.name then
                    RegisterCommand(name .. " " .. v.name, function(source, args, rawCommand)
                        callback(source, args, rawCommand)
                    end, restricted)
                end
            end
        end
    end
end

-- Useable Items
WalshCore.UseableItems = {}

WalshCore.Functions = {}

WalshCore.Functions.CreateUseableItem = function(item, cb)
    WalshCore.UseableItems[item] = cb
end

WalshCore.Functions.CanUseItem = function(item)
    return WalshCore.UseableItems[item] ~= nil
end

WalshCore.Functions.UseItem = function(source, item)
    if WalshCore.UseableItems[item] then
        WalshCore.UseableItems[item](source, item)
    end
end

-- Utility Functions
WalshCore.Functions.GetIdentifier = function(source, idtype)
    local idtype = idtype or WalshCore.IdentifierType
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

WalshCore.Functions.GetSource = function(identifier)
    for src, _ in pairs(WalshCore.Players) do
        local idf = WalshCore.Functions.GetIdentifier(src)
        if idf == identifier then
            return src
        end
    end
    return 0
end

WalshCore.Functions.GetPlayer = function(source)
    if type(source) == 'number' then
        return WalshCore.Players[source]
    else
        return WalshCore.Players[WalshCore.Functions.GetSource(source)]
    end
end

WalshCore.Functions.GetPlayerByPhone = function(number)
    for src, _ in pairs(WalshCore.Players) do
        local player = WalshCore.Functions.GetPlayer(src)
        if player then
            local phone = player.PlayerData.charinfo.phone
            if phone == number then
                return player
            end
        end
    end
    return nil
end

WalshCore.Functions.GetPlayerByCitizenId = function(citizenid)
    for src, _ in pairs(WalshCore.Players) do
        local player = WalshCore.Functions.GetPlayer(src)
        if player and player.PlayerData.citizenid == citizenid then
            return player
        end
    end
    return nil
end

WalshCore.Functions.GetOfflinePlayer = function(citizenid)
    -- Implementation for offline player data
    return {}
end

WalshCore.Functions.GetPlayers = function()
    local sources = {}
    for k, _ in pairs(WalshCore.Players) do
        sources[#sources + 1] = k
    end
    return sources
end

WalshCore.Functions.GetPlayersCount = function()
    return #WalshCore.Functions.GetPlayers()
end

-- Permission System
WalshCore.Functions.HasPermission = function(source, permission)
    local player = WalshCore.Functions.GetPlayer(source)
    if not player then return false end
    
    local steamId = WalshCore.Functions.GetIdentifier(source, 'steam')
    local license = WalshCore.Functions.GetIdentifier(source, 'license')
    
    -- Check for admin permissions
    if permission == 'admin' or permission == 'god' then
        return IsPlayerAceAllowed(source, permission) or 
               IsPlayerAceAllowed(source, 'group.admin') or
               IsPlayerAceAllowed(source, 'group.superadmin')
    end
    
    return IsPlayerAceAllowed(source, permission)
end

WalshCore.Functions.AddPermission = function(source, permission)
    ExecuteCommand('add_ace identifier.license:' .. WalshCore.Functions.GetIdentifier(source) .. ' ' .. permission .. ' allow')
end

WalshCore.Functions.RemovePermission = function(source, permission)
    ExecuteCommand('remove_ace identifier.license:' .. WalshCore.Functions.GetIdentifier(source) .. ' ' .. permission)
end

-- Events
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Initialize()
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local steamId = WalshCore.Functions.GetIdentifier(source, 'steam')
    local license = WalshCore.Functions.GetIdentifier(source, 'license')
    
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking your information...')
    Wait(2000)
    
    if WalshCore.Server.Closed and not WalshCore.Functions.HasPermission(source, WalshCore.Server.Permission) then
        deferrals.done(WalshCore.Server.ClosedReason)
        return
    end
    
    if WalshCore.Server.Whitelist then
        deferrals.update('Checking whitelist...')
        Wait(2000)
        
        if not WalshCore.Functions.HasPermission(source, 'walsh.join') then
            deferrals.done('You are not whitelisted on this server.')
            return
        end
    end
    
    deferrals.update('Welcome to Walsh RP!')
    Wait(1000)
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local player = WalshCore.Functions.GetPlayer(source)
    
    if player then
        player.Functions.Save()
        WalshCore.Player_Buckets[source] = nil
        WalshCore.Players[source] = nil
    end
end)

-- Player joined event
RegisterNetEvent('WalshCore:Server:OnPlayerLoaded', function()
    local source = source
    WalshCore.Functions.CreatePlayer(source)
end)

-- Export Walsh Core
exports('GetCoreObject', function()
    return WalshCore
end)

print("^2[Walsh Core]^7 Server main loaded successfully!")