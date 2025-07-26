-- Client Vehicle Module

local currentVehicle = nil
local vehicleKeys = {}
local engineRunning = false
local vehicleLocked = false

-- Vehicle spawning
RegisterNetEvent('walsh:client:spawnVehicle')
AddEventHandler('walsh:client:spawnVehicle', function(vehicleData, spawnCoords)
    local model = GetHashKey(vehicleData.model)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    -- Clear area first
    local area = GetEntityCoords(PlayerPedId())
    ClearAreaOfVehicles(area.x, area.y, area.z, 5.0, false, false, false, false, false)
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    
    -- Apply modifications if any
    if vehicleData.modifications then
        ApplyVehicleModifications(vehicle, vehicleData.modifications)
    end
    
    -- Set plate
    if vehicleData.plate then
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    end
    
    -- Give keys to player
    vehicleKeys[GetVehicleNumberPlateText(vehicle)] = true
    
    -- Warp player into vehicle
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    currentVehicle = vehicle
    
    TriggerEvent('walsh:client:notify', 'Vehicle spawned successfully', 'success')
    SetModelAsNoLongerNeeded(model)
end)

-- Vehicle deletion
RegisterNetEvent('walsh:client:deleteVehicle')
AddEventHandler('walsh:client:deleteVehicle', function()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
        currentVehicle = nil
        TriggerEvent('walsh:client:notify', 'Vehicle stored', 'success')
    end
end)

-- Vehicle repair
RegisterNetEvent('walsh:client:repairVehicle')
AddEventHandler('walsh:client:repairVehicle', function(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        -- Visual effect
        local coords = GetEntityCoords(vehicle)
        local particles = {"scr_recartheft", "scr_wheel_burnout"}
        
        RequestNamedPtfxAsset(particles[1])
        while not HasNamedPtfxAssetLoaded(particles[1]) do
            Wait(0)
        end
        
        UseParticleFxAssetNextCall(particles[1])
        StartParticleFxNonLoopedAtCoord(particles[2], coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end
end)

-- Vehicle modification system
function ApplyVehicleModifications(vehicle, mods)
    if not DoesEntityExist(vehicle) then return end
    
    -- Apply performance mods
    for modType, modIndex in pairs(mods) do
        if type(modType) == "number" and type(modIndex) == "number" then
            SetVehicleMod(vehicle, modType, modIndex, false)
        end
    end
    
    -- Apply colors
    if mods.primaryColor and mods.secondaryColor then
        SetVehicleColours(vehicle, mods.primaryColor, mods.secondaryColor)
    end
    
    -- Apply extras
    if mods.extras then
        for extraId, enabled in pairs(mods.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), not enabled)
        end
    end
    
    -- Apply neon lights
    if mods.neon then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, mods.neon.enabled or false)
        end
        if mods.neon.color then
            SetVehicleNeonLightsColour(vehicle, mods.neon.color.r, mods.neon.color.g, mods.neon.color.b)
        end
    end
    
    -- Apply window tint
    if mods.windowTint then
        SetVehicleWindowTint(vehicle, mods.windowTint)
    end
    
    -- Apply license plate
    if mods.plateStyle then
        SetVehicleNumberPlateTextIndex(vehicle, mods.plateStyle)
    end
end

-- Vehicle interaction system
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        
        -- Check for nearby vehicles
        local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
        
        if vehicle ~= 0 and not IsPedInAnyVehicle(playerPed, false) then
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehCoords)
            
            if distance < 3.0 then
                local plate = GetVehicleNumberPlateText(vehicle)
                local hasKeys = vehicleKeys[plate] or false
                
                -- Show interaction prompts
                if hasKeys then
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.0, "[E] Enter Vehicle | [L] Lock/Unlock")
                else
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.0, "[E] Try Door")
                end
                
                -- Handle input
                if IsControlJustReleased(0, 38) then -- E key
                    if hasKeys or not GetVehicleDoorsLockedForPlayer(vehicle, PlayerId()) then
                        TaskEnterVehicle(playerPed, vehicle, 10000, -1, 1.0, 1, 0)
                    else
                        TriggerEvent('walsh:client:notify', 'Vehicle is locked', 'error')
                    end
                elseif IsControlJustReleased(0, 183) and hasKeys then -- L key
                    ToggleVehicleLock(vehicle)
                end
            end
        end
        
        -- Vehicle controls when inside
        if IsPedInAnyVehicle(playerPed, false) then
            local veh = GetVehiclePedIsIn(playerPed, false)
            local plate = GetVehicleNumberPlateText(veh)
            
            if vehicleKeys[plate] then
                -- Engine toggle
                if IsControlJustReleased(0, 57) then -- F10
                    ToggleVehicleEngine(veh)
                end
                
                -- Handbrake
                if IsControlPressed(0, 76) then -- Space
                    SetVehicleHandbrake(veh, true)
                else
                    SetVehicleHandbrake(veh, false)
                end
            end
        end
    end
end)

-- Vehicle locking system
function ToggleVehicleLock(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    
    if vehicleKeys[plate] then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        
        if lockStatus == 1 then -- Unlocked
            SetVehicleDoorsLocked(vehicle, 2) -- Locked
            vehicleLocked = true
            TriggerEvent('walsh:client:notify', 'Vehicle locked', 'info')
            
            -- Play lock sound and lights
            StartVehicleAlarm(vehicle)
            Wait(500)
            StopVehicleAlarm(vehicle)
            
            -- Flash lights
            for i = 1, 3 do
                SetVehicleLights(vehicle, 2)
                Wait(100)
                SetVehicleLights(vehicle, 0)
                Wait(100)
            end
        else -- Locked
            SetVehicleDoorsLocked(vehicle, 1) -- Unlocked
            vehicleLocked = false
            TriggerEvent('walsh:client:notify', 'Vehicle unlocked', 'info')
            
            -- Flash lights once
            SetVehicleLights(vehicle, 2)
            Wait(200)
            SetVehicleLights(vehicle, 0)
        end
    end
end

-- Engine management
function ToggleVehicleEngine(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    
    if vehicleKeys[plate] then
        engineRunning = not engineRunning
        SetVehicleEngineOn(vehicle, engineRunning, true, true)
        
        if engineRunning then
            TriggerEvent('walsh:client:notify', 'Engine started', 'success')
        else
            TriggerEvent('walsh:client:notify', 'Engine stopped', 'info')
        end
    end
end

-- Vehicle shop system
local inVehicleShop = false
local shopVehicles = {}

RegisterNetEvent('walsh:client:openVehicleShop')
AddEventHandler('walsh:client:openVehicleShop', function(shopData)
    inVehicleShop = true
    shopVehicles = shopData.vehicles or {}
    
    SendNUIMessage({
        type = 'showVehicleShop',
        shop = shopData
    })
    SetNuiFocus(true, true)
    
    -- Spawn preview vehicles
    SpawnShopVehicles(shopData)
end)

function SpawnShopVehicles(shopData)
    local spawnCoords = shopData.coords
    local spacing = 8.0
    
    for i, vehicleData in ipairs(shopData.vehicles) do
        local model = GetHashKey(vehicleData.model)
        RequestModel(model)
        
        while not HasModelLoaded(model) do
            Wait(0)
        end
        
        local x = spawnCoords.x + ((i - 1) * spacing)
        local y = spawnCoords.y
        local z = spawnCoords.z
        
        local vehicle = CreateVehicle(model, x, y, z, 0.0, false, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        
        -- Make vehicle unenterable for preview
        SetVehicleDoorsLocked(vehicle, 2)
        
        -- Add to shop vehicles list for cleanup
        table.insert(shopVehicles, {
            entity = vehicle,
            model = vehicleData.model,
            price = vehicleData.price
        })
        
        SetModelAsNoLongerNeeded(model)
    end
end

function ClearShopVehicles()
    for _, vehData in pairs(shopVehicles) do
        if DoesEntityExist(vehData.entity) then
            DeleteVehicle(vehData.entity)
        end
    end
    shopVehicles = {}
end

-- Vehicle customization
RegisterNetEvent('walsh:client:openVehicleCustomization')
AddEventHandler('walsh:client:openVehicleCustomization', function()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local plate = GetVehicleNumberPlateText(vehicle)
        
        if vehicleKeys[plate] then
            SendNUIMessage({
                type = 'showVehicleCustomization',
                vehicle = {
                    model = GetEntityModel(vehicle),
                    plate = plate,
                    mods = GetCurrentVehicleMods(vehicle)
                }
            })
            SetNuiFocus(true, true)
        else
            TriggerEvent('walsh:client:notify', 'You don\'t own this vehicle', 'error')
        end
    else
        TriggerEvent('walsh:client:notify', 'You must be in a vehicle', 'error')
    end
end)

function GetCurrentVehicleMods(vehicle)
    local mods = {}
    
    -- Get all modification categories
    for i = 0, 48 do
        mods[i] = GetVehicleMod(vehicle, i)
    end
    
    -- Get colors
    local primary, secondary = GetVehicleColours(vehicle)
    mods.primaryColor = primary
    mods.secondaryColor = secondary
    
    -- Get window tint
    mods.windowTint = GetVehicleWindowTint(vehicle)
    
    -- Get neon lights
    mods.neon = {
        enabled = IsVehicleNeonLightEnabled(vehicle, 0),
        color = {}
    }
    mods.neon.color.r, mods.neon.color.g, mods.neon.color.b = GetVehicleNeonLightsColour(vehicle)
    
    return mods
end

-- Vehicle fuel system
local vehicleFuel = {}

Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local plate = GetVehicleNumberPlateText(vehicle)
            
            if vehicleKeys[plate] then
                -- Decrease fuel based on usage
                if not vehicleFuel[plate] then
                    vehicleFuel[plate] = 100.0 -- Start with full tank
                end
                
                local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                local fuelConsumption = (speed / 100) * 0.5 -- Base consumption
                
                vehicleFuel[plate] = math.max(0, vehicleFuel[plate] - fuelConsumption)
                
                -- Update UI
                SendNUIMessage({
                    type = 'updateVehicleFuel',
                    fuel = vehicleFuel[plate]
                })
                
                -- Handle empty tank
                if vehicleFuel[plate] <= 0 then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    TriggerEvent('walsh:client:notify', 'Vehicle out of fuel!', 'error')
                end
            end
        end
    end
end)

-- Gas station system
local gasStations = {
    {x = 49.4187, y = 2778.793, z = 58.043},
    {x = 263.894, y = 2606.463, z = 44.983},
    {x = 1039.958, y = 2671.134, z = 39.550},
    {x = 1207.260, y = 2660.175, z = 37.899},
    {x = 2539.685, y = 2594.192, z = 37.944}
}

Citizen.CreateThread(function()
    -- Create gas station blips
    for _, station in pairs(gasStations) do
        local blip = AddBlipForCoord(station.x, station.y, station.z)
        SetBlipSprite(blip, 361)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Gas Station")
        EndTextCommandSetBlipName(blip)
    end
    
    -- Gas station interaction
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearGasStation = false
        
        for _, station in pairs(gasStations) do
            local distance = #(playerCoords - vector3(station.x, station.y, station.z))
            
            if distance < 10.0 then
                nearGasStation = true
                
                local playerPed = PlayerPedId()
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    
                    if vehicleKeys[plate] and distance < 5.0 then
                        SendNUIMessage({
                            type = 'showInteractionPrompt',
                            text = 'Press E to refuel vehicle',
                            show = true
                        })
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            RefuelVehicle(vehicle, plate)
                        end
                    end
                end
                break
            end
        end
        
        if not nearGasStation then
            SendNUIMessage({
                type = 'showInteractionPrompt',
                show = false
            })
        end
    end
end)

function RefuelVehicle(vehicle, plate)
    local currentFuel = vehicleFuel[plate] or 0
    local fuelNeeded = 100 - currentFuel
    local fuelCost = math.ceil(fuelNeeded * 2) -- $2 per liter
    
    if fuelNeeded <= 0 then
        TriggerEvent('walsh:client:notify', 'Vehicle tank is already full', 'info')
        return
    end
    
    -- Start refueling animation
    local playerPed = PlayerPedId()
    RequestAnimDict("timetable@gardener@filling_can")
    while not HasAnimDictLoaded("timetable@gardener@filling_can") do
        Wait(0)
    end
    
    TaskPlayAnim(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 8.0, 8.0, -1, 50, 0, false, false, false)
    
    -- Show refueling progress
    SendNUIMessage({
        type = 'showRefuelProgress',
        cost = fuelCost,
        show = true
    })
    
    -- Refueling process
    Citizen.CreateThread(function()
        local refuelTime = fuelNeeded * 100 -- 100ms per liter
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < refuelTime do
            Wait(100)
            
            local progress = (GetGameTimer() - startTime) / refuelTime
            local currentFuelAmount = currentFuel + (fuelNeeded * progress)
            
            vehicleFuel[plate] = currentFuelAmount
            
            SendNUIMessage({
                type = 'updateRefuelProgress',
                progress = progress * 100,
                fuel = currentFuelAmount
            })
        end
        
        -- Complete refueling
        vehicleFuel[plate] = 100
        ClearPedTasksImmediately(playerPed)
        
        SendNUIMessage({
            type = 'showRefuelProgress',
            show = false
        })
        
        -- Charge player
        TriggerServerEvent('walsh:server:removeMoney', fuelCost, 'cash')
        TriggerEvent('walsh:client:notify', 'Vehicle refueled for $' .. fuelCost, 'success')
    end)
end

-- Utility functions
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

-- Export functions
exports('GetCurrentVehicle', function() return currentVehicle end)
exports('HasVehicleKeys', function(plate) return vehicleKeys[plate] or false end)
exports('GetVehicleFuel', function(plate) return vehicleFuel[plate] or 0 end)
exports('SetVehicleFuel', function(plate, fuel) vehicleFuel[plate] = fuel end)
