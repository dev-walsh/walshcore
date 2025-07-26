-- Job Management Module

-- Load jobs from config
function LoadJobs()
    Walsh.Jobs = Config.Jobs
    print("^2[Jobs] ^7Loaded " .. #Walsh.Jobs .. " job types")
end

-- Set player job
RegisterServerEvent('walsh:server:setJob')
AddEventHandler('walsh:server:setJob', function(targetId, job, grade)
    local src = source
    
    -- Check admin permissions for remote job setting
    if src ~= 0 and not IsPlayerAdmin(src) then
        TriggerClientEvent('walsh:client:notify', src, 'Insufficient permissions', 'error')
        return
    end
    
    local targetPlayer = GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('walsh:client:notify', src, 'Player not found', 'error')
        return
    end
    
    if not Config.Jobs[job] then
        TriggerClientEvent('walsh:client:notify', src, 'Invalid job', 'error')
        return
    end
    
    grade = grade or 0
    targetPlayer.job = job
    targetPlayer.job_grade = grade
    
    TriggerClientEvent('walsh:client:jobUpdate', targetId, job, grade)
    TriggerClientEvent('walsh:client:notify', targetId, 'Your job has been set to ' .. Config.Jobs[job].label, 'success')
    
    if src ~= 0 then
        TriggerClientEvent('walsh:client:notify', src, 'Set ' .. targetPlayer.name .. "'s job to " .. Config.Jobs[job].label, 'success')
    end
end)

-- Job duty toggle
RegisterServerEvent('walsh:server:toggleDuty')
AddEventHandler('walsh:server:toggleDuty', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local job = Config.Jobs[player.job]
    if not job then return end
    
    player.onduty = not player.onduty
    
    TriggerClientEvent('walsh:client:dutyUpdate', src, player.onduty)
    
    local status = player.onduty and 'on' or 'off'
    TriggerClientEvent('walsh:client:notify', src, 'You are now ' .. status .. ' duty', 'info')
end)

-- Job specific commands and functionality

-- Police job functions
RegisterServerEvent('walsh:server:handcuffPlayer')
AddEventHandler('walsh:server:handcuffPlayer', function(targetId)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' or not player.onduty then
        TriggerClientEvent('walsh:client:notify', src, 'You must be on duty as police', 'error')
        return
    end
    
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId)))
    if distance > 5.0 then
        TriggerClientEvent('walsh:client:notify', src, 'Player too far away', 'error')
        return
    end
    
    target.handcuffed = not target.handcuffed
    
    TriggerClientEvent('walsh:client:handcuff', targetId, target.handcuffed)
    
    local action = target.handcuffed and 'handcuffed' or 'uncuffed'
    TriggerClientEvent('walsh:client:notify', src, 'Player ' .. action, 'success')
    TriggerClientEvent('walsh:client:notify', targetId, 'You have been ' .. action, 'info')
end)

RegisterServerEvent('walsh:server:jailPlayer')
AddEventHandler('walsh:server:jailPlayer', function(targetId, time)
    local src = source
    local player = GetPlayer(src)
    local target = GetPlayer(targetId)
    
    if not player or not target then return end
    
    if player.job ~= 'police' or not player.onduty then
        TriggerClientEvent('walsh:client:notify', src, 'You must be on duty as police', 'error')
        return
    end
    
    time = tonumber(time) or 5
    if time > 60 then time = 60 end -- Max 60 minutes
    
    target.jailed = true
    target.jail_time = time * 60 -- Convert to seconds
    
    TriggerClientEvent('walsh:client:sendToJail', targetId, time)
    TriggerClientEvent('walsh:client:notify', src, 'Jailed ' .. target.name .. ' for ' .. time .. ' minutes', 'success')
    TriggerClientEvent('walsh:client:notify', targetId, 'You have been jailed for ' .. time .. ' minutes', 'error')
end)

-- Mechanic job functions
RegisterServerEvent('walsh:server:repairVehicle')
AddEventHandler('walsh:server:repairVehicle', function(targetId)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    if player.job ~= 'mechanic' or not player.onduty then
        TriggerClientEvent('walsh:client:notify', src, 'You must be on duty as mechanic', 'error')
        return
    end
    
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        -- Try to find nearby vehicle
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    
    if vehicle ~= 0 then
        TriggerClientEvent('walsh:client:repairVehicle', src, vehicle)
        TriggerClientEvent('walsh:client:notify', src, 'Vehicle repaired', 'success')
        
        -- Charge for repair if target is specified
        if targetId and targetId ~= src then
            local target = GetPlayer(targetId)
            if target then
                local repairCost = 500
                if target.money >= repairCost then
                    target.money = target.money - repairCost
                    player.money = player.money + repairCost
                    
                    TriggerClientEvent('walsh:client:updateMoney', targetId, target.money, target.bank)
                    TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
                    TriggerClientEvent('walsh:client:notify', targetId, 'Paid $' .. repairCost .. ' for vehicle repair', 'info')
                    TriggerClientEvent('walsh:client:notify', src, 'Received $' .. repairCost .. ' for repair', 'success')
                end
            end
        end
    else
        TriggerClientEvent('walsh:client:notify', src, 'No vehicle nearby', 'error')
    end
end)

-- Job salary system (handled in economy module)
RegisterServerEvent('walsh:server:getJobInfo')
AddEventHandler('walsh:server:getJobInfo', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local job = Config.Jobs[player.job]
    if job then
        local jobInfo = {
            name = player.job,
            label = job.label,
            grade = player.job_grade,
            onduty = player.onduty or false
        }
        
        if job.grades and job.grades[tostring(player.job_grade)] then
            jobInfo.grade_name = job.grades[tostring(player.job_grade)].name
            jobInfo.salary = job.grades[tostring(player.job_grade)].payment or 0
        end
        
        TriggerClientEvent('walsh:client:receiveJobInfo', src, jobInfo)
    end
end)

-- Job specific locations and blips
local jobLocations = {
    police = {
        {x = 425.1, y = -979.5, z = 30.7, label = "Mission Row PD"},
        {x = 1853.2, y = 3689.6, z = 34.3, label = "Sandy Shores PD"}
    },
    mechanic = {
        {x = -347.5, y = -133.6, z = 39.0, label = "LS Customs"},
        {x = -1155.0, y = -2007.0, z = 13.2, label = "Airport Garage"}
    }
}

-- Function to get job locations
function GetJobLocations(job)
    return jobLocations[job] or {}
end

-- Export functions
exports('LoadJobs', LoadJobs)
exports('GetJobLocations', GetJobLocations)
