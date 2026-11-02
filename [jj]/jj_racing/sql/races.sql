-- Instalacion del recurso races (MySQL / MariaDB, oxmysql)

CREATE TABLE IF NOT EXISTS `race_settings` (
    `key`   VARCHAR(48) NOT NULL,
    `value` TEXT        NOT NULL,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `race_tracks` (
    `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `name`           VARCHAR(48)   NOT NULL,
    `category`       VARCHAR(16)   NOT NULL,
    `difficulty`     VARCHAR(16)   NOT NULL,
    `description`    VARCHAR(255)  NOT NULL DEFAULT '',
    `laps_default`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `vehicle_class`  VARCHAR(24)   NOT NULL DEFAULT 'any',
    `enabled`        TINYINT(1)    NOT NULL DEFAULT 0,
    `version`        INT UNSIGNED  NOT NULL DEFAULT 1,
    `tested_version` INT UNSIGNED  NOT NULL DEFAULT 0,
    `allow_crews`    TINYINT(1)    NOT NULL DEFAULT 1,
    `base_prize`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `time_limit`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `collisions`     TINYINT(1)    NOT NULL DEFAULT 1,
    `reference_time` INT UNSIGNED  NOT NULL DEFAULT 0,
    `grid`           MEDIUMTEXT    NOT NULL,
    `created_by`     VARCHAR(50)   NOT NULL DEFAULT '',
    `created_at`     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_race_tracks_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Se conservan las filas de versiones anteriores del trazado (historial de versiones)
CREATE TABLE IF NOT EXISTS `race_checkpoints` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `track_id`  INT UNSIGNED NOT NULL,
    `version`   INT UNSIGNED NOT NULL,
    `idx`       SMALLINT UNSIGNED NOT NULL,
    `kind`      VARCHAR(10)  NOT NULL DEFAULT 'normal',
    `x`         DOUBLE       NOT NULL,
    `y`         DOUBLE       NOT NULL,
    `z`         DOUBLE       NOT NULL,
    `radius`    FLOAT        NOT NULL DEFAULT 12,
    `height`    FLOAT        NOT NULL DEFAULT 8,
    `link_from` SMALLINT UNSIGNED NOT NULL DEFAULT 0,   -- 0 = sin enlace (solo atajos)
    `link_to`   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_race_cp` (`track_id`, `version`, `idx`),
    CONSTRAINT `fk_race_cp_track` FOREIGN KEY (`track_id`) REFERENCES `race_tracks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `race_events` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `track_id`     INT UNSIGNED NOT NULL,
    `title`        VARCHAR(64)  NOT NULL,
    `laps`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `vehicle_class` VARCHAR(24) NOT NULL DEFAULT 'any',
    `prize`        INT UNSIGNED NOT NULL DEFAULT 0,
    `scheduled_at` DATETIME     NOT NULL,
    `status`       VARCHAR(12)  NOT NULL DEFAULT 'scheduled',  -- scheduled | open | running | done | cancelled
    `created_by`   VARCHAR(50)  NOT NULL DEFAULT '',
    `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_race_events_status` (`status`, `scheduled_at`),
    CONSTRAINT `fk_race_events_track` FOREIGN KEY (`track_id`) REFERENCES `race_tracks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- No hay clave foranea al circuito: los resultados se conservan aunque se elimine
CREATE TABLE IF NOT EXISTS `race_results` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `race_key`      VARCHAR(40)  NOT NULL,
    `track_id`      INT UNSIGNED NOT NULL,
    `track_name`    VARCHAR(48)  NOT NULL,
    `track_version` INT UNSIGNED  NOT NULL,
    `event_id`      INT UNSIGNED NOT NULL DEFAULT 0,        -- 0 = sin evento
    `mode`          VARCHAR(10)  NOT NULL DEFAULT 'open',   -- open | crew | official
    `citizenid`     VARCHAR(50)  NOT NULL,
    `name`          VARCHAR(64)  NOT NULL,
    `crew_id`       INT UNSIGNED NOT NULL DEFAULT 0,        -- 0 = sin crew
    `crew_tag`      VARCHAR(8)   NOT NULL DEFAULT '',
    `crew_color`    CHAR(7)      NOT NULL DEFAULT '',
    `position`      SMALLINT UNSIGNED NOT NULL,
    `status`        VARCHAR(10)  NOT NULL,                  -- finished | dnf | dq
    `total_time`    INT UNSIGNED NOT NULL DEFAULT 0,
    `best_lap`      INT UNSIGNED NOT NULL DEFAULT 0,
    `laps`          SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `vehicle_model` VARCHAR(40)  NOT NULL DEFAULT '',
    `vehicle_class` VARCHAR(24)  NOT NULL DEFAULT '',
    `prize`         INT UNSIGNED NOT NULL DEFAULT 0,
    `points`        INT          NOT NULL DEFAULT 0,
    `crew_points`   INT          NOT NULL DEFAULT 0,
    `flagged`       TINYINT(1)   NOT NULL DEFAULT 0,
    `flag_reason`   VARCHAR(120) NOT NULL DEFAULT '',
    `voided`        TINYINT(1)   NOT NULL DEFAULT 0,
    `void_reason`   VARCHAR(120) NOT NULL DEFAULT '',
    `voided_by`     VARCHAR(64)  NOT NULL DEFAULT '',
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_race_results_key` (`race_key`),
    KEY `idx_race_results_cid` (`citizenid`, `id`),
    KEY `idx_race_results_track` (`track_id`, `track_version`, `voided`, `flagged`, `best_lap`),
    KEY `idx_race_results_flagged` (`flagged`, `voided`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mejor vuelta de cada piloto por circuito y version del trazado
CREATE TABLE IF NOT EXISTS `race_records` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `track_id`      INT UNSIGNED NOT NULL,
    `track_version` INT UNSIGNED NOT NULL,
    `citizenid`     VARCHAR(50)  NOT NULL,
    `name`          VARCHAR(64)  NOT NULL,
    `crew_id`       INT UNSIGNED NOT NULL DEFAULT 0,
    `crew_tag`      VARCHAR(8)   NOT NULL DEFAULT '',
    `crew_color`    CHAR(7)      NOT NULL DEFAULT '',
    `best_lap`      INT UNSIGNED NOT NULL,
    `vehicle_model` VARCHAR(40)  NOT NULL DEFAULT '',
    `vehicle_class` VARCHAR(24)  NOT NULL DEFAULT '',
    `result_id`     BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_race_record` (`track_id`, `track_version`, `citizenid`),
    KEY `idx_race_record_best` (`track_id`, `track_version`, `best_lap`),
    CONSTRAINT `fk_race_record_track` FOREIGN KEY (`track_id`) REFERENCES `race_tracks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dinero retenido (inscripciones, apuestas de crews, bolsas). Si el servidor cae, se reembolsa al arrancar.
CREATE TABLE IF NOT EXISTS `race_escrow` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `kind`       VARCHAR(8)   NOT NULL,             -- player | crew
    `owner`      VARCHAR(50)  NOT NULL,             -- citizenid o id del crew
    `amount`     BIGINT UNSIGNED NOT NULL,
    `account`    VARCHAR(16)  NOT NULL DEFAULT 'bank',
    `ref`        VARCHAR(40)  NOT NULL,             -- race_key
    `reason`     VARCHAR(32)  NOT NULL DEFAULT '',
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_race_escrow_ref` (`ref`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `race_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `actor_cid`  VARCHAR(50)  NOT NULL DEFAULT '',
    `actor_name` VARCHAR(64)  NOT NULL DEFAULT '',
    `action`     VARCHAR(40)  NOT NULL,
    `details`    TEXT         NOT NULL,
    `is_admin`   TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_race_logs_action` (`action`, `id`),
    KEY `idx_race_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
