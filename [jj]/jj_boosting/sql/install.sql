-- jj_boosting: se puede ejecutar más de una vez. No borra ni cambia lo que ya exista.
-- El recurso también crea estas tablas al arrancar, a partir de este mismo archivo.

CREATE TABLE IF NOT EXISTS `jj_boosting_profiles` (
    `identifier` VARCHAR(60) NOT NULL,
    `display_name` VARCHAR(32) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `xp` INT UNSIGNED NOT NULL DEFAULT 0,
    `crypto` INT UNSIGNED NOT NULL DEFAULT 0,
    `completed` INT UNSIGNED NOT NULL DEFAULT 0,
    `failed` INT UNSIGNED NOT NULL DEFAULT 0,
    `money_earned` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `crypto_earned` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `services` TEXT NULL,
    `name_changed_at` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_activity` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    UNIQUE KEY `uq_jj_boosting_display_name` (`display_name`),
    KEY `idx_jj_boosting_xp` (`xp`),
    KEY `idx_jj_boosting_completed` (`completed`),
    KEY `idx_jj_boosting_crypto_earned` (`crypto_earned`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_boosting_contracts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uid` CHAR(16) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `class` VARCHAR(4) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `label` VARCHAR(60) NOT NULL,
    `plate` VARCHAR(8) NOT NULL,
    `zone_id` VARCHAR(40) NOT NULL,
    `spot_index` SMALLINT UNSIGNED NOT NULL,
    `dropoff_id` VARCHAR(40) NOT NULL,
    `reward_money` INT UNSIGNED NOT NULL,
    `reward_crypto` INT UNSIGNED NOT NULL,
    `reward_xp` INT UNSIGNED NOT NULL,
    `status` VARCHAR(12) NOT NULL DEFAULT 'offered',
    `assigned_by` VARCHAR(60) NULL,
    `expires_at` INT UNSIGNED NOT NULL,
    `accepted_at` INT UNSIGNED NULL,
    `stolen_at` INT UNSIGNED NULL,
    `finished_at` INT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_boosting_contract_uid` (`uid`),
    KEY `idx_jj_boosting_contract_owner` (`identifier`, `status`),
    KEY `idx_jj_boosting_contract_status` (`status`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_boosting_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contract_uid` CHAR(16) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `player_name` VARCHAR(64) NOT NULL,
    `class` VARCHAR(4) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `label` VARCHAR(60) NOT NULL,
    `result` VARCHAR(12) NOT NULL,
    `reason` VARCHAR(40) NULL,
    `duration` INT UNSIGNED NOT NULL DEFAULT 0,
    `reward_money` INT UNSIGNED NOT NULL DEFAULT 0,
    `reward_crypto` INT UNSIGNED NOT NULL DEFAULT 0,
    `reward_xp` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_boosting_history_contract` (`contract_uid`),
    KEY `idx_jj_boosting_history_owner` (`identifier`, `id`),
    KEY `idx_jj_boosting_history_filter` (`result`, `class`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_boosting_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reference` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `amount` INT NOT NULL,
    `reason` VARCHAR(64) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_boosting_tx_reference` (`reference`),
    KEY `idx_jj_boosting_tx_owner` (`identifier`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Unidades que quedan de cada artículo. Se repone al arrancar el recurso
CREATE TABLE IF NOT EXISTS `jj_boosting_store_stock` (
    `item_id` VARCHAR(40) NOT NULL,
    `remaining` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_boosting_store_purchases` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `reference` VARCHAR(64) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `item_id` VARCHAR(40) NOT NULL,
    `quantity` INT UNSIGNED NOT NULL,
    `price` INT UNSIGNED NOT NULL,
    `status` VARCHAR(10) NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `collected_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_boosting_purchase_reference` (`reference`),
    KEY `idx_jj_boosting_purchase_owner` (`identifier`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cambios hechos desde el panel de administración, por encima de config.lua
CREATE TABLE IF NOT EXISTS `jj_boosting_settings` (
    `name` VARCHAR(64) NOT NULL,
    `value` TEXT NOT NULL,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Auditoría: administración, seguridad, alertas policiales y rastreador
CREATE TABLE IF NOT EXISTS `jj_boosting_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(16) NOT NULL,
    `actor` VARCHAR(60) NULL,
    `target` VARCHAR(60) NULL,
    `action` VARCHAR(40) NOT NULL,
    `details` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_jj_boosting_logs_category` (`category`, `id`),
    KEY `idx_jj_boosting_logs_target` (`target`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
