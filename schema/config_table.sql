CREATE TABLE config_options (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
     `data_struct` VARCHAR(48) NOT NULL,
     `serialized`  TEXT,
     UNIQUE `idx_data_struct` (`data_struct`)
) TYPE=innodb;
