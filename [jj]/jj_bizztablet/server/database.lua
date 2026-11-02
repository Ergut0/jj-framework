local ready = false

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jj_bizztablet_businesses` (
        `name` VARCHAR(50) NOT NULL,
        `logo` VARCHAR(500) DEFAULT NULL,
        `description` TEXT DEFAULT NULL,
        `discord_url` VARCHAR(500) DEFAULT NULL,
        `category` VARCHAR(20) DEFAULT NULL,
        `coords` VARCHAR(100) DEFAULT NULL,
        `categories` LONGTEXT DEFAULT NULL,
        `promotions` LONGTEXT DEFAULT NULL,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jj_bizztablet_events` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `job` VARCHAR(50) NOT NULL,
        `title` VARCHAR(80) NOT NULL,
        `start_at` BIGINT NOT NULL,
        `end_at` BIGINT NOT NULL,
        `location` VARCHAR(80) NOT NULL,
        `description` TEXT DEFAULT NULL,
        `organizer` VARCHAR(80) NOT NULL,
        `image_url` VARCHAR(500) DEFAULT NULL,
        `cancelled` TINYINT(1) NOT NULL DEFAULT 0,
        `created_by` VARCHAR(60) DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `jj_bizztablet_events_job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    local limit = (os.time() - Config.EventRetentionDays * 86400) * 1000
    MySQL.query.await('DELETE FROM jj_bizztablet_events WHERE end_at < ?', { limit })

    ready = true
end)

function WaitForDatabase()
    while not ready do Wait(100) end
end
