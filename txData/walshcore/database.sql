-- Walsh Core Framework Database Schema
-- This file contains all the necessary tables for the framework to function

-- Users table - stores player data
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
    UNIQUE KEY `license` (`license`),
    INDEX `idx_license` (`license`),
    INDEX `idx_job` (`job`),
    INDEX `idx_gang` (`gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gangs table - stores gang information
CREATE TABLE IF NOT EXISTS `gangs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `leader` varchar(60) NOT NULL,
    `money` int(11) DEFAULT 0,
    `territory` varchar(100) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    INDEX `idx_leader` (`leader`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gang members table - links players to gangs
CREATE TABLE IF NOT EXISTS `gang_members` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `gang_id` int(11) NOT NULL,
    `user_license` varchar(60) NOT NULL,
    `rank` int(11) DEFAULT 0,
    `joined_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`gang_id`) REFERENCES `gangs`(`id`) ON DELETE CASCADE,
    INDEX `idx_gang_id` (`gang_id`),
    INDEX `idx_user_license` (`user_license`),
    UNIQUE KEY `unique_gang_member` (`gang_id`, `user_license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Owned vehicles table - stores player vehicles
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner` varchar(60) NOT NULL,
    `plate` varchar(12) NOT NULL,
    `vehicle` longtext NOT NULL,
    `type` varchar(20) DEFAULT 'car',
    `job` varchar(50) DEFAULT NULL,
    `garage` varchar(50) DEFAULT 'pillboxgarage',
    `stored` tinyint(1) DEFAULT 1,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_stored` (`stored`),
    INDEX `idx_garage` (`garage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Red zone control table - tracks territory control
CREATE TABLE IF NOT EXISTS `redzone_control` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `zone_name` varchar(100) NOT NULL,
    `controlling_gang` varchar(50) DEFAULT NULL,
    `control_start` timestamp NULL DEFAULT NULL,
    `last_contested` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `zone_name` (`zone_name`),
    INDEX `idx_controlling_gang` (`controlling_gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Economy transactions table - logs all money transactions
CREATE TABLE IF NOT EXISTS `transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `from_license` varchar(60) DEFAULT NULL,
    `to_license` varchar(60) DEFAULT NULL,
    `amount` int(11) NOT NULL,
    `type` varchar(50) NOT NULL,
    `description` text DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_from_license` (`from_license`),
    INDEX `idx_to_license` (`to_license`),
    INDEX `idx_type` (`type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bans table - stores player bans
CREATE TABLE IF NOT EXISTS `bans` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `license` varchar(60) NOT NULL,
    `reason` text NOT NULL,
    `expires` bigint(20) DEFAULT 0,
    `banned_by` varchar(100) NOT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_license` (`license`),
    INDEX `idx_expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Items table - stores available items in the economy
CREATE TABLE IF NOT EXISTS `items` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `description` text DEFAULT NULL,
    `weight` decimal(10,2) DEFAULT 0.00,
    `rare` tinyint(1) DEFAULT 0,
    `can_remove` tinyint(1) DEFAULT 1,
    `price` int(11) DEFAULT 0,
    `category` varchar(50) DEFAULT 'misc',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player inventory table - stores player items
CREATE TABLE IF NOT EXISTS `player_inventory` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner` varchar(60) NOT NULL,
    `item` varchar(50) NOT NULL,
    `count` int(11) NOT NULL DEFAULT 1,
    `slot` int(11) DEFAULT NULL,
    `metadata` longtext DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`),
    INDEX `idx_item` (`item`),
    INDEX `idx_slot` (`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Properties table - stores property ownership
CREATE TABLE IF NOT EXISTS `properties` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `label` varchar(100) NOT NULL,
    `coords` text NOT NULL,
    `price` int(11) NOT NULL,
    `owner` varchar(60) DEFAULT NULL,
    `locked` tinyint(1) DEFAULT 1,
    `garage` tinyint(1) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server logs table - stores server events and admin actions
CREATE TABLE IF NOT EXISTS `server_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `type` varchar(50) NOT NULL,
    `message` text NOT NULL,
    `data` longtext DEFAULT NULL,
    `source` varchar(60) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_source` (`source`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gang wars table - tracks gang warfare events
CREATE TABLE IF NOT EXISTS `gang_wars` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `gang1` varchar(50) NOT NULL,
    `gang2` varchar(50) NOT NULL,
    `zone` varchar(100) NOT NULL,
    `status` enum('active', 'ended') DEFAULT 'active',
    `winner` varchar(50) DEFAULT NULL,
    `started_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `ended_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_gang1` (`gang1`),
    INDEX `idx_gang2` (`gang2`),
    INDEX `idx_zone` (`zone`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Kill logs table - tracks PvP kills
CREATE TABLE IF NOT EXISTS `kill_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `killer` varchar(60) NOT NULL,
    `victim` varchar(60) NOT NULL,
    `weapon` varchar(50) DEFAULT NULL,
    `distance` decimal(10,2) DEFAULT NULL,
    `location` text DEFAULT NULL,
    `zone` varchar(100) DEFAULT NULL,
    `reward` int(11) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_killer` (`killer`),
    INDEX `idx_victim` (`victim`),
    INDEX `idx_zone` (`zone`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Drug labs table - stores drug production facilities
CREATE TABLE IF NOT EXISTS `drug_labs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `type` varchar(50) NOT NULL,
    `coords` text NOT NULL,
    `owner_gang` varchar(50) DEFAULT NULL,
    `production_rate` decimal(10,2) DEFAULT 1.00,
    `storage` int(11) DEFAULT 0,
    `max_storage` int(11) DEFAULT 1000,
    `last_production` timestamp DEFAULT CURRENT_TIMESTAMP,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_owner_gang` (`owner_gang`),
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default items
INSERT IGNORE INTO `items` (`name`, `label`, `description`, `weight`, `price`, `category`) VALUES
('bread', 'Bread', 'A loaf of bread to satisfy hunger', 0.5, 5, 'food'),
('water', 'Water Bottle', 'Clean drinking water', 0.3, 3, 'drink'),
('bandage', 'Bandage', 'Medical bandage for treating wounds', 0.1, 15, 'medical'),
('lockpick', 'Lockpick', 'Tool for picking locks', 0.1, 50, 'illegal'),
('phone', 'Phone', 'Mobile phone for communication', 0.2, 250, 'electronics'),
('cigarettes', 'Cigarettes', 'Pack of cigarettes', 0.1, 15, 'misc'),
('energy_drink', 'Energy Drink', 'Restores stamina and energy', 0.3, 8, 'drink'),
('weapon_ammo', 'Weapon Ammo', 'Ammunition for weapons', 0.1, 5, 'weapon'),
('health_kit', 'Health Kit', 'Advanced medical kit', 0.5, 100, 'medical'),
('dirty_money', 'Dirty Money', 'Money from illegal activities', 0.0, 1, 'illegal');

-- Insert default red zones into redzone_control table
INSERT IGNORE INTO `redzone_control` (`zone_name`) VALUES
('Downtown Gang Territory'),
('Industrial Warzone');

-- Create initial admin user (optional - remove in production)
-- INSERT IGNORE INTO `users` (`license`, `name`, `money`, `bank`, `job`, `job_grade`) VALUES
-- ('license:admin', 'Admin', 1000000, 1000000, 'police', 4);

-- Database optimization indexes
ALTER TABLE `users` ADD INDEX `idx_money` (`money`);
ALTER TABLE `users` ADD INDEX `idx_last_seen` (`last_seen`);
ALTER TABLE `transactions` ADD INDEX `idx_amount` (`amount`);
ALTER TABLE `gang_members` ADD INDEX `idx_rank` (`rank`);
ALTER TABLE `owned_vehicles` ADD INDEX `idx_type` (`type`);

-- Database maintenance triggers
DELIMITER ;;

-- Trigger to update gang member count
CREATE TRIGGER `update_gang_timestamp` 
AFTER INSERT ON `gang_members` 
FOR EACH ROW 
BEGIN
    UPDATE `gangs` SET `updated_at` = CURRENT_TIMESTAMP WHERE `id` = NEW.gang_id;
END;;

-- Trigger to log transactions
CREATE TRIGGER `log_transaction` 
AFTER INSERT ON `transactions` 
FOR EACH ROW 
BEGIN
    INSERT INTO `server_logs` (`type`, `message`, `data`) 
    VALUES ('transaction', CONCAT('Transaction: ', NEW.description), JSON_OBJECT('amount', NEW.amount, 'type', NEW.type));
END;;

DELIMITER ;

-- Views for common queries
CREATE OR REPLACE VIEW `player_stats` AS
SELECT 
    u.license,
    u.name,
    u.money,
    u.bank,
    u.job,
    u.job_grade,
    u.gang,
    u.gang_grade,
    u.last_seen,
    COUNT(DISTINCT t1.id) as transactions_sent,
    COUNT(DISTINCT t2.id) as transactions_received,
    COALESCE(SUM(t1.amount), 0) as total_sent,
    COALESCE(SUM(t2.amount), 0) as total_received
FROM users u
LEFT JOIN transactions t1 ON u.license = t1.from_license
LEFT JOIN transactions t2 ON u.license = t2.to_license
GROUP BY u.license;

CREATE OR REPLACE VIEW `gang_stats` AS
SELECT 
    g.id,
    g.name,
    g.label,
    g.leader,
    g.money,
    g.territory,
    COUNT(gm.id) as member_count,
    g.created_at
FROM gangs g
LEFT JOIN gang_members gm ON g.id = gm.gang_id
GROUP BY g.id;

-- Cleanup old records procedure
DELIMITER ;;

CREATE PROCEDURE CleanupOldRecords()
BEGIN
    -- Clean up old transaction logs (older than 90 days)
    DELETE FROM transactions WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
    
    -- Clean up old server logs (older than 30 days)
    DELETE FROM server_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
    
    -- Clean up expired bans
    DELETE FROM bans WHERE expires > 0 AND expires < UNIX_TIMESTAMP();
    
    -- Clean up disconnected players' temporary data (older than 7 days)
    UPDATE users SET position = NULL WHERE last_seen < DATE_SUB(NOW(), INTERVAL 7 DAY);
END;;

DELIMITER ;

-- Event scheduler for automatic cleanup (requires SUPER privilege)
-- SET GLOBAL event_scheduler = ON;
-- CREATE EVENT IF NOT EXISTS cleanup_old_records
-- ON SCHEDULE EVERY 1 DAY
-- STARTS CURRENT_TIMESTAMP
-- DO CALL CleanupOldRecords();

-- Final database integrity check
ANALYZE TABLE users, gangs, gang_members, owned_vehicles, redzone_control, transactions, bans;

-- Database version tracking
CREATE TABLE IF NOT EXISTS `database_version` (
    `version` varchar(20) NOT NULL,
    `applied_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `database_version` (`version`) VALUES ('1.0.0');
