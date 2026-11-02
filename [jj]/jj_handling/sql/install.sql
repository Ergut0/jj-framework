-- jj_handling. El recurso crea estas tablas solo al arrancar; este archivo es por si preferís crearlas a mano

CREATE TABLE IF NOT EXISTS `jj_handling_profiles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `model_hash` INT UNSIGNED NOT NULL,
    `model_name` VARCHAR(32) NULL,
    `vehicle_class` TINYINT NULL,
    `params` TEXT NOT NULL,
    `preset` VARCHAR(32) NULL,
    `is_global` TINYINT(1) NOT NULL DEFAULT 0,
    `author` VARCHAR(64) NOT NULL,
    `author_name` VARCHAR(64) NULL,
    `version` INT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `model_hash` (`model_hash`),
    KEY `author` (`author`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Versiones anteriores de cada perfil, para poder restaurarlas
CREATE TABLE IF NOT EXISTS `jj_handling_history` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `profile_id` INT UNSIGNED NOT NULL,
    `version` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `params` TEXT NOT NULL,
    `edited_by` VARCHAR(64) NULL,
    `edited_by_name` VARCHAR(64) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `profile_id` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Perfil de serie de un modelo (kind = 'model', target = hash) o instalado en una matrícula (kind = 'plate')
CREATE TABLE IF NOT EXISTS `jj_handling_assignments` (
    `kind` VARCHAR(8) NOT NULL,
    `target` VARCHAR(16) NOT NULL,
    `profile_id` INT UNSIGNED NOT NULL,
    `assigned_by` VARCHAR(64) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`kind`, `target`),
    KEY `profile_id` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_handling_logs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `action` VARCHAR(32) NOT NULL,
    `actor` VARCHAR(64) NULL,
    `actor_name` VARCHAR(64) NULL,
    `target` VARCHAR(64) NULL,
    `details` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `action` (`action`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
