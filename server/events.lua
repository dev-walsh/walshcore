-- Player money events
RegisterServerEvent('walsh:server:addMoney')
AddEventHandler('walsh:server:addMoney', function(amount, type)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    type = type or 'cash'
    
    if type == 'cash' then
        player.money = player.money + amount
    elseif type == 'bank' then
        player.bank = player.bank + amount
    end
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    
    -- Log transaction
    MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
        ['@license'] = player.license,
        ['@amount'] = amount,
        ['@type'] = 'add_money',
        ['@description'] = 'Money added: ' .. amount .. ' (' .. type .. ')'
    })
end)

RegisterServerEvent('walsh:server:removeMoney')
AddEventHandler('walsh:server:removeMoney', function(amount, type)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    type = type or 'cash'
    
    if type == 'cash' and player.money >= amount then
        player.money = player.money - amount
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = amount,
            ['@type'] = 'remove_money',
            ['@description'] = 'Money removed: ' .. amount .. ' (' .. type .. ')'
        })
        
        return true
    elseif type == 'bank' and player.bank >= amount then
        player.bank = player.bank - amount
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = amount,
            ['@type'] = 'remove_money',
            ['@description'] = 'Money removed: ' .. amount .. ' (' .. type .. ')'
        })
        
        return true
    end
    
    return false
end)

-- Player transfer money
RegisterServerEvent('walsh:server:transferMoney')
AddEventHandler('walsh:server:transferMoney', function(targetId, amount, type)
    local src = source
    local player = GetPlayer(src)
    local targetPlayer = GetPlayer(targetId)
    
    if not player or not targetPlayer then
        TriggerClientEvent('walsh:client:notify', src, 'Player not found', 'error')
        return
    end
    
    type = type or 'cash'
    
    if type == 'cash' and player.money >= amount then
        player.money = player.money - amount
        targetPlayer.money = targetPlayer.money + amount
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        TriggerClientEvent('walsh:client:updateMoney', targetId, targetPlayer.money, targetPlayer.bank)
        
        TriggerClientEvent('walsh:client:notify', src, 'Sent $' .. amount .. ' to ' .. targetPlayer.name, 'success')
        TriggerClientEvent('walsh:client:notify', targetId, 'Received $' .. amount .. ' from ' .. player.name, 'success')
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, to_license, amount, type, description) VALUES (@from, @to, @amount, @type, @description)', {
            ['@from'] = player.license,
            ['@to'] = targetPlayer.license,
            ['@amount'] = amount,
            ['@type'] = 'transfer',
            ['@description'] = 'Money transfer'
        })
    else
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
    end
end)

-- Player death handler
RegisterServerEvent('walsh:server:playerDied')
AddEventHandler('walsh:server:playerDied', function(deathCause)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    player.is_dead = true
    
    -- Apply death penalty
    local penalty = math.floor(player.money * Config.DeathPenalty)
    player.money = player.money - penalty
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    TriggerClientEvent('walsh:client:notify', src, 'You died and lost $' .. penalty .. ' (' .. (Config.DeathPenalty * 100) .. '% penalty)', 'error')
    
    -- Log death
    MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
        ['@license'] = player.license,
        ['@amount'] = penalty,
        ['@type'] = 'death_penalty',
        ['@description'] = 'Death penalty: ' .. (deathCause or 'Unknown')
    })
end)

-- Player respawn handler
RegisterServerEvent('walsh:server:playerRespawned')
AddEventHandler('walsh:server:playerRespawned', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    player.is_dead = false
end)

-- Position update handler
RegisterServerEvent('walsh:server:updatePosition')
AddEventHandler('walsh:server:updatePosition', function(coords, heading)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    player.position = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    }
end)
