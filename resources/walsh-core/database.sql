-- Walsh Core Framework Database Schema
-- Complete database structure for Walsh Core Framework

-- Players table - Main player data
CREATE TABLE IF NOT EXISTS `players` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `cid` int(11) DEFAULT NULL,
    `license` varchar(255) NOT NULL,
    `name` varchar(255) NOT NULL,
    `money` text DEFAULT NULL,
    `charinfo` text DEFAULT NULL,
    `job` text DEFAULT NULL,
    `gang` text DEFAULT NULL,
    `position` text DEFAULT NULL,
    `metadata` text DEFAULT NULL,
    `inventory` longtext DEFAULT NULL,
    `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`citizenid`),
    KEY `id` (`id`),
    KEY `last_updated` (`last_updated`),
    KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player vehicles
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `license` varchar(50) DEFAULT NULL,
    `citizenid` varchar(50) DEFAULT NULL,
    `vehicle` varchar(50) DEFAULT NULL,
    `hash` varchar(50) DEFAULT NULL,
    `mods` text DEFAULT NULL,
    `plate` varchar(15) NOT NULL,
    `fakeplate` varchar(50) DEFAULT NULL,
    `garage` varchar(50) DEFAULT NULL,
    `fuel` int(11) DEFAULT 100,
    `engine` float DEFAULT 1000,
    `body` float DEFAULT 1000,
    `state` int(11) DEFAULT 1,
    `depotprice` int(11) NOT NULL DEFAULT 0,
    `drivingdistance` int(50) DEFAULT NULL,
    `status` text DEFAULT NULL,
    `balance` int(11) NOT NULL DEFAULT 0,
    `paymentamount` int(11) NOT NULL DEFAULT 0,
    `paymentsleft` int(11) NOT NULL DEFAULT 0,
    `financetime` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `citizenid` (`citizenid`),
    KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gangs
CREATE TABLE IF NOT EXISTS `gangs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(50) NOT NULL,
    `grades` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Jobs
CREATE TABLE IF NOT EXISTS `jobs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(50) NOT NULL,
    `whitelisted` tinyint(1) NOT NULL DEFAULT 0,
    `grades` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Apartments
CREATE TABLE IF NOT EXISTS `apartments` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `type` varchar(255) DEFAULT NULL,
    `label` varchar(255) DEFAULT NULL,
    `citizenid` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- House locations
CREATE TABLE IF NOT EXISTS `houselocations` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) DEFAULT NULL,
    `label` varchar(255) DEFAULT NULL,
    `coords` text DEFAULT NULL,
    `owned` tinyint(1) DEFAULT NULL,
    `price` int(11) DEFAULT NULL,
    `tier` tinyint(4) DEFAULT NULL,
    `garage` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player houses
CREATE TABLE IF NOT EXISTS `player_houses` (
    `id` int(255) NOT NULL AUTO_INCREMENT,
    `house` varchar(50) NOT NULL,
    `identifier` varchar(50) DEFAULT NULL,
    `citizenid` varchar(50) DEFAULT NULL,
    `keyholders` text DEFAULT NULL,
    `decorations` text DEFAULT NULL,
    `stash` text DEFAULT NULL,
    `outfit` text DEFAULT NULL,
    `logout` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `house` (`house`),
    KEY `citizenid` (`citizenid`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Management
CREATE TABLE IF NOT EXISTS `management_funds` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `job_name` varchar(50) NOT NULL,
    `amount` int(100) NOT NULL,
    `type` enum('boss','gang') NOT NULL DEFAULT 'boss',
    PRIMARY KEY (`id`),
    UNIQUE KEY `job_name` (`job_name`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Occasions
CREATE TABLE IF NOT EXISTS `occasion_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `seller` varchar(50) DEFAULT NULL,
    `price` int(11) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `plate` varchar(50) DEFAULT NULL,
    `model` varchar(50) DEFAULT NULL,
    `mods` text DEFAULT NULL,
    `occasionid` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `occasionId` (`occasionid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Phone messages
CREATE TABLE IF NOT EXISTS `phone_messages` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `number` varchar(50) DEFAULT NULL,
    `messages` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `number` (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Playerskins
CREATE TABLE IF NOT EXISTS `playerskins` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `model` varchar(255) NOT NULL,
    `skin` text NOT NULL,
    `active` tinyint(4) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bans
CREATE TABLE IF NOT EXISTS `bans` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) DEFAULT NULL,
    `license` varchar(50) DEFAULT NULL,
    `discord` varchar(50) DEFAULT NULL,
    `ip` varchar(50) DEFAULT NULL,
    `reason` text DEFAULT NULL,
    `expire` int(11) DEFAULT NULL,
    `bannedby` varchar(255) NOT NULL DEFAULT 'Walsh System',
    PRIMARY KEY (`id`),
    KEY `license` (`license`),
    KEY `discord` (`discord`),
    KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crypto
CREATE TABLE IF NOT EXISTS `crypto` (
    `crypto` varchar(50) NOT NULL DEFAULT 'qbit',
    `worth` int(11) NOT NULL DEFAULT 0,
    `history` text DEFAULT NULL,
    PRIMARY KEY (`crypto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crypto transactions
CREATE TABLE IF NOT EXISTS `crypto_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `title` varchar(50) DEFAULT NULL,
    `message` text DEFAULT NULL,
    `date` timestamp NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dealers
CREATE TABLE IF NOT EXISTS `dealers` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL DEFAULT '0',
    `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    `time` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    `createdby` varchar(50) NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Phone gallery
CREATE TABLE IF NOT EXISTS `phone_gallery` (
    `citizenid` varchar(50) NOT NULL,
    `image` varchar(255) NOT NULL,
    `date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inmate
CREATE TABLE IF NOT EXISTS `inmate` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) DEFAULT NULL,
    `criminalcode` varchar(50) DEFAULT NULL,
    `linkedcitizen` varchar(50) DEFAULT NULL,
    `warrant` varchar(50) DEFAULT NULL,
    `guilty` varchar(50) DEFAULT NULL,
    `sentenced` varchar(50) DEFAULT NULL,
    `servetime` varchar(50) DEFAULT NULL,
    `chargedtime` varchar(50) DEFAULT NULL,
    `fine` varchar(50) DEFAULT NULL,
    `paid` varchar(50) DEFAULT NULL,
    `night` varchar(50) DEFAULT NULL,
    `day` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default data

-- Insert default gangs
INSERT IGNORE INTO `gangs` (`name`, `label`, `grades`) VALUES
('none', 'No Gang', '{}'),
('lostmc', 'The Lost MC', '{"0": {"name": "Recruit", "payment": 200}, "1": {"name": "Enforcer", "payment": 400}, "2": {"name": "Shot Caller", "payment": 600}, "3": {"name": "Boss", "isboss": true, "payment": 800}}'),
('ballas', 'Ballas', '{"0": {"name": "Recruit", "payment": 200}, "1": {"name": "Enforcer", "payment": 400}, "2": {"name": "Shot Caller", "payment": 600}, "3": {"name": "Boss", "isboss": true, "payment": 800}}'),
('vagos', 'Vagos', '{"0": {"name": "Recruit", "payment": 200}, "1": {"name": "Enforcer", "payment": 400}, "2": {"name": "Shot Caller", "payment": 600}, "3": {"name": "Boss", "isboss": true, "payment": 800}}'),
('cartel', 'Cartel', '{"0": {"name": "Recruit", "payment": 200}, "1": {"name": "Enforcer", "payment": 400}, "2": {"name": "Shot Caller", "payment": 600}, "3": {"name": "Boss", "isboss": true, "payment": 800}}'),
('families', 'Families', '{"0": {"name": "Recruit", "payment": 200}, "1": {"name": "Enforcer", "payment": 400}, "2": {"name": "Shot Caller", "payment": 600}, "3": {"name": "Boss", "isboss": true, "payment": 800}}');

-- Insert default jobs
INSERT IGNORE INTO `jobs` (`name`, `label`, `whitelisted`, `grades`) VALUES
('unemployed', 'Civilian', 0, '{}'),
('police', 'Law Enforcement', 1, '{"0": {"name": "Cadet", "payment": 50}, "1": {"name": "Officer", "payment": 75}, "2": {"name": "Sergeant", "payment": 100}, "3": {"name": "Lieutenant", "payment": 125}, "4": {"name": "Chief", "isboss": true, "payment": 150}}'),
('ambulance', 'EMS', 1, '{"0": {"name": "Paramedic", "payment": 50}, "1": {"name": "Doctor", "payment": 75}, "2": {"name": "Surgeon", "payment": 100}, "3": {"name": "Chief", "isboss": true, "payment": 150}}'),
('realestate', 'Real Estate', 1, '{"0": {"name": "Recruit", "payment": 50}, "1": {"name": "House Sales", "payment": 75}, "2": {"name": "Business Sales", "payment": 100}, "3": {"name": "Broker", "payment": 125}, "4": {"name": "Manager", "isboss": true, "payment": 150}}'),
('taxi', 'Taxi', 1, '{"0": {"name": "Recruit", "payment": 50}, "1": {"name": "Driver", "payment": 75}, "2": {"name": "Event Driver", "payment": 100}, "3": {"name": "Sales Manager", "payment": 125}, "4": {"name": "Manager", "isboss": true, "payment": 150}}'),
('bus', 'Bus', 1, '{"0": {"name": "Driver", "payment": 50}}'),
('reporter', 'Reporter', 1, '{"0": {"name": "Journalist", "payment": 50}}'),
('trucker', 'Trucker', 1, '{"0": {"name": "Driver", "payment": 50}}'),
('tow', 'Towing', 1, '{"0": {"name": "Driver", "payment": 50}}'),
('garbage', 'Garbage', 1, '{"0": {"name": "Collector", "payment": 50}}'),
('vineyard', 'Vineyard', 1, '{"0": {"name": "Picker", "payment": 50}}'),
('hotdog', 'Hotdog', 1, '{"0": {"name": "Sales", "payment": 50}}'),
('mechanic', 'Mechanic', 1, '{"0": {"name": "Recruit", "payment": 50}, "1": {"name": "Novice", "payment": 75}, "2": {"name": "Experienced", "payment": 100}, "3": {"name": "Advanced", "payment": 125}, "4": {"name": "Manager", "isboss": true, "payment": 150}}');

-- Insert crypto
INSERT IGNORE INTO `crypto` (`crypto`, `worth`, `history`) VALUES
('qbit', 1253, '[{"PreviousWorth":983, "NewWorth": 1253}]'),
('shungite', 753, '[{"PreviousWorth":463, "NewWorth": 753}]'),
('lme', 1060, '[{"PreviousWorth":960, "NewWorth": 1060}]'),
('xcoin', 318, '[{"PreviousWorth":234, "NewWorth": 318}]');

-- Create database version tracking
CREATE TABLE IF NOT EXISTS `database_version` (
    `version` varchar(20) NOT NULL,
    `applied_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `database_version` (`version`) VALUES ('1.0.0');

print("^2[Walsh Core]^7 Database schema loaded successfully!");