-- Client Economy Module

local atmLocations = {
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -1410.736, y = -100.437, z = 52.396},
    {x = -1410.736, y = -98.927, z = 52.396},
    {x = -2962.582, y = 482.627, z = 15.703},
    {x = -3144.1, y = 1127.5, z = 20.9},
    {x = -1091.5, y = 2708.2, z = 18.9}
}

-- Create ATM blips
Citizen.CreateThread(function()
    for _, atm in pairs(atmLocations) do
        local blip = AddBlipForCoord(atm.x, atm.y, atm.z)
        SetBlipSprite(blip, 277)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("ATM")
        EndTextCommandSetBlipName(blip)
    end
end)

-- ATM interaction
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearATM = false
        
        for _, atm in pairs(atmLocations) do
            local distance = #(playerCoords - vector3(atm.x, atm.y, atm.z))
            
            if distance < 3.0 then
                nearATM = true
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    text = 'Press E to use ATM',
                    show = true
                })
                
                if IsControlJustReleased(0, 38) then -- E key
                    OpenATM()
                end
                break
            end
        end
        
        if not nearATM then
            SendNUIMessage({
                type = 'showInteractionPrompt',
                show = false
            })
        end
    end
end)

function OpenATM()
    TriggerServerCallback('walsh:server:getATMData', function(data)
        if data then
            SendNUIMessage({
                type = 'showATM',
                show = true,
                playerData = data
            })
            SetNuiFocus(true, true)
        else
            TriggerEvent('walsh:client:notify', 'ATM Error', 'error')
        end
    end)
end

-- Store locations
local stores = {
    {
        name = "24/7 Store",
        coords = vector3(25.7, -1347.3, 29.5),
        items = {
            {name = "Bread", price = 5},
            {name = "Water", price = 3},
            {name = "Phone", price = 250},
            {name = "Energy Drink", price = 8}
        }
    },
    {
        name = "LTD Gasoline",
        coords = vector3(-48.0, -1757.5, 29.4),
        items = {
            {name = "Snacks", price = 10},
            {name = "Soda", price = 5},
            {name = "Cigarettes", price = 15},
            {name = "Lottery Ticket", price = 20}
        }
    }
}

-- Create store blips
Citizen.CreateThread(function()
    for _, store in pairs(stores) do
        local blip = AddBlipForCoord(store.coords.x, store.coords.y, store.coords.z)
        SetBlipSprite(blip, 52)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(store.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Store interaction
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, store in pairs(stores) do
            local distance = #(playerCoords - store.coords)
            
            if distance < 5.0 then
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    text = 'Press E to open ' .. store.name,
                    show = true
                })
                
                if distance < 3.0 and IsControlJustReleased(0, 38) then
                    OpenStore(store)
                end
                break
            else
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    show = false
                })
            end
        end
    end
end)

function OpenStore(store)
    SendNUIMessage({
        type = 'showStore',
        store = store
    })
    SetNuiFocus(true, true)
end

-- Store purchase callback
RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('walsh:server:purchaseItem', data.item, data.price, data.shop)
    cb('ok')
end)

-- Bank locations
local banks = {
    {
        name = "Fleeca Bank",
        coords = vector3(149.9, -1040.2, 29.4),
        blip = true
    },
    {
        name = "Fleeca Bank",
        coords = vector3(-1212.980, -330.841, 37.787),
        blip = true
    },
    {
        name = "Fleeca Bank",
        coords = vector3(-2962.71, 482.627, 15.703),
        blip = true
    }
}

-- Create bank blips
Citizen.CreateThread(function()
    for _, bank in pairs(banks) do
        if bank.blip then
            local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
            SetBlipSprite(blip, 108)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.9)
            SetBlipColour(blip, 2)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(bank.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Bank interaction
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, bank in pairs(banks) do
            local distance = #(playerCoords - bank.coords)
            
            if distance < 5.0 then
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    text = 'Press E to access bank',
                    show = true
                })
                
                if distance < 3.0 and IsControlJustReleased(0, 38) then
                    OpenBank()
                end
                break
            else
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    show = false
                })
            end
        end
    end
end)

function OpenBank()
    TriggerServerCallback('walsh:server:getATMData', function(data)
        if data then
            SendNUIMessage({
                type = 'showBank',
                show = true,
                playerData = data
            })
            SetNuiFocus(true, true)
        else
            TriggerEvent('walsh:client:notify', 'Bank Error', 'error')
        end
    end)
end

-- Money transfer interface
RegisterCommand('givemoney', function(source, args, rawCommand)
    local playerId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if playerId and amount and amount > 0 then
        -- Check if player is nearby
        local nearbyPlayers = exports['walsh']:GetNearbyPlayers()
        local targetFound = false
        
        for _, player in pairs(nearbyPlayers) do
            if player.id == playerId then
                targetFound = true
                break
            end
        end
        
        if targetFound then
            TriggerServerEvent('walsh:server:transferMoney', playerId, amount, 'cash')
        else
            TriggerEvent('walsh:client:notify', 'Player not nearby', 'error')
        end
    else
        TriggerEvent('walsh:client:notify', 'Usage: /givemoney [player_id] [amount]', 'error')
    end
end, false)

-- Paycheck notification
RegisterNetEvent('walsh:client:receivePaycheck')
AddEventHandler('walsh:client:receivePaycheck', function(amount, job)
    SendNUIMessage({
        type = 'showPaycheck',
        amount = amount,
        job = job
    })
end)

-- Money laundering locations (for criminal activities)
local launderingLocations = {
    {
        name = "Laundromat",
        coords = vector3(1122.0, -3193.6, -40.4),
        blip = false -- Hidden from legitimate players
    }
}

-- Business management
local playerBusinesses = {}

RegisterNetEvent('walsh:client:updateBusinesses')
AddEventHandler('walsh:client:updateBusinesses', function(businesses)
    playerBusinesses = businesses
    
    SendNUIMessage({
        type = 'updateBusinesses',
        businesses = businesses
    })
end)

-- Robbery system for stores
local robberyInProgress = false
local robberyTarget = nil

RegisterCommand('rob', function()
    if robberyInProgress then
        TriggerEvent('walsh:client:notify', 'Robbery already in progress', 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local playerData = GetPlayerData()
    
    -- Check if player has weapon
    local weaponHash = GetSelectedPedWeapon(PlayerPedId())
    if weaponHash == GetHashKey('WEAPON_UNARMED') then
        TriggerEvent('walsh:client:notify', 'You need a weapon to rob', 'error')
        return
    end
    
    -- Find nearby store
    for _, store in pairs(stores) do
        local distance = #(playerCoords - store.coords)
        
        if distance < 3.0 then
            StartRobbery(store)
            break
        end
    end
end, false)

function StartRobbery(store)
    robberyInProgress = true
    robberyTarget = store
    
    TriggerEvent('walsh:client:notify', 'Robbery started! Stay in the area!', 'info')
    TriggerServerEvent('walsh:server:startRobbery', store.name)
    
    -- Start robbery timer
    Citizen.CreateThread(function()
        local robTime = 30000 -- 30 seconds
        local startTime = GetGameTimer()
        
        while robberyInProgress and (GetGameTimer() - startTime) < robTime do
            Wait(1000)
            
            -- Check if player left area
            local currentCoords = GetEntityCoords(PlayerPedId())
            local distance = #(currentCoords - store.coords)
            
            if distance > 10.0 then
                TriggerEvent('walsh:client:notify', 'You left the area! Robbery failed!', 'error')
                robberyInProgress = false
                robberyTarget = nil
                return
            end
            
            -- Update UI with remaining time
            local remainingTime = math.max(0, robTime - (GetGameTimer() - startTime))
            SendNUIMessage({
                type = 'updateRobberyProgress',
                timeLeft = math.ceil(remainingTime / 1000)
            })
        end
        
        if robberyInProgress then
            -- Robbery successful
            local reward = math.random(500, 2000)
            TriggerServerEvent('walsh:server:completeRobbery', store.name, reward)
            TriggerEvent('walsh:client:notify', 'Robbery completed! Received $' .. reward, 'success')
        end
        
        robberyInProgress = false
        robberyTarget = nil
        
        SendNUIMessage({
            type = 'hideRobberyProgress'
        })
    end)
end

-- Export functions
exports('OpenATM', OpenATM)
exports('OpenBank', OpenBank)
exports('OpenStore', OpenStore)
exports('IsRobberyInProgress', function() return robberyInProgress end)
