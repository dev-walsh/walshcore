-- UI Management Module

local isUIOpen = false
local currentMenu = nil
local menuStack = {}

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('menuAction', function(data, cb)
    HandleMenuAction(data)
    cb('ok')
end)

RegisterNUICallback('giveMoneyToPlayer', function(data, cb)
    TriggerServerEvent('walsh:server:transferMoney', data.targetId, data.amount, 'cash')
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
    TriggerServerEvent('walsh:server:depositMoney', data.amount)
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    TriggerServerEvent('walsh:server:withdrawMoney', data.amount)
    cb('ok')
end)

RegisterNUICallback('buyWeapon', function(data, cb)
    TriggerServerEvent('walsh:server:buyWeapon', data.weapon, data.price)
    cb('ok')
end)

RegisterNUICallback('buyAmmo', function(data, cb)
    TriggerServerEvent('walsh:server:buyAmmo', data.weapon, data.amount)
    cb('ok')
end)

RegisterNUICallback('purchaseVehicle', function(data, cb)
    TriggerServerEvent('walsh:server:purchaseVehicle', data.model, data.price, data.shop)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    local playerCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('walsh:server:spawnVehicle', data.plate, playerCoords)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        local vehicleData = {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            modifications = GetVehicleMods(vehicle)
        }
        
        TriggerServerEvent('walsh:server:storeVehicle', vehicleData.plate, vehicleData)
    end
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('createGang', function(data, cb)
    TriggerServerEvent('walsh:server:createGang', data.name, data.label)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('inviteToGang', function(data, cb)
    TriggerServerEvent('walsh:server:inviteToGang', data.targetId)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('leaveGang', function(data, cb)
    TriggerServerEvent('walsh:server:leaveGang')
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('acceptGangInvitation', function(data, cb)
    TriggerServerEvent('walsh:server:acceptGangInvitation', data.gangName, data.inviterId)
    CloseUI()
    cb('ok')
end)

-- Main menu
RegisterNetEvent('walsh:client:openMainMenu')
AddEventHandler('walsh:client:openMainMenu', function()
    local playerData = GetPlayerData()
    if not playerData then return end
    
    local menu = {
        title = "Main Menu",
        items = {
            {label = "Character", action = "character_menu"},
            {label = "Vehicle", action = "vehicle_menu"},
            {label = "Gang", action = "gang_menu"},
            {label = "Settings", action = "settings_menu"}
        }
    }
    
    OpenMenu(menu)
end)

-- Character menu
function OpenCharacterMenu()
    local playerData = GetPlayerData()
    
    local menu = {
        title = "Character",
        items = {
            {label = "Money: $" .. (playerData.money or 0), action = "none"},
            {label = "Bank: $" .. (playerData.bank or 0), action = "none"},
            {label = "Job: " .. (playerData.job or "unemployed"), action = "none"},
            {label = "Gang: " .. (playerData.gang or "None"), action = "none"},
            {label = "Toggle Duty", action = "toggle_duty"},
            {label = "Show ID", action = "show_id"}
        }
    }
    
    OpenMenu(menu)
end

-- Vehicle menu
function OpenVehicleMenu()
    local menu = {
        title = "Vehicle",
        items = {
            {label = "Garage", action = "open_garage"},
            {label = "Vehicle Shop", action = "vehicle_shop"},
            {label = "Store Vehicle", action = "store_vehicle"},
            {label = "Lock/Unlock", action = "toggle_vehicle_lock"}
        }
    }
    
    OpenMenu(menu)
end

-- Gang menu
RegisterNetEvent('walsh:client:openGangMenu')
AddEventHandler('walsh:client:openGangMenu', function()
    local playerData = GetPlayerData()
    
    local menu = {
        title = "Gang",
        items = {}
    }
    
    if playerData.gang then
        table.insert(menu.items, {label = "Gang: " .. playerData.gang, action = "none"})
        table.insert(menu.items, {label = "Invite Player", action = "gang_invite"})
        table.insert(menu.items, {label = "Gang Info", action = "gang_info"})
        table.insert(menu.items, {label = "Leave Gang", action = "gang_leave"})
    else
        table.insert(menu.items, {label = "Create Gang", action = "gang_create"})
        table.insert(menu.items, {label = "No Gang", action = "none"})
    end
    
    OpenMenu(menu)
end)

-- ATM interface
RegisterNetEvent('walsh:client:openATM')
AddEventHandler('walsh:client:openATM', function()
    SendNUIMessage({
        type = 'showATM',
        show = true
    })
    SetNuiFocus(true, true)
    isUIOpen = true
end)

-- Weapon shop
RegisterNetEvent('walsh:client:openWeaponShop')
AddEventHandler('walsh:client:openWeaponShop', function()
    -- Get available weapons from server
    TriggerServerCallback('walsh:server:getAvailableWeapons', function(weapons)
        SendNUIMessage({
            type = 'showWeaponShop',
            weapons = weapons
        })
        SetNuiFocus(true, true)
        isUIOpen = true
    end)
end)

-- Vehicle shop
RegisterNetEvent('walsh:client:openVehicleShop')
AddEventHandler('walsh:client:openVehicleShop', function(shopData)
    SendNUIMessage({
        type = 'showVehicleShop',
        shop = shopData
    })
    SetNuiFocus(true, true)
    isUIOpen = true
end)

-- Garage interface
RegisterNetEvent('walsh:client:openGarage')
AddEventHandler('walsh:client:openGarage', function()
    TriggerServerCallback('walsh:server:getPlayerVehicles', function(vehicles)
        SendNUIMessage({
            type = 'showGarage',
            vehicles = vehicles
        })
        SetNuiFocus(true, true)
        isUIOpen = true
    end)
end)

-- Gang invitation
RegisterNetEvent('walsh:client:gangInvitation')
AddEventHandler('walsh:client:gangInvitation', function(inviteData)
    SendNUIMessage({
        type = 'showGangInvitation',
        data = inviteData
    })
    SetNuiFocus(true, true)
    isUIOpen = true
end)

-- Red zone UI
RegisterNetEvent('walsh:client:enteredRedZone')
AddEventHandler('walsh:client:enteredRedZone', function(zone)
    SendNUIMessage({
        type = 'showRedZoneWarning',
        zone = zone,
        show = true
    })
end)

RegisterNetEvent('walsh:client:leftRedZone')
AddEventHandler('walsh:client:leftRedZone', function()
    SendNUIMessage({
        type = 'showRedZoneWarning',
        show = false
    })
end)

-- Zone contest notification
RegisterNetEvent('walsh:client:zoneContest')
AddEventHandler('walsh:client:zoneContest', function(contestData)
    SendNUIMessage({
        type = 'showZoneContest',
        data = contestData
    })
end)

-- Zone control change
RegisterNetEvent('walsh:client:zoneControlChange')
AddEventHandler('walsh:client:zoneControlChange', function(controlData)
    SendNUIMessage({
        type = 'showZoneControlChange',
        data = controlData
    })
end)

-- Admin menu
RegisterNetEvent('walsh:client:openAdminMenu')
AddEventHandler('walsh:client:openAdminMenu', function()
    local menu = {
        title = "Admin Menu",
        items = {
            {label = "Player Management", action = "admin_players"},
            {label = "Vehicle Management", action = "admin_vehicles"},
            {label = "Server Management", action = "admin_server"},
            {label = "Teleport Menu", action = "admin_teleport"}
        }
    }
    
    OpenMenu(menu)
end)

-- Utility functions
function OpenMenu(menu)
    currentMenu = menu
    table.insert(menuStack, menu)
    
    SendNUIMessage({
        type = 'showMenu',
        menu = menu
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

function CloseUI()
    SendNUIMessage({
        type = 'hideUI'
    })
    
    SetNuiFocus(false, false)
    isUIOpen = false
    currentMenu = nil
    menuStack = {}
end

function HandleMenuAction(data)
    local action = data.action
    
    if action == "character_menu" then
        OpenCharacterMenu()
    elseif action == "vehicle_menu" then
        OpenVehicleMenu()
    elseif action == "gang_menu" then
        TriggerEvent('walsh:client:openGangMenu')
    elseif action == "open_garage" then
        TriggerEvent('walsh:client:openGarage')
    elseif action == "vehicle_shop" then
        -- Find nearest vehicle shop
        local nearestShop = GetNearestVehicleShop()
        if nearestShop then
            TriggerEvent('walsh:client:openVehicleShop', nearestShop)
        end
    elseif action == "gang_create" then
        SendNUIMessage({
            type = 'showGangCreation'
        })
    elseif action == "gang_invite" then
        local nearbyPlayers = exports['walsh']:GetNearbyPlayers()
        if #nearbyPlayers > 0 then
            SendNUIMessage({
                type = 'showPlayerSelection',
                players = nearbyPlayers,
                action = 'gang_invite'
            })
        end
    elseif action == "toggle_duty" then
        TriggerServerEvent('walsh:server:toggleDuty')
        CloseUI()
    else
        -- Handle other actions
        CloseUI()
    end
end

function GetNearestVehicleShop()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestShop = nil
    local nearestDistance = math.huge
    
    for _, shop in pairs(Config.VehicleShops) do
        local distance = #(playerCoords - shop.coords)
        if distance < nearestDistance and distance < 10.0 then
            nearestDistance = distance
            nearestShop = shop
        end
    end
    
    return nearestShop
end

function GetVehicleMods(vehicle)
    local mods = {}
    
    -- Get all modification data
    for i = 0, 48 do
        mods[i] = GetVehicleMod(vehicle, i)
    end
    
    -- Get colors
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    mods.primaryColor = primaryColor
    mods.secondaryColor = secondaryColor
    
    -- Get extras
    mods.extras = {}
    for i = 0, 12 do
        if DoesExtraExist(vehicle, i) then
            mods.extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    
    return mods
end

-- Server callback utility
function TriggerServerCallback(name, cb, ...)
    local requestId = math.random(1000000, 9999999)
    
    Walsh = Walsh or {}
    Walsh.ServerCallbacks = Walsh.ServerCallbacks or {}
    Walsh.ServerCallbacks[requestId] = cb
    
    TriggerServerEvent('walsh:server:triggerServerCallback', name, requestId, ...)
end

RegisterNetEvent('walsh:client:serverCallback')
AddEventHandler('walsh:client:serverCallback', function(requestId, ...)
    if Walsh.ServerCallbacks and Walsh.ServerCallbacks[requestId] then
        Walsh.ServerCallbacks[requestId](...)
        Walsh.ServerCallbacks[requestId] = nil
    end
end)

-- Export functions
exports('OpenMenu', OpenMenu)
exports('CloseUI', CloseUI)
exports('IsUIOpen', function() return isUIOpen end)
