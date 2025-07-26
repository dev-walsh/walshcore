-- Weapon Management Module

-- Buy weapon
RegisterServerEvent('walsh:server:buyWeapon')
AddEventHandler('walsh:server:buyWeapon', function(weaponName, price)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if not Config.Weapons[weaponName] then
        TriggerClientEvent('walsh:client:notify', src, 'Invalid weapon', 'error')
        return
    end
    
    if player.money < price then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
        return
    end
    
    -- Check if player already has weapon
    if player.loadout[weaponName] then
        TriggerClientEvent('walsh:client:notify', src, 'You already own this weapon', 'error')
        return
    end
    
    -- Deduct money
    player.money = player.money - price
    
    -- Add weapon to loadout
    player.loadout[weaponName] = {
        name = weaponName,
        ammo = 0
    }
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    TriggerClientEvent('walsh:client:receiveWeapon', src, weaponName, 0)
    TriggerClientEvent('walsh:client:notify', src, 'Weapon purchased: ' .. weaponName, 'success')
    
    -- Log transaction
    MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
        ['@license'] = player.license,
        ['@amount'] = price,
        ['@type'] = 'weapon_purchase',
        ['@description'] = 'Purchased weapon: ' .. weaponName
    })
end)

-- Buy ammo
RegisterServerEvent('walsh:server:buyAmmo')
AddEventHandler('walsh:server:buyAmmo', function(weaponName, amount)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if not Config.Weapons[weaponName] then
        TriggerClientEvent('walsh:client:notify', src, 'Invalid weapon', 'error')
        return
    end
    
    if not player.loadout[weaponName] then
        TriggerClientEvent('walsh:client:notify', src, 'You don\'t own this weapon', 'error')
        return
    end
    
    local price = Config.Weapons[weaponName].ammoPrice * amount
    
    if player.money < price then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
        return
    end
    
    -- Deduct money
    player.money = player.money - price
    
    -- Add ammo
    player.loadout[weaponName].ammo = player.loadout[weaponName].ammo + amount
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    TriggerClientEvent('walsh:client:updateAmmo', src, weaponName, player.loadout[weaponName].ammo)
    TriggerClientEvent('walsh:client:notify', src, 'Ammo purchased: ' .. amount .. ' rounds', 'success')
    
    -- Log transaction
    MySQL.Async.execute('INSERT INTO transactions (from_license, amount, type, description) VALUES (@license, @amount, @type, @description)', {
        ['@license'] = player.license,
        ['@amount'] = price,
        ['@type'] = 'ammo_purchase',
        ['@description'] = 'Purchased ammo for ' .. weaponName .. ': ' .. amount .. ' rounds'
    })
end)

-- Remove weapon
RegisterServerEvent('walsh:server:removeWeapon')
AddEventHandler('walsh:server:removeWeapon', function(weaponName)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.loadout[weaponName] then
        player.loadout[weaponName] = nil
        TriggerClientEvent('walsh:client:removeWeapon', src, weaponName)
        TriggerClientEvent('walsh:client:notify', src, 'Weapon removed: ' .. weaponName, 'info')
    end
end)

-- Update weapon ammo
RegisterServerEvent('walsh:server:updateAmmo')
AddEventHandler('walsh:server:updateAmmo', function(weaponName, ammo)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.loadout[weaponName] then
        player.loadout[weaponName].ammo = ammo
    end
end)

-- Police weapon confiscation
RegisterServerEvent('walsh:server:confiscateWeapons')
AddEventHandler('walsh:server:confiscateWeapons', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' or not player.onduty then
        TriggerClientEvent('walsh:client:notify', src, 'You must be on duty as police', 'error')
        return
    end
    
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId)))
    if distance > 5.0 then
        TriggerClientEvent('walsh:client:notify', src, 'Player too far away', 'error')
        return
    end
    
    -- Confiscate all weapons
    local confiscatedWeapons = {}
    for weaponName, weaponData in pairs(target.loadout) do
        table.insert(confiscatedWeapons, weaponName)
        TriggerClientEvent('walsh:client:removeWeapon', targetId, weaponName)
    end
    
    target.loadout = {}
    
    if #confiscatedWeapons > 0 then
        TriggerClientEvent('walsh:client:notify', src, 'Confiscated ' .. #confiscatedWeapons .. ' weapons', 'success')
        TriggerClientEvent('walsh:client:notify', targetId, 'Your weapons have been confiscated', 'error')
    else
        TriggerClientEvent('walsh:client:notify', src, 'No weapons to confiscate', 'info')
    end
end)

-- License system for weapons
RegisterServerEvent('walsh:server:checkWeaponLicense')
AddEventHandler('walsh:server:checkWeaponLicense', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' then
        TriggerClientEvent('walsh:client:notify', src, 'Only police can check licenses', 'error')
        return
    end
    
    -- Check if target has weapon license
    local hasLicense = GetPlayerStatus(targetId, 'weapon_license') or false
    
    if hasLicense then
        TriggerClientEvent('walsh:client:notify', src, target.name .. ' has a valid weapon license', 'success')
    else
        TriggerClientEvent('walsh:client:notify', src, target.name .. ' does not have a weapon license', 'error')
    end
end)

-- Issue weapon license
RegisterServerEvent('walsh:server:issueWeaponLicense')
AddEventHandler('walsh:server:issueWeaponLicense', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' or player.job_grade < 2 then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient permissions', 'error')
        return
    end
    
    SetPlayerStatus(targetId, 'weapon_license', true)
    
    TriggerClientEvent('walsh:client:notify', src, 'Issued weapon license to ' .. target.name, 'success')
    TriggerClientEvent('walsh:client:notify', targetId, 'You have been issued a weapon license', 'success')
end)

-- Revoke weapon license
RegisterServerEvent('walsh:server:revokeWeaponLicense')
AddEventHandler('walsh:server:revokeWeaponLicense', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' or player.job_grade < 2 then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient permissions', 'error')
        return
    end
    
    SetPlayerStatus(targetId, 'weapon_license', false)
    
    TriggerClientEvent('walsh:client:notify', src, 'Revoked weapon license from ' .. target.name, 'success')
    TriggerClientEvent('walsh:client:notify', targetId, 'Your weapon license has been revoked', 'error')
end)

-- Weapon shop locations
local weaponShops = {
    {x = 1692.54, y = 3760.16, z = 34.71, name = "Sandy Shores Gun Shop"},
    {x = 252.696, y = -50.0643, z = 69.941, name = "Downtown Gun Shop"},
    {x = 22.56, y = -1109.89, z = 29.80, name = "Little Seoul Gun Shop"}
}

-- Get weapon shop locations
RegisterServerCallback('walsh:server:getWeaponShops', function(source, cb)
    cb(weaponShops)
end)

-- Get available weapons for purchase
RegisterServerCallback('walsh:server:getAvailableWeapons', function(source, cb)
    local player = GetPlayer(source)
    if not player then
        cb({})
        return
    end
    
    local availableWeapons = {}
    
    for weaponName, weaponData in pairs(Config.Weapons) do
        -- Check if player already owns weapon
        if not player.loadout[weaponName] then
            table.insert(availableWeapons, {
                name = weaponName,
                price = weaponData.price,
                ammoPrice = weaponData.ammoPrice
            })
        end
    end
    
    cb(availableWeapons)
end)

-- Get player weapons
RegisterServerCallback('walsh:server:getPlayerWeapons', function(source, cb)
    local player = GetPlayer(source)
    if not player then
        cb({})
        return
    end
    
    local weapons = {}
    for weaponName, weaponData in pairs(player.loadout) do
        table.insert(weapons, {
            name = weaponName,
            ammo = weaponData.ammo
        })
    end
    
    cb(weapons)
end)

-- Black market weapon system (for gangs)
RegisterServerEvent('walsh:server:buyBlackMarketWeapon')
AddEventHandler('walsh:server:buyBlackMarketWeapon', function(weaponName, price)
    local src = source
    local player = GetPlayer(src)
    
    if not player or not player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'Gang membership required', 'error')
        return
    end
    
    -- Black market weapons cost more
    local blackMarketPrice = math.floor(price * 1.5)
    
    if player.money < blackMarketPrice then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient funds', 'error')
        return
    end
    
    -- Deduct money
    player.money = player.money - blackMarketPrice
    
    -- Add weapon
    player.loadout[weaponName] = {
        name = weaponName,
        ammo = 30 -- Black market weapons come with some ammo
    }
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    TriggerClientEvent('walsh:client:receiveWeapon', src, weaponName, 30)
    TriggerClientEvent('walsh:client:notify', src, 'Black market weapon acquired: ' .. weaponName, 'success')
    
    -- Add dirty money status (illegal transaction)
    local dirtyMoney = GetPlayerStatus(src, 'dirty_money') or 0
    SetPlayerStatus(src, 'dirty_money', dirtyMoney + math.floor(blackMarketPrice * 0.5))
end)
