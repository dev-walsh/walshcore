-- Money commands
RegisterCommand('givemoney', function(source, args, rawCommand)
    if source == 0 then -- Console command
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        local type = args[3] or 'cash'
        
        if targetId and amount and amount > 0 then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                if type == 'cash' then
                    targetPlayer.money = targetPlayer.money + amount
                elseif type == 'bank' then
                    targetPlayer.bank = targetPlayer.bank + amount
                end
                
                TriggerClientEvent('walsh:client:updateMoney', targetId, targetPlayer.money, targetPlayer.bank)
                print("Gave $" .. amount .. " (" .. type .. ") to " .. targetPlayer.name)
                
                -- Log transaction
                MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                    ['@license'] = targetPlayer.license,
                    ['@amount'] = amount,
                    ['@type'] = 'admin_give',
                    ['@description'] = 'Admin gave money via console'
                })
            else
                print("Player not found")
            end
        else
            print("Usage: givemoney [player_id] [amount] [cash/bank]")
        end
    else
        -- Admin check for in-game command
        if IsPlayerAdmin(source) then
            local targetId = tonumber(args[1])
            local amount = tonumber(args[2])
            local type = args[3] or 'cash'
            
            if targetId and amount and amount > 0 then
                local targetPlayer = GetPlayer(targetId)
                if targetPlayer then
                    if type == 'cash' then
                        targetPlayer.money = targetPlayer.money + amount
                    elseif type == 'bank' then
                        targetPlayer.bank = targetPlayer.bank + amount
                    end
                    
                    TriggerClientEvent('walsh:client:updateMoney', targetId, targetPlayer.money, targetPlayer.bank)
                    TriggerClientEvent('walsh:client:notify', source, "Gave $" .. amount .. " to " .. targetPlayer.name, 'success')
                    TriggerClientEvent('walsh:client:notify', targetId, "Admin gave you $" .. amount, 'success')
                    
                    -- Log transaction
                    MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                        ['@license'] = targetPlayer.license,
                        ['@amount'] = amount,
                        ['@type'] = 'admin_give',
                        ['@description'] = 'Admin gave money: ' .. GetPlayerName(source)
                    })
                else
                    TriggerClientEvent('walsh:client:notify', source, "Player not found", 'error')
                end
            else
                TriggerClientEvent('walsh:client:notify', source, "Usage: /givemoney [player_id] [amount] [cash/bank]", 'error')
            end
        else
            TriggerClientEvent('walsh:client:notify', source, "Insufficient permissions", 'error')
        end
    end
end, false)

-- Remove money command
RegisterCommand('removemoney', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        local type = args[3] or 'cash'
        
        if targetId and amount and amount > 0 then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                if type == 'cash' and targetPlayer.money >= amount then
                    targetPlayer.money = targetPlayer.money - amount
                    TriggerClientEvent('walsh:client:updateMoney', targetId, targetPlayer.money, targetPlayer.bank)
                    
                    if source == 0 then
                        print("Removed $" .. amount .. " from " .. targetPlayer.name)
                    else
                        TriggerClientEvent('walsh:client:notify', source, "Removed $" .. amount .. " from " .. targetPlayer.name, 'success')
                    end
                    
                    -- Log transaction
                    MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                        ['@license'] = targetPlayer.license,
                        ['@amount'] = amount,
                        ['@type'] = 'admin_remove',
                        ['@description'] = 'Admin removed money'
                    })
                elseif type == 'bank' and targetPlayer.bank >= amount then
                    targetPlayer.bank = targetPlayer.bank - amount
                    TriggerClientEvent('walsh:client:updateMoney', targetId, targetPlayer.money, targetPlayer.bank)
                    
                    if source == 0 then
                        print("Removed $" .. amount .. " from " .. targetPlayer.name .. "'s bank")
                    else
                        TriggerClientEvent('walsh:client:notify', source, "Removed $" .. amount .. " from " .. targetPlayer.name .. "'s bank", 'success')
                    end
                else
                    local msg = "Player doesn't have enough money"
                    if source == 0 then
                        print(msg)
                    else
                        TriggerClientEvent('walsh:client:notify', source, msg, 'error')
                    end
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
            local msg = "Usage: /removemoney [player_id] [amount] [cash/bank]"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, "Insufficient permissions", 'error')
    end
end, false)

-- Player info command
RegisterCommand('playerinfo', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        
        if targetId then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer then
                local info = string.format([[
Player Info for %s (ID: %d):
License: %s
Money: $%d
Bank: $%d
Job: %s (Grade: %d)
Gang: %s (Grade: %d)
Status: %s
                ]], 
                targetPlayer.name, 
                targetId,
                targetPlayer.license,
                targetPlayer.money,
                targetPlayer.bank,
                targetPlayer.job,
                targetPlayer.job_grade,
                targetPlayer.gang or 'None',
                targetPlayer.gang_grade,
                targetPlayer.is_dead and 'Dead' or 'Alive'
                )
                
                if source == 0 then
                    print(info)
                else
                    TriggerClientEvent('chat:addMessage', source, {
                        args = {"SYSTEM", info}
                    })
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
            local msg = "Usage: /playerinfo [player_id]"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, "Insufficient permissions", 'error')
    end
end, false)

-- Set job command
RegisterCommand('setjob', function(source, args, rawCommand)
    if source == 0 or IsPlayerAdmin(source) then
        local targetId = tonumber(args[1])
        local job = args[2]
        local grade = tonumber(args[3]) or 0
        
        if targetId and job then
            local targetPlayer = GetPlayer(targetId)
            if targetPlayer and Config.Jobs[job] then
                targetPlayer.job = job
                targetPlayer.job_grade = grade
                
                TriggerClientEvent('walsh:client:jobUpdate', targetId, job, grade)
                
                local msg = "Set " .. targetPlayer.name .. "'s job to " .. job .. " (Grade: " .. grade .. ")"
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'success')
                end
                
                TriggerClientEvent('walsh:client:notify', targetId, "Your job has been set to " .. job, 'success')
            else
                local msg = "Player not found or invalid job"
                if source == 0 then
                    print(msg)
                else
                    TriggerClientEvent('walsh:client:notify', source, msg, 'error')
                end
            end
        else
            local msg = "Usage: /setjob [player_id] [job] [grade]"
            if source == 0 then
                print(msg)
            else
                TriggerClientEvent('walsh:client:notify', source, msg, 'error')
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', source, "Insufficient permissions", 'error')
    end
end, false)

-- Utility function to check admin status
function IsPlayerAdmin(src)
    local license = GetPlayerIdentifier(src, 0)
    
    -- This should be integrated with your admin system
    -- For now, using a simple group check
    for i = 1, GetNumPlayerIndices() do
        local playerId = GetPlayerFromIndex(i)
        if playerId == src then
            for _, group in ipairs(Config.AdminGroups) do
                if IsPlayerAceAllowed(src, "group." .. group) then
                    return true
                end
            end
        end
    end
    
    return false
end
