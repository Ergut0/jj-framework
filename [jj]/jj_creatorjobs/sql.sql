-- =============================================================
-- jj_creatorjobs - Esquema de base de datos
-- Ejecuta este archivo en tu base de datos antes de iniciar el recurso.
-- (Las tablas también se crean automáticamente al arrancar el recurso)
-- =============================================================

-- Trabajos creados con el Job Creator
CREATE TABLE IF NOT EXISTS `jobscreator_jobs` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rangos/grades de cada trabajo (id = nivel del rango, empieza en 0)
CREATE TABLE IF NOT EXISTS `jobscreator_grades` (
  `id` INT(11) NOT NULL DEFAULT 0,
  `job_name` VARCHAR(50) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `salary` INT(11) NOT NULL DEFAULT 0,
  `permission` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`job_name`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Puntos de interacción (Servicio, Inventario, Mercado, Ropero, Crafteo, Tuneo, Garaje, GuardarVehiculo, Jefe, Zona Centro...)
CREATE TABLE IF NOT EXISTS `jobscreator_points` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Blips del mapa
CREATE TABLE IF NOT EXISTS `jobscreator_blips` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Items del mercado de cada trabajo
CREATE TABLE IF NOT EXISTS `jobscreator_market` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `price` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `jobscreator_market_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Vehículos del garaje de cada trabajo
CREATE TABLE IF NOT EXISTS `jobscreator_vehicles` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `livery` INT(11) NOT NULL DEFAULT 0,
  `plate` VARCHAR(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `jobscreator_vehicles_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Permisos del menú F6 (Facturar, Cachear, Compraventa, Reparar...)
CREATE TABLE IF NOT EXISTS `jobscreator_perms` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `typePermission` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobscreator_perms_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Teleports de trabajos (privados del job o públicos)
CREATE TABLE IF NOT EXISTS `jobscreator_teleports` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Teleports globales (con contraseña y routing bucket opcionales)
CREATE TABLE IF NOT EXISTS `jobscreator_global_teleports` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Mercancía comprada pendiente de recoger en la lonja/mayorista
CREATE TABLE IF NOT EXISTS `jobscreator_lonja` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `amount` INT(11) NOT NULL DEFAULT 0,
  `price` INT(11) NOT NULL DEFAULT 0,
  `typeLonja` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobscreator_lonja_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Stock de vehículos de la compraventa
CREATE TABLE IF NOT EXISTS `jobscreator_compraventa` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `vehicle` VARCHAR(50) NOT NULL,
  `plate` VARCHAR(20) NOT NULL,
  `price` INT(11) NOT NULL DEFAULT 0,
  `mods` LONGTEXT DEFAULT NULL,
  `state` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `jobscreator_compraventa_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Facturas de fd_banking cuya experiencia ya se ha dado
CREATE TABLE IF NOT EXISTS `jobscreator_invoice_exp` (
  `invoice_id` INT(20) UNSIGNED NOT NULL,
  PRIMARY KEY (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Registro de cada empresa
CREATE TABLE IF NOT EXISTS `jobscreator_logs` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) DEFAULT NULL,
  `category` VARCHAR(20) NOT NULL,
  `actor` VARCHAR(100) NOT NULL,
  `identifier` VARCHAR(60) DEFAULT NULL,
  `message` TEXT NOT NULL,
  `created_at` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobscreator_logs_job` (`job`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
