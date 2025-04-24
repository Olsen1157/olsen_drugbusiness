CREATE TABLE `druglabs` (
	`user_id` VARCHAR(40) NOT NULL COLLATE 'latin1_swedish_ci',
	`labID` INT(11) NOT NULL,
	`supplies` INT(11) NOT NULL DEFAULT '0',
	`stock` INT(11) NOT NULL DEFAULT '0',
	PRIMARY KEY (`labID`, `user_id`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;
