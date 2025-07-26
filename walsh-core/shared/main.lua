WalshCore = {}
WalshCore.Players = {}
WalshCore.Player = {}
WalshCore.Commands = {}
WalshCore.UseableItems = {}

-- Shared Variables
WalshCore.Shared = {}
WalshCore.Shared.Jobs = {}
WalshCore.Shared.Gangs = {}
WalshCore.Shared.Items = {}
WalshCore.Shared.Vehicles = {}
WalshCore.Shared.Weapons = {}

-- Debug function
function WalshCore.Debug(message, type)
    if WalshCore.CoreSettings and WalshCore.CoreSettings.DebugMode then
        local msgType = type or 'info'
        print(('[^3Walsh Core^7] [^5%s^7] %s'):format(msgType:upper(), message))
    end
end

-- Shared utility functions
WalshCore.Shared.Round = function(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
end

WalshCore.Shared.Trim = function(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

WalshCore.Shared.SplitStr = function(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

WalshCore.Shared.Dump = function(table)
    return json.encode(table, {indent = true})
end

WalshCore.Shared.TableContains = function(table, val)
    for _, value in pairs(table) do
        if value == val then return true end
    end
    return false
end

WalshCore.Shared.GetRandomLetter = function(length)
    length = length or 1
    local str = ''
    for _ = 1, length do
        str = str .. string.char(math.random(65, 90))
    end
    return str
end

WalshCore.Shared.GetRandomNumber = function(length)
    length = length or 1
    local str = ''
    for _ = 1, length do
        str = str .. math.random(0, 9)
    end
    return str
end

WalshCore.Shared.GetPlate = function()
    local plate = WalshCore.Shared.GetRandomLetter(WalshCore.PlateLetters) .. WalshCore.Shared.GetRandomNumber(WalshCore.PlateNumbers)
    if WalshCore.PlateUseSpace then
        return plate:sub(1, WalshCore.PlateLetters) .. ' ' .. plate:sub(WalshCore.PlateLetters + 1)
    else
        return plate
    end
end

WalshCore.Shared.GetVehiclesByName = function()
    return WalshCore.Shared.Vehicles
end

WalshCore.Shared.GetVehiclesByHash = function()
    local vehicles = {}
    for _, v in pairs(WalshCore.Shared.Vehicles) do
        vehicles[GetHashKey(v.model)] = v
    end
    return vehicles
end

WalshCore.Shared.GetVehiclesByCategory = function()
    local vehicles = {}
    for _, v in pairs(WalshCore.Shared.Vehicles) do
        if not vehicles[v.category] then vehicles[v.category] = {} end
        vehicles[v.category][#vehicles[v.category] + 1] = v
    end
    return vehicles
end

WalshCore.Shared.GetWeapons = function()
    return WalshCore.Shared.Weapons
end

WalshCore.Shared.GetWeaponsByName = function()
    return WalshCore.Shared.Weapons
end

WalshCore.Shared.GetWeaponsByHash = function()
    local weapons = {}
    for k, v in pairs(WalshCore.Shared.Weapons) do
        weapons[GetHashKey(k)] = v
    end
    return weapons
end

WalshCore.Shared.GetItems = function()
    return WalshCore.Shared.Items
end

WalshCore.Shared.GetJobs = function()
    return WalshCore.Shared.Jobs
end

WalshCore.Shared.GetGangs = function()
    return WalshCore.Shared.Gangs
end

-- Money formatting
WalshCore.Shared.CommaValue = function(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

WalshCore.Shared.GroupDigits = function(value)
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- Color utilities for UI
WalshCore.Shared.HexToRGB = function(hex)
    local hex = hex:gsub("#", "")
    return {
        r = tonumber("0x" .. hex:sub(1, 2)),
        g = tonumber("0x" .. hex:sub(3, 4)),
        b = tonumber("0x" .. hex:sub(5, 6))
    }
end

WalshCore.Shared.RGBToHex = function(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Event system for shared usage
WalshCore.Shared.TriggerCallback = function() end -- Will be overridden by client/server

-- Export the core object
exports('GetCoreObject', function()
    return WalshCore
end)