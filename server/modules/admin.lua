-- Admin Management Module

-- Admin command processing
RegisterCommand('tp', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        
        if source == 0 then
            print("Cannot teleport from console")
            return
        end
        
        if targetId then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
                TriggerClientEvent('walsh:client:teleportPlayer', source, targetCoords)
                TriggerClientEvent('walsh:client:notify', source, 'Teleported to ' .. targetPlayer.name, 'success')
            else
                TriggerClientEvent('walsh:client:notify', source, 'Player not found', 'error')
            end
        else
            TriggerClientEvent('walsh:client:notify', source, 'Usage: /tp [player_id]', 'error')
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('tphere', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        
        if source == 0 then
            print("Cannot teleport from console")
            return
        end
        
        if targetId then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                local adminCoords = GetEntityCoords(GetPlayerPed(source))
                TriggerClientEvent('walsh:client:teleportPlayer', targetId, adminCoords)
                TriggerClientEvent('walsh:client:notify', source, 'Teleported ' .. targetPlayer.name .. ' to you', 'success')
                TriggerClientEvent('walsh:client:notify', targetId, 'You were teleported by an admin', 'info')
            else
                TriggerClientEvent('walsh:client:notify', source, 'Player not found', 'error')
            end
        else
            TriggerClientEvent('walsh:client:notify', source, 'Usage: /tphere [player_id]', 'error')
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('heal', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1]) or source
        
        if source == 0 and not args[1] then
            print("Usage: heal [player_id]")
            return
        end
        
        local targetPlayer = GetPlayer(targetId)
        if targetPlayer then
            TriggerClientEvent('walsh:client:healPlayer', targetId)
            
            if source == 0 then
                print("Healed " .. targetPlayer.name)
            else
                TriggerClientEvent('walsh:client:notify', source, 'Healed ' .. (targetId == source and 'yourself' or targetPlayer.name), 'success')
            end
            
            if targetId ~= source then
                TriggerClientEvent('walsh:client:notify', targetId, 'You were healed by an admin', 'success')
            end
        else
            local msg = "Player not found"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('revive', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1]) or source
        
        if source == 0 and not args[1] then
            print("Usage: revive [player_id]")
            return
        end
        
        local targetPlayer = GetPlayer(targetId)
        if targetPlayer then
            targetPlayer.is_dead = false
            TriggerClientEvent('walsh:client:revivePlayer', targetId)
            
            if source == 0 then
                print("Revived " .. targetPlayer.name)
            else
                TriggerClientEvent('walsh:client:notify', source, 'Revived ' .. (targetId == source and 'yourself' or targetPlayer.name), 'success')
            end
            
            if targetId ~= source then
                TriggerClientEvent('walsh:client:notify', targetId, 'You were revived by an admin', 'success')
            end
        else
            local msg = "Player not found"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('kick', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2) or "No reason specified"
        
        if targetId then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                DropPlayer(targetId, "Kicked by admin: " .. reason)
                
                local msg = "Kicked " .. targetPlayer.name .. " - Reason: " .. reason
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'success')
                end
            else
                local msg = "Player not found"
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'error')
                end
            end
        else
            local msg = "Usage: /kick [player_id] [reason]"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('ban', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        local duration = tonumber(args[2]) or 0 -- 0 = permanent
        local reason = table.concat(args, " ", 3) or "No reason specified"
        
        if targetId then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                local banExpiry = duration > 0 and (os.time() + (duration * 3600)) or 0 -- Convert hours to seconds
                
                -- Store ban in database
                MySQL.Async.execute('INSERT INTO bans (license, reason, expires, banned_by) VALUES (@license, @reason, @expires, @banned_by)', {
                    ['@license'] = targetPlayer.license,
                    ['@reason'] = reason,
                    ['@expires'] = banExpiry,
                    ['@banned_by'] = source == 0 and 'Console' or GetPlayerName(source)
                })
                
                DropPlayer(targetId, "Banned: " .. reason .. (duration > 0 and (" - Duration: " .. duration .. " hours") or " - Permanent"))
                
                local msg = "Banned " .. targetPlayer.name .. " - Reason: " .. reason .. (duration > 0 and (" - Duration: " .. duration .. " hours") or " - Permanent")
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'success')
                end
            else
                local msg = "Player not found"
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'error')
                end
            end
        else
            local msg = "Usage: /ban [player_id] [duration_hours] [reason] (0 = permanent)"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('noclip', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        TriggerClientEvent('walsh:client:toggleNoclip', source)
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('godmode', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        TriggerClientEvent('walsh:client:toggleGodmode', source)
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('invisible', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        TriggerClientEvent('walsh:client:toggleInvisible', source)
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

RegisterCommand('adminmenu', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        TriggerClientEvent('walsh:client:openAdminMenu', source)
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

-- Ban checking on player connect
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local license = GetPlayerIdentifier(src, 0)
    
    MySQL.Async.fetchAll('SELECT * FROM bans WHERE license = @license', {
        ['@license'] = license
    }, function(result)
        if result[1] then
            local ban = result[1]
            
            -- Check if ban has expired
            if ban.expires > 0 and ban.expires < os.time() then
                -- Ban expired, remove from database
                MySQL.Async.execute('DELETE FROM bans WHERE id = @id', {
                    ['@id'] = ban.id
                })
                return
            end
            
            -- Player is banned
            local banMessage = "You are banned from this server.\nReason: " .. ban.reason .. "\nBanned by: " .. ban.banned_by
            if ban.expires > 0 then
                banMessage = banMessage .. "\nExpires: " .. os.date("%Y-%m-%d %H:%M:%S", ban.expires)
            else
                banMessage = banMessage .. "\nThis is a permanent ban."
            end
            
            setKickReason(banMessage)
            CancelEvent()
        end
    end)
end)

-- Server statistics
RegisterCommand('serverstats', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local playerCount = #GetPlayers()
        local totalMoney = 0
        local totalGangs = 0
        
        -- Calculate total money in circulation
        for _, player in pairs(Walsh.Players) do
            totalMoney = totalMoney + player.money + player.bank
        end
        
        -- Count gangs
        for _ in pairs(Walsh.Gangs) do
            totalGangs = totalGangs + 1
        end
        
        local stats = string.format([[
Server Statistics:
Players Online: %d
Total Money in Circulation: $%d
Active Gangs: %d
Uptime: %s
        ]], playerCount, totalMoney, totalGangs, "N/A") -- You could implement uptime tracking
        
        if source == 0 then
            print(stats)
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = {"SYSTEM", stats}
            })
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

-- Announce command
RegisterCommand('announce', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local message = table.concat(args, " ")
        
        if message and message ~= "" then
            TriggerClientEvent('walsh:client:announce', -1, message, source == 0 and 'Server' or GetPlayerName(source))
            
            if source == 0 then
                print("Announcement sent: " .. message)
            else
                TriggerClientEvent('walsh:client:notify', source, 'Announcement sent', 'success')
            end
        else
            local msg = "Usage: /announce [message]"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

-- Clear area command
RegisterCommand('cleararea', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        local radius = tonumber(args[1]) or 50.0
        TriggerClientEvent('walsh:client:clearArea', source, radius)
        TriggerClientEvent('walsh:client:notify', source, 'Cleared area with radius ' .. radius, 'success')
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

-- Vehicle spawn command
RegisterCommand('admincar', function(source, args, rawCommand)
    if source ~= 0 and IsPlayerAdmin(source) then
        local model = args[1] or 'adder'
        TriggerClientEvent('walsh:client:spawnAdminVehicle', source, model)
    else
        TriggerClientEvent('walsh:client:notify', source, 'Insufficient permissions', 'error')
    end
end, false)

-- Export admin functions
exports('IsPlayerAdmin', IsPlayerAdmin)
