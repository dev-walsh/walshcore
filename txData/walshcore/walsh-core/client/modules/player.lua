-- Client Player Module

local playerLoaded = false
local playerSpawned = false

-- Player spawn handling
AddEventHandler('playerSpawned', function()
    playerSpawned = true
    
    -- Wait for player data to load
    while not playerLoaded do
        Wait(100)
    end
    
    -- Set player appearance if available
    local playerData = GetPlayerData()
    if playerData and playerData.skin then
        ApplyPlayerSkin(playerData.skin)
    end
    
    -- Set player loadout
    if playerData and playerData.loadout then
        ApplyPlayerLoadout(playerData.loadout)
    end
end)

RegisterNetEvent('walsh:client:playerReady')
AddEventHandler('walsh:client:playerReady', function()
    playerLoaded = true
end)

-- Player appearance system
function ApplyPlayerSkin(skinData)
    local playerPed = PlayerPedId()
    
    if skinData.model then
        local modelHash = GetHashKey(skinData.model)
        RequestModel(modelHash)
        
        while not HasModelLoaded(modelHash) do
            Wait(0)
        end
        
        SetPlayerModel(PlayerId(), modelHash)
        SetModelAsNoLongerNeeded(modelHash)
    end
    
    -- Apply clothing and features
    if skinData.components then
        for i, component in pairs(skinData.components) do
            SetPedComponentVariation(playerPed, i, component.drawable, component.texture, component.palette)
        end
    end
    
    if skinData.props then
        for i, prop in pairs(skinData.props) do
            SetPedPropIndex(playerPed, i, prop.drawable, prop.texture, true)
        end
    end
end

-- Player loadout system
function ApplyPlayerLoadout(loadout)
    local playerPed = PlayerPedId()
    
    -- Remove all weapons first
    RemoveAllPedWeapons(playerPed, true)
    
    -- Give weapons from loadout
    for weaponName, weaponData in pairs(loadout) do
        local weaponHash = GetHashKey(weaponName)
        GiveWeaponToPed(playerPed, weaponHash, weaponData.ammo or 0, false, true)
    end
end

-- Weapon events
RegisterNetEvent('walsh:client:receiveWeapon')
AddEventHandler('walsh:client:receiveWeapon', function(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    GiveWeaponToPed(playerPed, weaponHash, ammo or 0, false, true)
    TriggerEvent('walsh:client:notify', 'Received weapon: ' .. weaponName, 'success')
end)

RegisterNetEvent('walsh:client:removeWeapon')
AddEventHandler('walsh:client:removeWeapon', function(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    RemoveWeaponFromPed(playerPed, weaponHash)
    TriggerEvent('walsh:client:notify', 'Weapon removed: ' .. weaponName, 'info')
end)

RegisterNetEvent('walsh:client:updateAmmo')
AddEventHandler('walsh:client:updateAmmo', function(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    SetPedAmmo(playerPed, weaponHash, ammo)
end)

-- Status updates
RegisterNetEvent('walsh:client:statusUpdate')
AddEventHandler('walsh:client:statusUpdate', function(status, value)
    SendNUIMessage({
        type = 'updateStatus',
        status = status,
        value = value
    })
    
    -- Handle specific status effects
    if status == 'hunger' then
        TriggerEvent('walsh:client:updateHunger', value)
    elseif status == 'thirst' then
        TriggerEvent('walsh:client:updateThirst', value)
    elseif status == 'stress' then
        TriggerEvent('walsh:client:updateStress', value)
    end
end)

-- Player actions
RegisterNetEvent('walsh:client:playAnimation')
AddEventHandler('walsh:client:playAnimation', function(animDict, animName, duration, flag)
    local playerPed = PlayerPedId()
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, duration or -1, flag or 0, 0, false, false, false)
end)

RegisterNetEvent('walsh:client:playScenario')
AddEventHandler('walsh:client:playScenario', function(scenario, duration)
    local playerPed = PlayerPedId()
    
    TaskStartScenarioInPlace(playerPed, scenario, 0, true)
    
    if duration then
        Wait(duration)
        ClearPedTasksImmediately(playerPed)
    end
end)

-- Player clothing shops
local clothingShops = {
    {x = 72.3, y = -1399.1, z = 29.4, blip = true},
    {x = -703.8, y = -152.3, z = 37.4, blip = true},
    {x = -167.9, y = -299.0, z = 39.7, blip = true},
    {x = 428.7, y = -800.1, z = 29.5, blip = true}
}

-- Create clothing shop blips
Citizen.CreateThread(function()
    for _, shop in pairs(clothingShops) do
        if shop.blip then
            local blip = AddBlipForCoord(shop.x, shop.y, shop.z)
            SetBlipSprite(blip, 73)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 47)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Clothing Store")
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Clothing shop interaction
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, shop in pairs(clothingShops) do
            local distance = #(playerCoords - vector3(shop.x, shop.y, shop.z))
            
            if distance < 10.0 then
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    text = 'Press E to open clothing store',
                    show = true
                })
                
                if distance < 3.0 and IsControlJustReleased(0, 38) then
                    OpenClothingStore()
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

function OpenClothingStore()
    SendNUIMessage({
        type = 'showClothingStore',
        show = true
    })
    SetNuiFocus(true, true)
end

-- Character creation/customization
RegisterNetEvent('walsh:client:openCharacterCreation')
AddEventHandler('walsh:client:openCharacterCreation', function()
    SendNUIMessage({
        type = 'showCharacterCreation',
        show = true
    })
    SetNuiFocus(true, true)
    
    -- Freeze player during creation
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false, 0)
    
    -- Create camera for character viewing
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local coords = GetEntityCoords(playerPed)
    SetCamCoord(cam, coords.x, coords.y - 3.0, coords.z + 1.0)
    SetCamRot(cam, 0.0, 0.0, 0.0, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
end)

-- Save character appearance
RegisterNUICallback('saveCharacterAppearance', function(data, cb)
    local playerPed = PlayerPedId()
    
    -- Apply the new appearance
    ApplyPlayerSkin(data.skinData)
    
    -- Save to server
    TriggerServerEvent('walsh:server:saveCharacterAppearance', data.skinData)
    
    -- Restore normal game state
    FreezeEntityPosition(playerPed, false)
    SetEntityVisible(playerPed, true, 0)
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(cam, false)
    
    CloseUI()
    cb('ok')
end)

-- Player identification
RegisterNetEvent('walsh:client:showID')
AddEventHandler('walsh:client:showID', function(playerData)
    SendNUIMessage({
        type = 'showPlayerID',
        data = playerData
    })
end)

-- Emote system
local emotes = {
    ["dance"] = {"anim@amb@nightclub@dancers@podium_dancers@", "hi_dance_facedj_17_v2_male^5"},
    ["salute"] = {"anim@mp_player_intuppersalute", "idle_a"},
    ["sit"] = {"anim@heists@fleeca_bank@ig_7_jetski_owner", "owner_idle"},
    ["kneel"] = {"random@arrests", "idle_2_hands_up"},
    ["surrender"] = {"random@arrests@busted", "idle_a"}
}

RegisterCommand('e', function(source, args, rawCommand)
    local emoteName = args[1]
    
    if emoteName and emotes[emoteName] then
        local emote = emotes[emoteName]
        TriggerEvent('walsh:client:playAnimation', emote[1], emote[2], -1, 49)
    else
        TriggerEvent('walsh:client:notify', 'Invalid emote. Available: ' .. table.concat(GetEmoteList(), ', '), 'error')
    end
end, false)

RegisterCommand('stopanim', function()
    ClearPedTasksImmediately(PlayerPedId())
end, false)

function GetEmoteList()
    local emoteList = {}
    for name, _ in pairs(emotes) do
        table.insert(emoteList, name)
    end
    return emoteList
end

-- Export functions
exports('GetPlayerLoaded', function() return playerLoaded end)
exports('GetPlayerSpawned', function() return playerSpawned end)
exports('ApplyPlayerSkin', ApplyPlayerSkin)
exports('ApplyPlayerLoadout', ApplyPlayerLoadout)
