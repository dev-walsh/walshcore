-- Client Red Zone Module

local redZoneBlips = {}
local inRedZone = false
local currentRedZone = nil
local redZoneParticles = {}

-- Initialize red zones
Citizen.CreateThread(function()
    Wait(1000) -- Wait for config to load
    
    CreateRedZoneBlips()
    StartRedZoneMonitoring()
end)

function CreateRedZoneBlips()
    for _, zone in pairs(Config.RedZones) do
        -- Create zone blip
        local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(blip, 84)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 1) -- Red
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Red Zone: " .. zone.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(redZoneBlips, blip)
        
        -- Create radius blip
        local radiusBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipHighDetail(radiusBlip, true)
        SetBlipColour(radiusBlip, 1)
        SetBlipAlpha(radiusBlip, 100)
        
        table.insert(redZoneBlips, radiusBlip)
    end
end

function StartRedZoneMonitoring()
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local wasInRedZone = inRedZone
            local oldZone = currentRedZone
            
            inRedZone = false
            currentRedZone = nil
            
            -- Check all red zones
            for _, zone in pairs(Config.RedZones) do
                local distance = #(vector3(zone.coords.x, zone.coords.y, zone.coords.z) - playerCoords)
                
                if distance <= zone.radius then
                    inRedZone = true
                    currentRedZone = zone
                    break
                end
            end
            
            -- Handle zone transitions
            if inRedZone and not wasInRedZone then
                OnEnterRedZone(currentRedZone)
            elseif not inRedZone and wasInRedZone then
                OnExitRedZone(oldZone)
            end
        end
    end)
end

function OnEnterRedZone(zone)
    TriggerEvent('walsh:client:enteredRedZone', zone)
    
    -- Show red zone warning
    SendNUIMessage({
        type = 'showRedZoneWarning',
        zone = zone,
        show = true
    })
    
    -- Play warning sound
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 1)
    
    -- Start visual effects
    StartRedZoneEffects(zone)
    
    -- Notify player
    TriggerEvent('walsh:client:notify', 'Entered Red Zone: ' .. zone.name .. ' - PvP ENABLED!', 'error')
end

function OnExitRedZone(zone)
    TriggerEvent('walsh:client:leftRedZone')
    
    -- Hide red zone warning
    SendNUIMessage({
        type = 'showRedZoneWarning',
        show = false
    })
    
    -- Stop visual effects
    StopRedZoneEffects()
    
    -- Notify player
    TriggerEvent('walsh:client:notify', 'Left Red Zone - PvP DISABLED', 'success')
end

function StartRedZoneEffects(zone)
    -- Screen tint effect
    SetTimecycleModifier('glasses_red')
    SetTimecycleModifierStrength(0.3)
    
    -- Screen border effect
    SendNUIMessage({
        type = 'showRedZoneBorder',
        show = true
    })
    
    -- Particle effects around zone border
    CreateRedZoneParticles(zone)
end

function StopRedZoneEffects()
    -- Remove screen effects
    ClearTimecycleModifier()
    
    SendNUIMessage({
        type = 'showRedZoneBorder',
        show = false
    })
    
    -- Remove particles
    RemoveRedZoneParticles()
end

function CreateRedZoneParticles(zone)
    Citizen.CreateThread(function()
        local particleDict = "scr_agencyheistb"
        local particleName = "scr_env_agency3b_smoke"
        
        RequestNamedPtfxAsset(particleDict)
        while not HasNamedPtfxAssetLoaded(particleDict) do
            Wait(0)
        end
        
        while inRedZone do
            for i = 1, 8 do
                local angle = (i * 45) * math.pi / 180
                local x = zone.coords.x + math.cos(angle) * zone.radius
                local y = zone.coords.y + math.sin(angle) * zone.radius
                local z = zone.coords.z
                
                UseParticleFxAssetNextCall(particleDict)
                local particle = StartParticleFxLoopedAtCoord(particleName, x, y, z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                table.insert(redZoneParticles, particle)
            end
            
            Wait(5000) -- Update particles every 5 seconds
            
            -- Clean up old particles
            for j = #redZoneParticles, 1, -1 do
                StopParticleFxLooped(redZoneParticles[j], 0)
                table.remove(redZoneParticles, j)
            end
        end
    end)
end

function RemoveRedZoneParticles()
    for _, particle in pairs(redZoneParticles) do
        StopParticleFxLooped(particle, 0)
    end
    redZoneParticles = {}
end

-- Red zone combat events
RegisterNetEvent('walsh:client:zoneContest')
AddEventHandler('walsh:client:zoneContest', function(contestData)
    SendNUIMessage({
        type = 'showZoneContest',
        data = contestData
    })
    
    -- Play contest sound
    PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", 1)
end)

RegisterNetEvent('walsh:client:zoneControlChange')
AddEventHandler('walsh:client:zoneControlChange', function(controlData)
    SendNUIMessage({
        type = 'showZoneControlChange',
        data = controlData
    })
    
    -- Update zone blip color based on controlling gang
    UpdateZoneBlipColor(controlData.zoneName, controlData.newController)
end)

RegisterNetEvent('walsh:client:zoneNeutral')
AddEventHandler('walsh:client:zoneNeutral', function(neutralData)
    SendNUIMessage({
        type = 'showZoneNeutral',
        data = neutralData
    })
    
    -- Reset zone blip to default color
    UpdateZoneBlipColor(neutralData.zoneName, nil)
end)

function UpdateZoneBlipColor(zoneName, controllingGang)
    -- This would update the blip color based on which gang controls it
    -- For now, we'll keep it simple
    for i, blip in pairs(redZoneBlips) do
        -- Skip radius blips (odd indices are zone blips, even are radius blips)
        if i % 2 == 1 then
            if controllingGang then
                SetBlipColour(blip, GetGangColor(controllingGang))
            else
                SetBlipColour(blip, 1) -- Default red
            end
        end
    end
end

function GetGangColor(gangName)
    local gangColors = {
        ["bloods"] = 1,    -- Red
        ["crips"] = 9,     -- Blue  
        ["grove"] = 2,     -- Green
        ["ballas"] = 27,   -- Purple
        ["vagos"] = 5      -- Yellow
    }
    
    return gangColors[gangName] or 1
end

-- PvP kill tracking in red zones
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        if inRedZone then
            local playerPed = PlayerPedId()
            
            -- Check if player was killed
            if IsEntityDead(playerPed) then
                local killer = GetPedSourceOfDeath(playerPed)
                local killerId = NetworkGetPlayerIndexFromPed(killer)
                
                if killerId ~= -1 then
                    local killerServerId = GetPlayerServerId(killerId)
                    TriggerServerEvent('walsh:server:playerKilledInRedZone', killerServerId, currentRedZone.name)
                end
                
                Wait(5000) -- Prevent spam
            end
        end
    end
end)

-- Red zone commands
RegisterCommand('zones', function()
    ShowRedZoneStatus()
end, false)

function ShowRedZoneStatus()
    TriggerServerCallback('walsh:server:getZoneStatus', function(zoneStatus)
        local statusText = "Red Zone Status:\n\n"
        
        for zoneName, status in pairs(zoneStatus) do
            statusText = statusText .. zoneName .. ":\n"
            if status.controlling_gang then
                statusText = statusText .. "  Controlled by: " .. status.controlling_gang .. "\n"
                if status.control_start then
                    local controlTime = os.time() - status.control_start
                    statusText = statusText .. "  Control time: " .. math.floor(controlTime / 60) .. " minutes\n"
                end
            else
                statusText = statusText .. "  Status: Neutral\n"
            end
            statusText = statusText .. "\n"
        end
        
        SendNUIMessage({
            type = 'showZoneStatus',
            status = statusText
        })
        SetNuiFocus(true, true)
    end)
end

-- Red zone minimap
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        if inRedZone and currentRedZone then
            -- Show minimap indicator
            SendNUIMessage({
                type = 'updateMinimapRedZone',
                show = true,
                zone = currentRedZone.name
            })
        else
            SendNUIMessage({
                type = 'updateMinimapRedZone',
                show = false
            })
        end
    end
end)

-- Enhanced PvP mechanics in red zones
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if inRedZone then
            local playerPed = PlayerPedId()
            
            -- Increase damage in red zones
            SetPlayerWeaponDamageModifier(PlayerId(), 1.5)
            
            -- Reduce vehicle lock-on time
            SetPlayerCanUseCover(PlayerId(), false)
            
            -- Show enemy players on minimap
            for _, playerId in ipairs(GetActivePlayers()) do
                if playerId ~= PlayerId() then
                    local targetPed = GetPlayerPed(playerId)
                    local targetCoords = GetEntityCoords(targetPed)
                    
                    -- Check if target is also in red zone
                    local distance = #(targetCoords - vector3(currentRedZone.coords.x, currentRedZone.coords.y, currentRedZone.coords.z))
                    if distance <= currentRedZone.radius then
                        SetPlayerBlipPositionThisFrame(playerId)
                    end
                end
            end
        else
            -- Reset damage modifier outside red zones
            SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
            SetPlayerCanUseCover(PlayerId(), true)
        end
    end
end)

-- Red zone loot spawning
local redZoneLoot = {}

Citizen.CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        
        for _, zone in pairs(Config.RedZones) do
            SpawnRedZoneLoot(zone)
        end
    end
end)

function SpawnRedZoneLoot(zone)
    -- Random chance to spawn loot
    if math.random() < 0.3 then -- 30% chance
        local lootCoords = {
            x = zone.coords.x + math.random(-zone.radius, zone.radius),
            y = zone.coords.y + math.random(-zone.radius, zone.radius),
            z = zone.coords.z
        }
        
        -- Spawn loot pickup
        local lootItems = {"weapon_ammo", "money", "health_kit"}
        local lootType = lootItems[math.random(#lootItems)]
        
        redZoneLoot[#redZoneLoot + 1] = {
            coords = lootCoords,
            type = lootType,
            spawned = GetGameTimer()
        }
        
        -- Create visual indicator
        SendNUIMessage({
            type = 'addLootMarker',
            coords = lootCoords,
            type = lootType
        })
    end
end

-- Loot collection
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for i = #redZoneLoot, 1, -1 do
            local loot = redZoneLoot[i]
            local distance = #(playerCoords - vector3(loot.coords.x, loot.coords.y, loot.coords.z))
            
            if distance < 2.0 then
                -- Collect loot
                CollectRedZoneLoot(loot)
                table.remove(redZoneLoot, i)
            elseif GetGameTimer() - loot.spawned > 600000 then -- 10 minutes
                -- Remove expired loot
                table.remove(redZoneLoot, i)
            end
        end
    end
end)

function CollectRedZoneLoot(loot)
    if loot.type == "weapon_ammo" then
        TriggerServerEvent('walsh:server:giveAmmo', 50)
        TriggerEvent('walsh:client:notify', 'Found ammo!', 'success')
    elseif loot.type == "money" then
        local amount = math.random(500, 2000)
        TriggerServerEvent('walsh:server:addMoney', amount)
        TriggerEvent('walsh:client:notify', 'Found $' .. amount .. '!', 'success')
    elseif loot.type == "health_kit" then
        local playerPed = PlayerPedId()
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        TriggerEvent('walsh:client:notify', 'Found health kit!', 'success')
    end
    
    SendNUIMessage({
        type = 'removeLootMarker',
        coords = loot.coords
    })
end

-- Export functions
exports('IsInRedZone', function() return inRedZone end)
exports('GetCurrentRedZone', function() return currentRedZone end)
exports('GetRedZoneLoot', function() return redZoneLoot end)
