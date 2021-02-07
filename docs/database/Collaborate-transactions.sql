



delimiter //
CREATE PROCEDURE login_user (IN email1 varchar(50), IN password1 varchar(30))
    BEGIN

        DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                ROLLBACK;
                SELECT 'Error : SQLError' AS 'message';
            END;

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
        START TRANSACTION;

            SELECT id FROM users WHERE email=email1 AND password = password1;

        COMMIT;
    END//

delimiter ; 



delimiter //
CREATE PROCEDURE insert_new_user (IN email1 varchar(50), IN name1 varchar(20), IN surname1 varchar(70), IN password1 varchar(30))
    BEGIN

        DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                ROLLBACK;
                SELECT 'Error : SQLError' AS 'message';
            END;

        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        START TRANSACTION;

            SET @last_id = (SELECT MAX(id) FROM users);
            INSERT INTO users(email,name,surname,password) VALUES 
            (email1, name1, surname1,password1);

        COMMIT;
    END//

delimiter ; 


--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- TO TRZEBA WYWOŁYWAĆ W PĘTLI PHP 
-- WSTAWIA TYLKO POJEDYŃCZĄ TECHNOLOGIĘ
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
delimiter //
CREATE PROCEDURE insert_technology_user (IN id_user_inserting INT, IN technology VARCHAR(40))
       BEGIN

            DECLARE EXIT HANDLER FOR SQLEXCEPTION
                BEGIN
                    ROLLBACK;
                    SELECT 'Error : SQLError' AS 'message';
                END;

            SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
            START TRANSACTION;
               
                SET @check_technology = (SELECT id from Technology where name=technology);

                IF @check_technology IS NOT NULL THEN
                    -- DODAĆ POTEM DODATKOWY IF CHRONIĄCY CZY NIE PRÓBUJEMY WSTAWIĆ DUPLIKATU
                    INSERT INTO Users_Technology(id_user, id_technology) VALUES (id_user_inserting, @check_technology);
                    SELECT 'Done' AS 'message';
                ELSE
                    SELECT 'Error : Wrong name' AS 'message';
                END IF;

            COMMIT;
       END//
delimiter ;




delimiter //
CREATE PROCEDURE insert_collaborator (IN id_user_inserting INT, IN id_user_inserted INT, IN id_offert_destination INT)
       BEGIN

        DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                ROLLBACK;
                SELECT 'Error : SQLError' AS 'message';
            END;

        SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
            START TRANSACTION;
               
                SET @check_ownership = (SELECT count(offert.id) FROM offert INNER JOIN users ON offert.owner_id = users.id WHERE offert.owner_id = id_user_inserting AND users.id = id_user_inserting);

                IF @check_ownership = 1 THEN
                    INSERT INTO collabolators_Offert(id_user, id_offert) VALUES (id_user_inserted, id_offert_destination);
                    SELECT 'Done' AS 'message';
                ELSE    
                    SELECT 'Error : Not an owner' AS 'message';
                END IF;      

            COMMIT;
       END//
delimiter ;




--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- FUNKCJA WSTAWIAJĄCA DANE O MATCH
-- OD RAZU SPRAWDZA CZY NASTĄPIŁO DOPASOWANIE
-- JEŚLI TAK, TO OD RAZU TWORZY CHAT I WYSYŁA AUTOMATYCZNIE WIADOMOŚĆ
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
delimiter //
CREATE PROCEDURE insert_match (IN id_user_inserted INT, IN id_offert1 INT)
       BEGIN

            DECLARE EXIT HANDLER FOR SQLEXCEPTION
                BEGIN
                    ROLLBACK;
                    SELECT 'Error : SQLError' AS 'message';
                END;

            SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
            START TRANSACTION;

                SET @setmatch = (SELECT count(*) FROM liked_Offert WHERE id_offert=id_offert1 AND id_user=id_user_inserted);

                
                IF @setmatch < 2 THEN
                    INSERT INTO liked_Offert(id_user, id_offert) VALUES(id_user_inserted,id_offert1);
                END IF;
                

                IF @setmatch + 1 = 2 THEN
                    @owner = (SELECT id FROM users INNER JOIN offert ON users.id = offert.owner_id WHERE offert.id = id_offert1);
                    CALL insert_message(id_user_inserted, @owner, "Właśnie dostaliście matcha! Super! Teraz możecie do siebie pisać. Ta wiadomość została wygenerowana automatycznie")
                    SELECT 'Match' AS 'message';
                ELSE
                    SELECT 'Not match' AS 'message'; 
                END IF;

            COMMIT;
       END//
delimiter ;



delimiter //
CREATE PROCEDURE insert_new_offert (IN id_user_inserting INT, IN category_name VARCHAR(20), IN offert_name VARCHAR(60), IN offert_description TEXT, IN technology_list TEXT)
       BEGIN

            

            SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
            START TRANSACTION;

                

                IF @current_id_offert IS NULL THEN
                    SET @current_id_offert = 0;
                END IF;

                SET @category_id = (SELECT id FROM project_category WHERE name=category_name);
                
                
                INSERT INTO offert(name, description, owner_id) VALUES 
                (offert_name, offert_description, id_user_inserting);
                


                SET @current_id_offert = (SELECT max(id) FROM offert);
                IF @category_id IS NOT NULL THEN
                    INSERT INTO offert_category(id_offert, id_category) VALUES
                    (@current_id_offert, @category_id);
                ELSE
                    INSERT INTO offert_category(id_offert, id_category) VALUES
                    (@current_id_offert, 6);
                END IF;

                
                iterator:LOOP

                    IF CHAR_LENGTH(TRIM(technology_list)) = 0 OR technology_list IS NULL THEN
                        LEAVE iterator;
                    END IF;

                    SET @_next = SUBSTRING_INDEX(technology_list,',',1);
                    SET @_nextlen = CHAR_LENGTH(@_next);

                    SET @_value = TRIM(@_next);

                    set @help = (select id from technology where name=@_value);

                    INSERT INTO offert_technology(id_technology,id_offert)
                    values(@help,@current_id_offert); 
                
                    SET technology_list = INSERT(technology_list,1,@_nextlen + 1,'');

                END LOOP;

            COMMIT;
    END//
delimiter ;



delimiter //
CREATE PROCEDURE insert_message(IN id_sender1 INT, IN id_recipent1 INT, IN message1 VARCHAR(255))
       BEGIN
            SET TRANSACTION ISOLATION LEVEL READ COMMITED;
            START TRANSACTION;

                DECLARE EXIT HANDLER FOR SQLEXCEPTION
                    BEGIN
                        ROLLBACK;
                        SELECT 'Error : SQLError' AS 'message';
                    END;

                INSERT INTO chat(id_recipent, id_sender, message, time_sended) VALUES
                (id_recipent1, id_sender1, message1, now());
                
            COMMIT;
    END//
delimiter ;