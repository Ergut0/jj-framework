--[[
    Módulo de base de datos - Creación de tablas y helpers de consulta.
    Usa oxmysql (MySQL.*) cargado desde @oxmysql/lib/MySQL.lua en el fxmanifest.
]]

--- Crea todas las tablas necesarias si no existen.
--- Se ejecuta al arrancar el recurso desde server.lua (MySQL.ready).
function CreateTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_jobs` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(50) NOT NULL,
        `label` VARCHAR(100) NOT NULL,
        `img` TEXT DEFAULT NULL,
        `open` TINYINT(1) NOT NULL DEFAULT 1,
        `level` INT(11) NOT NULL DEFAULT 1,
        `experience` INT(11) NOT NULL DEFAULT 0,
        `money` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `jobscreator_jobs_name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_grades` (
        `id` INT(11) NOT NULL DEFAULT 0,
        `job_name` VARCHAR(50) NOT NULL,
        `name` VARCHAR(50) NOT NULL,
        `label` VARCHAR(100) NOT NULL,
        `salary` INT(11) NOT NULL DEFAULT 0,
        `permission` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`job_name`, `id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_points` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `x` FLOAT NOT NULL DEFAULT 0,
        `y` FLOAT NOT NULL DEFAULT 0,
        `z` FLOAT NOT NULL DEFAULT 0,
        `heading` FLOAT NOT NULL DEFAULT 0,
        `typePoint` VARCHAR(50) NOT NULL,
        `unique_identifier` VARCHAR(100) DEFAULT NULL,
        `radius` FLOAT NOT NULL DEFAULT 25.0,
        PRIMARY KEY (`id`),
        KEY `jobscreator_points_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_blips` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `x` FLOAT NOT NULL DEFAULT 0,
        `y` FLOAT NOT NULL DEFAULT 0,
        `z` FLOAT NOT NULL DEFAULT 0,
        `label` VARCHAR(100) NOT NULL,
        `blipsprite` INT(11) NOT NULL DEFAULT 1,
        `blipcolor` INT(11) NOT NULL DEFAULT 1,
        PRIMARY KEY (`id`),
        KEY `jobscreator_blips_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_market` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `name` VARCHAR(50) NOT NULL,
        `price` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `jobscreator_market_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_vehicles` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `name` VARCHAR(50) NOT NULL,
        `livery` INT(11) NOT NULL DEFAULT 0,
        `plate` VARCHAR(20) DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `jobscreator_vehicles_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_perms` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `typePermission` VARCHAR(50) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jobscreator_perms_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_teleports` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `label` VARCHAR(100) NOT NULL,
        `entrance_x` FLOAT NOT NULL DEFAULT 0,
        `entrance_y` FLOAT NOT NULL DEFAULT 0,
        `entrance_z` FLOAT NOT NULL DEFAULT 0,
        `entrance_heading` FLOAT NOT NULL DEFAULT 0,
        `exit_x` FLOAT NOT NULL DEFAULT 0,
        `exit_y` FLOAT NOT NULL DEFAULT 0,
        `exit_z` FLOAT NOT NULL DEFAULT 0,
        `exit_heading` FLOAT NOT NULL DEFAULT 0,
        `job_only` TINYINT(1) NOT NULL DEFAULT 1,
        `on_duty_only` TINYINT(1) NOT NULL DEFAULT 0,
        `allow_vehicle` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `jobscreator_teleports_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_global_teleports` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `label` VARCHAR(100) NOT NULL,
        `entrance_x` FLOAT NOT NULL DEFAULT 0,
        `entrance_y` FLOAT NOT NULL DEFAULT 0,
        `entrance_z` FLOAT NOT NULL DEFAULT 0,
        `entrance_heading` FLOAT NOT NULL DEFAULT 0,
        `exit_x` FLOAT NOT NULL DEFAULT 0,
        `exit_y` FLOAT NOT NULL DEFAULT 0,
        `exit_z` FLOAT NOT NULL DEFAULT 0,
        `exit_heading` FLOAT NOT NULL DEFAULT 0,
        `password` VARCHAR(50) DEFAULT NULL,
        `bucket` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_lonja` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `name` VARCHAR(50) NOT NULL,
        `label` VARCHAR(100) NOT NULL,
        `amount` INT(11) NOT NULL DEFAULT 0,
        `price` INT(11) NOT NULL DEFAULT 0,
        `typeLonja` VARCHAR(100) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jobscreator_lonja_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_compraventa` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `vehicle` VARCHAR(50) NOT NULL,
        `plate` VARCHAR(20) NOT NULL,
        `price` INT(11) NOT NULL DEFAULT 0,
        `mods` LONGTEXT DEFAULT NULL,
        `state` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `jobscreator_compraventa_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_invoice_exp` (
        `invoice_id` INT(20) UNSIGNED NOT NULL,
        PRIMARY KEY (`invoice_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jobscreator_logs` (
        `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) DEFAULT NULL,
        `category` VARCHAR(20) NOT NULL,
        `actor` VARCHAR(100) NOT NULL,
        `identifier` VARCHAR(60) DEFAULT NULL,
        `message` TEXT NOT NULL,
        `created_at` INT(11) UNSIGNED NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jobscreator_logs_job` (`job`, `created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    -- Solo se conservan los últimos días
    MySQL.update.await('DELETE FROM jobscreator_logs WHERE created_at < ?', { os.time() - (Config.LogDays or 30) * 86400 })

    print('[jj_creatorjobs] Tablas de la base de datos verificadas/creadas.')
end
