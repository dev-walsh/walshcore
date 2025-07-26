-- Client Weapon Module

local currentWeapons = {}
local weaponAttachments = {}
local isAiming = false
local inCombat = false
local lastShotTime = 0

-- Weapon receiving
RegisterNetEvent('walsh:client:receiveWeapon')
AddEventHandler('walsh:client:receiveWeapon', function(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    -- Give weapon to player
    GiveWeaponToPed(playerPed, weaponHash, ammo or 0, false, true)
    
    -- Store in current weapons
    currentWeapons[weaponName] = {
        hash = weaponHash,
        ammo = ammo or 0,
        attachments = {}
    }
    
    -- Update UI
    SendNUIMessage({
        type = 'addWeapon',
        weapon = weaponName,
        ammo = ammo
    })
    
    TriggerEvent('walsh:client:notify', 'Received: ' .. GetWeaponDisplayName(weaponName), 'success')
end)

-- Weapon removal
RegisterNetEvent('walsh:client:removeWeapon')
AddEventHandler('walsh:client:removeWeapon', function(weaponName)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    -- Remove from player
    RemoveWeaponFromPed(playerPed, weaponHash)
    
    -- Remove from current weapons
    currentWeapons[weaponName] = nil
    
    -- Update UI
    SendNUIMessage({
        type = 'removeWeapon',
        weapon = weaponName
    })
    
    TriggerEvent('walsh:client:notify', 'Removed: ' .. GetWeaponDisplayName(weaponName), 'info')
end)

-- Ammo update
RegisterNetEvent('walsh:client:updateAmmo')
AddEventHandler('walsh:client:updateAmmo', function(weaponName, ammo)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    
    -- Update ammo
    SetPedAmmo(playerPed, weaponHash, ammo)
    
    -- Update stored data
    if currentWeapons[weaponName] then
        currentWeapons[weaponName].ammo = ammo
    end
    
    -- Update UI
    SendNUIMessage({
        type = 'updateWeaponAmmo',
        weapon = weaponName,
        ammo = ammo
    })
end)

-- Weapon shops
local weaponShops = {
    {
        coords = vector3(1692.54, 3760.16, 34.71),
        name = "Sandy Shores Gun Shop",
        blip = true,
        requiresLicense = true
    },
    {
        coords = vector3(252.696, -50.0643, 69.941),
        name = "Downtown Gun Shop", 
        blip = true,
        requiresLicense = true
    },
    {
        coords = vector3(22.56, -1109.89, 29.80),
        name = "Little Seoul Gun Shop",
        blip = true,
        requiresLicense = true
    }
}

-- Create weapon shop blips
Citizen.CreateThread(function()
    for _, shop in pairs(weaponShops) do
        if shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, 110)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Weapon shop interaction
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, shop in pairs(weaponShops) do
            local distance = #(playerCoords - shop.coords)
            
            if distance < 5.0 then
                SendNUIMessage({
                    type = 'showInteractionPrompt',
                    text = 'Press E to open ' .. shop.name,
                    show = true
                })
                
                if distance < 3.0 and IsControlJustReleased(0, 38) then
                    OpenWeaponShop(shop)
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

function OpenWeaponShop(shop)
    TriggerServerCallback('walsh:server:getAvailableWeapons', function(weapons)
        SendNUIMessage({
            type = 'showWeaponShop',
            shop = shop,
            weapons = weapons
        })
        SetNuiFocus(true, true)
    end)
end

-- Combat system enhancements
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(playerPed)
        
        -- Check if player is aiming
        local wasAiming = isAiming
        isAiming = IsPlayerFreeAiming(PlayerId())
        
        if isAiming and not wasAiming then
            TriggerEvent('walsh:client:startAiming')
        elseif not isAiming and wasAiming then
            TriggerEvent('walsh:client:stopAiming')
        end
        
        -- Check if player is in combat
        local wasInCombat = inCombat
        inCombat = IsPedInCombat(playerPed, 0) or IsPlayerFreeAiming(PlayerId())
        
        if inCombat and not wasInCombat then
            TriggerEvent('walsh:client:enterCombat')
        elseif not inCombat and wasInCombat then
            TriggerEvent('walsh:client:exitCombat')
        end
        
        -- Track shots fired
        if IsPedShooting(playerPed) then
            local currentTime = GetGameTimer()
            if currentTime - lastShotTime > 100 then -- Prevent spam
                lastShotTime = currentTime
                TriggerEvent('walsh:client:weaponFired', currentWeapon)
                
                -- Update ammo count
                local ammo = GetAmmoInPedWeapon(playerPed, currentWeapon)
                local weaponName = GetWeaponNameFromHash(currentWeapon)
                if currentWeapons[weaponName] then
                    currentWeapons[weaponName].ammo = ammo
                    TriggerServerEvent('walsh:server:updateAmmo', weaponName, ammo)
                end
            end
        end
    end
end)

-- Weapon attachment system
RegisterNetEvent('walsh:client:addWeaponAttachment')
AddEventHandler('walsh:client:addWeaponAttachment', function(weaponName, attachment)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    local attachmentHash = GetHashKey(attachment)
    
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        GiveWeaponComponentToPed(playerPed, weaponHash, attachmentHash)
        
        -- Store attachment
        if not weaponAttachments[weaponName] then
            weaponAttachments[weaponName] = {}
        end
        table.insert(weaponAttachments[weaponName], attachment)
        
        TriggerEvent('walsh:client:notify', 'Attachment added: ' .. attachment, 'success')
    end
end)

-- Weapon customization
function OpenWeaponCustomization()
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    local weaponName = GetWeaponNameFromHash(currentWeapon)
    
    if currentWeapon ~= GetHashKey('WEAPON_UNARMED') then
        local attachments = GetAvailableAttachments(weaponName)
        
        SendNUIMessage({
            type = 'showWeaponCustomization',
            weapon = weaponName,
            attachments = attachments,
            currentAttachments = weaponAttachments[weaponName] or {}
        })
        SetNuiFocus(true, true)
    else
        TriggerEvent('walsh:client:notify', 'No weapon selected', 'error')
    end
end

function GetAvailableAttachments(weaponName)
    local attachments = {
        ['WEAPON_PISTOL'] = {
            'COMPONENT_AT_PI_FLSH',
            'COMPONENT_AT_PI_SUPP_02',
            'COMPONENT_PISTOL_CLIP_02'
        },
        ['WEAPON_ASSAULTRIFLE'] = {
            'COMPONENT_AT_AR_FLSH',
            'COMPONENT_AT_SCOPE_MACRO',
            'COMPONENT_AT_AR_SUPP_02',
            'COMPONENT_ASSAULTRIFLE_CLIP_02',
            'COMPONENT_AT_AR_AFGRIP'
        },
        ['WEAPON_SMG'] = {
            'COMPONENT_AT_PI_FLSH',
            'COMPONENT_AT_SCOPE_MACRO_02',
            'COMPONENT_AT_AR_SUPP_02',
            'COMPONENT_SMG_CLIP_02'
        }
    }
    
    return attachments[weaponName] or {}
end

-- Weapon display names
function GetWeaponDisplayName(weaponName)
    local displayNames = {
        ['WEAPON_PISTOL'] = 'Pistol',
        ['WEAPON_SMG'] = 'SMG',
        ['WEAPON_ASSAULTRIFLE'] = 'Assault Rifle',
        ['WEAPON_SNIPERRIFLE'] = 'Sniper Rifle',
        ['WEAPON_SHOTGUN'] = 'Shotgun',
        ['WEAPON_KNIFE'] = 'Knife',
        ['WEAPON_BAT'] = 'Baseball Bat'
    }
    
    return displayNames[weaponName] or weaponName
end

function GetWeaponNameFromHash(hash)
    for weaponName, weaponData in pairs(currentWeapons) do
        if weaponData.hash == hash then
            return weaponName
        end
    end
    return nil
end

-- Black market weapons (gang-only)
local blackMarkets = {
    {
        coords = vector3(-1150.0, -1520.0, 10.6),
        name = "Underground Arms",
        gangsOnly = true,
        blip = false
    }
}

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerData = GetPlayerData()
        if playerData and playerData.gang then
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for _, market in pairs(blackMarkets) do
                local distance = #(playerCoords - market.coords)
                
                if distance < 5.0 then
                    SendNUIMessage({
                        type = 'showInteractionPrompt',
                        text = 'Press E to access black market',
                        show = true
                    })
                    
                    if distance < 3.0 and IsControlJustReleased(0, 38) then
                        OpenBlackMarket(market)
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
    end
end)

function OpenBlackMarket(market)
    local blackMarketWeapons = {
        {name = 'WEAPON_ASSAULTRIFLE', price = 45000},
        {name = 'WEAPON_SMG', price = 20000},
        {name = 'WEAPON_SNIPERRIFLE', price = 85000},
        {name = 'WEAPON_RPG', price = 150000}
    }
    
    SendNUIMessage({
        type = 'showBlackMarket',
        market = market,
        weapons = blackMarketWeapons
    })
    SetNuiFocus(true, true)
end

-- Weapon damage modification in red zones
RegisterNetEvent('walsh:client:enteredRedZone')
AddEventHandler('walsh:client:enteredRedZone', function(zone)
    -- Increase weapon damage in red zones
    local playerPed = PlayerPedId()
    SetPlayerWeaponDamageModifier(PlayerId(), 1.5)
    
    TriggerEvent('walsh:client:notify', 'Enhanced combat mode activated', 'error')
end)

RegisterNetEvent('walsh:client:leftRedZone')
AddEventHandler('walsh:client:leftRedZone', function()
    -- Reset weapon damage
    SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
end)

-- Weapon wheel customization
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        -- Disable default weapon wheel
        DisableControlAction(0, 37, true)
        
        -- Custom weapon wheel trigger
        if IsControlJustPressed(0, 37) then -- TAB
            OpenCustomWeaponWheel()
        end
    end
end)

function OpenCustomWeaponWheel()
    local playerWeapons = {}
    
    for weaponName, weaponData in pairs(currentWeapons) do
        table.insert(playerWeapons, {
            name = weaponName,
            displayName = GetWeaponDisplayName(weaponName),
            ammo = weaponData.ammo,
            attachments = weaponAttachments[weaponName] or {}
        })
    end
    
    SendNUIMessage({
        type = 'showWeaponWheel',
        weapons = playerWeapons
    })
    SetNuiFocus(true, true)
end

-- Weapon holstering
RegisterCommand('holster', function()
    local playerPed = PlayerPedId()
    SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
    TriggerEvent('walsh:client:notify', 'Weapon holstered', 'info')
end, false)

-- Weapon reloading enhancements
Citizen.CreateThread(function()
    while true do
        Wait(100)
        
        local playerPed = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(playerPed)
        
        if currentWeapon ~= GetHashKey('WEAPON_UNARMED') then
            local maxAmmo = GetMaxAmmoInClip(playerPed, currentWeapon, true)
            local currentAmmoInClip = GetAmmoInClip(playerPed, currentWeapon)
            
            -- Auto-reload when clip is empty and ammo is available
            if currentAmmoInClip == 0 and GetAmmoInPedWeapon(playerPed, currentWeapon) > 0 then
                -- Show reload prompt
                SendNUIMessage({
                    type = 'showReloadPrompt',
                    show = true
                })
            else
                SendNUIMessage({
                    type = 'showReloadPrompt',
                    show = false
                })
            end
        end
    end
end)

-- Combat events
RegisterNetEvent('walsh:client:startAiming')
AddEventHandler('walsh:client:startAiming', function()
    SendNUIMessage({
        type = 'updateCombatMode',
        aiming = true
    })
end)

RegisterNetEvent('walsh:client:stopAiming')
AddEventHandler('walsh:client:stopAiming', function()
    SendNUIMessage({
        type = 'updateCombatMode',
        aiming = false
    })
end)

RegisterNetEvent('walsh:client:enterCombat')
AddEventHandler('walsh:client:enterCombat', function()
    SendNUIMessage({
        type = 'updateCombatMode',
        inCombat = true
    })
end)

RegisterNetEvent('walsh:client:exitCombat')
AddEventHandler('walsh:client:exitCombat', function()
    SendNUIMessage({
        type = 'updateCombatMode',
        inCombat = false
    })
end)

RegisterNetEvent('walsh:client:weaponFired')
AddEventHandler('walsh:client:weaponFired', function(weapon)
    -- Add screen shake on weapon fire
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
    
    -- Update UI with shot fired
    SendNUIMessage({
        type = 'weaponFired',
        weapon = GetWeaponNameFromHash(weapon)
    })
end)

-- Server callbacks for weapon operations
RegisterNUICallback('buyWeapon', function(data, cb)
    TriggerServerEvent('walsh:server:buyWeapon', data.weapon, data.price)
    cb('ok')
end)

RegisterNUICallback('buyAmmo', function(data, cb)
    TriggerServerEvent('walsh:server:buyAmmo', data.weapon, data.amount)
    cb('ok')
end)

RegisterNUICallback('buyBlackMarketWeapon', function(data, cb)
    TriggerServerEvent('walsh:server:buyBlackMarketWeapon', data.weapon, data.price)
    cb('ok')
end)

RegisterNUICallback('selectWeapon', function(data, cb)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(data.weapon)
    
    if HasPedGotWeapon(playerPed, weaponHash, false) then
        SetCurrentPedWeapon(playerPed, weaponHash, true)
    end
    
    cb('ok')
end)

-- Export functions
exports('GetCurrentWeapons', function() return currentWeapons end)
exports('IsInCombat', function() return inCombat end)
exports('IsAiming', function() return isAiming end)
exports('GetWeaponAttachments', function(weapon) return weaponAttachments[weapon] or {} end)
