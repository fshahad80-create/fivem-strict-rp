-- fivem-strict-rp :: database.sql
-- جداول كل الأنظمة (تُنشأ تلقائياً عند التشغيل، لكن يمكن تنفيذها يدوياً).

-- النظام 1: العقوبات
CREATE TABLE IF NOT EXISTS `srp_penalty_points` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `points` INT NOT NULL DEFAULT 0,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_criminal_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `offense` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `points` INT NOT NULL,
    `fine` INT NOT NULL,
    `jail` INT NOT NULL,
    `officer` VARCHAR(50) DEFAULT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_cid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_wanted` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `level` INT NOT NULL DEFAULT 1,
    `offenses` TEXT DEFAULT NULL,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- النظام 2: الاقتصاد
CREATE TABLE IF NOT EXISTS `srp_salary_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `job` VARCHAR(32) NOT NULL,
    `grade` INT NOT NULL,
    `gross` INT NOT NULL,
    `tax` INT NOT NULL,
    `net` INT NOT NULL,
    `bonus` INT NOT NULL DEFAULT 0,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_cid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_bills` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` VARCHAR(32) NOT NULL,
    `label` VARCHAR(64) NOT NULL,
    `amount` INT NOT NULL,
    `status` ENUM('unpaid','paid','overdue') NOT NULL DEFAULT 'unpaid',
    `due_at` INT NOT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_cid` (`citizenid`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_inflation` (
    `id` INT NOT NULL PRIMARY KEY DEFAULT 1,
    `index_value` DECIMAL(6,4) NOT NULL DEFAULT 1.0000,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_insurance` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `premium` INT NOT NULL DEFAULT 0,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `paid_until` INT NOT NULL DEFAULT 0,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- النظام 3: الاحتياجات والطقس
CREATE TABLE IF NOT EXISTS `srp_needs` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `hunger` INT NOT NULL DEFAULT 100,
    `thirst` INT NOT NULL DEFAULT 100,
    `energy` INT NOT NULL DEFAULT 100,
    `hygiene` INT NOT NULL DEFAULT 100,
    `health` INT NOT NULL DEFAULT 100,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_weather_state` (
    `id` INT NOT NULL PRIMARY KEY DEFAULT 1,
    `weather` VARCHAR(24) NOT NULL DEFAULT 'CLEAR',
    `hour` INT NOT NULL DEFAULT 12,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- النظام 4: القوانين والإشراف
CREATE TABLE IF NOT EXISTS `srp_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reporter` VARCHAR(50) NOT NULL,
    `reporter_name` VARCHAR(64) NOT NULL,
    `target` VARCHAR(50) DEFAULT NULL,
    `target_name` VARCHAR(64) DEFAULT NULL,
    `category` VARCHAR(32) NOT NULL,
    `message` TEXT NOT NULL,
    `status` ENUM('open','handled','dismissed') NOT NULL DEFAULT 'open',
    `handled_by` VARCHAR(50) DEFAULT NULL,
    `handled_note` TEXT DEFAULT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_staff_log` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `staff` VARCHAR(50) NOT NULL,
    `target` VARCHAR(50) NOT NULL,
    `action` VARCHAR(24) NOT NULL,
    `rule` VARCHAR(32) DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `points` INT NOT NULL DEFAULT 0,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_target` (`target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `srp_staff_points` (
    `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
    `points` INT NOT NULL DEFAULT 0,
    `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
