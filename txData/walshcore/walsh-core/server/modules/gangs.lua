-- Gang Management Module

Walsh.Gangs = {}

-- Load gangs from database
function LoadGangs()
    MySQL.Async.fetchAll('SELECT * FROM gangs', {}, function(result)
        for i = 1, #result do
            local gang = result[i]
            Walsh.Gangs[gang.name] = {
                id = gang.id,
                name = gang.name,
                label = gang.label,
                leader = gang.leader,
                money = gang.money,
                territory = gang.territory,
                members = {}
            }
        end
        
        -- Load gang members
        MySQL.Async.fetchAll('SELECT * FROM gang_members', {}, function(members)
            for i = 1, #members do
                local member = members[i]
                local gangName = nil
                
                -- Find gang by ID
                for name, gang in pairs(Walsh.Gangs) do
                    if gang.id == member.gang_id then
                        gangName = name
                        break
                    end
                end
                
                if gangName then
                    table.insert(Walsh.Gangs[gangName].members, {
                        license = member.user_license,
                        rank = member.rank,
                        joined_at = member.joined_at
                    })
                end
            end
        end)
        
        print("^2[Gangs] ^7Loaded " .. #result .. " gangs")
    end)
end

-- Create new gang
RegisterServerEvent('walsh:server:createGang')
AddEventHandler('walsh:server:createGang', function(gangName, gangLabel)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'You are already in a gang', 'error')
        return
    end
    
    if Walsh.Gangs[gangName] then
        TriggerClientEvent('walsh:client:notify', src, 'Gang name already exists', 'error')
        return
    end
    
    -- Check if player has enough money (example: 50k to create gang)
    local creationCost = 50000
    if player.money < creationCost then
        TriggerClientEvent('walsh:client:notify', src, 'Need $' .. creationCost .. ' to create a gang', 'error')
        return
    end
    
    player.money = player.money - creationCost
    
    MySQL.Async.execute('INSERT INTO gangs (name, label, leader, money) VALUES (@name, @label, @leader, @money)', {
        ['@name'] = gangName,
        ['@label'] = gangLabel,
        ['@leader'] = player.license,
        ['@money'] = 0
    }, function(insertId)
        if insertId then
            -- Create gang in memory
            Walsh.Gangs[gangName] = {
                id = insertId,
                name = gangName,
                label = gangLabel,
                leader = player.license,
                money = 0,
                members = {{license = player.license, rank = #Config.GangRanks, joined_at = os.time()}}
            }
            
            -- Add creator as leader
            MySQL.Async.execute('INSERT INTO gang_members (gang_id, user_license, rank) VALUES (@gang_id, @license, @rank)', {
                ['@gang_id'] = insertId,
                ['@license'] = player.license,
                ['@rank'] = #Config.GangRanks
            })
            
            -- Set player gang
            player.gang = gangName
            player.gang_grade = #Config.GangRanks
            
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            TriggerClientEvent('walsh:client:gangUpdate', src, gangName, #Config.GangRanks)
            TriggerClientEvent('walsh:client:notify', src, 'Gang "' .. gangLabel .. '" created successfully!', 'success')
        end
    end)
end)

-- Invite player to gang
RegisterServerEvent('walsh:server:inviteToGang')
AddEventHandler('walsh:server:inviteToGang', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local targetPlayer = GetPlayer(targetId)
    
    if not player or not targetPlayer then
        TriggerClientEvent('walsh:client:notify', src, 'Player not found', 'error')
        return
    end
    
    if not player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'You are not in a gang', 'error')
        return
    end
    
    if targetPlayer.gang then
        TriggerClientEvent('walsh:client:notify', src, 'Player is already in a gang', 'error')
        return
    end
    
    -- Check if player has permission to invite
    local gang = Walsh.Gangs[player.gang]
    if not gang then return end
    
    local playerRank = Config.GangRanks[player.gang_grade]
    if not playerRank or not HasGangPermission(playerRank.permissions, 'invite') then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient permissions', 'error')
        return
    end
    
    -- Check gang member limit
    if #gang.members >= Config.MaxGangMembers then
        TriggerClientEvent('walsh:client:notify', src, 'Gang is full', 'error')
        return
    end
    
    -- Send invitation
    TriggerClientEvent('walsh:client:gangInvitation', targetId, {
        gangName = gang.name,
        gangLabel = gang.label,
        inviterName = player.name,
        inviterId = src
    })
    
    TriggerClientEvent('walsh:client:notify', src, 'Sent gang invitation to ' .. targetPlayer.name, 'success')
end)

-- Accept gang invitation
RegisterServerEvent('walsh:server:acceptGangInvitation')
AddEventHandler('walsh:server:acceptGangInvitation', function(gangName, inviterId)
    local src = source
    local player = GetPlayer(src)
    local inviter = GetPlayer(inviterId)
    
    if not player or not inviter then return end
    
    if player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'You are already in a gang', 'error')
        return
    end
    
    local gang = Walsh.Gangs[gangName]
    if not gang then
        TriggerClientEvent('walsh:client:notify', src, 'Gang no longer exists', 'error')
        return
    end
    
    -- Add to database
    MySQL.Async.execute('INSERT INTO gang_members (gang_id, user_license, rank) VALUES (@gang_id, @license, @rank)', {
        ['@gang_id'] = gang.id,
        ['@license'] = player.license,
        ['@rank'] = 1
    }, function(success)
        if success then
            -- Add to memory
            table.insert(gang.members, {
                license = player.license,
                rank = 1,
                joined_at = os.time()
            })
            
            -- Set player gang
            player.gang = gangName
            player.gang_grade = 1
            
            TriggerClientEvent('walsh:client:gangUpdate', src, gangName, 1)
            TriggerClientEvent('walsh:client:notify', src, 'Joined gang: ' .. gang.label, 'success')
            TriggerClientEvent('walsh:client:notify', inviterId, player.name .. ' joined the gang', 'success')
            
            -- Notify all gang members
            for _, member in pairs(gang.members) do
                local memberPlayer = GetPlayerByLicense(member.license)
                if memberPlayer and memberPlayer.source ~= src then
                    TriggerClientEvent('walsh:client:notify', memberPlayer.source, player.name .. ' joined the gang', 'info')
                end
            end
        end
    end)
end)

-- Leave gang
RegisterServerEvent('walsh:server:leaveGang')
AddEventHandler('walsh:server:leaveGang', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player or not player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'You are not in a gang', 'error')
        return
    end
    
    local gang = Walsh.Gangs[player.gang]
    if gang and gang.leader == player.license then
        TriggerClientEvent('walsh:client:notify', src, 'Gang leaders cannot leave. Transfer leadership or disband the gang.', 'error')
        return
    end
    
    -- Remove from database
    MySQL.Async.execute('DELETE FROM gang_members WHERE gang_id = @gang_id AND user_license = @license', {
        ['@gang_id'] = gang.id,
        ['@license'] = player.license
    }, function(success)
        if success then
            -- Remove from memory
            for i, member in ipairs(gang.members) do
                if member.license == player.license then
                    table.remove(gang.members, i)
                    break
                end
            end
            
            -- Clear player gang
            local oldGang = player.gang
            player.gang = nil
            player.gang_grade = 0
            
            TriggerClientEvent('walsh:client:gangUpdate', src, nil, 0)
            TriggerClientEvent('walsh:client:notify', src, 'Left gang: ' .. gang.label, 'success')
            
            -- Notify remaining gang members
            for _, member in pairs(gang.members) do
                local memberPlayer = GetPlayerByLicense(member.license)
                if memberPlayer then
                    TriggerClientEvent('walsh:client:notify', memberPlayer.source, player.name .. ' left the gang', 'info')
                end
            end
        end
    end)
end)

-- Gang management functions
function HasGangPermission(permissions, permission)
    for _, perm in ipairs(permissions) do
        if perm == permission then
            return true
        end
    end
    return false
end

function GetGangData(gangName)
    return Walsh.Gangs[gangName]
end

function GetPlayerGang(src)
    local player = GetPlayer(src)
    if player and player.gang then
        return Walsh.Gangs[player.gang]
    end
    return nil
end

-- Gang money management
RegisterServerEvent('walsh:server:depositGangMoney')
AddEventHandler('walsh:server:depositGangMoney', function(amount)
    local src = source
    local player = GetPlayer(src)
    
    if not player or not player.gang then
        TriggerClientEvent('walsh:client:notify', src, 'You are not in a gang', 'error')
        return
    end
    
    if player.money < amount or amount <= 0 then
        TriggerClientEvent('walsh:client:notify', src, 'Invalid amount', 'error')
        return
    end
    
    local gang = Walsh.Gangs[player.gang]
    if not gang then return end
    
    player.money = player.money - amount
    gang.money = gang.money + amount
    
    -- Update database
    MySQL.Async.execute('UPDATE gangs SET money = @money WHERE id = @id', {
        ['@money'] = gang.money,
        ['@id'] = gang.id
    })
    
    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
    TriggerClientEvent('walsh:client:notify', src, 'Deposited $' .. amount .. ' to gang funds', 'success')
end)

-- Export functions
exports('GetGangData', GetGangData)
exports('GetPlayerGang', GetPlayerGang)
exports('HasGangPermission', HasGangPermission)
