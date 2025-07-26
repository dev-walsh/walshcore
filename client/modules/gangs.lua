-- Client Gang Module

local currentGang = nil
local gangBlips = {}
local gangZones = {}

-- Gang system initialization
RegisterNetEvent('walsh:client:gangUpdate')
AddEventHandler('walsh:client:gangUpdate', function(gang, grade)
    currentGang = gang
    
    if gang then
        LoadGangData(gang)
    else
        ClearGangData()
    end
    
    UpdateGangUI()
end)

function LoadGangData(gangName)
    TriggerServerCallback('walsh:server:getGangData', function(gangData)
        if gangData then
            currentGang = gangData
            CreateGangBlips(gangData)
            UpdateGangZones(gangData)
        end
    end, gangName)
end

function ClearGangData()
    currentGang = nil
    ClearGangBlips()
    ClearGangZones()
end

-- Gang invitation system
RegisterNetEvent('walsh:client:gangInvitation')
AddEventHandler('walsh:client:gangInvitation', function(inviteData)
    SendNUIMessage({
        type = 'showGangInvitation',
        data = inviteData
    })
    SetNuiFocus(true, true)
    
    -- Auto-close invitation after 30 seconds
    Citizen.CreateThread(function()
        Wait(30000)
        SendNUIMessage({
            type = 'hideGangInvitation'
        })
    end)
end)

-- Gang menu
RegisterNetEvent('walsh:client:openGangMenu')
AddEventHandler('walsh:client:openGangMenu', function()
    local playerData = GetPlayerData()
    
    if playerData.gang then
        TriggerServerCallback('walsh:server:getGangInfo', function(gangInfo)
            SendNUIMessage({
                type = 'showGangMenu',
                gang = gangInfo,
                playerData = playerData
            })
            SetNuiFocus(true, true)
        end, playerData.gang)
    else
        SendNUIMessage({
            type = 'showGangCreation'
        })
        SetNuiFocus(true, true)
    end
end)

-- Gang territory visualization
function CreateGangBlips(gangData)
    ClearGangBlips()
    
    if gangData.territory then
        local coords = gangData.territory.coords
        local radius = gangData.territory.radius
        
        -- Create main territory blip
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 84)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.2)
        SetBlipColour(blip, 1) -- Red for gang territory
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(gangData.name .. " Territory")
        EndTextCommandSetBlipName(blip)
        
        table.insert(gangBlips, blip)
        
        -- Create radius blip
        local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
        SetBlipHighDetail(radiusBlip, true)
        SetBlipColour(radiusBlip, 1)
        SetBlipAlpha(radiusBlip, 80)
        
        table.insert(gangBlips, radiusBlip)
    end
end

function ClearGangBlips()
    for _, blip in pairs(gangBlips) do
        RemoveBlip(blip)
    end
    gangBlips = {}
end

-- Gang zones for territory control
function UpdateGangZones(gangData)
    ClearGangZones()
    
    if gangData.territory then
        local coords = gangData.territory.coords
        local radius = gangData.territory.radius
        
        gangZones[gangData.name] = {
            coords = coords,
            radius = radius,
            color = {255, 0, 0, 100} -- Red with transparency
        }
    end
end

function ClearGangZones()
    gangZones = {}
end

-- Gang zone monitoring
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        if currentGang then
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for zoneName, zone in pairs(gangZones) do
                local distance = #(playerCoords - zone.coords)
                
                if distance <= zone.radius then
                    -- Player is in gang territory
                    SendNUIMessage({
                        type = 'showTerritoryInfo',
                        zone = zoneName,
                        show = true
                    })
                    break
                else
                    SendNUIMessage({
                        type = 'showTerritoryInfo',
                        show = false
                    })
                end
            end
        end
    end
end)

-- Gang commands
RegisterCommand('gang', function(source, args, rawCommand)
    local action = args[1]
    
    if not action then
        TriggerEvent('walsh:client:openGangMenu')
        return
    end
    
    if action == "invite" then
        local targetId = tonumber(args[2])
        if targetId then
            TriggerServerEvent('walsh:server:inviteToGang', targetId)
        else
            TriggerEvent('walsh:client:notify', 'Usage: /gang invite [player_id]', 'error')
        end
    elseif action == "leave" then
        TriggerServerEvent('walsh:server:leaveGang')
    elseif action == "info" then
        ShowGangInfo()
    elseif action == "deposit" then
        local amount = tonumber(args[2])
        if amount and amount > 0 then
            TriggerServerEvent('walsh:server:depositGangMoney', amount)
        else
            TriggerEvent('walsh:client:notify', 'Usage: /gang deposit [amount]', 'error')
        end
    else
        TriggerEvent('walsh:client:notify', 'Available commands: invite, leave, info, deposit', 'info')
    end
end, false)

function ShowGangInfo()
    local playerData = GetPlayerData()
    
    if playerData.gang then
        TriggerServerCallback('walsh:server:getGangInfo', function(gangInfo)
            if gangInfo then
                local info = string.format([[
Gang: %s
Members: %d
Money: $%d
Territory: %s
Your Rank: %s
                ]], 
                gangInfo.label, 
                #gangInfo.members, 
                gangInfo.money,
                gangInfo.territory and gangInfo.territory.name or "None",
                Config.GangRanks[playerData.gang_grade] and Config.GangRanks[playerData.gang_grade].name or "Unknown"
                )
                
                SendNUIMessage({
                    type = 'showGangInfo',
                    info = info
                })
            end
        end, playerData.gang)
    else
        TriggerEvent('walsh:client:notify', 'You are not in a gang', 'error')
    end
end

-- Gang chat system
RegisterCommand('g', function(source, args, rawCommand)
    local message = table.concat(args, " ")
    
    if message and message ~= "" then
        TriggerServerEvent('walsh:server:sendGangMessage', message)
    else
        TriggerEvent('walsh:client:notify', 'Usage: /g [message]', 'error')
    end
end, false)

RegisterNetEvent('walsh:client:receiveGangMessage')
AddEventHandler('walsh:client:receiveGangMessage', function(sender, message)
    SendNUIMessage({
        type = 'addChatMessage',
        data = {
            template = '<div class="chat-message gang-chat"><span class="gang-tag">[GANG]</span> <span class="sender">{0}:</span> {1}</div>',
            args = {sender, message}
        }
    })
end)

-- Gang vehicle spawning
local gangVehicles = {
    {
        model = "rumpo3",
        coords = vector3(-1030.0, -2730.0, 13.8),
        heading = 240.0,
        gang = "bloods"
    },
    {
        model = "speedo",
        coords = vector3(-1035.0, -2735.0, 13.8),
        heading = 240.0,
        gang = "crips"
    }
}

RegisterCommand('gcar', function()
    local playerData = GetPlayerData()
    
    if not playerData.gang then
        TriggerEvent('walsh:client:notify', 'You must be in a gang', 'error')
        return
    end
    
    -- Find gang vehicle spawn
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestSpawn = nil
    local nearestDistance = math.huge
    
    for _, spawn in pairs(gangVehicles) do
        if spawn.gang == playerData.gang then
            local distance = #(playerCoords - spawn.coords)
            if distance < nearestDistance and distance < 10.0 then
                nearestDistance = distance
                nearestSpawn = spawn
            end
        end
    end
    
    if nearestSpawn then
        SpawnGangVehicle(nearestSpawn)
    else
        TriggerEvent('walsh:client:notify', 'No gang vehicle spawn nearby', 'error')
    end
end, false)

function SpawnGangVehicle(spawn)
    local model = GetHashKey(spawn.model)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local vehicle = CreateVehicle(model, spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.heading, true, false)
    
    -- Customize vehicle for gang
    SetVehicleColours(vehicle, 1, 1) -- Gang colors
    SetVehicleWindowTint(vehicle, 1) -- Dark tint
    
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    TriggerEvent('walsh:client:notify', 'Gang vehicle spawned', 'success')
    
    SetModelAsNoLongerNeeded(model)
end

-- Gang war system
local activeGangWars = {}

RegisterNetEvent('walsh:client:gangWarStarted')
AddEventHandler('walsh:client:gangWarStarted', function(warData)
    activeGangWars[warData.id] = warData
    
    SendNUIMessage({
        type = 'showGangWar',
        war = warData
    })
    
    -- Add war zone blip
    local blip = AddBlipForCoord(warData.coords.x, warData.coords.y, warData.coords.z)
    SetBlipSprite(blip, 84)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.5)
    SetBlipColour(blip, 1)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Gang War Zone")
    EndTextCommandSetBlipName(blip)
    
    warData.blip = blip
end)

RegisterNetEvent('walsh:client:gangWarEnded')
AddEventHandler('walsh:client:gangWarEnded', function(warId, winner)
    local war = activeGangWars[warId]
    if war then
        RemoveBlip(war.blip)
        activeGangWars[warId] = nil
        
        SendNUIMessage({
            type = 'hideGangWar',
            warId = warId,
            winner = winner
        })
    end
end)

-- Gang drug operations
local drugLabs = {
    {
        gang = "bloods",
        coords = vector3(1388.0, 3600.0, 38.9),
        type = "meth"
    },
    {
        gang = "crips", 
        coords = vector3(-1150.0, -1520.0, 10.6),
        type = "cocaine"
    }
}

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        
        local playerData = GetPlayerData()
        if playerData and playerData.gang then
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for _, lab in pairs(drugLabs) do
                if lab.gang == playerData.gang then
                    local distance = #(playerCoords - lab.coords)
                    
                    if distance < 5.0 then
                        SendNUIMessage({
                            type = 'showInteractionPrompt',
                            text = 'Press E to operate ' .. lab.type .. ' lab',
                            show = true
                        })
                        
                        if distance < 2.0 and IsControlJustReleased(0, 38) then
                            StartDrugOperation(lab)
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
    end
end)

function StartDrugOperation(lab)
    SendNUIMessage({
        type = 'showDrugLab',
        lab = lab
    })
    SetNuiFocus(true, true)
end

-- NUI Callbacks for gang operations
RegisterNUICallback('acceptGangInvitation', function(data, cb)
    TriggerServerEvent('walsh:server:acceptGangInvitation', data.gangName, data.inviterId)
    cb('ok')
end)

RegisterNUICallback('declineGangInvitation', function(data, cb)
    -- Just close the invitation
    cb('ok')
end)

RegisterNUICallback('createGang', function(data, cb)
    TriggerServerEvent('walsh:server:createGang', data.name, data.label)
    cb('ok')
end)

RegisterNUICallback('leaveGang', function(data, cb)
    TriggerServerEvent('walsh:server:leaveGang')
    cb('ok')
end)

RegisterNUICallback('inviteToGang', function(data, cb)
    TriggerServerEvent('walsh:server:inviteToGang', data.targetId)
    cb('ok')
end)

RegisterNUICallback('startDrugProduction', function(data, cb)
    TriggerServerEvent('walsh:server:startDrugProduction', data.labType, data.amount)
    cb('ok')
end)

function UpdateGangUI()
    local playerData = GetPlayerData()
    
    SendNUIMessage({
        type = 'updateGangInfo',
        gang = playerData.gang,
        gangGrade = playerData.gang_grade,
        gangData = currentGang
    })
end

-- Export functions
exports('GetCurrentGang', function() return currentGang end)
exports('IsInGangTerritory', function() 
    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, zone in pairs(gangZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            return true
        end
    end
    return false
end)
