WalshCore = {}

-- Framework Information
WalshCore.Info = {
    Name = "Walsh Core",
    Version = "1.0.0",
    Author = "Walsh Development Team",
    Description = "Walsh Core Framework for FiveM",
    Website = "https://walsh.dev",
    Discord = "https://discord.gg/walsh"
}

-- Database Configuration
WalshCore.Database = {
    Type = "mysql-async", -- mysql-async, ghmattimysql, oxmysql
    Host = "localhost",
    Port = 3306,
    Username = "root",
    Password = "",
    Database = "walsh_framework"
}

-- Core Settings
WalshCore.CoreSettings = {
    MaxPlayers = 128,
    UseTarget = true, -- Enable targeting system
    UseInventory = true, -- Enable inventory system
    UseMulticharacter = true, -- Enable multiple characters per player
    UseSteamWhitelist = false, -- Enable Steam whitelist
    UseDiscordWhitelist = false, -- Enable Discord whitelist
    UsePermissions = true, -- Enable permission system
    DebugMode = false, -- Enable debug mode
    TestMode = false -- Enable test mode for development
}

-- Player Settings
WalshCore.Player = {
    StartingMoney = {
        cash = 5000,
        bank = 0,
        crypto = 0
    },
    StartingItems = {
        'phone',
        'id_card',
        'driver_license'
    },
    StartingApartment = true,
    IdentifierType = 'license', -- license, steam, discord
    UpdateInterval = 5 * 60 * 1000, -- 5 minutes
    SaveInterval = 10 * 60 * 1000 -- 10 minutes
}

-- Economy Settings
WalshCore.Economy = {
    EnableBanking = true,
    EnableCrypto = true,
    EnableBusinesses = true,
    TaxRate = 0.15, -- 15% tax rate
    WelfareAmount = 1000, -- Welfare payment amount
    WelfareInterval = 24 * 60 * 60 * 1000, -- 24 hours
    SurvivalAmount = 100000, -- Amount needed to survive (100k or Die)
    CheckInterval = 5 * 60 * 1000, -- Check every 5 minutes
    DeathPenalty = 0.10 -- 10% money loss on death
}

-- PvP Settings
WalshCore.PvP = {
    Enabled = true,
    SafeZones = {
        {coords = vector3(-269.4, -955.3, 31.2), radius = 100.0}, -- Spawn area
        {coords = vector3(1839.6, 3672.9, 34.3), radius = 150.0}, -- Hospital
        {coords = vector3(-247.8, 6331.5, 32.4), radius = 150.0}, -- Paleto Hospital
    },
    KillRewards = {
        enabled = true,
        minAmount = 1000,
        maxAmount = 5000,
        percentage = 0.05 -- 5% of victim's money
    }
}

-- Job System
WalshCore.Jobs = {
    Default = 'unemployed',
    WhitelistJobs = {'police', 'ambulance', 'mechanic'}, -- Jobs requiring whitelist
    MaxJobGrade = 10,
    PaycheckInterval = 15 * 60 * 1000, -- 15 minutes
    PaycheckTax = 0.15 -- 15% tax on paychecks
}

-- Gang System
WalshCore.Gangs = {
    Enabled = true,
    MaxMembers = 20,
    CreationCost = 50000,
    MaxGangs = 15,
    TerritorySystem = true,
    WarSystem = true,
    DefaultRanks = {
        [0] = {name = 'Recruit', payment = 0, permissions = {}},
        [1] = {name = 'Member', payment = 100, permissions = {'garage'}},
        [2] = {name = 'Enforcer', payment = 200, permissions = {'garage', 'invite'}},
        [3] = {name = 'Lieutenant', payment = 300, permissions = {'garage', 'invite', 'kick'}},
        [4] = {name = 'Boss', payment = 500, permissions = {'garage', 'invite', 'kick', 'promote', 'demote', 'withdraw'}}
    }
}

-- Vehicle System
WalshCore.Vehicles = {
    Ownership = true,
    Keys = true,
    Fuel = true,
    Damage = true,
    MaxVehicles = 15,
    PlateLetters = 3,
    PlateNumbers = 4,
    PlateUseSpace = true
}

-- Weapon System
WalshCore.Weapons = {
    Licensing = true,
    Durability = true,
    Recoil = true,
    AutoReload = false,
    InfiniteAmmo = false
}

-- Spawn Locations
WalshCore.SpawnPoints = {
    {coords = vector4(-269.4, -955.3, 31.2, 205.8), info = {label = "Bus Station"}},
    {coords = vector4(-558.5, -1334.0, 25.1, 312.3), info = {label = "Downtown"}},
    {coords = vector4(195.7, -933.4, 30.7, 142.5), info = {label = "Legion Square"}}
}

-- Branding & UI
WalshCore.UI = {
    Logo = "walsh-logo.png",
    PrimaryColor = "#8B5CF6", -- Purple
    SecondaryColor = "#FFFFFF", -- White
    AccentColor = "#A855F7", -- Light Purple
    BackgroundColor = "#1F2937", -- Dark Gray
    TextColor = "#FFFFFF", -- White
    Font = "Roboto"
}

-- Notification Settings
WalshCore.Notifications = {
    Position = "top-right",
    Duration = 5000,
    MaxVisible = 5
}

-- Server Settings
WalshCore.Server = {
    Name = "Walsh RP",
    Logo = "https://cdn.walsh.dev/logo.png",
    IP = "connect.walsh.dev",
    Locale = "en",
    UseNumbersOnly = false,
    Closed = false,
    ClosedReason = "Server maintenance in progress",
    Whitelist = false,
    Permission = "god" -- Required permission to join when whitelisted
}

-- Commands
WalshCore.Commands = {
    Prefix = "/",
    SuggestionMode = true -- Enable command suggestions
}

-- Logging
WalshCore.Logging = {
    Webhook = "", -- Discord webhook URL
    Colors = {
        default = 16777215,
        blue = 255,
        red = 16711680,
        green = 65280,
        white = 16777215,
        black = 0,
        orange = 16753920,
        yellow = 16776960,
        pink = 16761035,
        lightgreen = 9498256,
        purple = 8855711
    }
}

-- Load order for dependencies
WalshCore.LoadOrder = {
    "walsh-core",
    "walsh-multicharacter", 
    "walsh-spawn",
    "walsh-hud",
    "walsh-inventory",
    "walsh-banking",
    "walsh-phone",
    "walsh-vehiclekeys",
    "walsh-garage",
    "walsh-fuel",
    "walsh-hospital",
    "walsh-police",
    "walsh-ambulance",
    "walsh-mechanic",
    "walsh-gangs",
    "walsh-drugs",
    "walsh-houses",
    "walsh-shops",
    "walsh-clothing",
    "walsh-barbershop",
    "walsh-weapons",
    "walsh-admin"
}