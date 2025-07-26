-- Client Events Module

-- Key mappings
RegisterKeyMapping('openmenu', 'Open Main Menu', 'keyboard', 'F1')
RegisterKeyMapping('openphone', 'Open Phone', 'keyboard', 'F2')
RegisterKeyMapping('openinventory', 'Open Inventory', 'keyboard', 'TAB')
RegisterKeyMapping('gangmenu', 'Open Gang Menu', 'keyboard', 'F6')

-- Command handlers
RegisterCommand('openmenu', function()
    if not IsPlayerDead() then
        TriggerEvent('walsh:client:openMainMenu')
    end
end, false)

RegisterCommand('openphone', function()
    if not IsPlayerDead() and not IsPlayerHandcuffed() then
        TriggerEvent('walsh:client:openPhone')
    end
end, false)

RegisterCommand('openinventory', function()
    if not IsPlayerDead() and not IsPlayerHandcuffed() then
        TriggerEvent('walsh:client:openInventory')
    end
end, false)

RegisterCommand('gangmenu', function()
    if not IsPlayerDead() and not IsPlayerHandcuffed() then
        TriggerEvent('walsh:client:openGangMenu')
    end
end, false)

-- Interaction system
local nearbyPlayers = {}
local nearbyVehicles = {}
local isNearATM = false
local isNearGarage = false
local isNearShop = false

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check nearby players
        nearbyPlayers = {}
        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local targetPed = GetPlayerPed(playerId)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= 5.0 then
                    table.insert(nearbyPlayers, {
                        id = GetPlayerServerId(playerId),
                        ped = targetPed,
                        coords = targetCoords,
                        distance = distance
                    })
                end
            end
        end
        
        -- Check nearby vehicles
        nearbyVehicles = {}
        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehicleCoords)
            
            if distance <= 10.0 then
                table.insert(nearbyVehicles, {
                    entity = vehicle,
                    coords = vehicleCoords,
                    distance = distance,
                    model = GetEntityModel(vehicle),
                    plate = GetVehicleNumberPlateText(vehicle)
                })
            end
        end
        
        -- Check ATM proximity
        -- This would typically check against ATM coordinates
        isNearATM = false -- Placeholder
        
        -- Check garage proximity
        isNearGarage = false -- Placeholder
        
        -- Check shop proximity
        isNearShop = false -- Placeholder
    end
end)

-- Interaction key handler
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if IsControlJustReleased(0, 38) then -- E key
            if #nearbyPlayers > 0 and not IsPlayerDead() and not IsPlayerHandcuffed() then
                TriggerEvent('walsh:client:openPlayerInteraction', nearbyPlayers[1])
            elseif #nearbyVehicles > 0 and not IsPlayerDead() then
                TriggerEvent('walsh:client:openVehicleInteraction', nearbyVehicles[1])
            elseif isNearATM then
                TriggerEvent('walsh:client:openATM')
            elseif isNearGarage then
                TriggerEvent('walsh:client:openGarage')
            elseif isNearShop then
                TriggerEvent('walsh:client:openShop')
            end
        end
    end
end)

-- Player interaction menu
RegisterNetEvent('walsh:client:openPlayerInteraction')
AddEventHandler('walsh:client:openPlayerInteraction', function(targetPlayer)
    local playerData = GetPlayerData()
    if not playerData then return end
    
    local menu = {
        {
            label = 'Give Money',
            action = 'give_money',
            targetId = targetPlayer.id
        },
        {
            label = 'Check ID',
            action = 'check_id',
            targetId = targetPlayer.id
        }
    }
    
    -- Add job-specific options
    if playerData.job == 'police' then
        table.insert(menu, {
            label = 'Handcuff',
            action = 'handcuff',
            targetId = targetPlayer.id
        })
        table.insert(menu, {
            label = 'Search',
            action = 'search',
            targetId = targetPlayer.id
        })
        table.insert(menu, {
            label = 'Fine',
            action = 'fine',
            targetId = targetPlayer.id
        })
    end
    
    -- Add gang-specific options
    if playerData.gang then
        table.insert(menu, {
            label = 'Invite to Gang',
            action = 'gang_invite',
            targetId = targetPlayer.id
        })
    end
    
    SendNUIMessage({
        type = 'showInteractionMenu',
        menu = menu,
        targetId = targetPlayer.id
    })
    SetNuiFocus(true, true)
end)

-- Vehicle interaction menu
RegisterNetEvent('walsh:client:openVehicleInteraction')
AddEventHandler('walsh:client:openVehicleInteraction', function(vehicle)
    local menu = {
        {
            label = 'Lock/Unlock',
            action = 'toggle_lock',
            entity = vehicle.entity
        },
        {
            label = 'Engine On/Off',
            action = 'toggle_engine',
            entity = vehicle.entity
        }
    }
    
    local playerData = GetPlayerData()
    if playerData and playerData.job == 'police' then
        table.insert(menu, {
            label = 'Impound Vehicle',
            action = 'impound',
            entity = vehicle.entity,
            plate = vehicle.plate
        })
    end
    
    SendNUIMessage({
        type = 'showVehicleMenu',
        menu = menu,
        vehicle = vehicle
    })
    SetNuiFocus(true, true)
end)

-- Chat system integration
RegisterNetEvent('chat:addMessage')
AddEventHandler('chat:addMessage', function(data)
    SendNUIMessage({
        type = 'addChatMessage',
        data = data
    })
end)

-- Stress system
local currentStress = 0
RegisterNetEvent('walsh:client:updateStress')
AddEventHandler('walsh:client:updateStress', function(stress)
    currentStress = stress
    
    SendNUIMessage({
        type = 'updateStress',
        stress = stress
    })
    
    -- Visual effects based on stress level
    if stress > 80 then
        -- High stress effects
        SetTimecycleModifier('glasses_blue')
        ShakeGameplayCam('DRUNK_SHAKE', 0.5)
    elseif stress > 60 then
        -- Medium stress effects
        SetTimecycleModifier('glasses_brown')
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
    elseif stress > 40 then
        -- Low stress effects
        SetTimecycleModifier('glasses_green')
    else
        -- No stress
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
    end
end)

-- Hunger and thirst system
local currentHunger = 100
local currentThirst = 100

Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Decrease every minute
        
        if not IsPlayerDead() then
            currentHunger = math.max(0, currentHunger - 1)
            currentThirst = math.max(0, currentThirst - 2) -- Thirst decreases faster
            
            SendNUIMessage({
                type = 'updateNeeds',
                hunger = currentHunger,
                thirst = currentThirst
            })
            
            -- Apply effects for low hunger/thirst
            local playerPed = PlayerPedId()
            
            if currentHunger <= 10 or currentThirst <= 10 then
                -- Very low - start losing health
                local health = GetEntityHealth(playerPed)
                if health > 110 then -- Don't kill if already low health
                    SetEntityHealth(playerPed, health - 5)
                end
            elseif currentHunger <= 25 or currentThirst <= 25 then
                -- Low - reduced stamina
                RestorePlayerStamina(PlayerId(), 0.5)
            end
        end
    end
end)

-- Weather sync
RegisterNetEvent('walsh:client:syncWeather')
AddEventHandler('walsh:client:syncWeather', function(weather, time)
    SetWeatherTypeNowPersist(weather)
    NetworkOverrideClockTime(time.hour, time.minute, time.second)
end)

-- Speed cameras and traffic system
local speedCameras = {
    {x = -623.99, y = -823.01, z = 25.25, speed = 80},
    {x = -652.05, y = -854.40, z = 24.55, speed = 80},
    {x = -821.23, y = -1146.09, z = 7.68, speed = 120}
}

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
            local coords = GetEntityCoords(vehicle)
            
            for _, camera in pairs(speedCameras) do
                local distance = #(vector3(camera.x, camera.y, camera.z) - coords)
                
                if distance < 50.0 and speed > camera.speed then
                    -- Speeding ticket
                    local fine = math.floor((speed - camera.speed) * 10)
                    TriggerServerEvent('walsh:server:speedingTicket', fine, speed, camera.speed)
                    break
                end
            end
        end
    end
end)

-- Export utility functions
exports('GetNearbyPlayers', function() return nearbyPlayers end)
exports('GetNearbyVehicles', function() return nearbyVehicles end)
exports('GetCurrentStress', function() return currentStress end)
exports('GetCurrentHunger', function() return currentHunger end)
exports('GetCurrentThirst', function() return currentThirst end)
