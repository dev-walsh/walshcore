Config = {}

-- Framework Settings
Config.FrameworkName = "WalshCore"
Config.StartingMoney = 5000
Config.DeathPenalty = 0.1 -- 10% money loss on death
Config.MinMoneyToSurvive = 100000 -- 100k requirement
Config.CheckInterval = 300000 -- 5 minutes in ms

-- Database Settings
Config.DatabaseName = "walsh_framework"

-- Red Zone Settings
Config.RedZones = {
    {
        name = "Downtown Gang Territory",
        coords = vector3(-265.0, -957.0, 31.0),
        radius = 150.0,
        color = {255, 0, 0, 100},
        rewards = {
            money = {min = 5000, max = 15000},
            experience = {min = 100, max = 300}
        },
        controlTime = 300 -- 5 minutes to control
    },
    {
        name = "Industrial Warzone",
        coords = vector3(716.0, -1088.0, 22.0),
        radius = 200.0,
        color = {255, 0, 0, 100},
        rewards = {
            money = {min = 10000, max = 25000},
            experience = {min = 200, max = 500}
        },
        controlTime = 600 -- 10 minutes to control
    }
}

-- Gang Settings
Config.MaxGangMembers = 15
Config.GangRanks = {
    {name = "Member", permissions = {"invite"}},
    {name = "Lieutenant", permissions = {"invite", "kick", "promote"}},
    {name = "Boss", permissions = {"invite", "kick", "promote", "demote", "disband"}}
}

-- Job Settings
Config.Jobs = {
    unemployed = {label = "Unemployed", defaultDuty = true, grades = {}},
    police = {
        label = "Police",
        defaultDuty = false,
        grades = {
            ['0'] = {name = "Cadet", payment = 50},
            ['1'] = {name = "Officer", payment = 75},
            ['2'] = {name = "Sergeant", payment = 100},
            ['3'] = {name = "Lieutenant", payment = 125},
            ['4'] = {name = "Captain", payment = 150}
        }
    },
    mechanic = {
        label = "Mechanic",
        defaultDuty = false,
        grades = {
            ['0'] = {name = "Trainee", payment = 40},
            ['1'] = {name = "Mechanic", payment = 60},
            ['2'] = {name = "Advanced Mechanic", payment = 80},
            ['3'] = {name = "Shop Manager", payment = 100}
        }
    }
}

-- Weapon Settings
Config.Weapons = {
    ['WEAPON_PISTOL'] = {price = 5000, ammoPrice = 2},
    ['WEAPON_SMG'] = {price = 15000, ammoPrice = 5},
    ['WEAPON_ASSAULTRIFLE'] = {price = 35000, ammoPrice = 10},
    ['WEAPON_SNIPERRIFLE'] = {price = 75000, ammoPrice = 25}
}

-- Vehicle Settings
Config.VehicleShops = {
    {
        name = "PDM",
        coords = vector3(-56.0, -1097.0, 26.0),
        vehicles = {
            {model = "adder", price = 1000000},
            {model = "zentorno", price = 725000},
            {model = "t20", price = 2200000}
        }
    }
}

-- Admin Settings
Config.AdminGroups = {
    "superadmin",
    "admin",
    "moderator"
}
