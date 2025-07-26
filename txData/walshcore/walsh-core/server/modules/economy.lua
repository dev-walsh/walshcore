-- Economy Management Module

-- Banking functions
RegisterServerEvent('walsh:server:depositMoney')
AddEventHandler('walsh:server:depositMoney', function(amount)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.money >= amount and amount > 0 then
        player.money = player.money - amount
        player.bank = player.bank + amount
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        TriggerClientEvent('walsh:client:notify', src, 'Deposited $' .. amount, 'success')
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, to_license, amount, type, description) VALUES (@license, @license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = amount,
            ['@type'] = 'deposit',
            ['@description'] = 'Bank deposit'
        })
    else
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient cash', 'error')
    end
end)

RegisterServerEvent('walsh:server:withdrawMoney')
AddEventHandler('walsh:server:withdrawMoney', function(amount)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.bank >= amount and amount > 0 then
        player.bank = player.bank - amount
        player.money = player.money + amount
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        TriggerClientEvent('walsh:client:notify', src, 'Withdrew $' .. amount, 'success')
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, to_license, amount, type, description) VALUES (@license, @license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = amount,
            ['@type'] = 'withdrawal',
            ['@description'] = 'Bank withdrawal'
        })
    else
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient bank funds', 'error')
    end
end)

-- Business transactions
RegisterServerEvent('walsh:server:purchaseItem')
AddEventHandler('walsh:server:purchaseItem', function(item, price, shop)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.money >= price then
        player.money = player.money - price
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        TriggerClientEvent('walsh:client:notify', src, 'Purchased ' .. item .. ' for $' .. price, 'success')
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = price,
            ['@type'] = 'purchase',
            ['@description'] = 'Purchased ' .. item .. ' from ' .. (shop or 'unknown shop')
        })
        
        -- Give item to player (this would integrate with inventory system)
        TriggerEvent('walsh:server:giveItem', src, item, 1)
    else
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
    end
end)

-- Paycheck system
function StartPaycheckSystem()
    Citizen.CreateThread(function()
        while true do
            Wait(600000) -- 10 minutes
            
            for playerId, playerData in pairs(Walsh.Players) do
                local job = Config.Jobs[playerData.job]
                if job and job.grades and job.grades[tostring(playerData.job_grade)] then
                    local payment = job.grades[tostring(playerData.job_grade)].payment
                    if payment and payment > 0 then
                        playerData.bank = playerData.bank + payment
                        
                        TriggerClientEvent('walsh:client:updateMoney', playerId, playerData.money, playerData.bank)
                        TriggerClientEvent('walsh:client:notify', playerId, 'Received paycheck: $' .. payment, 'success')
                        
                        -- Log transaction
                        MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                            ['@license'] = playerData.license,
                            ['@amount'] = payment,
                            ['@type'] = 'paycheck',
                            ['@description'] = 'Job paycheck: ' .. playerData.job
                        })
                    end
                end
            end
        end
    end)
end

-- ATM locations and functionality
local atmLocations = {
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -1410.736, y = -100.437, z = 52.396},
    {x = -1410.736, y = -98.927, z = 52.396},
    {x = -1205.35, y = -325.579, z = 37.870}
}

RegisterServerCallback('walsh:server:getATMData', function(source, cb)
    local player = GetPlayer(source)
    if player then
        cb({
            money = player.money,
            bank = player.bank,
            name = player.name
        })
    else
        cb(false)
    end
end)

-- Money laundering system (for criminal activities)
RegisterServerEvent('walsh:server:launderMoney')
AddEventHandler('walsh:server:launderMoney', function(amount)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local dirtyMoney = GetPlayerStatus(src, 'dirty_money') or 0
    
    if dirtyMoney >= amount and amount > 0 then
        local cleanAmount = math.floor(amount * 0.85) -- 15% tax for laundering
        
        SetPlayerStatus(src, 'dirty_money', dirtyMoney - amount)
        player.money = player.money + cleanAmount
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        TriggerClientEvent('walsh:client:notify', src, 'Laundered $' .. amount .. ' (received $' .. cleanAmount .. ')', 'success')
        
        -- Log transaction
        MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
            ['@license'] = player.license,
            ['@amount'] = cleanAmount,
            ['@type'] = 'money_laundering',
            ['@description'] = 'Money laundering operation'
        })
    else
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient dirty money', 'error')
    end
end)

-- Start paycheck system when server starts
Citizen.CreateThread(function()
    Wait(5000) -- Wait for server to fully load
    StartPaycheckSystem()
end)

-- Utility function for server callbacks
function RegisterServerCallback(name, cb)
    Walsh.ServerCallbacks = Walsh.ServerCallbacks or {}
    Walsh.ServerCallbacks[name] = cb
end

RegisterServerEvent('walsh:server:triggerServerCallback')
AddEventHandler('walsh:server:triggerServerCallback', function(name, requestId, ...)
    local src = source
    
    if Walsh.ServerCallbacks[name] then
        Walsh.ServerCallbacks[name](src, function(...)
            TriggerClientEvent('walsh:client:serverCallback', src, requestId, ...)
        end, ...)
    end
end)
