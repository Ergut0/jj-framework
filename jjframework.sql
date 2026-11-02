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

-- jj_gangs: bandas y su barrio
CREATE TABLE IF NOT EXISTS `jj_gangs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `label` VARCHAR(40) NOT NULL,
    `color` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `x` FLOAT NOT NULL DEFAULT 0,
    `y` FLOAT NOT NULL DEFAULT 0,
    `z` FLOAT NOT NULL DEFAULT 0,
    `radius` FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_jj_gangs_label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_gangs: miembros, por identificador de personaje
CREATE TABLE IF NOT EXISTS `jj_gang_members` (
    `identifier` VARCHAR(60) NOT NULL,
    `gang_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`),
    KEY `idx_jj_gang_members_gang` (`gang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_gangs: jefe, armario, ropero, garaje y laboratorio
CREATE TABLE IF NOT EXISTS `jj_gang_points` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `gang_id` INT UNSIGNED NOT NULL,
    `type` VARCHAR(12) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `h` FLOAT NOT NULL DEFAULT 0,
    `lab` VARCHAR(20) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_jj_gang_points_gang` (`gang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_gangs: grafitis pintados
CREATE TABLE IF NOT EXISTS `jj_gang_graffitis` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `gang_id` INT UNSIGNED NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `nx` FLOAT NOT NULL,
    `ny` FLOAT NOT NULL,
    `nz` FLOAT NOT NULL,
    `url` VARCHAR(500) NULL,
    `author` VARCHAR(64) NULL,
    PRIMARY KEY (`id`),
    KEY `idx_jj_gang_graffitis_gang` (`gang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_personajes: huecos de personaje de las licencias que no usan el valor por defecto
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

-- lb-phone: copia de [phone]/lb-phone/phone.sql
-- phone_number is the identifier used for phones in twitter etc
CREATE TABLE IF NOT EXISTS `phone_phones` (
    `id` VARCHAR(100) NOT NULL, -- if metadata - unique id for the phone; if not - player identifier
    `owner_id` VARCHAR(100) NOT NULL, -- the player identifier of the first person who used the phone, used for lookup app etc
    `phone_number` VARCHAR(15) NOT NULL,
    `name` VARCHAR(50),

    `pin` VARCHAR(4) DEFAULT NULL,
    `face_id` VARCHAR(100) DEFAULT NULL, -- the identifier of the face that is used for the phone

    `settings` LONGTEXT, -- json encoded settings
    `is_setup` BOOLEAN DEFAULT FALSE,
    `assigned` BOOLEAN DEFAULT FALSE, -- if the phone is assigned to a phone item (metadata)
    `battery` INT NOT NULL DEFAULT 100, -- battery percentage

    `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY (`phone_number`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_last_phone` (
    `id` VARCHAR(100) NOT NULL, -- the player's identifier (not named identifier since esx_multicharacter breaks it)
    `phone_number` VARCHAR(15) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_albums` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `title` VARCHAR(100) NOT NULL,
    `shared` BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_album_members` (
    `album_id` INT NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,

    PRIMARY KEY (`album_id`, `phone_number`),
    FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photos` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `link` VARCHAR(500) NOT NULL,
    `is_video` BOOLEAN DEFAULT FALSE,
    `size` FLOAT NOT NULL DEFAULT 0,
    `metadata` VARCHAR(20) DEFAULT NULL,

    `is_favourite` BOOLEAN DEFAULT FALSE,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_photo_album_photos` (
    `album_id` INT NOT NULL,
    `photo_id` INT NOT NULL,

    PRIMARY KEY (`album_id`, `photo_id`),
    FOREIGN KEY (`album_id`) REFERENCES `phone_photo_albums`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`photo_id`) REFERENCES `phone_photos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_notes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,
    `title` VARCHAR(50) NOT NULL,
    `content` LONGTEXT, -- limit maybe?
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_notifications` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `app` VARCHAR(50) NOT NULL,

    `title` VARCHAR(50) DEFAULT NULL,
    `content` VARCHAR(500) DEFAULT NULL,
    `thumbnail` VARCHAR(500) DEFAULT NULL,
    `avatar` VARCHAR(500) DEFAULT NULL,
    `show_avatar` BOOLEAN DEFAULT FALSE,
    `custom_data` TEXT DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- TWITTER
CREATE TABLE IF NOT EXISTS `phone_twitter_hashtags` (
    `hashtag` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `last_used` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`hashtag`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_accounts` (
    `display_name` VARCHAR(30) NOT NULL,

    `username` VARCHAR(20) NOT NULL,
    `password` VARCHAR(100) NOT NULL,

    `phone_number` VARCHAR(15) NOT NULL,
    `bio` VARCHAR(100) DEFAULT NULL,
    `profile_image` VARCHAR(500) DEFAULT NULL,
    `profile_header` VARCHAR(500) DEFAULT NULL,

    `pinned_tweet` VARCHAR(50) DEFAULT NULL,

    `verified` TINYINT DEFAULT 0,
    `follower_count` INT(11) NOT NULL DEFAULT 0,
    `following_count` INT(11) NOT NULL DEFAULT 0,

    `private` BOOLEAN DEFAULT FALSE,

    `date_joined` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`username`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_follows` (
    `followed` VARCHAR(20) NOT NULL,
    `follower` VARCHAR(20) NOT NULL,
    `notifications` BOOLEAN NOT NULL DEFAULT FALSE, -- if the follower gets notifications from the followed

    PRIMARY KEY (`followed`, `follower`),
    FOREIGN KEY (`followed`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`follower`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_follow_requests` (
    `requester` VARCHAR(20) NOT NULL,
    `requestee` VARCHAR(20) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`requester`, `requestee`),
    FOREIGN KEY (`requester`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`requestee`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_tweets` (
    `id` VARCHAR(10) NOT NULL,
    `username` VARCHAR(20) NOT NULL, -- the person who tweeted, matches to `username` in phone_twitter_accounts

    `content` VARCHAR(280),
    `attachments` TEXT, -- json array of attachments

    `reply_to` VARCHAR(50) DEFAULT NULL, -- the tweet / reply this tweet / reply was a reply to

    `like_count` INT(11) DEFAULT 0,
    `reply_count` INT(11) DEFAULT 0,
    `retweet_count` INT(11) DEFAULT 0,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_likes` (
    `tweet_id` VARCHAR(50) NOT NULL,
    `username` VARCHAR(20) NOT NULL, -- the person who liked the tweet / reply, matches to `username` in phone_twitter_accounts

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`tweet_id`, `username`),
    FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
    -- no foreign key on tweet_id as it should still show in the feed, even if the tweet is deleted
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_retweets` (
    `tweet_id` VARCHAR(50) NOT NULL,
    `username` VARCHAR(20) NOT NULL, -- the person who retweeted the tweet / reply, matches to `username` in phone_twitter_accounts

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`tweet_id`, `username`),
    FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
    -- no foreign key on tweet_id as it should still show in the feed, even if the tweet is deleted
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_promoted` (
    `tweet_id` VARCHAR(50) NOT NULL,
    `promotions` INT(11) NOT NULL DEFAULT 0, -- how how many times this tweet should be promoted
    `views` INT(11) NOT NULL DEFAULT 0, -- how many times this tweet has been promoted

    PRIMARY KEY (`tweet_id`),
    FOREIGN KEY (`tweet_id`) REFERENCES `phone_twitter_tweets`(`id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_messages` (
    `id` VARCHAR(10) NOT NULL,

    `sender` VARCHAR(20) NOT NULL, -- the person who sent the message, matches to `username` in phone_twitter_accounts
    `recipient` VARCHAR(20) NOT NULL, -- the person who received the message, matches to `username` in phone_twitter_accounts

    `content` VARCHAR(1000),
    `attachments` TEXT, -- json array of attachments

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`sender`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`recipient`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_twitter_notifications` (
    `id` VARCHAR(10) NOT NULL,
    `username` VARCHAR(20) NOT NULL, -- the person who received the notification, matches to `username` in phone_twitter_accounts
    `from` VARCHAR(20) NOT NULL, -- the person who sent the notification, matches to `username` in phone_twitter_accounts

    `type` VARCHAR(20) NOT NULL, -- like, retweet, reply, follow
    `tweet_id` VARCHAR(50) DEFAULT NULL, -- the tweet / reply this notification is about

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`from`) REFERENCES `phone_twitter_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- PHONE
CREATE TABLE IF NOT EXISTS `phone_phone_contacts` (
    `contact_phone_number` VARCHAR(15) NOT NULL, -- the phone number of the contact
    `firstname` VARCHAR(50) NOT NULL DEFAULT "",
    `lastname` VARCHAR(50) NOT NULL DEFAULT "",
    `profile_image` VARCHAR(500) DEFAULT NULL,
    `email` VARCHAR(50) DEFAULT NULL,
    `address` VARCHAR(50) DEFAULT NULL,
    `favourite` BOOLEAN DEFAULT FALSE,
    `phone_number` VARCHAR(15) NOT NULL, -- the phone number of the person who added the contact

    PRIMARY KEY (`contact_phone_number`, `phone_number`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_calls` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,

    `caller` VARCHAR(15) NOT NULL, -- the phone number of the person who called
    `callee` VARCHAR(15) NOT NULL, -- the phone number of the person who was called

    `duration` INT(11) NOT NULL DEFAULT 0,
    `answered` BOOLEAN DEFAULT FALSE, -- whether the call was answered or not

    `hide_caller_id` BOOLEAN DEFAULT FALSE, -- whether the caller's phone number was hidden or not

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX IF NOT EXISTS idx_calls_missed ON phone_phone_calls (`callee`, `answered`);
CREATE INDEX IF NOT EXISTS idx_calls_callee_id ON phone_phone_calls (`callee`);
CREATE INDEX IF NOT EXISTS idx_calls_caller_id ON phone_phone_calls (`caller`);

CREATE TABLE IF NOT EXISTS `phone_phone_blocked_numbers` (
    `phone_number` VARCHAR(15) NOT NULL, -- the phone number of the person who blocked the number
    `blocked_number` VARCHAR(15) NOT NULL, -- the phone number that was blocked

    PRIMARY KEY (`phone_number`, `blocked_number`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_phone_voicemail` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,

    `caller` VARCHAR(15) NOT NULL,
    `callee` VARCHAR(15) NOT NULL,

    `url` VARCHAR(500) NOT NULL,
    `duration` INT NOT NULL,
    `hide_caller_id` BOOLEAN DEFAULT FALSE,
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- INSTAGRAM
CREATE TABLE IF NOT EXISTS `phone_instagram_accounts` (
    `display_name` VARCHAR(30) NOT NULL,

    `username` VARCHAR(20) NOT NULL,
    `password` VARCHAR(100) NOT NULL,

    `profile_image` VARCHAR(500) DEFAULT NULL,
    `bio` VARCHAR(100) DEFAULT NULL,

    `post_count` INT(11) NOT NULL DEFAULT 0,
    `story_count` INT(11) NOT NULL DEFAULT 0,
    `follower_count` INT(11) NOT NULL DEFAULT 0,
    `following_count` INT(11) NOT NULL DEFAULT 0,

    `phone_number` VARCHAR(15) NOT NULL,

    `private` BOOLEAN DEFAULT FALSE,

    `verified` BOOLEAN DEFAULT FALSE,
    `date_joined` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`username`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_follows` (
    `followed` VARCHAR(20) NOT NULL, -- the person followed, matches to `username` in phone_instagram_accounts
    `follower` VARCHAR(20) NOT NULL, -- the person following, matches to `username` in phone_instagram_accounts

    PRIMARY KEY (`followed`, `follower`),
    FOREIGN KEY (`followed`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`follower`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_posts` (
    `id` VARCHAR(10) NOT NULL,

    `media` TEXT, -- json array of attached media
    `caption` VARCHAR(500) NOT NULL DEFAULT "",
    `location` VARCHAR(50) DEFAULT NULL,

    `like_count` INT(11) NOT NULL DEFAULT 0,
    `comment_count` INT(11) NOT NULL DEFAULT 0,

    `username` VARCHAR(20) NOT NULL, -- the person who posted, matches to `username` in phone_instagram_accounts

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_comments` (
    `id` VARCHAR(10) NOT NULL,
    `post_id` VARCHAR(50) NOT NULL, -- the post this comment was made on, matches to `id` in phone_instagram_posts

    `username` VARCHAR(20) NOT NULL, -- the person who commented, matches to `username` in phone_instagram_accounts
    `comment` VARCHAR(500) NOT NULL DEFAULT "",
    `like_count` INT(11) NOT NULL DEFAULT 0,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`post_id`) REFERENCES `phone_instagram_posts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_likes` (
    `id` VARCHAR(10) NOT NULL, -- the post / comment this like was on, matches to `id` in phone_instagram_posts / phone_instagram_comments
    `username` VARCHAR(20) NOT NULL, -- the person who liked, matches to `username` in phone_instagram_accounts
    `is_comment` BOOLEAN NOT NULL DEFAULT FALSE, -- whether this like was on a comment or a post

    PRIMARY KEY (`id`, `username`),
    FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_messages` (
    `id` VARCHAR(10) NOT NULL,

    `sender` VARCHAR(20) NOT NULL, -- the person who sent the message, matches to `username` in phone_instagram_accounts
    `recipient` VARCHAR(20) NOT NULL, -- the person who received the message, matches to `username` in phone_instagram_accounts

    `content` VARCHAR(1000),
    `attachments` TEXT, -- json array of attachments

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`sender`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`recipient`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_notifications` (
    `id` VARCHAR(10) NOT NULL,
    `username` VARCHAR(20) NOT NULL,
    `from` VARCHAR(20) NOT NULL,

    `type` VARCHAR(20) NOT NULL, -- like, comment, follow
    `post_id` VARCHAR(50) DEFAULT NULL, -- the post / comment this notification is about

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`from`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_stories` (
    `id` VARCHAR(10) NOT NULL,

    `username` VARCHAR(20) NOT NULL,
    `image` VARCHAR(500) NOT NULL,
    `metadata` LONGTEXT DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_stories_views` (
    `story_id` VARCHAR(50) NOT NULL,
    `viewer` VARCHAR(20) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`story_id`, `viewer`),
    FOREIGN KEY (`story_id`) REFERENCES `phone_instagram_stories`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`viewer`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_instagram_follow_requests` (
    `requester` VARCHAR(20) NOT NULL,
    `requestee` VARCHAR(20) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`requester`, `requestee`),
    FOREIGN KEY (`requester`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`requestee`) REFERENCES `phone_instagram_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CLOCK
CREATE TABLE IF NOT EXISTS `phone_clock_alarms` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `hours` INT(2) NOT NULL DEFAULT 0,
    `minutes` INT(2) NOT NULL DEFAULT 0,

    `label` VARCHAR(50) DEFAULT NULL,
    `enabled` BOOLEAN DEFAULT TRUE,

    PRIMARY KEY (`id`, `phone_number`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- TINDER
CREATE TABLE IF NOT EXISTS `phone_tinder_accounts` (
    `name` VARCHAR(50) NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,

    `photos` TEXT, -- json array of photos
    `bio` VARCHAR(500) DEFAULT NULL,
    `dob` DATE NOT NULL,

    `is_male` BOOLEAN NOT NULL,
    `interested_men` BOOLEAN NOT NULL,
    `interested_women` BOOLEAN NOT NULL,
    `active` BOOLEAN NOT NULL DEFAULT TRUE,

    `last_seen` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`phone_number`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_swipes` (
    `swiper` VARCHAR(15) NOT NULL, -- the phone number of the person who swiped
    `swipee` VARCHAR(15) NOT NULL, -- the phone number of the person who was swiped on

    `liked` BOOLEAN NOT NULL DEFAULT FALSE, -- whether the swiper liked the swipee or not

    PRIMARY KEY (`swiper`, `swipee`),
    FOREIGN KEY (`swiper`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`swipee`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_matches` (
    `phone_number_1` VARCHAR(15) NOT NULL,
    `phone_number_2` VARCHAR(15) NOT NULL,

    `latest_sender` VARCHAR(15) DEFAULT NULL, -- the phone number of the person who sent the latest message between the two people
    `latest_message` VARCHAR(1000) DEFAULT NULL, -- the latest message sent between the two people
    `latest_message_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- the timestamp of the latest message sent between the two people

    `phone_number_1_has_unread` BOOLEAN NOT NULL DEFAULT FALSE, -- whether phone_number_1 has unread messages from phone_number_2
    `phone_number_2_has_unread` BOOLEAN NOT NULL DEFAULT FALSE, -- whether phone_number_2 has unread messages from phone_number_1

    PRIMARY KEY (`phone_number_1`, `phone_number_2`),
    FOREIGN KEY (`phone_number_1`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`phone_number_2`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tinder_messages` (
    `id` INT NOT NULL AUTO_INCREMENT, -- the message id

    `sender` VARCHAR(15) NOT NULL, -- the phone number of the person who sent the message
    `recipient` VARCHAR(15) NOT NULL, -- the phone number of the person who received the message

    `content` VARCHAR(1000),
    `attachments` TEXT, -- json array of attachments

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`sender`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`recipient`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MESSAGES
CREATE TABLE IF NOT EXISTS `phone_message_channels` (
    `id` INT NOT NULL AUTO_INCREMENT,

    `is_group` BOOLEAN NOT NULL DEFAULT FALSE,
    `name` VARCHAR(50) DEFAULT NULL,
    `photo` VARCHAR(500) DEFAULT NULL,
    `last_message` VARCHAR(50) NOT NULL DEFAULT "",
    `last_message_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_message_members` (
    `channel_id` INT NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,

    `is_owner` BOOLEAN NOT NULL DEFAULT FALSE,
    `deleted` BOOLEAN NOT NULL DEFAULT FALSE, -- if the member has deleted the channel
    `unread` INT NOT NULL DEFAULT 0,

    PRIMARY KEY (`channel_id`, `phone_number`),
    FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX IF NOT EXISTS idx_members_phone_number ON phone_message_members (`phone_number`);

CREATE TABLE IF NOT EXISTS `phone_message_messages` (
    `id` INT NOT NULL AUTO_INCREMENT,

    `channel_id` INT NOT NULL,

    `sender` VARCHAR(15) NOT NULL,
    `content` VARCHAR(1000),
    `attachments` TEXT DEFAULT NULL, -- json array of attachments

    `reply_to` INT DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`channel_id`) REFERENCES `phone_message_channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_message_reactions` (
    `message_id` INT NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,
    `reaction` VARCHAR(50) NOT NULL,

    PRIMARY KEY (`message_id`, `phone_number`, `reaction`),
    FOREIGN KEY (`message_id`) REFERENCES `phone_message_messages`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- DARKCHAT
CREATE TABLE IF NOT EXISTS `phone_darkchat_accounts` (
    `phone_number` VARCHAR(15) NOT NULL,
    `username` VARCHAR(20) NOT NULL,
    `password` VARCHAR(100) NOT NULL,

    PRIMARY KEY (`username`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_channels` (
    `name` VARCHAR(50) NOT NULL,
    `password` VARCHAR(100) DEFAULT NULL, -- if set, the channel is private and requires a password to join

    PRIMARY KEY (`name`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_members` (
    `channel_name` VARCHAR(50) NOT NULL,
    `username` VARCHAR(20) NOT NULL,

    PRIMARY KEY (`channel_name`, `username`),
    FOREIGN KEY (`channel_name`) REFERENCES `phone_darkchat_channels`(`name`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`username`) REFERENCES `phone_darkchat_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_darkchat_messages` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `channel` VARCHAR(50) NOT NULL,
    `sender` VARCHAR(20) NOT NULL,
    `content` VARCHAR(1000),
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`channel`) REFERENCES `phone_darkchat_channels`(`name`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`sender`) REFERENCES `phone_darkchat_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- WALLET
CREATE TABLE IF NOT EXISTS `phone_wallet_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `amount` INT(11) NOT NULL,
    `company` VARCHAR(50) NOT NULL,
    `logo` VARCHAR(200) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- YELLOW PAGES
CREATE TABLE IF NOT EXISTS `phone_yellow_pages_posts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,
    `title` VARCHAR(50) NOT NULL,
    `description` VARCHAR(1000) NOT NULL,

    `attachment` VARCHAR(500) DEFAULT NULL,
    `price` INT(11) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- BACKUPS
CREATE TABLE IF NOT EXISTS `phone_backups` (
    `id` VARCHAR(100) NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MARKETPLACE
CREATE TABLE IF NOT EXISTS `phone_marketplace_posts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `title` VARCHAR(50) NOT NULL,
    `description` VARCHAR(1000) NOT NULL,
    `attachments` TEXT, -- json array of attachments
    `price` INT(11) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MUSIC
CREATE TABLE IF NOT EXISTS `phone_music_playlists` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `name` VARCHAR(50) NOT NULL,
    `cover` VARCHAR(500) DEFAULT NULL,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_music_saved_playlists` (
    `playlist_id` INT UNSIGNED NOT NULL,
    `phone_number` VARCHAR(15) NOT NULL,

    PRIMARY KEY (`playlist_id`, `phone_number`),
    FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_music_songs` (
    `song_id` VARCHAR(100) NOT NULL,
    `playlist_id` INT UNSIGNED NOT NULL,

    PRIMARY KEY (`song_id`, `playlist_id`),
    FOREIGN KEY (`playlist_id`) REFERENCES `phone_music_playlists`(`id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MAIL
CREATE TABLE IF NOT EXISTS `phone_mail_accounts` (
    `address` VARCHAR(100) NOT NULL,
    `password` VARCHAR(100) NOT NULL,

    PRIMARY KEY (`address`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_mail_messages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,

    `recipient` VARCHAR(100) NOT NULL,
    `sender` VARCHAR(100) NOT NULL,

    `subject` VARCHAR(100) NOT NULL,
    `content` TEXT NOT NULL,
    `attachments` LONGTEXT, -- json array of attachments
    `actions` LONGTEXT, -- json array of actions

    `read` BOOLEAN NOT NULL DEFAULT FALSE,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE INDEX IF NOT EXISTS idx_recipient ON phone_mail_messages (`recipient`);
CREATE INDEX IF NOT EXISTS idx_sender ON phone_mail_messages (`sender`);

CREATE TABLE IF NOT EXISTS `phone_mail_deleted` (
    `message_id` INT UNSIGNED NOT NULL,
    `address` VARCHAR(100) NOT NULL,

    PRIMARY KEY (`message_id`, `address`),
    FOREIGN KEY (`message_id`) REFERENCES `phone_mail_messages`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`address`) REFERENCES `phone_mail_accounts`(`address`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- COMPANIES APP
CREATE TABLE IF NOT EXISTS `phone_services_channels` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,
    `company` VARCHAR(50) NOT NULL,

    `last_message` VARCHAR(100) DEFAULT NULL,
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_services_messages` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `channel_id` INT UNSIGNED NOT NULL,

    `sender` VARCHAR(15) NOT NULL,
    `message` VARCHAR(1000) NOT NULL,

    `x_pos` INT(11) DEFAULT NULL,
    `y_pos` INT(11) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`channel_id`) REFERENCES `phone_services_channels`(`id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MAPS
CREATE TABLE IF NOT EXISTS `phone_maps_locations` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `name` VARCHAR(50) NOT NULL,

    `x_pos` FLOAT NOT NULL,
    `y_pos` FLOAT NOT NULL,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CRYPTO
CREATE TABLE IF NOT EXISTS `phone_crypto` (
    `id` VARCHAR(100) NOT NULL, -- player identifier
    `coin` VARCHAR(15) NOT NULL, -- coin, for example "bitcoin"
    `amount` DOUBLE UNSIGNED NOT NULL DEFAULT 0, -- amount of coins
    `invested` INT(11) NOT NULL DEFAULT 0, -- amount of $$$ invested

    PRIMARY KEY (`id`, `coin`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_crypto_coins` (
    `coin` VARCHAR(15) NOT NULL,
    `coin_value` DOUBLE UNSIGNED NOT NULL DEFAULT 0,

    PRIMARY KEY (`coin`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ACCOUNT SWITCHER
CREATE TABLE IF NOT EXISTS `phone_logged_in_accounts` (
    `phone_number` VARCHAR(15) NOT NULL,
    `app` VARCHAR(50) NOT NULL,
    `username` VARCHAR(100) NOT NULL,
    `active` BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (`phone_number`, `app`, `username`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- TIKTOK
CREATE TABLE IF NOT EXISTS `phone_tiktok_accounts` (
    `name` VARCHAR(30) NOT NULL,
    `bio` VARCHAR(100) DEFAULT NULL,
    `avatar` VARCHAR(500) DEFAULT NULL,

    `username` VARCHAR(20) NOT NULL,
    `password` VARCHAR(100) NOT NULL,

    `verified` BOOLEAN DEFAULT FALSE,

    `follower_count` INT(11) NOT NULL DEFAULT 0,
    `following_count` INT(11) NOT NULL DEFAULT 0,
    `like_count` INT(11) NOT NULL DEFAULT 0,
    `video_count` INT(11) NOT NULL DEFAULT 0,

    `twitter` VARCHAR(20) DEFAULT NULL,
    `instagram` VARCHAR(20) DEFAULT NULL,

    `show_likes` BOOLEAN DEFAULT TRUE,

    `phone_number` VARCHAR(15) NOT NULL,
    `date_joined` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`username`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_follows` (
    `followed` VARCHAR(20) NOT NULL,
    `follower` VARCHAR(20) NOT NULL,

    PRIMARY KEY (`followed`, `follower`),
    FOREIGN KEY (`followed`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`follower`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_videos` (
    `id` VARCHAR(10) NOT NULL,

    `username` VARCHAR(20) NOT NULL,

    `src` VARCHAR(500) NOT NULL,
    `caption` VARCHAR(100) DEFAULT NULL,
    `metadata` LONGTEXT, -- json array of metadata
    `music` TEXT DEFAULT NULL,

    `likes` INT(11) NOT NULL DEFAULT 0,
    `comments` INT(11) NOT NULL DEFAULT 0,
    `views` INT(11) NOT NULL DEFAULT 0,
    `saves` INT(11) NOT NULL DEFAULT 0,

    `pinned_comment` VARCHAR(10) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_likes` (
    `username` VARCHAR(20) NOT NULL,
    `video_id` VARCHAR(10) NOT NULL,

    PRIMARY KEY (`username`, `video_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_views` (
    `username` VARCHAR(20) NOT NULL,
    `video_id` VARCHAR(10) NOT NULL,

    PRIMARY KEY (`username`, `video_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_saves` (
    `username` VARCHAR(20) NOT NULL,
    `video_id` VARCHAR(10) NOT NULL,

    PRIMARY KEY (`username`, `video_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_comments` (
    `id` VARCHAR(10) NOT NULL,
    `reply_to` VARCHAR(10) DEFAULT NULL,
    `video_id` VARCHAR(10) NOT NULL,

    `username` VARCHAR(20) NOT NULL,
    `comment` VARCHAR(550) NOT NULL,

    `likes` INT(11) NOT NULL DEFAULT 0,
    `replies` INT(11) NOT NULL DEFAULT 0,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`reply_to`) REFERENCES `phone_tiktok_comments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_comments_likes` (
    `username` VARCHAR(20) NOT NULL,
    `comment_id` VARCHAR(10) NOT NULL,

    PRIMARY KEY (`username`, `comment_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_channels` (
    `id` VARCHAR(10) NOT NULL,

    `last_message` VARCHAR(50) NOT NULL,

    `member_1` VARCHAR(20) NOT NULL,
    `member_2` VARCHAR(20) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    UNIQUE KEY (`member_1`, `member_2`),
    FOREIGN KEY (`member_1`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`member_2`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_messages` (
    `id` VARCHAR(10) NOT NULL,
    `channel_id` VARCHAR(10) NOT NULL,
    `sender` VARCHAR(20) NOT NULL,

    `content` VARCHAR(500) NOT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`sender`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_pinned_videos` (
    `username` VARCHAR(20) NOT NULL,
    `video_id` VARCHAR(10) NOT NULL,

    PRIMARY KEY (`username`, `video_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_notifications` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(20) NOT NULL,

    `from` VARCHAR(20) NOT NULL,
    `type` VARCHAR(20) NOT NULL, -- like, comment, follow, save, reply or like_comment
    `video_id` VARCHAR(10) DEFAULT NULL,
    `comment_id` VARCHAR(10) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`from`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`video_id`) REFERENCES `phone_tiktok_videos`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`comment_id`) REFERENCES `phone_tiktok_comments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phone_tiktok_unread_messages` (
    `username` VARCHAR(20) NOT NULL,
    `channel_id` VARCHAR(10) NOT NULL,
    `amount` INT(11) NOT NULL DEFAULT 0,

    PRIMARY KEY (`username`, `channel_id`),
    FOREIGN KEY (`username`) REFERENCES `phone_tiktok_accounts`(`username`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`channel_id`) REFERENCES `phone_tiktok_channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- VOICE MEMOS
CREATE TABLE IF NOT EXISTS `phone_voice_memos_recordings` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `phone_number` VARCHAR(15) NOT NULL,

    `file_name` VARCHAR(50) NOT NULL,
    `file_url` VARCHAR(500) NOT NULL,
    `file_length` INT(11) NOT NULL,

    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`id`),
    FOREIGN KEY (`phone_number`) REFERENCES `phone_phones`(`phone_number`) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DELIMITER //

-- Instagram triggers
-- Triggers for post counts
CREATE TRIGGER IF NOT EXISTS phone_instagram_increment_post_count
AFTER INSERT ON phone_instagram_posts
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET post_count = post_count + 1
    WHERE username = NEW.username;
END //

CREATE TRIGGER IF NOT EXISTS phone_instagram_decrement_post_count
AFTER DELETE ON phone_instagram_posts
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET post_count = post_count - 1
    WHERE username = OLD.username;
END //

-- Trigger for story counts
CREATE TRIGGER IF NOT EXISTS phone_instagram_increment_story_count
AFTER INSERT ON phone_instagram_stories
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET story_count = story_count + 1
    WHERE username = NEW.username;
END //

CREATE TRIGGER IF NOT EXISTS phone_instagram_decrement_story_count
AFTER DELETE ON phone_instagram_stories
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET story_count = story_count - 1
    WHERE username = OLD.username;
END //

-- Trigger for comment counts
CREATE TRIGGER IF NOT EXISTS phone_instagram_increment_comment_count
AFTER INSERT ON phone_instagram_comments
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.post_id;
END //

CREATE TRIGGER IF NOT EXISTS phone_instagram_decrement_comment_count
AFTER DELETE ON phone_instagram_comments
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_posts
    SET comment_count = comment_count - 1
    WHERE id = OLD.post_id;
END //

-- Trigger for like counts
CREATE TRIGGER IF NOT EXISTS phone_instagram_increment_like_count
AFTER INSERT ON phone_instagram_likes
FOR EACH ROW
BEGIN
    IF NEW.is_comment = 0 THEN
        UPDATE phone_instagram_posts
        SET like_count = like_count + 1
        WHERE id = NEW.id;
    ELSE
        UPDATE phone_instagram_comments
        SET like_count = like_count + 1
        WHERE id = NEW.id;
    END IF;
END //

CREATE TRIGGER IF NOT EXISTS phone_instagram_decrement_like_count
AFTER DELETE ON phone_instagram_likes
FOR EACH ROW
BEGIN
    IF OLD.is_comment = 0 THEN
        UPDATE phone_instagram_posts
        SET like_count = like_count - 1
        WHERE id = OLD.id;
    ELSE
        UPDATE phone_instagram_comments
        SET like_count = like_count - 1
        WHERE id = OLD.id;
    END IF;
END //

-- Triggers for follower counts
CREATE TRIGGER IF NOT EXISTS phone_instagram_update_counts_after_follow
AFTER INSERT ON phone_instagram_follows
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    UPDATE phone_instagram_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END //

CREATE TRIGGER IF NOT EXISTS phone_instagram_update_counts_after_unfollow
AFTER DELETE ON phone_instagram_follows
FOR EACH ROW
BEGIN
    UPDATE phone_instagram_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    UPDATE phone_instagram_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END //

-- Triggers for phone_twitter_follows
CREATE TRIGGER IF NOT EXISTS phone_twitter_update_counts_after_follow
AFTER INSERT ON phone_twitter_follows
FOR EACH ROW
BEGIN
    -- Increment the follower_count for the followed user
    UPDATE phone_twitter_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    -- Increment the following_count for the follower user
    UPDATE phone_twitter_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END //

CREATE TRIGGER IF NOT EXISTS phone_twitter_update_counts_after_unfollow
AFTER DELETE ON phone_twitter_follows
FOR EACH ROW
BEGIN
    -- Decrement the follower_count for the followed user
    UPDATE phone_twitter_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    -- Decrement the following_count for the follower user
    UPDATE phone_twitter_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END //

CREATE TRIGGER IF NOT EXISTS phone_twitter_update_like_count_after_like
AFTER INSERT ON phone_twitter_likes
FOR EACH ROW
BEGIN
    UPDATE phone_twitter_tweets
    SET like_count = like_count + 1
    WHERE id = NEW.tweet_id;
END //

CREATE TRIGGER IF NOT EXISTS phone_twitter_update_like_count_after_unlike
AFTER DELETE ON phone_twitter_likes
FOR EACH ROW
BEGIN
    UPDATE phone_twitter_tweets
    SET like_count = like_count - 1
    WHERE id = OLD.tweet_id;
END //

CREATE TRIGGER IF NOT EXISTS phone_twitter_update_retweet_count_after_retweet
AFTER INSERT ON phone_twitter_retweets
FOR EACH ROW
BEGIN
    UPDATE phone_twitter_tweets
    SET retweet_count = retweet_count + 1
    WHERE id = NEW.tweet_id;
END //

CREATE TRIGGER IF NOT EXISTS phone_twitter_update_retweet_count_after_unretweet
AFTER DELETE ON phone_twitter_retweets
FOR EACH ROW
BEGIN
    UPDATE phone_twitter_tweets
    SET retweet_count = retweet_count - 1
    WHERE id = OLD.tweet_id;
END //

-- Triggers for phone_tiktok_follows
-- Increment phone_tiktok_accounts.follower_count and phone_tiktok_accounts.following_count after inserting a new row into phone_tiktok_follows
CREATE TRIGGER IF NOT EXISTS phone_tiktok_update_counts_after_follow
AFTER INSERT ON phone_tiktok_follows
FOR EACH ROW
BEGIN
    -- Increment the follower_count for the followed user
    UPDATE phone_tiktok_accounts
    SET follower_count = follower_count + 1
    WHERE username = NEW.followed;

    -- Increment the following_count for the follower user
    UPDATE phone_tiktok_accounts
    SET following_count = following_count + 1
    WHERE username = NEW.follower;
END //

-- Decrement phone_tiktok_accounts.follower_count and phone_tiktok_accounts.following_count after deleting a row from phone_tiktok_follows
CREATE TRIGGER IF NOT EXISTS phone_tiktok_update_counts_after_unfollow
AFTER DELETE ON phone_tiktok_follows
FOR EACH ROW
BEGIN
    -- Decrement the follower_count for the followed user
    UPDATE phone_tiktok_accounts
    SET follower_count = follower_count - 1
    WHERE username = OLD.followed;

    -- Decrement the following_count for the follower user
    UPDATE phone_tiktok_accounts
    SET following_count = following_count - 1
    WHERE username = OLD.follower;
END //

-- Trigger for phone_tiktok_videos
-- Trigger to increment phone_tiktok_accounts.video_count after inserting a new row into phone_tiktok_videos
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_video_count
AFTER INSERT ON phone_tiktok_videos
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_accounts
    SET video_count = video_count + 1
    WHERE username = NEW.username;
END //

-- Trigger for phone_tiktok_likes
-- Trigger to increment phone_tiktok_videos.likes after inserting a new row into phone_tiktok_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_video_likes
AFTER INSERT ON phone_tiktok_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET likes = likes + 1
    WHERE id = NEW.video_id;
END //

-- Trigger to decrement phone_tiktok_videos.likes after deleting a row from phone_tiktok_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_decrement_video_likes
AFTER DELETE ON phone_tiktok_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET likes = likes - 1
    WHERE id = OLD.video_id;
END //

-- Trigger to increment phone_tiktok_accounts.like_count for the user after a new like is inserted into phone_tiktok_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_account_likes
AFTER INSERT ON phone_tiktok_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_accounts
    JOIN phone_tiktok_videos ON phone_tiktok_videos.username = phone_tiktok_accounts.username
    SET phone_tiktok_accounts.like_count = phone_tiktok_accounts.like_count + 1
    WHERE phone_tiktok_videos.id = NEW.video_id;
END //

-- Trigger to decrement phone_tiktok_accounts.like_count for the user after a like is removed from phone_tiktok_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_decrement_account_likes
AFTER DELETE ON phone_tiktok_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_accounts
    JOIN phone_tiktok_videos ON phone_tiktok_videos.username = phone_tiktok_accounts.username
    SET phone_tiktok_accounts.like_count = phone_tiktok_accounts.like_count - 1
    WHERE phone_tiktok_videos.id = OLD.video_id;
END //

-- Triggers for phone_tiktok_views
-- Trigger to increment phone_tiktok_videos.views when a new view is inserted into phone_tiktok_views
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_video_views
AFTER INSERT ON phone_tiktok_views
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET views = views + 1
    WHERE id = NEW.video_id;
END //

-- Triggers for phone_tiktok_saves
-- Increment saves after inserting a new row into phone_tiktok_saves
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_video_saves
AFTER INSERT ON phone_tiktok_saves
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET saves = saves + 1
    WHERE id = NEW.video_id;
END //

-- Decrement saves after deleting a row from phone_tiktok_saves
CREATE TRIGGER IF NOT EXISTS phone_tiktok_decrement_video_saves
AFTER DELETE ON phone_tiktok_saves
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET saves = saves - 1
    WHERE id = OLD.video_id;
END //

-- Triggers for phone_tiktok_comments
-- Increment phone_tiktok_videos.comments after inserting a new row into phone_tiktok_comments
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_video_comments
AFTER INSERT ON phone_tiktok_comments
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_videos
    SET comments = comments + 1
    WHERE id = NEW.video_id;
END //

-- Decrement phone_tiktok_videos.comments after deleting a row from phone_tiktok_comments
CREATE TRIGGER IF NOT EXISTS phone_tiktok_decrement_video_comments
BEFORE DELETE ON phone_tiktok_comments
FOR EACH ROW
BEGIN
    DECLARE v_replies_count INT;

    -- Count the replies for the comment
    SELECT COUNT(*) INTO v_replies_count
    FROM phone_tiktok_comments
    WHERE reply_to = OLD.id;

    -- Update the video's comments count
    UPDATE phone_tiktok_videos
    SET comments = comments - (1 + v_replies_count)
    WHERE id = OLD.video_id;
END //

-- Triggers for phone_tiktok_comments_likes
-- Increment phone_tiktok_comments.likes after inserting a new row into phone_tiktok_comments_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_increment_comment_likes
AFTER INSERT ON phone_tiktok_comments_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_comments
    SET likes = likes + 1
    WHERE id = NEW.comment_id;
END //

-- Decrement phone_tiktok_comments.likes after deleting a row from phone_tiktok_comments_likes
CREATE TRIGGER IF NOT EXISTS phone_tiktok_decrement_comment_likes
AFTER DELETE ON phone_tiktok_comments_likes
FOR EACH ROW
BEGIN
    UPDATE phone_tiktok_comments
    SET likes = likes - 1
    WHERE id = OLD.comment_id;
END //

-- Triggers for phone_tiktok_messages
-- Trigger to update phone_tiktok_channels.last_message after a new message is inserted into phone_tiktok_messages
CREATE TRIGGER IF NOT EXISTS phone_tiktok_update_last_message
AFTER INSERT ON phone_tiktok_messages
FOR EACH ROW
BEGIN
    DECLARE modified_content TEXT CHARACTER SET utf8mb4;

    IF NEW.content LIKE '<!SHARED-VIDEO-URL%' THEN
        SET modified_content = 'Shared a video';
    ELSEIF LENGTH(NEW.content) > 50 THEN
        SET modified_content = CONCAT(SUBSTR(NEW.content, 1, 17), '...');
    ELSE
        SET modified_content = NEW.content;
    END IF;

    UPDATE phone_tiktok_channels
    SET last_message = modified_content
    WHERE id = NEW.channel_id;
END //

DELIMITER ;

-- fd_banking: como [standalone]/fd_banking/fd_banking.sql, pero sin borrar lo que ya exista
CREATE TABLE IF NOT EXISTS `fd_advanced_banking_accounts` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `iban` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `balance` bigint(255) NOT NULL,
  `type` char(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'personal',
  `is_frozen` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `business` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_society` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fd_advanced_banking_accounts_id_unique` (`id`) USING BTREE,
  UNIQUE KEY `fd_advanced_banking_accounts_iban_unique` (`iban`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `fd_advanced_banking_accounts_members` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(20) unsigned NOT NULL,
  `identifier` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `member_name` varchar(255) DEFAULT NULL,
  `can_deposit` tinyint(4) NOT NULL DEFAULT 0,
  `can_withdraw` tinyint(4) NOT NULL DEFAULT 0,
  `can_transfer` tinyint(4) NOT NULL DEFAULT 0,
  `can_export` tinyint(4) NOT NULL DEFAULT 0,
  `can_control_members` tinyint(4) NOT NULL DEFAULT 0,
  `is_owner` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `fd_advanced_banking_accounts_members_id_unique` (`id`) USING BTREE,
  KEY `fd_advanced_banking_accounts_members_account_id_index` (`account_id`) USING BTREE,
  CONSTRAINT `fk_fd_accounts_members` FOREIGN KEY (`account_id`) REFERENCES `fd_advanced_banking_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `fd_advanced_banking_accounts_transactions` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(20) unsigned NOT NULL,
  `action` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `done_by` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `from_account` varchar(100) DEFAULT NULL,
  `to_account` varchar(100) DEFAULT NULL,
  `amount` bigint(255) NOT NULL DEFAULT 0,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `fd_advanced_banking_accounts_transactions_id_unique` (`id`) USING BTREE,
  KEY `fd_advanced_banking_accounts_transactions_account_id_index` (`account_id`) USING BTREE,
  CONSTRAINT `fk_fd_accounts_transactions` FOREIGN KEY (`account_id`) REFERENCES `fd_advanced_banking_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `fd_advanced_banking_invoices` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `recipient` varchar(75) NOT NULL,
  `issued_by` varchar(75) NOT NULL,
  `status` tinyint(2) NOT NULL DEFAULT 1,
  `amount` int(20) unsigned NOT NULL DEFAULT 0,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `transfer_to` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `due_on` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `can_be_declined` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS `fd_advanced_banking_migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

INSERT IGNORE INTO `fd_advanced_banking_migrations` (`id`, `name`) VALUES
	(1, 'fd_advanced_banking_accounts'),
	(2, 'fd_advanced_banking_accounts_members'),
	(3, 'fd_advanced_banking_accounts_transactions'),
	(4, 'fd_advanced_banking_tracking'),
	(5, 'fd_advanced_banking_accounts_update_1'),
	(6, 'fd_advanced_banking_accounts_update_2'),
	(7, 'fd_advanced_banking_invoices'),
	(8, 'fd_advanced_banking_invoices_update'),
    (9, 'fd_banking_change_from_account_type'),
    (10, 'fd_banking_change_to_account_type'),
    (11, 'fd_advanced_banking_accounts_members_add_name');

CREATE TABLE IF NOT EXISTS `fd_advanced_banking_tracking` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- jj_creatorjobs: trabajos creados en marcha
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

-- Rangos/grades de cada trabajo (id = nivel del rango, empieza en 0 como QBCore)
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

-- jj_bizztablet: fichas de los negocios y eventos de la tablet
CREATE TABLE IF NOT EXISTS `jj_bizztablet_businesses` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_bizztablet_events` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_pausemenu: anuncios del menú de pausa
CREATE TABLE IF NOT EXISTS `jj_pausemenu_announcements` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `message` VARCHAR(300) NOT NULL,
    `author` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_policetablet: expedientes, multas, informes y código penal
CREATE TABLE IF NOT EXISTS `jj_policetablet_ranks` (
    `grade` INT NOT NULL,
    `permissions` LONGTEXT NOT NULL,
    PRIMARY KEY (`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_agents` (
    `citizenid` VARCHAR(60) NOT NULL,
    `badge_number` VARCHAR(10) DEFAULT NULL,
    `department` VARCHAR(20) NOT NULL DEFAULT 'lspd',
    `divisions` LONGTEXT DEFAULT NULL,
    `duty_seconds` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_infractions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(60) NOT NULL,
    `title` VARCHAR(120) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `author` VARCHAR(100) DEFAULT NULL,
    `date` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `jj_policetablet_infractions_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_citizens` (
    `citizenid` VARCHAR(60) NOT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `wanted` TINYINT(1) NOT NULL DEFAULT 0,
    `dangerous` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_notes` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_bills` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_vehicles` (
    `plate` VARCHAR(12) NOT NULL,
    `image` VARCHAR(500) DEFAULT NULL,
    `wanted` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_cases` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_announces` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `text` LONGTEXT NOT NULL,
    `pinned` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_chapters` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(120) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_penalcodes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `chapter_id` INT DEFAULT NULL,
    `id_article` VARCHAR(20) NOT NULL,
    `article` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `fine` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_templates` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `scope` VARCHAR(40) NOT NULL DEFAULT 'global',
    `name` VARCHAR(120) NOT NULL,
    `content` LONGTEXT NOT NULL,
    `created_at` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jj_policetablet_jail` (
    `citizenid` VARCHAR(60) NOT NULL,
    `minutes` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- jj_boosting: contratos de robo de vehículos, progresión, criptomoneda y tienda
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

-- ox_doorlock: puertas
CREATE TABLE
    IF NOT EXISTS `ox_doorlock` (
        `id` int (11) unsigned NOT NULL AUTO_INCREMENT,
        `name` varchar(50) NOT NULL,
        `data` longtext NOT NULL,
        PRIMARY KEY (`id`)
    );
