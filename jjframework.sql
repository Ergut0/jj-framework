-- Base de datos completa del servidor.
-- Crea la base de datos jjframework y todas las tablas de una vez.
-- Se puede importar más de una vez: no borra ni cambia lo que ya exista.

CREATE DATABASE IF NOT EXISTS `jjframework` DEFAULT CHARACTER SET utf8mb4;
USE `jjframework`;

-- jj-framework: una fila por personaje
CREATE TABLE IF NOT EXISTS `jj_players` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `license` VARCHAR(60) NULL,
    `name` VARCHAR(64) NOT NULL,
    `charinfo` LONGTEXT NULL,
    `skin` LONGTEXT NULL,
    `accounts` LONGTEXT NOT NULL,
    `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
    `job_grade` INT NOT NULL DEFAULT 0,
    `position` LONGTEXT NULL,
    `metadata` LONGTEXT NULL,
    `inventory` LONGTEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_players_identifier` (`identifier`),
    KEY `idx_jj_players_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_admin: baneos. expires_at es un tiempo unix; NULL significa permanente
CREATE TABLE IF NOT EXISTS `jj_bans` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `license` VARCHAR(60) NOT NULL,
    `discord` VARCHAR(60) NULL,
    `name` VARCHAR(64) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `admin` VARCHAR(64) NOT NULL,
    `created_at` INT UNSIGNED NOT NULL,
    `expires_at` INT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_jj_bans_license` (`license`),
    KEY `idx_jj_bans_discord` (`discord`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_admin: registro de las acciones de los administradores
CREATE TABLE IF NOT EXISTS `jj_admin_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admin` VARCHAR(64) NOT NULL,
    `license` VARCHAR(60) NULL,
    `action` VARCHAR(32) NOT NULL,
    `target` VARCHAR(64) NULL,
    `details` VARCHAR(300) NULL,
    `created_at` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_jj_admin_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_multicharacter: huecos de personaje de las licencias que no usan el valor por defecto
CREATE TABLE IF NOT EXISTS `jj_character_slots` (
    `license` VARCHAR(60) NOT NULL,
    `slots` INT NOT NULL,
    PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_garages: vehículos con propietario. ox_inventory guarda aquí el maletero y la guantera.
-- state: 0 = fuera, 1 = en el garaje, 2 = en el depósito
CREATE TABLE IF NOT EXISTS `jj_vehicles` (
    `plate` VARCHAR(12) NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `glovebox` LONGTEXT NULL,
    `trunk` LONGTEXT NULL,
    `garage` VARCHAR(50) NOT NULL DEFAULT 'garagecentral',
    `state` TINYINT NOT NULL DEFAULT 1,
    `props` LONGTEXT NULL,
    `fuel` FLOAT NOT NULL DEFAULT 100,
    `engine` FLOAT NOT NULL DEFAULT 1000,
    `body` FLOAT NOT NULL DEFAULT 1000,
    `depotprice` INT NOT NULL DEFAULT 0,
    `serial` VARCHAR(16) NULL,
    PRIMARY KEY (`plate`),
    KEY `idx_jj_vehicles_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_gym: estadísticas de cada personaje
CREATE TABLE IF NOT EXISTS `jj_gym` (
    `identifier` VARCHAR(60) NOT NULL,
    `stamina` INT NOT NULL DEFAULT 0,
    `strength` INT NOT NULL DEFAULT 0,
    `yoga` INT NOT NULL DEFAULT 0,
    `lung` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ox_inventory: almacenes. El inventario del personaje va en jj_players.inventory
CREATE TABLE IF NOT EXISTS `ox_inventory` (
    `owner` VARCHAR(60) DEFAULT NULL,
    `name` VARCHAR(100) NOT NULL,
    `data` LONGTEXT DEFAULT NULL,
    `lastupdated` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `owner` (`owner`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- illenium-appearance: conjuntos guardados. El aspecto del personaje va en jj_players.skin
CREATE TABLE IF NOT EXISTS `player_outfits` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(60) DEFAULT NULL,
    `outfitname` VARCHAR(50) NOT NULL DEFAULT '0',
    `model` VARCHAR(50) DEFAULT NULL,
    `props` VARCHAR(1000) DEFAULT NULL,
    `components` VARCHAR(1500) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid_outfitname_model` (`citizenid`, `outfitname`, `model`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `outfitid` INT NOT NULL,
    `code` VARCHAR(50) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `FK_player_outfit_codes_player_outfits` (`outfitid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `management_outfits` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `minrank` INT NOT NULL DEFAULT 0,
    `name` VARCHAR(50) NOT NULL DEFAULT 'Cool Outfit',
    `gender` VARCHAR(50) NOT NULL DEFAULT 'male',
    `model` VARCHAR(50) DEFAULT NULL,
    `props` VARCHAR(1000) DEFAULT NULL,
    `components` VARCHAR(1500) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
