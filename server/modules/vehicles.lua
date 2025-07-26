-- Vehicle Management Module

-- Vehicle purchase
RegisterServerEvent('walsh:server:purchaseVehicle')
AddEventHandler('walsh:server:purchaseVehicle', function(vehicleModel, price, shopName)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.money < price then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
        return
    end
    
    -- Generate unique plate
    local plate = GenerateUniquePlate()
    
    -- Deduct money
    player.money = player.money - price
    
    -- Add vehicle to database
    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, garage) VALUES (@owner, @plate, @vehicle, @garage)', {
        ['@owner'] = player.license,
        ['@plate'] = plate,
        ['@vehicle'] = json.encode({
            model = vehicleModel,
            plate = plate,
            modifications = {}
        }),
        ['@garage'] = 'pillboxgarage'
    }, function(insertId)
        if insertId then
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle purchased! Plate: ' .. plate, 'success')
            
            -- Log transaction
            MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                ['@license'] = player.license,
                ['@amount'] = price,
                ['@type'] = 'vehicle_purchase',
                ['@description'] = 'Purchased ' .. vehicleModel .. ' from ' .. shopName
            })
        else
            -- Refund on failure
            player.money = player.money + price
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            TriggerClientEvent('walsh:client:notify', src, 'Purchase failed', 'error')
        end
    end)
end)

-- Vehicle spawning from garage
RegisterServerEvent('walsh:server:spawnVehicle')
AddEventHandler('walsh:server:spawnVehicle', function(plate, spawnCoords)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND stored = 1', {
        ['@owner'] = player.license,
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            local vehicleData = json.decode(result[1].vehicle)
            
            -- Mark as not stored
            MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE plate = @plate', {
                ['@plate'] = plate
            })
            
            TriggerClientEvent('walsh:client:spawnVehicle', src, vehicleData, spawnCoords)
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle spawned', 'success')
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not found or already out', 'error')
        end
    end)
end)

-- Vehicle storing
RegisterServerEvent('walsh:server:storeVehicle')
AddEventHandler('walsh:server:storeVehicle', function(plate, vehicleData)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1, vehicle = @vehicle WHERE owner = @owner AND plate = @plate', {
        ['@vehicle'] = json.encode(vehicleData),
        ['@owner'] = player.license,
        ['@plate'] = plate
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('walsh:client:deleteVehicle', src)
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle stored', 'success')
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not owned by you', 'error')
        end
    end)
end)

-- Get player vehicles
RegisterServerCallback('walsh:server:getPlayerVehicles', function(source, cb)
    local player = GetPlayer(source)
    if not player then
        cb({})
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = player.license
    }, function(result)
        local vehicles = {}
        for i = 1, #result do
            local vehicle = result[i]
            table.insert(vehicles, {
                plate = vehicle.plate,
                model = json.decode(vehicle.vehicle).model,
                stored = vehicle.stored == 1,
                garage = vehicle.garage,
                type = vehicle.type
            })
        end
        cb(vehicles)
    end)
end)

-- Vehicle modification
RegisterServerEvent('walsh:server:modifyVehicle')
AddEventHandler('walsh:server:modifyVehicle', function(plate, modifications, cost)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.money < cost then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = player.license,
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            local vehicleData = json.decode(result[1].vehicle)
            vehicleData.modifications = modifications
            
            -- Deduct money
            player.money = player.money - cost
            
            -- Update vehicle data
            MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE plate = @plate', {
                ['@vehicle'] = json.encode(vehicleData),
                ['@plate'] = plate
            })
            
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle modified for $' .. cost, 'success')
            
            -- Log transaction
            MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                ['@license'] = player.license,
                ['@amount'] = cost,
                ['@type'] = 'vehicle_modification',
                ['@description'] = 'Vehicle modification for ' .. plate
            })
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not owned by you', 'error')
        end
    end)
end)

-- Vehicle selling
RegisterServerEvent('walsh:server:sellVehicle')
AddEventHandler('walsh:server:sellVehicle', function(plate, sellPrice)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = player.license,
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            -- Remove vehicle from database
            MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', {
                ['@plate'] = plate
            })
            
            -- Add money to player
            player.money = player.money + sellPrice
            
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle sold for $' .. sellPrice, 'success')
            
            -- Log transaction
            MySQL.Async.execute('INSERT INTO transactions (to_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
                ['@license'] = player.license,
                ['@amount'] = sellPrice,
                ['@type'] = 'vehicle_sale',
                ['@description'] = 'Sold vehicle ' .. plate
            })
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not found', 'error')
        end
    end)
end)

-- Vehicle transfer
RegisterServerEvent('walsh:server:transferVehicle')
AddEventHandler('walsh:server:transferVehicle', function(plate, targetId, price)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then
        TriggerClientEvent('walsh:client:notify', src, 'Player not found', 'error')
        return
    end
    
    price = price or 0
    
    if price > 0 and target.money < price then
        TriggerClientEvent('walsh:client:notify', src, 'Buyer has insufficient funds', 'error')
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = player.license,
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            -- Transfer ownership
            MySQL.Async.execute('UPDATE owned_vehicles SET owner = @new_owner WHERE plate = @plate', {
                ['@new_owner'] = target.license,
                ['@plate'] = plate
            })
            
            -- Handle payment
            if price > 0 then
                target.money = target.money - price
                player.money = player.money + price
                
                TriggerClientEvent('walsh:client:updateMoney', targetId, target.money, target.bank)
                TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
                
                -- Log transaction
                MySQL.Async.execute('INSERT INTO transactions (from_license, to_license, amount, type, description) VALUES (@from, @to, @amount, @type, @description)', {
                    ['@from'] = target.license,
                    ['@to'] = player.license,
                    ['@amount'] = price,
                    ['@type'] = 'vehicle_transfer',
                    ['@description'] = 'Vehicle transfer: ' .. plate
                })
            end
            
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle transferred to ' .. target.name, 'success')
            TriggerClientEvent('walsh:client:notify', targetId, 'Received vehicle ' .. plate .. ' from ' .. player.name, 'success')
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not found', 'error')
        end
    end)
end)

-- Utility functions
function GenerateUniquePlate()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    
    for i = 1, 8 do
        local rand = math.random(#charset)
        plate = plate .. string.sub(charset, rand, rand)
    end
    
    -- Check if plate exists
    MySQL.Sync.fetchAll('SELECT plate FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if #result > 0 then
            return GenerateUniquePlate() -- Recursively generate new plate
        end
    end)
    
    return plate
end

-- Vehicle impound system
RegisterServerEvent('walsh:server:impoundVehicle')
AddEventHandler('walsh:server:impoundVehicle', function(plate, reason)
    local src = source
    local player = GetPlayer(src)
    
    if not player or player.job ~= 'police' then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient permissions', 'error')
        return
    end
    
    MySQL.Async.execute('UPDATE owned_vehicles SET garage = @garage, stored = 1 WHERE plate = @plate', {
        ['@garage'] = 'impound',
        ['@plate'] = plate
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle impounded: ' .. plate, 'success')
            
            -- Notify owner if online
            MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
                ['@plate'] = plate
            }, function(result)
                if result[1] then
                    local owner = GetPlayerByLicense(result[1].owner)
                    if owner then
                        TriggerClientEvent('walsh:client:notify', owner.source, 'Your vehicle (' .. plate .. ') has been impounded. Reason: ' .. reason, 'error')
                    end
                end
            end)
        else
            TriggerClientEvent('walsh:client:notify', src, 'Vehicle not found', 'error')
        end
    end)
end)

-- Export functions
exports('GenerateUniquePlate', GenerateUniquePlate)
