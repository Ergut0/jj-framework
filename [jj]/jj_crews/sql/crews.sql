-- Instalacion del recurso crews (MySQL / MariaDB, oxmysql)

CREATE TABLE IF NOT EXISTS `crews` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(64)  NOT NULL,
    `tag`        VARCHAR(8)   NOT NULL,
    `color`      CHAR(7)      NOT NULL DEFAULT '#a855f7',
    `logo`       VARCHAR(255) NOT NULL DEFAULT '',
    `level`      INT          NOT NULL DEFAULT 1,
    `points`     BIGINT       NOT NULL DEFAULT 0,
    `wins`       INT          NOT NULL DEFAULT 0,
    `money`      BIGINT       NOT NULL DEFAULT 0,
    `frozen`     TINYINT(1)   NOT NULL DEFAULT 0,
    `leader_cid` VARCHAR(50)  NOT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_crews_name` (`name`),
    UNIQUE KEY `uq_crews_tag` (`tag`),
    KEY `idx_crews_points` (`points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_ranks` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `crew_id`     INT UNSIGNED NOT NULL,
    `name`        VARCHAR(32)  NOT NULL,
    `level`       INT          NOT NULL,
    `is_leader`   TINYINT(1)   NOT NULL DEFAULT 0,
    `permissions` TEXT         NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rank_level` (`crew_id`, `level`),
    CONSTRAINT `fk_rank_crew` FOREIGN KEY (`crew_id`) REFERENCES `crews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_members` (
    `citizenid` VARCHAR(50)  NOT NULL,
    `crew_id`   INT UNSIGNED NOT NULL,
    `rank_id`   INT UNSIGNED NOT NULL,
    `name`      VARCHAR(80)  NOT NULL DEFAULT '',
    `joined_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`),
    KEY `idx_member_crew` (`crew_id`),
    CONSTRAINT `fk_member_crew` FOREIGN KEY (`crew_id`) REFERENCES `crews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_invites` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `crew_id`     INT UNSIGNED NOT NULL,
    `citizenid`   VARCHAR(50)  NOT NULL,
    `invited_by`  VARCHAR(80)  NOT NULL DEFAULT '',
    `expires_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_invite` (`crew_id`, `citizenid`),
    KEY `idx_invite_cid` (`citizenid`),
    CONSTRAINT `fk_invite_crew` FOREIGN KEY (`crew_id`) REFERENCES `crews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_transactions` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `crew_id`       INT UNSIGNED NOT NULL,
    `citizenid`     VARCHAR(50)  NOT NULL DEFAULT '',
    `name`          VARCHAR(80)  NOT NULL DEFAULT '',
    `type`          VARCHAR(16)  NOT NULL,
    `amount`        BIGINT       NOT NULL,
    `balance_after` BIGINT       NOT NULL,
    `note`          VARCHAR(120) NOT NULL DEFAULT '',
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_tx_crew` (`crew_id`, `id`),
    CONSTRAINT `fk_tx_crew` FOREIGN KEY (`crew_id`) REFERENCES `crews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sin FK: los logs sobreviven al borrado del crew (auditoria).
CREATE TABLE IF NOT EXISTS `crew_logs` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `crew_id`    INT UNSIGNED NOT NULL DEFAULT 0,
    `crew_name`  VARCHAR(64)  NOT NULL DEFAULT '',
    `actor_cid`  VARCHAR(50)  NOT NULL DEFAULT '',
    `actor_name` VARCHAR(80)  NOT NULL DEFAULT '',
    `action`     VARCHAR(40)  NOT NULL,
    `details`    TEXT         NULL,
    `is_admin`   TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_log_crew` (`crew_id`, `id`),
    KEY `idx_log_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_settings` (
    `key`   VARCHAR(40) NOT NULL,
    `value` TEXT        NOT NULL,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
