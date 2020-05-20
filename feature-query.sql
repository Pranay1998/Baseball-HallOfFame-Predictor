use lahman2016;

CREATE TABLE unique_players 
(SELECT distinct playerID
From HallOfFame
WHERE category = 'player' AND needed > 0
GROUP BY playerID
);

CREATE TABLE classification_table (playerID varchar(10), classification varchar(1));

DELIMITER //
CREATE PROCEDURE InsertValues()
BEGIN
DECLARE n INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
SELECT COUNT(*) FROM unique_players INTO n;
SET i=0;
WHILE i<n DO 
	SET @id = (SELECT playerID FROM unique_players LIMIT i,1);
 	
 	IF EXISTS(SELECT playerID FROM HallOfFame WHERE playerID = @id AND inducted = 'Y') THEN
 		INSERT INTO `classification_table` VALUES(@id, 'Y');
	ELSE
		INSERT INTO `classification_table` VALUES(@id, 'N');
	END IF;

	SET i = i + 1;
END WHILE;
END //
DELIMITER ;

CALL InsertValues();


CREATE TABLE batting_table 
(SELECT 
playerID, SUM(H)/SUM(AB) as feature_batting_average, SUM(RBI) as feature_rbi, SUM(HR) as feature_homeruns, SUM(SB) as feature_stolen_bases, SUM(R) as feature_runs_scored
FROM Batting
GROUP BY playerID
HAVING SUM(AB) > 0);

CREATE TABLE pitching_table
(SELECT
playerID, AVG(ERA) as feature_ERA, SUM(SV) as feature_saves, SUM(SO) as feature_strikeouts, SUM(W) as feature_wins, (SUM(H) + SUM(BB)) * 3/SUM(IPOuts) as feature_WHIP
FROM Pitching
WHERE IPOuts > 0
GROUP BY playerID);

CREATE TABLE fielding_table
(SELECT
playerID, SUM(PO) as feature_putouts, SUM(A) as feature_assists, SUM(DP) as feature_doubleplays
FROM Fielding
GROUP BY playerID
);

CREATE TABLE allstar_table 
(SELECT 
playerID, SUM(gameNum) as feature_allstar_appearences
FROM AllStarFull
GROUP by playerID);

CREATE TABLE awards_table
(SELECT
playerID, COUNT(awardID) as feature_awards
FROM AwardsPlayers
GROUP BY playerID);

CREATE TABLE salary_table
(SELECT
playerID, AVG(salary) as feature_salary
FROM Salaries
GROUP BY playerID);

SELECT 
'playerID', #id
'feature_batting_average', 'feature_rbi', 'feature_homeruns', 'feature_stolen_bases', 'feature_runs_scored', #Batting Table
'feature_ERA', 'feature_saves', 'feature_strikeouts', 'feature_wins', 'feature_WHIP', #Pitching Table
'feature_putouts', 'feature_assists', 'feature_doubleplays', #Fielding Table
'feature_allstar_appearences', #AllStarFull Table
'feature_awards', #AwardsPlayers Table
'feature_salary',
'classification' #HallOfFame Table
UNION ALL
SELECT 
classification_table.playerID, 
batting_table.feature_batting_average, batting_table.feature_rbi,  batting_table.feature_homeruns, batting_table.feature_stolen_bases, batting_table.feature_runs_scored,
pitching_table.feature_ERA, pitching_table.feature_saves, pitching_table.feature_strikeouts, pitching_table.feature_wins, pitching_table.feature_WHIP,
fielding_table.feature_putouts, fielding_table.feature_assists, fielding_table.feature_doubleplays,
allstar_table.feature_allstar_appearences,
awards_table.feature_awards,
salary_table.feature_salary,
classification_table.classification
FROM (((((classification_table LEFT JOIN batting_table ON classification_table.playerID = batting_table.playerID) LEFT JOIN allstar_table ON classification_table.playerID = allstar_table.playerID) LEFT JOIN awards_table ON awards_table.playerID = classification_table.playerID) LEFT JOIN pitching_table ON pitching_table.playerID = classification_table.playerID) LEFT JOIN fielding_table ON fielding_table.playerID = classification_table.playerID) LEFT JOIN salary_table ON salary_table.playerID = classification_table.playerID
#Change destination for other computers
INTO OUTFILE '/Users/pranaykatta/Desktop/356_lab4/results.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';


DROP TABLE classification_table;
DROP TABLE batting_table;
DROP TABLE pitching_table;
DROP TABLE fielding_table;
DROP TABLE allstar_table;
DROP TABLE unique_players;
DROP TABLE awards_table;
DROP TABLE salary_table;
DROP PROCEDURE InsertValues;

