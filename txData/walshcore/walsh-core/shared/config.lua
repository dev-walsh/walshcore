-- Shared Configuration for Walsh Core Framework
-- This config is loaded on both client and server

WalshConfig = {}

-- Framework Information
WalshConfig.FrameworkInfo = {
    Name = "Walsh Core Framework",
    Version = "1.0.0",
    Author = "AI Generated Framework",
    Description = "Custom FiveM Framework for PvP Walsh Core gameplay"
}

-- Debug Settings
WalshConfig.Debug = false
WalshConfig.DevMode = false

-- Core Settings
WalshConfig.UseESX = false
WalshConfig.UseQBCore = false
WalshConfig.Standalone = true

-- Player Settings
WalshConfig.MaxPlayers = 64
WalshConfig.StartingMoney = 5000
WalshConfig.StartingBank = 0
WalshConfig.MaxMoney = 999999999
WalshConfig.MinMoneyToSurvive = 100000
WalshConfig.MoneyCheckInterval = 300000 -- 5 minutes

-- Death and Respawn Settings
WalshConfig.DeathPenalty = 0.1 -- 10% money loss
WalshConfig.RespawnTime = 30 -- seconds
WalshConfig.HospitalRespawn = true
WalshConfig.CanRespawnAtHospital = true

-- PvP Settings
WalshConfig.PvPEnabled = true
WalshConfig.FriendlyFire = true
WalshConfig.AllowKillRewards = true
WalshConfig.KillRewardMin = 1000
WalshConfig.KillRewardMax = 5000

-- Economy Settings
WalshConfig.UseBank = true
WalshConfig.UseCash = true
WalshConfig.ATMUsageFee = 5
WalshConfig.TransferFee = 10
WalshConfig.MaxTransferAmount = 100000

-- Tax Settings
WalshConfig.IncomeTax = 0.05 -- 5%
WalshConfig.PropertyTax = 0.02 -- 2%
WalshConfig.VehicleTax = 0.01 -- 1%

-- Gang Settings
WalshConfig.MaxGangMembers = 15
WalshConfig.GangCreationCost = 50000
WalshConfig.MaxGangs = 10
WalshConfig.AllowGangWars = true
WalshConfig.GangWarDuration = 1800 -- 30 minutes

-- Gang Ranks (shared with main config for consistency)
WalshConfig.GangRanks = {
    [1] = {name = "Member", permissions = {"invite"}},
    [2] = {name = "Lieutenant", permissions = {"invite", "kick", "promote"}},
    [3] = {name = "Boss", permissions = {"invite", "kick", "promote", "demote", "disband"}}
}

-- Job Settings
WalshConfig.DefaultJob = "unemployed"
WalshConfig.MaxJobGrade = 10
WalshConfig.PaycheckInterval = 600000 -- 10 minutes
WalshConfig.PaycheckAmount = {
    unemployed = 0,
    police = {[0] = 50, [1] = 75, [2] = 100, [3] = 125, [4] = 150},
    mechanic = {[0] = 40, [1] = 60, [2] = 80, [3] = 100}
}

-- Vehicle Settings
WalshConfig.EnableVehicleOwnership = true
WalshConfig.VehicleDespawnTime = 600000 -- 10 minutes
WalshConfig.MaxOwnedVehicles = 10
WalshConfig.VehicleKeys = true
WalshConfig.FuelEnabled = true
WalshConfig.FuelConsumption = 0.5

-- Weapon Settings
WalshConfig.EnableWeaponLicenses = true
WalshConfig.WeaponLicenseCost = 5000
WalshConfig.WeaponShopLicenseRequired = true
WalshConfig.AmmoConsumption = true
WalshConfig.WeaponDurability = false

-- Red Zone Settings
WalshConfig.RedZoneEnabled = true
WalshConfig.RedZonePvP = true
WalshConfig.RedZoneRewards = true
WalshConfig.RedZoneControlTime = 300 -- 5 minutes
WalshConfig.RedZoneContestants = 2 -- minimum players to contest

-- Drug System
WalshConfig.DrugSystemEnabled = true
WalshConfig.DrugLabProduction = true
WalshConfig.DrugSales = true
WalshConfig.DrugEffects = true

-- Property System
WalshConfig.PropertySystemEnabled = true
WalshConfig.PropertyOwnership = true
WalshConfig.PropertyRent = true
WalshConfig.MaxProperties = 3

-- Communication
WalshConfig.ChatEnabled = true
WalshConfig.ChatMaxMessages = 50
WalshConfig.ChatDistance = 20.0
WalshConfig.PhoneEnabled = true

-- Inventory Settings
WalshConfig.InventoryEnabled = true
WalshConfig.MaxInventorySlots = 40
WalshConfig.MaxInventoryWeight = 100.0
WalshConfig.ItemDecay = false

-- Status System
WalshConfig.StatusEnabled = true
WalshConfig.HungerEnabled = true
WalshConfig.ThirstEnabled = true
WalshConfig.StressEnabled = true
WalshConfig.HungerRate = 1.0
WalshConfig.ThirstRate = 2.0
WalshConfig.StressRate = 0.5

-- Weather and Time
WalshConfig.DynamicWeather = true
WalshConfig.WeatherChangeInterval = 1800000 -- 30 minutes
WalshConfig.TimeSync = true
WalshConfig.TimeCycle = true
WalshConfig.DayDuration = 48 -- minutes

-- Notification Settings
WalshConfig.NotificationDuration = 5000 -- 5 seconds
WalshConfig.NotificationPosition = "top-right"

-- UI Settings
WalshConfig.UIEnabled = true
WalshConfig.HUDEnabled = true
WalshConfig.MinimapEnabled = true
WalshConfig.SpeedometerEnabled = true

-- Sound Settings
WalshConfig.SoundsEnabled = true
WalshConfig.NotificationSounds = true
WalshConfig.UISounds = true

-- Admin Settings
WalshConfig.AdminMenuEnabled = true
WalshConfig.AdminGroups = {
    "superadmin",
    "admin", 
    "moderator"
}

-- Logging Settings
WalshConfig.LoggingEnabled = true
WalshConfig.LogTypes = {
    "transactions",
    "deaths",
    "kills",
    "admin_actions",
    "gang_activities",
    "vehicle_actions"
}

-- Performance Settings
WalshConfig.OptimizationEnabled = true
WalshConfig.StreamingDistance = 500.0
WalshConfig.UpdateRate = 1000 -- milliseconds

-- Anti-Cheat Settings
WalshConfig.AntiCheatEnabled = true
WalshConfig.SpeedLimit = 300 -- km/h
WalshConfig.HealthCheck = true
WalshConfig.MoneyCheck = true
WalshConfig.WeaponCheck = true

-- Spawn Settings
WalshConfig.SpawnPoints = {
    {x = -269.4, y = -955.3, z = 31.2, heading = 205.8},
    {x = -558.5, y = -1334.0, z = 25.1, heading = 312.3},
    {x = 195.7, y = -933.4, z = 30.7, heading = 142.5}
}

-- Hospital Locations
WalshConfig.Hospitals = {
    {x = 1839.6, y = 3672.9, z = 34.3, heading = 210.0, name = "Sandy Shores Medical Center"},
    {x = -247.8, y = 6331.5, z = 32.4, heading = 315.0, name = "Paleto Bay Medical Center"},
    {x = 357.4, y = -593.3, z = 28.8, heading = 252.0, name = "Pillbox Hill Medical Center"}
}

-- Police Stations
WalshConfig.PoliceStations = {
    {x = 425.1, y = -979.5, z = 30.7, heading = 96.0, name = "Mission Row PD"},
    {x = 1853.2, y = 3689.6, z = 34.3, heading = 210.0, name = "Sandy Shores PD"},
    {x = -449.4, y = 6012.7, z = 31.7, heading = 315.0, name = "Paleto Bay PD"}
}

-- Mechanic Shops
WalshConfig.MechanicShops = {
    {x = -347.5, y = -133.6, z = 39.0, heading = 340.0, name = "LS Customs"},
    {x = -1155.0, y = -2007.0, z = 13.2, heading = 135.0, name = "Airport Garage"},
    {x = 1175.0, y = 2640.0, z = 37.8, heading = 180.0, name = "Sandy Shores Garage"}
}

-- ATM Locations
WalshConfig.ATMLocations = {
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -1410.736, y = -100.437, z = 52.396},
    {x = -2962.582, y = 482.627, z = 15.703},
    {x = -3144.1, y = 1127.5, z = 20.9},
    {x = -1091.5, y = 2708.2, z = 18.9},
    {x = 527.3, y = -160.7, z = 57.1}
}

-- Store Locations
WalshConfig.StoreLocations = {
    {x = 25.7, y = -1347.3, z = 29.5, name = "24/7 Store"},
    {x = -48.0, y = -1757.5, z = 29.4, name = "LTD Gasoline"},
    {x = 1163.4, y = -323.8, z = 69.2, name = "24/7 Store"},
    {x = -707.5, y = -914.2, z = 19.2, name = "24/7 Store"}
}

-- Gas Station Locations
WalshConfig.GasStations = {
    {x = 49.4, y = 2778.8, z = 58.0},
    {x = 263.9, y = 2606.5, z = 44.9},
    {x = 1039.9, y = 2671.1, z = 39.5},
    {x = 1207.3, y = 2660.2, z = 37.9},
    {x = 2539.7, y = 2594.2, z = 37.9}
}

-- Clothing Store Locations
WalshConfig.ClothingStores = {
    {x = 72.3, y = -1399.1, z = 29.4, name = "Binco"},
    {x = -703.8, y = -152.3, z = 37.4, name = "Suburban"},
    {x = -167.9, y = -299.0, z = 39.7, name = "Ponsonbys"},
    {x = 428.7, y = -800.1, z = 29.5, name = "Binco"}
}

-- Barber Shop Locations
WalshConfig.BarberShops = {
    {x = -814.3, y = -183.8, z = 37.6, name = "Herr Kutz Barber"},
    {x = 136.8, y = -1708.4, z = 29.3, name = "Beach Combover"},
    {x = 1931.5, y = 3729.7, z = 32.8, name = "Sandy Shores Barber"}
}

-- Weapon Shop Locations (already in main config, but keeping here for consistency)
WalshConfig.WeaponShops = {
    {x = 1692.54, y = 3760.16, z = 34.71, name = "Sandy Shores Gun Shop"},
    {x = 252.696, y = -50.0643, z = 69.941, name = "Downtown Gun Shop"},
    {x = 22.56, y = -1109.89, z = 29.80, name = "Little Seoul Gun Shop"}
}

-- Telephone/Communication Settings
WalshConfig.PhoneNumber = {
    Emergency = "911",
    Police = "911",
    Medical = "911",
    Mechanic = "555-MECHANIC"
}

-- Key Bindings (default)
WalshConfig.DefaultKeys = {
    OpenMenu = "F1",
    OpenPhone = "F2", 
    OpenInventory = "TAB",
    GangMenu = "F6",
    Interaction = "E",
    VehicleLock = "L",
    EngineToggle = "F10"
}

-- Blip Settings
WalshConfig.BlipSettings = {
    ShowPlayers = true,
    ShowGangMembers = true,
    ShowJobMembers = true,
    ShowVehicles = false,
    ShowProperties = true
}

-- Voice Chat Settings (if using voice system)
WalshConfig.VoiceChat = {
    Enabled = true,
    DefaultRange = 15.0,
    ShoutRange = 30.0,
    WhisperRange = 3.0
}

-- Anti-Exploit Settings
WalshConfig.AntiExploit = {
    MoneyLimit = 999999999,
    SpeedCheck = true,
    GodModeCheck = true,
    SpectatorCheck = true,
    TeleportCheck = true
}

-- Backup and Recovery
WalshConfig.DataBackup = {
    Enabled = true,
    Interval = 300000, -- 5 minutes
    SaveOnDisconnect = true
}

-- Event Names (to prevent conflicts)
WalshConfig.Events = {
    PlayerLoaded = "walsh:client:playerLoaded",
    PlayerLogout = "walsh:server:playerLogout",
    MoneyChange = "walsh:client:updateMoney",
    JobChange = "walsh:client:jobUpdate",
    GangChange = "walsh:client:gangUpdate",
    Notification = "walsh:client:notify"
}

-- Global function to get shared config
function GetWalshConfig()
    return WalshConfig
end

-- Export the shared config
if IsDuplicityVersion() then
    -- Server side
    exports('GetWalshConfig', GetWalshConfig)
else
    -- Client side
    exports('GetWalshConfig', GetWalshConfig)
end

-- Make it globally accessible
_G.WalshConfig = WalshConfig
