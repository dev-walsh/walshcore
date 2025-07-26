-- Core Framework Variables
Walsh = {}
Walsh.Players = {}
Walsh.Jobs = {}
Walsh.Gangs = {}

-- Initialize Framework
Citizen.CreateThread(function()
    print("^2[Walsh Core Framework] ^7Starting up...")
    
    -- Initialize Database
    InitializeDatabase()
    
    -- Load jobs and gangs
    LoadJobs()
    LoadGangs()
    
    -- Start money check thread
    StartMoneyCheckThread()
    
    print("^2[Walsh Core Framework] ^7Successfully started!")
end)

-- Player connection handler
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local license = GetPlayerIdentifier(src, 0)
    
    deferrals.defer()
    
    Wait(0)
    deferrals.update("Checking player data...")
    
    -- Check if player exists in database
    MySQL.Async.fetchAll('SELECT * FROM users WHERE license = @license', {
        ['@license'] = license
    }, function(result)
        if result[1] then
            deferrals.done()
        else
            deferrals.done()
        end
    end)
end)

-- Player joining handler
AddEventHandler('playerJoining', function()
    local src = source
    local license = GetPlayerIdentifier(src, 0)
    
    CreatePlayerData(src, license)
end)

-- Player dropping handler
AddEventHandler('playerDropped', function(reason)
    local src = source
    SavePlayerData(src)
    
    if Walsh.Players[src] then
        Walsh.Players[src] = nil
    end
end)

-- Money check thread - removes players with less than 100k
function StartMoneyCheckThread()
    Citizen.CreateThread(function()
        while true do
            Wait(Config.CheckInterval)
            
            for playerId, playerData in pairs(Walsh.Players) do
                if playerData.money < Config.MinMoneyToSurvive then
                    TriggerClientEvent('walsh:client:eliminatePlayer', playerId)
                    Wait(5000) -- Give 5 seconds warning
                    DropPlayer(playerId, "You failed to maintain 100k - You have been eliminated!")
                end
            end
        end
    end)
end

-- Utility Functions
function GetPlayer(src)
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

-- Export functions for other resources
exports('GetPlayer', GetPlayer)
exports('GetPlayerByLicense', GetPlayerByLicense)
