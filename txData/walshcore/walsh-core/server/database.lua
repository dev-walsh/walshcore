function InitializeDatabase()
    print("^3[Database] ^7Initializing database connection...")
    
    -- Test database connection
    MySQL.ready(function()
        print("^2[Database] ^7Database connection established!")
        CreateTables()
    end)
end

function CreateTables()
    -- Users table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `license` varchar(60) NOT NULL,
            `name` varchar(50) NOT NULL,
            `money` int(11) DEFAULT 5000,
            `bank` int(11) DEFAULT 0,
            `job` varchar(50) DEFAULT 'unemployed',
            `job_grade` int(11) DEFAULT 0,
            `gang` varchar(50) DEFAULT NULL,
            `gang_grade` int(11) DEFAULT 0,
            `position` text DEFAULT NULL,
            `skin` longtext DEFAULT NULL,
            `loadout` longtext DEFAULT NULL,
            `status` longtext DEFAULT NULL,
            `is_dead` tinyint(1) DEFAULT 0,
            `last_seen` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Users table ready")
        end
    end)
    
    -- Gangs table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gangs` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(50) NOT NULL,
            `label` varchar(100) NOT NULL,
            `leader` varchar(60) NOT NULL,
            `money` int(11) DEFAULT 0,
            `territory` varchar(100) DEFAULT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Gangs table ready")
        end
    end)
    
    -- Gang members table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gang_members` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `gang_id` int(11) NOT NULL,
            `user_license` varchar(60) NOT NULL,
            `rank` int(11) DEFAULT 0,
            `joined_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            FOREIGN KEY (`gang_id`) REFERENCES `gangs`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Gang members table ready")
        end
    end)
    
    -- Vehicles table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `owned_vehicles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner` varchar(60) NOT NULL,
            `plate` varchar(12) NOT NULL,
            `vehicle` longtext NOT NULL,
            `type` varchar(20) DEFAULT 'car',
            `job` varchar(50) DEFAULT NULL,
            `garage` varchar(50) DEFAULT 'pillboxgarage',
            `stored` tinyint(1) DEFAULT 1,
            PRIMARY KEY (`id`),
            UNIQUE KEY `plate` (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Vehicles table ready")
        end
    end)
    
    -- Red zone control table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `redzone_control` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `zone_name` varchar(100) NOT NULL,
            `controlling_gang` varchar(50) DEFAULT NULL,
            `control_start` timestamp DEFAULT CURRENT_TIMESTAMP,
            `last_contested` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `zone_name` (`zone_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Red zone control table ready")
        end
    end)
    
    -- Economy transactions table
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `transactions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `from_license` varchar(60) DEFAULT NULL,
            `to_license` varchar(60) DEFAULT NULL,
            `amount` int(11) NOT NULL,
            `type` varchar(50) NOT NULL,
            `description` text DEFAULT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            print("^2[Database] ^7Transactions table ready")
        end
    end)
end

-- Player data functions
function CreatePlayerData(src, license)
    local name = GetPlayerName(src)
    
    MySQL.Async.fetchAll('SELECT * FROM users WHERE license = @license', {
        ['@license'] = license
    }, function(result)
        if result[1] then
            -- Load existing player
            LoadPlayerData(src, result[1])
        else
            -- Create new player
            MySQL.Async.execute('INSERT INTO users (license, name, money) VALUES (@license, @name, @money)', {
                ['@license'] = license,
                ['@name'] = name,
                ['@money'] = Config.StartingMoney
            }, function(insertId)
                if insertId then
                    LoadPlayerData(src, {
                        id = insertId,
                        license = license,
                        name = name,
                        money = Config.StartingMoney,
                        bank = 0,
                        job = 'unemployed',
                        job_grade = 0,
                        gang = nil,
                        gang_grade = 0
                    })
                end
            end)
        end
    end)
end

function LoadPlayerData(src, data)
    Walsh.Players[src] = {
        source = src,
        license = data.license,
        name = data.name,
        money = data.money,
        bank = data.bank,
        job = data.job,
        job_grade = data.job_grade,
        gang = data.gang,
        gang_grade = data.gang_grade,
        position = data.position and json.decode(data.position) or nil,
        skin = data.skin and json.decode(data.skin) or nil,
        loadout = data.loadout and json.decode(data.loadout) or {},
        status = data.status and json.decode(data.status) or {},
        is_dead = data.is_dead == 1
    }
    
    TriggerClientEvent('walsh:client:playerLoaded', src, Walsh.Players[src])
    print("^2[Player] ^7" .. data.name .. " has been loaded")
end

function SavePlayerData(src)
    local player = Walsh.Players[src]
    if not player then return end
    
    local position = json.encode({
        x = player.position and player.position.x or 0,
        y = player.position and player.position.y or 0,
        z = player.position and player.position.z or 0,
        heading = player.position and player.position.heading or 0
    })
    
    MySQL.Async.execute('UPDATE users SET money = @money, bank = @bank, job = @job, job_grade = @job_grade, gang = @gang, gang_grade = @gang_grade, position = @position, skin = @skin, loadout = @loadout, status = @status, is_dead = @is_dead WHERE license = @license', {
        ['@money'] = player.money,
        ['@bank'] = player.bank,
        ['@job'] = player.job,
        ['@job_grade'] = player.job_grade,
        ['@gang'] = player.gang,
        ['@gang_grade'] = player.gang_grade,
        ['@position'] = position,
        ['@skin'] = json.encode(player.skin or {}),
        ['@loadout'] = json.encode(player.loadout or {}),
        ['@status'] = json.encode(player.status or {}),
        ['@is_dead'] = player.is_dead and 1 or 0,
        ['@license'] = player.license
    })
end
