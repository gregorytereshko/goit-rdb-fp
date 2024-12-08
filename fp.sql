-- Створення бази даних, якщо вона не існує
CREATE DATABASE IF NOT EXISTS pandemic;

-- Вибір бази даних для використання
USE pandemic;

SELECT * FROM infectious_cases LIMIT 30;

-- 2. Нормалізація
-- Створюємо таблицю countries
CREATE TABLE IF NOT EXISTS countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY, -- Унікальний ідентифікатор країни
    country_name VARCHAR(255) NOT NULL, -- Назва країни
    country_code VARCHAR(10) NOT NULL, -- Код країни
    UNIQUE (country_name, country_code) -- Забезпечуємо унікальність
);

-- Заповнюємо таблицю countries унікальними записами
INSERT IGNORE INTO countries (country_name, country_code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- Додаємо колонку country_id до таблиці infectious_cases
ALTER TABLE infectious_cases ADD COLUMN country_id INT;

-- Оновлюємо колонку country_id на основі відповідності таблиці countries
SET SQL_SAFE_UPDATES = 0;
UPDATE infectious_cases ic
JOIN countries c ON ic.Entity = c.country_name AND ic.Code = c.country_code
SET ic.country_id = c.country_id;
SET SQL_SAFE_UPDATES = 1;

-- Видаляємо старі колонки Entity і Code
ALTER TABLE infectious_cases DROP COLUMN Entity;
ALTER TABLE infectious_cases DROP COLUMN Code;

-- Додаємо зовнішній ключ до колонки country_id
ALTER TABLE infectious_cases
ADD CONSTRAINT fk_country FOREIGN KEY (country_id) REFERENCES countries(country_id);

-- 3. Аналіз даних
-- Фільтруємо порожні значення Number_rabies і виконуємо агрегацію
-- Фільтруємо порожні значення Number_rabies і виконуємо агрегацію
SELECT 
    c.country_name AS Entity, -- Назва країни з таблиці countries
    c.country_code AS Code, -- Код країни з таблиці countries
    AVG(ic.Number_rabies) AS avg_rabies, -- Середнє значення
    MIN(ic.Number_rabies) AS min_rabies, -- Мінімальне значення
    MAX(ic.Number_rabies) AS max_rabies, -- Максимальне значення
    SUM(ic.Number_rabies) AS sum_rabies -- Сума
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.country_id -- З'єднання з таблицею countries
WHERE ic.Number_rabies IS NOT NULL AND ic.Number_rabies != '' -- Фільтруємо NULL та порожні значення
GROUP BY c.country_name, c.country_code -- Групування за країною
ORDER BY avg_rabies DESC -- Сортуємо за середнім значенням у порядку спадання
LIMIT 10; -- Виводимо тільки 10 рядків

-- 4. Різниця в роках
SELECT 
    `Year`, 
	CURDATE() AS current,
    DATE(CONCAT(`Year`, '-01-01')) AS first_january, 
    TIMESTAMPDIFF(YEAR, DATE(CONCAT(`Year`, '-01-01')), CURDATE()) AS year_difference
FROM infectious_cases;

-- 5. Власна функція
DELIMITER $$

CREATE FUNCTION year_difference(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE first_january DATE;
    DECLARE years_difference INT;

    -- Створюємо дату першого січня для введеного року
    SET first_january = DATE(CONCAT(input_year, '-01-01'));

    -- Обчислюємо різницю в роках між поточною датою та цією датою
    SET years_difference = TIMESTAMPDIFF(YEAR, first_january, CURDATE());

    RETURN years_difference;
END$$

DELIMITER ;

SELECT 
    `Year`, 
    CURDATE() AS current,
    DATE(CONCAT(`Year`, '-01-01')) AS first_january, 
    year_difference(`Year`) AS year_difference -- Використання функції
FROM infectious_cases;