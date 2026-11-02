local ready = false

local TABLES = {
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_ranks` (
        `grade` INT NOT NULL,
        `permissions` LONGTEXT NOT NULL,
        PRIMARY KEY (`grade`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_agents` (
        `citizenid` VARCHAR(60) NOT NULL,
        `badge_number` VARCHAR(10) DEFAULT NULL,
        `department` VARCHAR(20) NOT NULL DEFAULT 'lspd',
        `divisions` LONGTEXT DEFAULT NULL,
        `duty_seconds` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_infractions` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(60) NOT NULL,
        `title` VARCHAR(120) NOT NULL,
        `description` TEXT DEFAULT NULL,
        `author` VARCHAR(100) DEFAULT NULL,
        `date` VARCHAR(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jj_policetablet_infractions_citizen` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_citizens` (
        `citizenid` VARCHAR(60) NOT NULL,
        `image_url` VARCHAR(500) DEFAULT NULL,
        `wanted` TINYINT(1) NOT NULL DEFAULT 0,
        `dangerous` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_notes` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `kind` VARCHAR(10) NOT NULL,
        `reference` VARCHAR(60) NOT NULL,
        `title` VARCHAR(120) NOT NULL,
        `description` TEXT DEFAULT NULL,
        `pinged` TINYINT(1) NOT NULL DEFAULT 0,
        `author` VARCHAR(100) DEFAULT NULL,
        `date` VARCHAR(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jj_policetablet_notes_reference` (`kind`, `reference`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_bills` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `citizenid` VARCHAR(60) NOT NULL,
        `amount` INT NOT NULL DEFAULT 0,
        `title` VARCHAR(200) NOT NULL,
        `id_article` VARCHAR(20) DEFAULT NULL,
        `jail_time` VARCHAR(20) DEFAULT NULL,
        `payed` TINYINT(1) NOT NULL DEFAULT 0,
        `agent_citizenid` VARCHAR(60) DEFAULT NULL,
        `agent_name` VARCHAR(100) DEFAULT NULL,
        `agent_badge` VARCHAR(10) DEFAULT NULL,
        `date` VARCHAR(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jj_policetablet_bills_citizen` (`citizenid`),
        KEY `jj_policetablet_bills_agent` (`agent_citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_vehicles` (
        `plate` VARCHAR(12) NOT NULL,
        `image` VARCHAR(500) DEFAULT NULL,
        `wanted` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`plate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_cases` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `kind` VARCHAR(10) NOT NULL,
        `title` VARCHAR(200) NOT NULL,
        `description` LONGTEXT DEFAULT NULL,
        `status` VARCHAR(10) NOT NULL DEFAULT 'open',
        `division` VARCHAR(30) DEFAULT NULL,
        `creator_citizenid` VARCHAR(60) DEFAULT NULL,
        `creator_name` VARCHAR(100) DEFAULT NULL,
        `data` LONGTEXT DEFAULT NULL,
        `date` VARCHAR(20) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `jj_policetablet_cases_kind` (`kind`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_announces` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `text` LONGTEXT NOT NULL,
        `pinned` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_chapters` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(120) NOT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_penalcodes` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `chapter_id` INT DEFAULT NULL,
        `id_article` VARCHAR(20) NOT NULL,
        `article` VARCHAR(200) NOT NULL,
        `description` TEXT DEFAULT NULL,
        `fine` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_templates` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `scope` VARCHAR(40) NOT NULL DEFAULT 'global',
        `name` VARCHAR(120) NOT NULL,
        `content` LONGTEXT NOT NULL,
        `created_at` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `jj_policetablet_jail` (
        `citizenid` VARCHAR(60) NOT NULL,
        `minutes` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
}

CreateThread(function()
    for _, query in ipairs(TABLES) do
        MySQL.query.await(query)
    end
    ready = true
end)

function WaitForDatabase()
    while not ready do Wait(100) end
end
