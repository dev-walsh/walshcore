-- Client Main Module
local PlayerData = {}
local isLoggedIn = false
local isDead = false
local isHandcuffed = false
local inRedZone = false
local currentZone = nil

-- Framework initialization
Citizen.CreateThread(function()
    while not HasStreamedTextureDictLoaded('mpleaderboard') do
        RequestStreamedTextureDict('mpleaderboard', true)
        Citizen.Wait(0)
    end
    
    TriggerServerEvent('walsh:server:playerReady')
end)

-- Player loaded event
RegisterNetEvent('walsh:client:playerLoaded')
AddEventHandler('walsh:client:playerLoaded', function(playerData)
    PlayerData = playerData
    isLoggedIn = true
    
    -- Initialize UI
    SendNUIMessage({
        type = 'updatePlayerData',
        data = playerData
    })
    
    -- Start client threads
    StartMoneyDisplay()
    StartPlayerStatusCheck()
    StartRedZoneMonitoring()
    
    TriggerEvent('walsh:client:playerReady')
end)

-- Money update
RegisterNetEvent('walsh:client:updateMoney')
AddEventHandler('walsh:client:updateMoney', function(money, bank)
    if PlayerData then
        PlayerData.money = money
        PlayerData.bank = bank
        
        SendNUIMessage({
            type = 'updateMoney',
            money = money,
            bank = bank
        })
    end
end)

-- Notification system
RegisterNetEvent('walsh:client:notify')
AddEventHandler('walsh:client:notify', function(message, type)
    SendNUIMessage({
        type = 'showNotification',
        message = message,
        notificationType = type or 'info'
    })
end)

-- Job update
RegisterNetEvent('walsh:client:jobUpdate')
AddEventHandler('walsh:client:jobUpdate', function(job, grade)
    if PlayerData then
        PlayerData.job = job
        PlayerData.job_grade = grade
        
        SendNUIMessage({
            type = 'updateJob',
            job = job,
            grade = grade
        })
    end
end)

-- Gang update
RegisterNetEvent('walsh:client:gangUpdate')
AddEventHandler('walsh:client:gangUpdate', function(gang, grade)
    if PlayerData then
        PlayerData.gang = gang
        PlayerData.gang_grade = grade
        
        SendNUIMessage({
            type = 'updateGang',
            gang = gang,
            grade = grade
        })
    end
end)

-- Death system
RegisterNetEvent('walsh:client:playerDied')
AddEventHandler('walsh:client:playerDied', function()
    isDead = true
    local playerPed = PlayerPedId()
    
    -- Play death animation
    RequestAnimDict('dead')
    while not HasAnimDictLoaded('dead') do
        Citizen.Wait(0)
    end
    
    TaskPlayAnim(playerPed, 'dead', 'dead_a', 1.0, 1.0, -1, 2, 0, 0, 0, 0)
    
    -- Disable controls
    Citizen.CreateThread(function()
        while isDead do
            Citizen.Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Camera look
            EnableControlAction(0, 2, true) -- Camera look
        end
    end)
    
    -- Show death screen
    SendNUIMessage({
        type = 'showDeathScreen',
        show = true
    })
end)

RegisterNetEvent('walsh:client:revivePlayer')
AddEventHandler('walsh:client:revivePlayer', function()
    isDead = false
    local playerPed = PlayerPedId()
    
    -- Clear death animation
    ClearPedTasksImmediately(playerPed)
    
    -- Restore health
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    
    -- Hide death screen
    SendNUIMessage({
        type = 'showDeathScreen',
        show = false
    })
end)

-- Elimination warning
RegisterNetEvent('walsh:client:eliminatePlayer')
AddEventHandler('walsh:client:eliminatePlayer', function()
    SendNUIMessage({
        type = 'showElimination',
        show = true
    })
    
    -- Play elimination sound
    PlaySoundFrontend(-1, "LOSER", "HUD_AWARDS", 1)
end)

-- Handcuff system
RegisterNetEvent('walsh:client:handcuff')
AddEventHandler('walsh:client:handcuff', function(cuffed)
    isHandcuffed = cuffed
    local playerPed = PlayerPedId()
    
    if cuffed then
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do
            Citizen.Wait(0)
        end
        
        TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
        
        -- Disable movement
        Citizen.CreateThread(function()
            while isHandcuffed do
                Citizen.Wait(0)
                DisableControlAction(0, 21, true) -- Sprint
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisableControlAction(0, 47, true) -- Weapon wheel
                DisableControlAction(0, 58, true) -- Weapon wheel
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 264, true) -- Melee Attack 2
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 140, true) -- Melee Attack Light
                DisableControlAction(0, 141, true) -- Melee Attack Heavy
                DisableControlAction(0, 142, true) -- Melee Attack Alternate
                DisableControlAction(0, 143, true) -- Melee Block
            end
        end)
    else
        ClearPedTasksImmediately(playerPed)
    end
end)

-- Position saving
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Save every 30 seconds
        
        if isLoggedIn and not isDead then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            TriggerServerEvent('walsh:server:updatePosition', coords, heading)
        end
    end
end)

-- Money display thread
function StartMoneyDisplay()
    Citizen.CreateThread(function()
        while isLoggedIn do
            Wait(1000)
            
            if PlayerData then
                -- Check if money is getting low
                if PlayerData.money < Config.MinMoneyToSurvive * 0.2 then -- 20% of requirement
                    SendNUIMessage({
                        type = 'showLowMoneyWarning',
                        show = true,
                        amount = PlayerData.money,
                        required = Config.MinMoneyToSurvive
                    })
                else
                    SendNUIMessage({
                        type = 'showLowMoneyWarning',
                        show = false
                    })
                end
            end
        end
    end)
end

-- Player status check
function StartPlayerStatusCheck()
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            
            if isLoggedIn then
                local playerPed = PlayerPedId()
                
                -- Check if player died
                if IsEntityDead(playerPed) and not isDead then
                    local killer = GetPedSourceOfDeath(playerPed)
                    local killerId = NetworkGetPlayerIndexFromPed(killer)
                    
                    if killerId ~= -1 then
                        TriggerServerEvent('walsh:server:playerDied', 'Killed by player')
                    else
                        TriggerServerEvent('walsh:server:playerDied', 'Other')
                    end
                    
                    TriggerEvent('walsh:client:playerDied')
                end
                
                -- Check if player respawned
                if not IsEntityDead(playerPed) and isDead then
                    TriggerServerEvent('walsh:server:playerRespawned')
                    TriggerEvent('walsh:client:revivePlayer')
                end
            end
        end
    end)
end

-- Red zone monitoring
function StartRedZoneMonitoring()
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            
            if isLoggedIn then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local wasInRedZone = inRedZone
                inRedZone = false
                currentZone = nil
                
                -- Check all red zones
                for _, zone in pairs(Config.RedZones) do
                    local distance = #(vector3(zone.coords.x, zone.coords.y, zone.coords.z) - playerCoords)
                    
                    if distance <= zone.radius then
                        inRedZone = true
                        currentZone = zone
                        break
                    end
                end
                
                -- Zone entry/exit events
                if inRedZone and not wasInRedZone then
                    TriggerEvent('walsh:client:enteredRedZone', currentZone)
                elseif not inRedZone and wasInRedZone then
                    TriggerEvent('walsh:client:leftRedZone')
                end
            end
        end
    end)
end

-- Admin functions
RegisterNetEvent('walsh:client:teleportPlayer')
AddEventHandler('walsh:client:teleportPlayer', function(coords)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent('walsh:client:healPlayer')
AddEventHandler('walsh:client:healPlayer', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    SetPedArmour(playerPed, 100)
end)

local noclipEnabled = false
RegisterNetEvent('walsh:client:toggleNoclip')
AddEventHandler('walsh:client:toggleNoclip', function()
    noclipEnabled = not noclipEnabled
    local playerPed = PlayerPedId()
    
    SetEntityInvincible(playerPed, noclipEnabled)
    SetEntityVisible(playerPed, not noclipEnabled, 0)
    SetEntityCollision(playerPed, not noclipEnabled, true)
    FreezeEntityPosition(playerPed, noclipEnabled)
    
    if noclipEnabled then
        TriggerEvent('walsh:client:notify', 'Noclip enabled', 'success')
    else
        TriggerEvent('walsh:client:notify', 'Noclip disabled', 'info')
    end
end)

local godmodeEnabled = false
RegisterNetEvent('walsh:client:toggleGodmode')
AddEventHandler('walsh:client:toggleGodmode', function()
    godmodeEnabled = not godmodeEnabled
    local playerPed = PlayerPedId()
    
    SetEntityInvincible(playerPed, godmodeEnabled)
    
    if godmodeEnabled then
        TriggerEvent('walsh:client:notify', 'Godmode enabled', 'success')
    else
        TriggerEvent('walsh:client:notify', 'Godmode disabled', 'info')
    end
end)

local invisibleEnabled = false
RegisterNetEvent('walsh:client:toggleInvisible')
AddEventHandler('walsh:client:toggleInvisible', function()
    invisibleEnabled = not invisibleEnabled
    local playerPed = PlayerPedId()
    
    SetEntityVisible(playerPed, not invisibleEnabled, 0)
    
    if invisibleEnabled then
        TriggerEvent('walsh:client:notify', 'Invisible enabled', 'success')
    else
        TriggerEvent('walsh:client:notify', 'Invisible disabled', 'info')
    end
end)

-- Announcement system
RegisterNetEvent('walsh:client:announce')
AddEventHandler('walsh:client:announce', function(message, sender)
    SendNUIMessage({
        type = 'showAnnouncement',
        message = message,
        sender = sender
    })
end)

-- Utility functions
function GetPlayerData()
    return PlayerData
end

function IsPlayerDead()
    return isDead
end

function IsPlayerHandcuffed()
    return isHandcuffed
end

function IsInRedZone()
    return inRedZone
end

function GetCurrentRedZone()
    return currentZone
end

-- Export functions
exports('GetPlayerData', GetPlayerData)
exports('IsPlayerDead', IsPlayerDead)
exports('IsPlayerHandcuffed', IsPlayerHandcuffed)
exports('IsInRedZone', IsInRedZone)
exports('GetCurrentRedZone', GetCurrentRedZone)
