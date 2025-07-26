-- Player Management Module

-- Get player functions
function GetPlayerData(src)
    return Walsh.Players[src]
end

function GetPlayerByLicense(license)
    for k, v in pairs(Walsh.Players) do
        if v.license == license then
            return v
        end
    end
    return nil
end

function GetPlayersByJob(job)
    local players = {}
    for k, v in pairs(Walsh.Players) do
        if v.job == job then
            table.insert(players, v)
        end
    end
    return players
end

function GetPlayersByGang(gang)
    local players = {}
    for k, v in pairs(Walsh.Players) do
        if v.gang == gang then
            table.insert(players, v)
        end
    end
    return players
end

-- Player modification functions
function SetPlayerJob(src, job, grade)
    local player = GetPlayerData(src)
    if player and Config.Jobs[job] then
        player.job = job
        player.job_grade = grade or 0
        
        TriggerClientEvent('walsh:client:jobUpdate', src, job, grade)
        SavePlayerData(src)
        return true
    end
    return false
end

function SetPlayerGang(src, gang, grade)
    local player = GetPlayerData(src)
    if player then
        player.gang = gang
        player.gang_grade = grade or 0
        
        TriggerClientEvent('walsh:client:gangUpdate', src, gang, grade)
        SavePlayerData(src)
        return true
    end
    return false
end

function AddPlayerMoney(src, amount, type)
    local player = GetPlayerData(src)
    if player and amount > 0 then
        type = type or 'cash'
        
        if type == 'cash' then
            player.money = player.money + amount
        elseif type == 'bank' then
            player.bank = player.bank + amount
        end
        
        TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
        return true
    end
    return false
end

function RemovePlayerMoney(src, amount, type)
    local player = GetPlayerData(src)
    if player and amount > 0 then
        type = type or 'cash'
        
        if type == 'cash' and player.money >= amount then
            player.money = player.money - amount
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            return true
        elseif type == 'bank' and player.bank >= amount then
            player.bank = player.bank - amount
            TriggerClientEvent('walsh:client:updateMoney', src, player.money, player.bank)
            return true
        end
    end
    return false
end

function GetPlayerMoney(src, type)
    local player = GetPlayerData(src)
    if player then
        type = type or 'cash'
        return type == 'cash' and player.money or player.bank
    end
    return 0
end

-- Player status functions
function SetPlayerStatus(src, status, value)
    local player = GetPlayerData(src)
    if player then
        if not player.status then
            player.status = {}
        end
        player.status[status] = value
        
        TriggerClientEvent('walsh:client:statusUpdate', src, status, value)
        return true
    end
    return false
end

function GetPlayerStatus(src, status)
    local player = GetPlayerData(src)
    if player and player.status then
        return player.status[status] or 0
    end
    return 0
end

-- Player inventory/loadout functions
function GivePlayerWeapon(src, weapon, ammo)
    local player = GetPlayerData(src)
    if player then
        if not player.loadout then
            player.loadout = {}
        end
        
        player.loadout[weapon] = {
            name = weapon,
            ammo = ammo or 0
        }
        
        TriggerClientEvent('walsh:client:receiveWeapon', src, weapon, ammo)
        return true
    end
    return false
end

function RemovePlayerWeapon(src, weapon)
    local player = GetPlayerData(src)
    if player and player.loadout and player.loadout[weapon] then
        player.loadout[weapon] = nil
        TriggerClientEvent('walsh:client:removeWeapon', src, weapon)
        return true
    end
    return false
end

function GetPlayerLoadout(src)
    local player = GetPlayerData(src)
    if player then
        return player.loadout or {}
    end
    return {}
end

-- Export functions
exports('GetPlayerData', GetPlayerData)
exports('GetPlayerByLicense', GetPlayerByLicense) 
exports('GetPlayersByJob', GetPlayersByJob)
exports('GetPlayersByGang', GetPlayersByGang)
exports('SetPlayerJob', SetPlayerJob)
exports('SetPlayerGang', SetPlayerGang)
exports('AddPlayerMoney', AddPlayerMoney)
exports('RemovePlayerMoney', RemovePlayerMoney)
exports('GetPlayerMoney', GetPlayerMoney)
exports('SetPlayerStatus', SetPlayerStatus)
exports('GetPlayerStatus', GetPlayerStatus)
exports('GivePlayerWeapon', GivePlayerWeapon)
exports('RemovePlayerWeapon', RemovePlayerWeapon)
exports('GetPlayerLoadout', GetPlayerLoadout)
