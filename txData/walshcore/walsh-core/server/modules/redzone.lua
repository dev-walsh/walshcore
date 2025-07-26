-- Red Zone Management Module

local activeZones = {}
local zoneControl = {}

-- Initialize red zones
Citizen.CreateThread(function()
    Wait(5000) -- Wait for database to be ready
    
    -- Load zone control from database
    for _, zone in pairs(Config.RedZones) do
        MySQL.Async.fetchAll('SELECT * FROM redzone_control WHERE zone_name = @zone_name', {
            ['@zone_name'] = zone.name
        }, function(result)
            if result[1] then
                zoneControl[zone.name] = {
                    controlling_gang = result[1].controlling_gang,
                    control_start = result[1].control_start,
                    last_contested = result[1].last_contested
                }
            else
                -- Insert new zone
                MySQL.Async.execute('INSERT INTO redzone_control (zone_name) VALUES (@zone_name)', {
                    ['@zone_name'] = zone.name
                })
                zoneControl[zone.name] = {
                    controlling_gang = nil,
                    control_start = nil,
                    last_contested = nil
                }
            end
        end)
    end
    
    -- Start zone monitoring
    StartZoneMonitoring()
    print("^2[Red Zones] ^7Initialized " .. #Config.RedZones .. " red zones")
end)

function StartZoneMonitoring()
    Citizen.CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            
            for _, zone in pairs(Config.RedZones) do
                CheckZoneActivity(zone)
            end
        end
    end)
end

function CheckZoneActivity(zone)
    local playersInZone = {}
    local gangPresence = {}
    
    -- Check all players in the zone
    for playerId, playerData in pairs(Walsh.Players) do
        local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
        local distance = #(vector3(zone.coords.x, zone.coords.y, zone.coords.z) - playerCoords)
        
        if distance <= zone.radius then
            table.insert(playersInZone, {
                source = playerId,
                gang = playerData.gang,
                coords = playerCoords
            })
            
            if playerData.gang then
                if not gangPresence[playerData.gang] then
                    gangPresence[playerData.gang] = 0
                end
                gangPresence[playerData.gang] = gangPresence[playerData.gang] + 1
            end
        end
    end
    
    -- Determine zone contest
    local dominantGang = nil
    local maxMembers = 0
    local contestedBy = {}
    
    for gang, count in pairs(gangPresence) do
        if count > maxMembers then
            maxMembers = count
            dominantGang = gang
        end
        if count >= 2 then -- Minimum 2 members to contest
            table.insert(contestedBy, gang)
        end
    end
    
    -- Handle zone control logic
    if #contestedBy > 1 then
        -- Zone is contested
        HandleZoneContest(zone, contestedBy, playersInZone)
    elseif dominantGang and maxMembers >= 3 then
        -- Single gang controlling
        HandleZoneControl(zone, dominantGang, playersInZone)
    else
        -- Zone is neutral or insufficient presence
        HandleNeutralZone(zone, playersInZone)
    end
end

function HandleZoneContest(zone, contestingGangs, players)
    local currentTime = os.time()
    
    -- Update last contested time
    zoneControl[zone.name].last_contested = currentTime
    
    -- Notify players of contest
    for _, player in pairs(players) do
        if player.gang and HasValue(contestingGangs, player.gang) then
            TriggerClientEvent('walsh:client:zoneContest', player.source, {
                zoneName = zone.name,
                contestingGangs = contestingGangs,
                rewards = zone.rewards
            })
        end
    end
    
    -- Update database
    MySQL.Async.execute('UPDATE redzone_control SET last_contested = NOW() WHERE zone_name = @zone_name', {
        ['@zone_name'] = zone.name
    })
end

function HandleZoneControl(zone, controllingGang, players)
    local currentTime = os.time()
    local control = zoneControl[zone.name]
    
    if control.controlling_gang ~= controllingGang then
        -- Gang is taking control
        control.controlling_gang = controllingGang
        control.control_start = currentTime
        
        -- Notify all players in zone
        for _, player in pairs(players) do
            TriggerClientEvent('walsh:client:zoneControlChange', player.source, {
                zoneName = zone.name,
                newController = controllingGang
            })
        end
        
        -- Update database
        MySQL.Async.execute('UPDATE redzone_control SET controlling_gang = @gang, control_start = NOW() WHERE zone_name = @zone_name', {
            ['@gang'] = controllingGang,
            ['@zone_name'] = zone.name
        })
        
        print("^3[Red Zone] ^7" .. controllingGang .. " took control of " .. zone.name)
    else
        -- Gang maintains control, check for rewards
        if control.control_start then
            local controlTime = currentTime - control.control_start
            if controlTime >= zone.controlTime then
                -- Award control rewards
                AwardZoneRewards(zone, controllingGang, players)
                control.control_start = currentTime -- Reset timer
            end
        end
    end
end

function HandleNeutralZone(zone, players)
    local control = zoneControl[zone.name]
    
    if control.controlling_gang then
        -- Zone lost control
        control.controlling_gang = nil
        control.control_start = nil
        
        -- Notify players
        for _, player in pairs(players) do
            TriggerClientEvent('walsh:client:zoneNeutral', player.source, {
                zoneName = zone.name
            })
        end
        
        -- Update database
        MySQL.Async.execute('UPDATE redzone_control SET controlling_gang = NULL, control_start = NULL WHERE zone_name = @zone_name', {
            ['@zone_name'] = zone.name
        })
    end
end

function AwardZoneRewards(zone, gang, players)
    local gangData = Walsh.Gangs[gang]
    if not gangData then return end
    
    local gangMembers = {}
    for _, player in pairs(players) do
        if player.gang == gang then
            table.insert(gangMembers, player.source)
        end
    end
    
    if #gangMembers == 0 then return end
    
    -- Calculate rewards
    local moneyReward = math.random(zone.rewards.money.min, zone.rewards.money.max)
    local expReward = math.random(zone.rewards.experience.min, zone.rewards.experience.max)
    local individualMoney = math.floor(moneyReward / #gangMembers)
    
    -- Award to gang funds
    gangData.money = gangData.money + moneyReward
    MySQL.Async.execute('UPDATE gangs SET money = @money WHERE id = @id', {
        ['@money'] = gangData.money,
        ['@id'] = gangData.id
    })
    
    -- Award to individual members
    for _, playerId in pairs(gangMembers) do
        local player = GetPlayer(playerId)
        if player then
            player.money = player.money + individualMoney
            
            -- Award experience (if you have an experience system)
            SetPlayerStatus(playerId, 'experience', (GetPlayerStatus(playerId, 'experience') or 0) + expReward)
            
            TriggerClientEvent('walsh:client:updateMoney', playerId, player.money, player.bank)
            TriggerClientEvent('walsh:client:notify', playerId, 'Zone control reward: $' .. individualMoney .. ' + ' .. expReward .. ' XP', 'success')
        end
    end
    
    print("^2[Red Zone] ^7Awarded rewards for " .. zone.name .. " control to " .. gang)
end

-- PvP events in red zones
RegisterServerEvent('walsh:server:playerKilledInRedZone')
AddEventHandler('walsh:server:playerKilledInRedZone', function(killerId, zoneName)
    local src = source -- victim
    local killer = GetPlayer(killerId)
    local victim = GetPlayer(src)
    
    if not killer or not victim then return end
    
    -- Find the zone
    local zone = nil
    for _, z in pairs(Config.RedZones) do
        if z.name == zoneName then
            zone = z
            break
        end
    end
    
    if not zone then return end
    
    -- Award kill rewards
    local killReward = math.random(1000, 5000)
    killer.money = killer.money + killReward
    
    TriggerClientEvent('walsh:client:updateMoney', killerId, killer.money, killer.bank)
    TriggerClientEvent('walsh:client:notify', killerId, 'Red zone kill bonus: $' .. killReward, 'success')
    
    -- Gang kill tracking
    if killer.gang and victim.gang and killer.gang ~= victim.gang then
        -- Award gang kill points or money
        local gangData = Walsh.Gangs[killer.gang]
        if gangData then
            gangData.money = gangData.money + (killReward * 2)
            MySQL.Async.execute('UPDATE gangs SET money = @money WHERE id = @id', {
                ['@money'] = gangData.money,
                ['@id'] = gangData.id
            })
        end
    end
    
    -- Log the kill
    MySQL.Async.execute('INSERT INTO transactions (from_license, to_license, amount, type, description) VALUES (@from, @to, @amount, @type, @description)', {
        ['@from'] = victim.license,
        ['@to'] = killer.license,
        ['@amount'] = killReward,
        ['@type'] = 'redzone_kill',
        ['@description'] = 'Red zone kill in ' .. zoneName
    })
end)

-- Get zone status
RegisterServerCallback('walsh:server:getZoneStatus', function(source, cb)
    local zoneStatus = {}
    
    for _, zone in pairs(Config.RedZones) do
        local control = zoneControl[zone.name]
        zoneStatus[zone.name] = {
            name = zone.name,
            coords = zone.coords,
            radius = zone.radius,
            controlling_gang = control.controlling_gang,
            control_start = control.control_start,
            last_contested = control.last_contested,
            rewards = zone.rewards
        }
    end
    
    cb(zoneStatus)
end)

-- Utility functions
function HasValue(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Export functions
exports('GetZoneStatus', function()
    return zoneControl
end)
