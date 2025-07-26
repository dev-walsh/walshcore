-- Shared Utility Functions for Walsh Core Framework
-- These functions are available on both client and server

WalshUtils = {}

-- Math utilities
function WalshUtils.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function WalshUtils.RandomFloat(min, max)
    return min + math.random() * (max - min)
end

function WalshUtils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function WalshUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- String utilities
function WalshUtils.FormatNumber(number)
    if not number then return "0" end
    local formatted = tostring(number)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function WalshUtils.FormatMoney(amount)
    return "$" .. WalshUtils.FormatNumber(amount)
end

function WalshUtils.Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end

function WalshUtils.Split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

function WalshUtils.StartsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function WalshUtils.EndsWith(str, suffix)
    return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end

function WalshUtils.SanitizeString(str)
    if not str then return "" end
    -- Remove potentially dangerous characters
    return string.gsub(str, "[<>&\"']", "")
end

-- Table utilities
function WalshUtils.TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function WalshUtils.TableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function WalshUtils.TableMerge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    for k, v in pairs(t2) do result[k] = v end
    return result
end

function WalshUtils.TableCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = WalshUtils.TableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function WalshUtils.TableRemoveByValue(table, value)
    for i, v in ipairs(table) do
        if v == value then
            table.remove(table, i)
            break
        end
    end
end

function WalshUtils.TableShuffle(t)
    local tbl = {}
    for i = 1, #t do
        tbl[i] = t[i]
    end
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- Distance and coordinate utilities
function WalshUtils.GetDistance(pos1, pos2)
    if type(pos1) == "table" and type(pos2) == "table" then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        local dz = (pos1.z or 0) - (pos2.z or 0)
        return math.sqrt(dx*dx + dy*dy + dz*dz)
    end
    return 0
end

function WalshUtils.GetDistance2D(pos1, pos2)
    if type(pos1) == "table" and type(pos2) == "table" then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        return math.sqrt(dx*dx + dy*dy)
    end
    return 0
end

function WalshUtils.IsInRange(pos1, pos2, range)
    return WalshUtils.GetDistance(pos1, pos2) <= range
end

function WalshUtils.GetHeading(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.deg(math.atan2(dy, dx))
end

-- Time utilities
function WalshUtils.GetTimestamp()
    return os.time()
end

function WalshUtils.FormatTime(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

function WalshUtils.GetTimeDifference(timestamp1, timestamp2)
    return math.abs(timestamp1 - timestamp2)
end

function WalshUtils.SecondsToTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

-- Validation utilities
function WalshUtils.IsValidLicense(license)
    return license and string.match(license, "^license:[%w%d]+$") ~= nil
end

function WalshUtils.IsValidMoney(amount)
    return type(amount) == "number" and amount >= 0 and amount <= 999999999
end

function WalshUtils.IsValidCoords(coords)
    return type(coords) == "table" and 
           type(coords.x) == "number" and 
           type(coords.y) == "number" and 
           type(coords.z) == "number"
end

function WalshUtils.IsValidName(name)
    return type(name) == "string" and 
           string.len(name) >= 2 and 
           string.len(name) <= 50 and
           string.match(name, "^[%w%s]+$") ~= nil
end

function WalshUtils.IsValidPlate(plate)
    return type(plate) == "string" and 
           string.len(plate) >= 2 and 
           string.len(plate) <= 8 and
           string.match(plate, "^[%w]+$") ~= nil
end

-- Color utilities
function WalshUtils.HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber("0x" .. hex:sub(1, 2)),
        g = tonumber("0x" .. hex:sub(3, 4)),
        b = tonumber("0x" .. hex:sub(5, 6))
    }
end

function WalshUtils.RGBToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Random utilities
function WalshUtils.GenerateID(length)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, length or 8 do
        local rand = math.random(1, #charset)
        id = id .. string.sub(charset, rand, rand)
    end
    return id
end

function WalshUtils.GeneratePlate(prefix)
    local numbers = ""
    for i = 1, 4 do
        numbers = numbers .. math.random(0, 9)
    end
    return (prefix or "HK") .. numbers
end

function WalshUtils.RandomChoice(choices)
    if #choices == 0 then return nil end
    return choices[math.random(1, #choices)]
end

-- JSON utilities
function WalshUtils.EncodeJSON(data)
    return json.encode(data)
end

function WalshUtils.DecodeJSON(jsonString)
    local success, result = pcall(json.decode, jsonString)
    if success then
        return result
    else
        return {}
    end
end

-- Gang utilities
function WalshUtils.GetGangRankName(rank)
    if Config and Config.GangRanks and Config.GangRanks[rank] then
        return Config.GangRanks[rank].name
    end
    return "Unknown"
end

function WalshUtils.GetJobGradeName(job, grade)
    if Config and Config.Jobs and Config.Jobs[job] and Config.Jobs[job].grades then
        local gradeData = Config.Jobs[job].grades[tostring(grade)]
        if gradeData then
            return gradeData.name
        end
    end
    return "Unknown"
end

-- Economy utilities
function WalshUtils.CalculateTax(amount, taxRate)
    return math.floor(amount * (taxRate or 0.1))
end

function WalshUtils.CalculateMoneyPenalty(amount, penaltyRate)
    return math.floor(amount * (penaltyRate or Config.DeathPenalty or 0.1))
end

function WalshUtils.IsRichEnoughToSurvive(money)
    return money >= (Config.MinMoneyToSurvive or 100000)
end

function WalshUtils.GetMoneyStatus(money)
    local required = Config.MinMoneyToSurvive or 100000
    local percentage = (money / required) * 100
    
    if percentage >= 100 then
        return "safe"
    elseif percentage >= 50 then
        return "warning"
    elseif percentage >= 20 then
        return "danger"
    else
        return "critical"
    end
end

-- Weapon utilities
function WalshUtils.GetWeaponDisplayName(weaponHash)
    local weaponNames = {
        [GetHashKey("WEAPON_PISTOL")] = "Pistol",
        [GetHashKey("WEAPON_SMG")] = "SMG",
        [GetHashKey("WEAPON_ASSAULTRIFLE")] = "Assault Rifle",
        [GetHashKey("WEAPON_SNIPERRIFLE")] = "Sniper Rifle",
        [GetHashKey("WEAPON_SHOTGUN")] = "Shotgun",
        [GetHashKey("WEAPON_KNIFE")] = "Knife",
        [GetHashKey("WEAPON_BAT")] = "Baseball Bat"
    }
    
    return weaponNames[weaponHash] or "Unknown Weapon"
end

function WalshUtils.IsWeaponMelee(weaponHash)
    local meleeWeapons = {
        [GetHashKey("WEAPON_KNIFE")] = true,
        [GetHashKey("WEAPON_BAT")] = true,
        [GetHashKey("WEAPON_HAMMER")] = true,
        [GetHashKey("WEAPON_CROWBAR")] = true
    }
    
    return meleeWeapons[weaponHash] or false
end

-- Vehicle utilities
function WalshUtils.GetVehicleDisplayName(modelHash)
    return GetDisplayNameFromVehicleModel(modelHash) or "Unknown Vehicle"
end

function WalshUtils.GetVehicleClass(modelHash)
    return GetVehicleClassFromName(modelHash)
end

-- Logging utilities
function WalshUtils.Log(level, message, data)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s", timestamp, level:upper(), message)
    
    if data then
        logMessage = logMessage .. " | Data: " .. json.encode(data)
    end
    
    print(logMessage)
end

function WalshUtils.LogInfo(message, data)
    WalshUtils.Log("info", message, data)
end

function WalshUtils.LogWarn(message, data)
    WalshUtils.Log("warn", message, data)
end

function WalshUtils.LogError(message, data)
    WalshUtils.Log("error", message, data)
end

-- Debug utilities
function WalshUtils.Debug(message, data)
    if Config and Config.Debug then
        WalshUtils.Log("debug", message, data)
    end
end

function WalshUtils.PrintTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            WalshUtils.PrintTable(v, indent + 1)
        else
            print(prefix .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- Phone number utilities
function WalshUtils.GeneratePhoneNumber()
    local number = ""
    for i = 1, 10 do
        if i == 1 then
            number = number .. math.random(1, 9)
        else
            number = number .. math.random(0, 9)
        end
    end
    return number
end

function WalshUtils.FormatPhoneNumber(number)
    if string.len(number) == 10 then
        return string.format("(%s) %s-%s", 
            string.sub(number, 1, 3),
            string.sub(number, 4, 6),
            string.sub(number, 7, 10)
        )
    end
    return number
end

-- Export the utility functions
if IsDuplicityVersion() then
    -- Server side
    exports('GetUtils', function()
        return WalshUtils
    end)
else
    -- Client side
    exports('GetUtils', function()
        return WalshUtils
    end)
end

-- Global access
_G.WalshUtils = WalshUtils
