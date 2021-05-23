-- -----------------------------------------------------
-- Database theater
-- -----------------------------------------------------

DROP DATABASE IF EXISTS `theater`;
CREATE DATABASE IF NOT EXISTS `theater`;
USE `theater` ;

-- -----------------------------------------------------
-- Table `halls`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `halls` ;

CREATE TABLE IF NOT EXISTS `halls` (
  `hallId` INT NOT NULL AUTO_INCREMENT,
  `hallName` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`hallId`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `shows`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `shows` ;

CREATE TABLE IF NOT EXISTS `shows` (
  `showId` INT NOT NULL AUTO_INCREMENT,
  `showName` VARCHAR(70) NOT NULL,
  `showDate` DATE NOT NULL,
  `beginning` TIME NOT NULL,
  `ending` TIME NOT NULL,
  `author` VARCHAR(70) NOT NULL,
  `director` VARCHAR(70) NOT NULL,
  `breaks` TINYINT NOT NULL,
  `hallId` INT NOT NULL,
  PRIMARY KEY (`showId`),
  INDEX `fk_shows_halls1_idx` (`hallId` ASC),
  CONSTRAINT `fk_shows_halls1`
    FOREIGN KEY (`hallId`)
    REFERENCES `halls` (`hallId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `seatRows`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `seatRows` ;

CREATE TABLE IF NOT EXISTS `seatRows` (
  `rowId` INT NOT NULL AUTO_INCREMENT,
  `rowNumber` TINYINT NOT NULL,
  `seatsCount` TINYINT NOT NULL,
  `seatPrice` DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (`rowId`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `seats`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `seats` ;

CREATE TABLE IF NOT EXISTS `seats` (
  `seatId` INT NOT NULL AUTO_INCREMENT,
  `seatNumber` TINYINT UNSIGNED NOT NULL,
  `rowId` INT NOT NULL,
  `hallId` INT NOT NULL,
  PRIMARY KEY (`seatId`),
  INDEX `fk_seats_halls1_idx` (`hallId` ASC),
  INDEX `fk_seats_seatRows1_idx` (`rowId` ASC),
  CONSTRAINT `fk_seats_halls1`
    FOREIGN KEY (`hallId`)
    REFERENCES `halls` (`hallId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_seats_seatRows1`
    FOREIGN KEY (`rowId`)
    REFERENCES `seatRows` (`rowId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `clients`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `clients` ;

CREATE TABLE IF NOT EXISTS `clients` (
  `clientId` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL,
  `surname` VARCHAR(30) NOT NULL,
  `age` TINYINT UNSIGNED NOT NULL,
  `email` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`clientId`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `tickets`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `tickets` ;

CREATE TABLE IF NOT EXISTS `tickets` (
  `ticketId` INT NOT NULL AUTO_INCREMENT,
  `seatId` INT NOT NULL,
  `showId` INT NOT NULL,
  `clientId` INT NOT NULL,
  PRIMARY KEY (`ticketId`),
  INDEX `fk_tickets_shows1_idx` (`showId` ASC),
  INDEX `fk_tickets_seats1_idx` (`seatId` ASC),
  INDEX `fk_tickets_clients1_idx` (`clientId` ASC),
  CONSTRAINT `fk_tickets_shows1`
    FOREIGN KEY (`showId`)
    REFERENCES `shows` (`showId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_tickets_seats1`
    FOREIGN KEY (`seatId`)
    REFERENCES `seats` (`seatId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_tickets_clients1`
    FOREIGN KEY (`clientId`)
    REFERENCES `clients` (`clientId`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `logs`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `logs` ;

CREATE TABLE IF NOT EXISTS `logs` (
  `logId` INT NOT NULL AUTO_INCREMENT,
  `action` TEXT NOT NULL,
  `actionTime` DATETIME NOT NULL,
  PRIMARY KEY (`logId`))
ENGINE = InnoDB;

USE `theater` ;

-- -----------------------------------------------------
-- procedure ticketsForShow
-- -----------------------------------------------------

USE `theater`;
DROP procedure IF EXISTS `ticketsForShow`;

DELIMITER $$
USE `theater`$$
CREATE PROCEDURE ticketsForShow(
	IN showName VARCHAR(70),
    IN showDate DATE)

BEGIN

	DROP TEMPORARY TABLE IF EXISTS ticketsForShow;

	-- copy data from tables (shows, seatRows, seats, halls, tickets)
	CREATE TEMPORARY TABLE ticketsForShow(
	-- get only those tickets that are assigned to given show
    SELECT
        t.ticketId AS tID,
        sh.showName AS show_name,
        sh.showDate AS show_date,
        sh.beginning AS beginning,
        sh.ending AS ending,
        h.hallName AS hall_name,
        CONCAT(c.name, ' ', c.surname) AS client_credentials,
        s.seatNumber AS seat_nr,
        sr.rowNumber AS rows_number,
        sr.seatPrice AS seat_price
    FROM
        tickets AS t
    NATURAL JOIN
        shows AS sh
    NATURAL JOIN
        halls AS h
    NATURAL JOIN
        clients AS c
    NATURAL JOIN
        seats AS s
    NATURAL JOIN
        seatRows AS sr
	WHERE
        t.showId IN(
		    SELECT
                sh.showId
            FROM
                shows AS sh
		    WHERE
                sh.showName = showName
                AND sh.showDate = showDate
        )
	);
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure addClient
-- -----------------------------------------------------

USE `theater`;
DROP procedure IF EXISTS `addClient`;

DELIMITER $$
USE `theater`$$
CREATE PROCEDURE addClient(
	IN cName VARCHAR(20),
    IN cSurname VARCHAR(30),
    IN cAge TINYINT,
    IN cEmail VARCHAR(40))
    
BEGIN
    -- add a new row with given values
    INSERT INTO clients(name, surname, age, email)
    VALUES(
        cName, cSurname, cAge, cEmail
    );
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure addTicket
-- -----------------------------------------------------

USE `theater`;
DROP procedure IF EXISTS `addTicket`;

DELIMITER $$
USE `theater`$$
CREATE PROCEDURE addTicket(
	IN client_name VARCHAR(20),
    IN client_surname VARCHAR(30),
    IN client_email VARCHAR(40),
    IN show_name VARCHAR(70),
    IN show_date DATE,
    IN seat_number TINYINT)
    
BEGIN
    -- search for a client
    SELECT
        c.clientId INTO @cId
    FROM
        clients AS c
    WHERE
        c.name = client_name
		AND c.surname = client_surname
		AND c.email = client_email;
    
    -- search for a show
    SELECT
        sh.showId INTO @shId
    FROM
        shows AS sh
    WHERE
        sh.showName = show_name
		AND sh.showDate = show_date;
        
    -- search for a seat
    SELECT
        s.seatId INTO @sId
    FROM
        seats AS s
    NATURAL JOIN
        halls AS h
    NATURAL JOIN
        shows AS sh
    NATURAL JOIN
        seatRows AS sr
    WHERE
        sh.showId = @shId
        AND h.hallId = sh.hallId
        AND s.seatNumber = seat_number;
    
    
    -- add a new row based on searched values
    INSERT INTO tickets(clientId, showId, seatId)
    VALUES(
        @cId, @shId, @sId);
END$$

DELIMITER ;

-- -----------------------------------------------------
-- tickets before insert
-- -----------------------------------------------------

USE `theater`;

DELIMITER $$

USE `theater`$$
DROP TRIGGER IF EXISTS `tickets_BEFORE_INSERT` $$
USE `theater`$$
CREATE DEFINER = CURRENT_USER TRIGGER `tickets_BEFORE_INSERT` BEFORE INSERT ON `tickets` FOR EACH ROW
BEGIN

    INSERT INTO `logs`(`action`, `actionTime`)
    VALUES(
	    'Attempt to add new ticket.', now());

    -- seat occupancy check
    IF (NEW.showID, NEW.seatId) IN(
        SELECT
            t.showID, t.seatId
        FROM
            tickets AS t
    )
    THEN
        -- logs update
        INSERT INTO `logs`(`action`, `actionTime`)
        VALUES(
	        'Ticket addition failed due to seat occupancy error.', now());
        
        -- error message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Seat with given id is already occupied.';
    END IF;

END$$

-- -----------------------------------------------------
-- tickets after insert
-- -----------------------------------------------------

USE `theater`$$
DROP TRIGGER IF EXISTS `tickets_AFTER_INSERT` $$
USE `theater`$$
CREATE DEFINER = CURRENT_USER TRIGGER `tickets_AFTER_INSERT` AFTER INSERT ON `tickets` FOR EACH ROW
BEGIN

	INSERT INTO `logs`(`action`, `actionTime`)
	VALUES(
		'New ticket added.', now());

END$$


DELIMITER ;

-- -----------------------------------------------------
-- Data for table `halls`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `halls` (`hallName`) VALUES ('Terpsychora');
INSERT INTO `halls` (`hallName`) VALUES ('Polichymnia');
INSERT INTO `halls` (`hallName`) VALUES ('Euterpe');

COMMIT;


-- -----------------------------------------------------
-- Data for table `shows`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `shows` (`showName`, `showDate`, `beginning`, `ending`, `author`, `director`, `breaks`, `hallId`) VALUES ('Krolowa Margot', '2021-07-21', '18:00', '21:00', 'Aleksader Dumas', 'Jan Englert', 1, 1);
INSERT INTO `shows` (`showName`, `showDate`, `beginning`, `ending`, `author`, `director`, `breaks`, `hallId`) VALUES ('Dziady', '2021-07-25', '16:00', '20:15', 'Adam Mickiewicz', 'Wojciech Faruga', 2, 2);
INSERT INTO `shows` (`showName`, `showDate`, `beginning`, `ending`, `author`, `director`, `breaks`, `hallId`) VALUES ('Romeo i Julia', '2021-07-15', '18:15', '20:30', 'William Shakespeare', 'Piotr Cieplak', 1, 3);
INSERT INTO `shows` (`showName`, `showDate`, `beginning`, `ending`, `author`, `director`, `breaks`, `hallId`) VALUES ('Romeo i Julia', '2021-03-12', '16:15', '18:30', 'William Shakespeare', 'Piotr Cieplak', 1, 3);

COMMIT;


-- -----------------------------------------------------
-- Data for table `seatRows`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (1, 6, 100.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (2, 6, 80.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (3, 6, 60.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (1, 4, 120.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (2, 4, 100.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (3, 4, 80.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (1, 2, 150.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (2, 2, 130.00);
INSERT INTO `seatRows` (`rowNumber`, `seatsCount`, `seatPrice`) VALUES (3, 2, 110.00);

COMMIT;


-- -----------------------------------------------------
-- Data for table `seats`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (1, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (2, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (3, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (4, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (5, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (6, 1, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (7, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (8, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (9, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (10, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (11, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (12, 2, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (13, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (14, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (15, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (16, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (17, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (18, 3, 1);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (1, 4, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (2, 4, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (3, 4, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (4, 4, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (5, 5, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (6, 5, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (7, 5, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (8, 5, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (9, 6, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (10, 6, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (11, 6, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (12, 6, 2);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (1, 7, 3);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (2, 7, 3);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (3, 8, 3);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (4, 8, 3);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (5, 9, 3);
INSERT INTO `seats` (`seatNumber`, `rowId`, `hallId`) VALUES (6, 9, 3);

COMMIT;


-- -----------------------------------------------------
-- Data for table `clients`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Dominika', 'Domyslna', 18, 'domi123@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Karol', 'Kulturalny', 32, 'karollo@o2.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Bartlomiej', 'Bezgrosza', 28, 'bartolomeo@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Malgorzata', 'Mala', 15, 'margo123@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Piotr', 'Pewnysiebie', 16, 'pewniaczek@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Sylwia', 'Samolubna', 21, 'nielubienikogo@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Nikodem', 'Niewychowany', 17, 'wychowywalemSieSam@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Krystian', 'Krzykliwy', 18, 'ciszajestpasse@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Mieszko', 'Malomowny', 45, 'mieszkomieszkomojkolezko@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Sebastian', 'Stary', 60, 'mamswojelata@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Kinga', 'Klotliwa', 18, 'niezgodabudujezgodarujnuje@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Lucjan', 'Lojalny', 28, 'luc3k@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Pawel', 'Prostacki', 29, 'PROSTO@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Krzysztof', 'Konkurencyjny', 37, 'rywalizacja@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Anna', 'Awangardowa', 30, 'AnnA@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Radoslaw', 'Rewolucyjny', 28, 'RadoslawRew@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Marek', 'Mocny', 15, 'mareczek@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Damian', 'Dobroczynny', 21, 'DamianDobroczynny@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Barbara', 'Bekowa', 25, 'basiab@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Zbigniew', 'Zawodny', 45, 'basiab@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Henryk', 'Historyczny', 60, 'basiab@gmail.com');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Genowefa', 'Garnizonowa', 25, 'gienia@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Czeslaw', 'Czepialski', 30, 'czCZ@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Dobromir', 'Dobry', 35, 'DobrDobr@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Ernest', 'Elokwentny', 40, 'Ernest2468@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Felicja', 'Fikusna', 20, 'FelaF@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Grzymislawa', 'Gornolotna', 22, 'GrzesiaPiast@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Iga', 'Irytujaca', 32, 'Iga123456@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Julian', 'Jurny', 42, 'JJurny@wp.pl');
INSERT INTO `clients` (`name`, `surname`, `age`, `email`) VALUES ('Onufry', 'Okragly', 51, 'OO@o2.pl');

COMMIT;

-- -----------------------------------------------------
-- Data for table `tickets`
-- -----------------------------------------------------
START TRANSACTION;
USE `theater`;
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (1, 1, 1);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (2, 2, 19);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (3, 2, 20);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (4, 1, 2);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (5, 3, 31);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (6, 3, 35);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (7, 1, 3);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (8, 4, 31);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (9, 4, 35);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (10, 4, 32);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (11, 1, 7);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (12, 1, 9);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (13, 1, 12);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (14, 1, 14);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (15, 1, 17);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (16, 1, 18);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (17, 2, 28);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (18, 2, 25);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (19, 2, 22);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (20, 2, 30);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (21, 1, 4);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (22, 1, 11);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (23, 1, 13);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (24, 1, 15);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (2, 1, 5);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (26, 2, 21);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (27, 2, 23);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (28, 2, 24);
INSERT INTO `tickets` (`clientId`, `showId`, `seatId`) VALUES (1, 3, 36);

COMMIT;

-- procedures call
USE `theater`;
CALL addClient('Tadeusz', 'Towarzyski', 35, 'PanTT@wp.pl');
CALL addTicket('Tadeusz', 'Towarzyski', 'PanTT@wp.pl', 'Krolowa Margot', '2021-07-21', 10);
CALL ticketsForShow('Dziady', '2021-07-25');

-- all tickets for a given show
USE `theater`;
SELECT * FROM ticketsForShow;

-- queries
USE `theater`;
-- current shows with hallname and seats count (natural join, count, group by)
SELECT 
    sh.showName AS show_name,
    sh.showDate AS show_date,
    h.hallname AS hall_name,
    COUNT(*) AS seat_count
FROM
    shows AS sh
NATURAL JOIN
    halls AS h
NATURAL JOIN
    seats AS s
WHERE
    sh.showDate > now()
GROUP BY
    sh.showName, sh.showDate, h.hallname
ORDER BY
    seat_count;

-- all seats with their price and row (where)
SELECT
    s.seatNumber AS seat_nr,
    sr.rowNumber AS row_nr,
    sr.seatPrice AS seat_price,
    h.hallName AS hall_name
FROM
    seats AS s,
    seatRows AS sr,
    halls AS h
WHERE
    s.rowId=sr.rowId
    AND s.hallId=h.hallId;

-- all tickets with proper info (inner join)
SELECT
    CONCAT(c.name, ' ', c.surname) AS client_credentials,
    sh.showName AS show_name,
    sh.showDate AS show_date,
    sh.beginning AS beginning,
    sh.ending AS ending,
    sh.breaks AS breaks,
    s.seatNumber AS seat_number,
    sr.rowNumber AS rows_number
FROM
    tickets AS t
INNER JOIN
    clients AS c
    USING(clientId)
INNER JOIN
    shows AS sh
    USING(showId)
INNER JOIN
    seats AS s
    USING(seatId)
INNER JOIN
    seatRows AS sr
    USING(rowId)
WHERE
    sh.showDate > now();


-- all seats with their occupancy (right outer join)
SELECT
    s.seatNumber AS seat_nr,
    sr.rowNumber AS row_nr,
    h.hallName AS hall_name,
    t.ticketId AS assigned_ticket_id
FROM
    tickets AS t
RIGHT OUTER JOIN
    seats AS s
    USING(seatId)
LEFT OUTER JOIN
    seatRows AS sr
    USING(rowId)
LEFT OUTER JOIN
    halls AS h
    USING(hallId)
LEFT OUTER JOIN
    shows AS sh
    USING(showID)
WHERE
    sh.showDate > now()
    OR t.ticketId IS NULL;

-- all shows with all tickets count (all time) (left outer join)
SELECT
    sh.showName AS show_name,
    COUNT(*) AS tickets_bought
FROM
    shows AS sh
LEFT OUTER JOIN
    tickets AS t
    ON sh.showId = t.showId
LEFT OUTER JOIN
    clients AS c
    ON c.clientId = t.clientId
GROUP BY
    show_name;

-- all clients with number of tickets bought (group by + count)
SELECT
    COUNT(*) AS all_tickets_count,
    CONCAT(c.name, ' ', c.surname) AS client_credentials
FROM
    tickets
NATURAL JOIN
    clients AS c
GROUP BY
    client_credentials
ORDER BY
    all_tickets_count DESC;

-- underaged count (having + count)
SELECT
    COUNT(*) AS people_amount,
    c.age AS age
FROM
    clients AS c
GROUP BY
    age
HAVING
    age <= 18;

-- clients ordered by money spent (order by + sum)
SELECT
    SUM(sr.seatPrice) AS money_spent,
    CONCAT(c.name, ' ', c.surname) AS client_credentials
FROM
    tickets
NATURAL JOIN
    clients AS c
NATURAL JOIN
    seats
NATURAL JOIN
    seatRows AS sr
GROUP BY
    client_credentials
ORDER BY
    money_spent DESC;

-- shows that generated income (100, 1000) (between + sum)
SELECT
    SUM(sr.seatPrice) AS income,
    sh.showName AS show_name
FROM
    tickets
NATURAL JOIN
    shows AS sh
NATURAL JOIN
    seats AS s
NATURAL JOIN
    seatRows AS sr
GROUP BY
    show_name
HAVING
    income BETWEEN 100 AND 10000
ORDER BY
    income DESC;

-- clients using wp.pl email (like + count)
SELECT
    COUNT(*) AS people_amount,
    SUBSTRING_INDEX(c.email, '@', -1) AS email_address
FROM
    clients AS c
GROUP BY
    email_address
HAVING
    email_address LIKE '%wp.pl';