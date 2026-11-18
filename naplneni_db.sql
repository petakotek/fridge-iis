-- FIT lednice: ukázková data pro MariaDB/MySQL, soubor v UTF-8.
-- Spustit JEDNOU nad prázdnými aplikačními tabulkami po provedení migrací.
-- Administrátor vytvořený migrací může zůstat v databázi: tento skript jej
-- nemění, nemaže ani nevytváří dalšího. Všech 11 nových účtů má isAdmin = 0.
-- Skript nevytváří schéma a neobsahuje DROP, TRUNCATE ani vypnutí cizích klíčů.
-- Import: mariadb --default-character-set=utf8mb4 -u UZIVATEL -p DATABAZE < naplneni_db.sql
-- Všichni níže uvedení uživatelé mají testovací heslo: Test12345! (bcrypt).
-- Přihlašovací e-maily a role:
--   jan.novak@example.test             Jan Novák: správce (novakovi)
--   jana.novakova@example.test         Jana Nováková: člen (novakovi)
--   petr.novak@example.test            Petr Novák: člen (novakovi)
--   tereza.dvorakova@example.test      Tereza Dvořáková: správce (studenti)
--   martin.svoboda@example.test        Martin Svoboda: člen (studenti)
--   eva.prochazkova@example.test       Eva Procházková: člen (studenti)
--   lucie.zelena@example.test          Lucie Zelená: správce (zeleni)
--   tomas.zeleny@example.test          Tomáš Zelený: člen (zeleni)
--   adam.cerny@example.test            Adam Černý: žádá o členství u Novákových
--   klara.vesela@example.test          Klára Veselá: žádá o členství u studentů
--   ondrej.maly@example.test           Ondřej Malý: bez domácnosti a žádosti
-- Tokeny pro vstup hosta / žádost o členství:
--   Novákovi: Novak2026A
--   Studentský byt: Stud2026AB
--   Zelení: Zelen2026A
-- Obsah: 3 domácnosti, 9 spotřebičů, 39 polic a víceúrovňové kategorie;
-- 120 uložených, 240 spotřebovaných a 30 vyhozených potravin.
-- Data/expirace jsou relativní k datu importu; historie pokrývá 60 posledních dnů.
-- Kalorie a živiny jsou součty pro uvedenou hmotnost/objem, stejně jako v aplikaci.
-- Balené výrobky: skutečné EAN a údaje z Open Food Facts (https://world.openfoodfacts.org/, ODbL).
-- Chybějící vláknina, nebalené suroviny a ceny jsou realistické orientační hodnoty.
-- Import nevyžaduje síť, PHP ani další pomocné soubory.

SET NAMES utf8mb4;
START TRANSACTION;
SET @seed_today = CURRENT_DATE();
SET @seed_now = CURRENT_TIMESTAMP();
SET @seed_password = '$2y$10$VijFEgad55b4YaJla4YGVOb.zVsBlz4uuFv7HltNYFvRtc.Qxe9km';

-- 1. Běžné účty. Členství se doplní až po založení domácností (cyklické vazby).
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Jan', 'Novák', 'jan.novak@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_jan = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Jana', 'Nováková', 'jana.novakova@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_jana = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Petr', 'Novák', 'petr.novak@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_petr = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Tereza', 'Dvořáková', 'tereza.dvorakova@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_tereza = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Martin', 'Svoboda', 'martin.svoboda@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_martin = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Eva', 'Procházková', 'eva.prochazkova@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_eva = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Lucie', 'Zelená', 'lucie.zelena@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_lucie = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Tomáš', 'Zelený', 'tomas.zeleny@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_tomas = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Adam', 'Černý', 'adam.cerny@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_adam = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Klára', 'Veselá', 'klara.vesela@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_klara = LAST_INSERT_ID();
INSERT INTO `UserEntity` (`name`, `surname`, `email`, `password`, `isAdmin`, `household_id`, `householdRequest`)
VALUES ('Ondřej', 'Malý', 'ondrej.maly@example.test', @seed_password, 0, NULL, NULL);
SET @seed_u_ondrej = LAST_INSERT_ID();

-- 2. Domácnosti a jejich správci; ID jsou získávána přes LAST_INSERT_ID().
INSERT INTO `HouseholdEntity` (`name`, `token`, `moderator_id`)
VALUES ('Novákovi', 'Novak2026A', @seed_u_jan);
SET @seed_h_novakovi = LAST_INSERT_ID();
UPDATE `UserEntity` SET `household_id` = @seed_h_novakovi WHERE `id` IN (@seed_u_jan, @seed_u_jana, @seed_u_petr);
INSERT INTO `HouseholdEntity` (`name`, `token`, `moderator_id`)
VALUES ('Studentský byt', 'Stud2026AB', @seed_u_tereza);
SET @seed_h_studenti = LAST_INSERT_ID();
UPDATE `UserEntity` SET `household_id` = @seed_h_studenti WHERE `id` IN (@seed_u_tereza, @seed_u_martin, @seed_u_eva);
INSERT INTO `HouseholdEntity` (`name`, `token`, `moderator_id`)
VALUES ('Zelení', 'Zelen2026A', @seed_u_lucie);
SET @seed_h_zeleni = LAST_INSERT_ID();
UPDATE `UserEntity` SET `household_id` = @seed_h_zeleni WHERE `id` IN (@seed_u_lucie, @seed_u_tomas);
UPDATE `UserEntity` SET `householdRequest` = @seed_h_novakovi WHERE `id` = @seed_u_adam;
UPDATE `UserEntity` SET `householdRequest` = @seed_h_studenti WHERE `id` = @seed_u_klara;

-- 3. Spotřebiče, police (nosnost v g/ml) a kategorie každé domácnosti.
-- Novákovi
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Lednice', @seed_h_novakovi);
SET @seed_a_novakovi_fridge = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Mrazák', @seed_h_novakovi);
SET @seed_a_novakovi_freezer = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Spíž', @seed_h_novakovi);
SET @seed_a_novakovi_pantry = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní – jogurty a svačiny', 4000, @seed_a_novakovi_fridge);
SET @seed_s_novakovi_fridge_top = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Střední – sýry a mléčné výrobky', 6000, @seed_a_novakovi_fridge);
SET @seed_s_novakovi_fridge_dairy = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní – uzeniny a vejce', 4000, @seed_a_novakovi_fridge);
SET @seed_s_novakovi_fridge_protein = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Zásuvka na zeleninu', 5000, @seed_a_novakovi_fridge);
SET @seed_s_novakovi_fridge_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Dveře – nápoje a dochucovadla', 5000, @seed_a_novakovi_fridge);
SET @seed_s_novakovi_fridge_door = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní zásuvka – zelenina a ovoce', 8000, @seed_a_novakovi_freezer);
SET @seed_s_novakovi_freezer_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Prostřední zásuvka – ryby a hotová jídla', 10000, @seed_a_novakovi_freezer);
SET @seed_s_novakovi_freezer_meals = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní zásuvka – zmrzlina', 3000, @seed_a_novakovi_freezer);
SET @seed_s_novakovi_freezer_sweets = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Těstoviny a rýže', 10000, @seed_a_novakovi_pantry);
SET @seed_s_novakovi_pantry_pasta = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Mouka, cukr a pečení', 10000, @seed_a_novakovi_pantry);
SET @seed_s_novakovi_pantry_baking = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Snídaně a svačiny', 8000, @seed_a_novakovi_pantry);
SET @seed_s_novakovi_pantry_breakfast = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Konzervy a omáčky', 6000, @seed_a_novakovi_pantry);
SET @seed_s_novakovi_pantry_cans = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Pečivo', 3000, @seed_a_novakovi_pantry);
SET @seed_s_novakovi_pantry_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Potraviny', 1, 52, 0, NULL, NULL, @seed_h_novakovi);
SET @seed_c_novakovi_root = LAST_INSERT_ID();
UPDATE `CategoryEntity` SET `tree_root` = @seed_c_novakovi_root WHERE `id` = @seed_c_novakovi_root;
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné výrobky', 2, 17, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_dairy = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Jogurty', 3, 8, 2, @seed_c_novakovi_root, @seed_c_novakovi_dairy, @seed_h_novakovi);
SET @seed_c_novakovi_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Bílé jogurty', 4, 5, 3, @seed_c_novakovi_root, @seed_c_novakovi_yogurt, @seed_h_novakovi);
SET @seed_c_novakovi_plain = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovocné jogurty', 6, 7, 3, @seed_c_novakovi_root, @seed_c_novakovi_yogurt, @seed_h_novakovi);
SET @seed_c_novakovi_fruit_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sýry', 9, 10, 2, @seed_c_novakovi_root, @seed_c_novakovi_dairy, @seed_h_novakovi);
SET @seed_c_novakovi_cheese = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléko a smetana', 11, 12, 2, @seed_c_novakovi_root, @seed_c_novakovi_dairy, @seed_h_novakovi);
SET @seed_c_novakovi_milk = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Máslo a pomazánky', 13, 14, 2, @seed_c_novakovi_root, @seed_c_novakovi_dairy, @seed_h_novakovi);
SET @seed_c_novakovi_spreads = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné dezerty', 15, 16, 2, @seed_c_novakovi_root, @seed_c_novakovi_dairy, @seed_h_novakovi);
SET @seed_c_novakovi_dessert = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Maso a vejce', 18, 19, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_meat = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Zelenina', 20, 21, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_vegetables = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovoce', 22, 23, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_fruit = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ryby', 24, 25, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_fish = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Hotová jídla', 26, 27, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_meals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sladkosti', 28, 29, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_sweets = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Trvanlivé potraviny', 30, 45, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_durable = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny a rýže', 31, 36, 2, @seed_c_novakovi_root, @seed_c_novakovi_durable, @seed_h_novakovi);
SET @seed_c_novakovi_pasta_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny', 32, 33, 3, @seed_c_novakovi_root, @seed_c_novakovi_pasta_rice, @seed_h_novakovi);
SET @seed_c_novakovi_pasta = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rýže', 34, 35, 3, @seed_c_novakovi_root, @seed_c_novakovi_pasta_rice, @seed_h_novakovi);
SET @seed_c_novakovi_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mouka a pečení', 37, 38, 2, @seed_c_novakovi_root, @seed_c_novakovi_durable, @seed_h_novakovi);
SET @seed_c_novakovi_baking = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Cereálie a ořechy', 39, 40, 2, @seed_c_novakovi_root, @seed_c_novakovi_durable, @seed_h_novakovi);
SET @seed_c_novakovi_cereals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Konzervy a omáčky', 41, 42, 2, @seed_c_novakovi_root, @seed_c_novakovi_durable, @seed_h_novakovi);
SET @seed_c_novakovi_cans = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Dochucovadla', 43, 44, 2, @seed_c_novakovi_root, @seed_c_novakovi_durable, @seed_h_novakovi);
SET @seed_c_novakovi_condiments = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rostlinné nápoje', 46, 47, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_plant_drinks = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Pečivo', 48, 49, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Luštěniny', 50, 51, 1, @seed_c_novakovi_root, @seed_c_novakovi_root, @seed_h_novakovi);
SET @seed_c_novakovi_legumes = LAST_INSERT_ID();
-- Studentský byt
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Lednice', @seed_h_studenti);
SET @seed_a_studenti_fridge = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Mrazák', @seed_h_studenti);
SET @seed_a_studenti_freezer = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Spíž', @seed_h_studenti);
SET @seed_a_studenti_pantry = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní – jogurty a svačiny', 4000, @seed_a_studenti_fridge);
SET @seed_s_studenti_fridge_top = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Střední – sýry a mléčné výrobky', 6000, @seed_a_studenti_fridge);
SET @seed_s_studenti_fridge_dairy = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní – uzeniny a vejce', 4000, @seed_a_studenti_fridge);
SET @seed_s_studenti_fridge_protein = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Zásuvka na zeleninu', 5000, @seed_a_studenti_fridge);
SET @seed_s_studenti_fridge_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Dveře – nápoje a dochucovadla', 5000, @seed_a_studenti_fridge);
SET @seed_s_studenti_fridge_door = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní zásuvka – zelenina a ovoce', 8000, @seed_a_studenti_freezer);
SET @seed_s_studenti_freezer_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Prostřední zásuvka – ryby a hotová jídla', 10000, @seed_a_studenti_freezer);
SET @seed_s_studenti_freezer_meals = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní zásuvka – zmrzlina', 3000, @seed_a_studenti_freezer);
SET @seed_s_studenti_freezer_sweets = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Těstoviny a rýže', 10000, @seed_a_studenti_pantry);
SET @seed_s_studenti_pantry_pasta = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Mouka, cukr a pečení', 10000, @seed_a_studenti_pantry);
SET @seed_s_studenti_pantry_baking = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Snídaně a svačiny', 8000, @seed_a_studenti_pantry);
SET @seed_s_studenti_pantry_breakfast = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Konzervy a omáčky', 6000, @seed_a_studenti_pantry);
SET @seed_s_studenti_pantry_cans = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Pečivo', 3000, @seed_a_studenti_pantry);
SET @seed_s_studenti_pantry_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Potraviny', 1, 52, 0, NULL, NULL, @seed_h_studenti);
SET @seed_c_studenti_root = LAST_INSERT_ID();
UPDATE `CategoryEntity` SET `tree_root` = @seed_c_studenti_root WHERE `id` = @seed_c_studenti_root;
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné výrobky', 2, 17, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_dairy = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Jogurty', 3, 8, 2, @seed_c_studenti_root, @seed_c_studenti_dairy, @seed_h_studenti);
SET @seed_c_studenti_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Bílé jogurty', 4, 5, 3, @seed_c_studenti_root, @seed_c_studenti_yogurt, @seed_h_studenti);
SET @seed_c_studenti_plain = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovocné jogurty', 6, 7, 3, @seed_c_studenti_root, @seed_c_studenti_yogurt, @seed_h_studenti);
SET @seed_c_studenti_fruit_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sýry', 9, 10, 2, @seed_c_studenti_root, @seed_c_studenti_dairy, @seed_h_studenti);
SET @seed_c_studenti_cheese = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléko a smetana', 11, 12, 2, @seed_c_studenti_root, @seed_c_studenti_dairy, @seed_h_studenti);
SET @seed_c_studenti_milk = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Máslo a pomazánky', 13, 14, 2, @seed_c_studenti_root, @seed_c_studenti_dairy, @seed_h_studenti);
SET @seed_c_studenti_spreads = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné dezerty', 15, 16, 2, @seed_c_studenti_root, @seed_c_studenti_dairy, @seed_h_studenti);
SET @seed_c_studenti_dessert = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Maso a vejce', 18, 19, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_meat = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Zelenina', 20, 21, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_vegetables = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovoce', 22, 23, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_fruit = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ryby', 24, 25, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_fish = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Hotová jídla', 26, 27, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_meals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sladkosti', 28, 29, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_sweets = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Trvanlivé potraviny', 30, 45, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_durable = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny a rýže', 31, 36, 2, @seed_c_studenti_root, @seed_c_studenti_durable, @seed_h_studenti);
SET @seed_c_studenti_pasta_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny', 32, 33, 3, @seed_c_studenti_root, @seed_c_studenti_pasta_rice, @seed_h_studenti);
SET @seed_c_studenti_pasta = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rýže', 34, 35, 3, @seed_c_studenti_root, @seed_c_studenti_pasta_rice, @seed_h_studenti);
SET @seed_c_studenti_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mouka a pečení', 37, 38, 2, @seed_c_studenti_root, @seed_c_studenti_durable, @seed_h_studenti);
SET @seed_c_studenti_baking = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Cereálie a ořechy', 39, 40, 2, @seed_c_studenti_root, @seed_c_studenti_durable, @seed_h_studenti);
SET @seed_c_studenti_cereals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Konzervy a omáčky', 41, 42, 2, @seed_c_studenti_root, @seed_c_studenti_durable, @seed_h_studenti);
SET @seed_c_studenti_cans = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Dochucovadla', 43, 44, 2, @seed_c_studenti_root, @seed_c_studenti_durable, @seed_h_studenti);
SET @seed_c_studenti_condiments = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rostlinné nápoje', 46, 47, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_plant_drinks = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Pečivo', 48, 49, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Luštěniny', 50, 51, 1, @seed_c_studenti_root, @seed_c_studenti_root, @seed_h_studenti);
SET @seed_c_studenti_legumes = LAST_INSERT_ID();
-- Zelení
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Lednice', @seed_h_zeleni);
SET @seed_a_zeleni_fridge = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Mrazák', @seed_h_zeleni);
SET @seed_a_zeleni_freezer = LAST_INSERT_ID();
INSERT INTO `ApplianceEntity` (`name`, `household_id`)
VALUES ('Spíž', @seed_h_zeleni);
SET @seed_a_zeleni_pantry = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní – jogurty a svačiny', 4000, @seed_a_zeleni_fridge);
SET @seed_s_zeleni_fridge_top = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Střední – sýry a mléčné výrobky', 6000, @seed_a_zeleni_fridge);
SET @seed_s_zeleni_fridge_dairy = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní – uzeniny a vejce', 4000, @seed_a_zeleni_fridge);
SET @seed_s_zeleni_fridge_protein = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Zásuvka na zeleninu', 5000, @seed_a_zeleni_fridge);
SET @seed_s_zeleni_fridge_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Dveře – nápoje a dochucovadla', 5000, @seed_a_zeleni_fridge);
SET @seed_s_zeleni_fridge_door = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Horní zásuvka – zelenina a ovoce', 8000, @seed_a_zeleni_freezer);
SET @seed_s_zeleni_freezer_produce = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Prostřední zásuvka – ryby a hotová jídla', 10000, @seed_a_zeleni_freezer);
SET @seed_s_zeleni_freezer_meals = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Spodní zásuvka – zmrzlina', 3000, @seed_a_zeleni_freezer);
SET @seed_s_zeleni_freezer_sweets = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Těstoviny a rýže', 10000, @seed_a_zeleni_pantry);
SET @seed_s_zeleni_pantry_pasta = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Mouka, cukr a pečení', 10000, @seed_a_zeleni_pantry);
SET @seed_s_zeleni_pantry_baking = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Snídaně a svačiny', 8000, @seed_a_zeleni_pantry);
SET @seed_s_zeleni_pantry_breakfast = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Konzervy a omáčky', 6000, @seed_a_zeleni_pantry);
SET @seed_s_zeleni_pantry_cans = LAST_INSERT_ID();
INSERT INTO `ShelfEntity` (`name`, `shelfCapacity`, `appliance_id`)
VALUES ('Pečivo', 3000, @seed_a_zeleni_pantry);
SET @seed_s_zeleni_pantry_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Potraviny', 1, 52, 0, NULL, NULL, @seed_h_zeleni);
SET @seed_c_zeleni_root = LAST_INSERT_ID();
UPDATE `CategoryEntity` SET `tree_root` = @seed_c_zeleni_root WHERE `id` = @seed_c_zeleni_root;
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné výrobky', 2, 17, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_dairy = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Jogurty', 3, 8, 2, @seed_c_zeleni_root, @seed_c_zeleni_dairy, @seed_h_zeleni);
SET @seed_c_zeleni_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Bílé jogurty', 4, 5, 3, @seed_c_zeleni_root, @seed_c_zeleni_yogurt, @seed_h_zeleni);
SET @seed_c_zeleni_plain = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovocné jogurty', 6, 7, 3, @seed_c_zeleni_root, @seed_c_zeleni_yogurt, @seed_h_zeleni);
SET @seed_c_zeleni_fruit_yogurt = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sýry', 9, 10, 2, @seed_c_zeleni_root, @seed_c_zeleni_dairy, @seed_h_zeleni);
SET @seed_c_zeleni_cheese = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléko a smetana', 11, 12, 2, @seed_c_zeleni_root, @seed_c_zeleni_dairy, @seed_h_zeleni);
SET @seed_c_zeleni_milk = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Máslo a pomazánky', 13, 14, 2, @seed_c_zeleni_root, @seed_c_zeleni_dairy, @seed_h_zeleni);
SET @seed_c_zeleni_spreads = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mléčné dezerty', 15, 16, 2, @seed_c_zeleni_root, @seed_c_zeleni_dairy, @seed_h_zeleni);
SET @seed_c_zeleni_dessert = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Maso a vejce', 18, 19, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_meat = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Zelenina', 20, 21, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_vegetables = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ovoce', 22, 23, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_fruit = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Ryby', 24, 25, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_fish = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Hotová jídla', 26, 27, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_meals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Sladkosti', 28, 29, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_sweets = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Trvanlivé potraviny', 30, 45, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_durable = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny a rýže', 31, 36, 2, @seed_c_zeleni_root, @seed_c_zeleni_durable, @seed_h_zeleni);
SET @seed_c_zeleni_pasta_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Těstoviny', 32, 33, 3, @seed_c_zeleni_root, @seed_c_zeleni_pasta_rice, @seed_h_zeleni);
SET @seed_c_zeleni_pasta = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rýže', 34, 35, 3, @seed_c_zeleni_root, @seed_c_zeleni_pasta_rice, @seed_h_zeleni);
SET @seed_c_zeleni_rice = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Mouka a pečení', 37, 38, 2, @seed_c_zeleni_root, @seed_c_zeleni_durable, @seed_h_zeleni);
SET @seed_c_zeleni_baking = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Cereálie a ořechy', 39, 40, 2, @seed_c_zeleni_root, @seed_c_zeleni_durable, @seed_h_zeleni);
SET @seed_c_zeleni_cereals = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Konzervy a omáčky', 41, 42, 2, @seed_c_zeleni_root, @seed_c_zeleni_durable, @seed_h_zeleni);
SET @seed_c_zeleni_cans = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Dochucovadla', 43, 44, 2, @seed_c_zeleni_root, @seed_c_zeleni_durable, @seed_h_zeleni);
SET @seed_c_zeleni_condiments = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Rostlinné nápoje', 46, 47, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_plant_drinks = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Pečivo', 48, 49, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_bread = LAST_INSERT_ID();
INSERT INTO `CategoryEntity` (`name`, `lft`, `rgt`, `level`, `tree_root`, `parent_id`, `household_id`)
VALUES ('Luštěniny', 50, 51, 1, @seed_c_zeleni_root, @seed_c_zeleni_root, @seed_h_zeleni);
SET @seed_c_zeleni_legumes = LAST_INSERT_ID();

-- 4. Aktuální zásoby. Několik položek je po trvanlivosti, dnes nebo zítra,
-- aby bylo možné vyzkoušet všechna upozornění. Žádná police není přeplněná.
-- Novákovi: 49 položek v zásobách.
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '8594001170012', 29.90, 335, 20, 19, 22, 0, @seed_s_novakovi_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 8 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL 0 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeské máslo', DATE_ADD(@seed_today, INTERVAL 32 DAY), 250, '8593803421216', 59.90, 1860, 2, 205, 2, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_spreads);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský eidam 30 % plátky', DATE_ADD(@seed_today, INTERVAL 18 DAY), 100, '8593803326252', 28.90, 265, 29, 16, 1, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Choceňské tradiční pomazánkové', DATE_ADD(@seed_today, INTERVAL 14 DAY), 150, '8594003219061', 32.90, 471, 5, 47, 8, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_spreads);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL 11 DAY), 180, '8594008278742', 49.90, 437, 11, 41, 6, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL 1 DAY), 200, '8593807332105', 32.90, 624, 4, 66, 6, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL 9 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Lipánek tradiční vanilkový', DATE_ADD(@seed_today, INTERVAL 7 DAY), 130, '8593803662152', 24.90, 241, 10, 14, 18, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_dessert), (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Zott Monte mléčný dezert', DATE_ADD(@seed_today, INTERVAL 15 DAY), 150, '40338231', 24.90, 272, 4, 18, 24, 0, @seed_s_novakovi_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_dessert), (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Pikok Kuřecí prsní šunka', DATE_ADD(@seed_today, INTERVAL 5 DAY), 100, '20837112', 29.90, 91, 19, 1, 1, 0, @seed_s_novakovi_fridge_protein, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL 20 DAY), 300, '', 44.90, 429, 38, 29, 2, 0, @seed_s_novakovi_fridge_protein, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '', 14.90, 175, 4, 1, 35, 13, @seed_s_novakovi_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL 6 DAY), 300, '', 34.90, 87, 3, 1, 14, 6, @seed_s_novakovi_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL 5 DAY), 300, '', 19.90, 42, 2, 0, 7, 2, @seed_s_novakovi_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -1 DAY), 250, '', 29.90, 45, 2, 1, 7, 3, @seed_s_novakovi_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL 4 DAY), 1000, '8593807204716', 32.90, 660, 33, 39, 46, 0, @seed_s_novakovi_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Valašské kefírové mléko nízkotučné', DATE_ADD(@seed_today, INTERVAL 7 DAY), 500, '8594003024139', 22.90, 195, 16, 6, 21, 0, @seed_s_novakovi_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Otma Gurmán kečup jemný extra – otevřený', DATE_ADD(@seed_today, INTERVAL 24 DAY), 520, '8595139797003', 39.90, 697, 8, 3, 151, 5, @seed_s_novakovi_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_condiments);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise ovesný nápoj', DATE_ADD(@seed_today, INTERVAL 5 DAY), 1000, '8590421062685', 39.90, 510, 10, 10, 90, 8, @seed_s_novakovi_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plant_drinks);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 190 DAY), 450, '8594046805054', 27.90, 198, 10, 3, 32, 14, @seed_s_novakovi_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 150 DAY), 350, '8594001041282', 24.90, 133, 5, 2, 25, 9, @seed_s_novakovi_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 210 DAY), 400, '8590421076538', 19.90, 104, 12, 3, 2, 8, @seed_s_novakovi_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 180 DAY), 450, '8590186263877', 32.90, 419, 28, 3, 53, 21, @seed_s_novakovi_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables), (@seed_food, @seed_c_novakovi_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Freshona směs lesního ovoce s višněmi', DATE_ADD(@seed_today, INTERVAL 240 DAY), 750, '20130596', 79.90, 357, 7, 2, 53, 26, @seed_s_novakovi_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 120 DAY), 475, '20466190', 89.90, 323, 72, 4, 0, 0, @seed_s_novakovi_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 160 DAY), 365, '4001724037576', 69.90, 829, 29, 40, 80, 7, @seed_s_novakovi_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 200 DAY), 400, '4770190078702', 89.90, 584, 20, 8, 104, 9, @seed_s_novakovi_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Míša tvarohový nanuk', DATE_ADD(@seed_today, INTERVAL 180 DAY), 47, '8594002648008', 19.90, 125, 4, 7, 11, 0, @seed_s_novakovi_freezer_sweets, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Prima Mrož jahodový v bílé polevě', DATE_ADD(@seed_today, INTERVAL 180 DAY), 43, '8594001040100', 17.90, 105, 1, 6, 11, 0, @seed_s_novakovi_freezer_sweets, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Prima Mrož mangový sorbet', DATE_ADD(@seed_today, INTERVAL 210 DAY), 390, '8594001041534', 79.90, 519, 2, 2, 129, 2, @seed_s_novakovi_freezer_sweets, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 450 DAY), 500, '3038351665002', 34.90, 1805, 60, 10, 360, 18, @seed_s_novakovi_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 480 DAY), 500, '3038351683808', 34.90, 1805, 60, 10, 360, 18, @seed_s_novakovi_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Combino Fusilli z červené čočky', DATE_ADD(@seed_today, INTERVAL 360 DAY), 250, '20143084', 39.90, 850, 60, 4, 136, 16, @seed_s_novakovi_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta), (@seed_food, @seed_c_novakovi_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 500 DAY), 1000, '8595237415014', 54.90, 3520, 54, 5, 820, 5, @seed_s_novakovi_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lagris Rýže kulatozrnná', DATE_ADD(@seed_today, INTERVAL 420 DAY), 1000, '8594004492876', 49.90, 3560, 70, 5, 800, 5, @seed_s_novakovi_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Albert Mouka pšeničná hladká', DATE_ADD(@seed_today, INTERVAL 240 DAY), 1000, '8590421045794', 18.90, 3450, 120, 17, 690, 31, @seed_s_novakovi_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Karlova Koruna Mouka pšeničná polohrubá', DATE_ADD(@seed_today, INTERVAL 210 DAY), 1000, '8590077105033', 18.90, 3480, 110, 15, 710, 30, @seed_s_novakovi_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tereos Cukr krupice bílý', DATE_ADD(@seed_today, INTERVAL 730 DAY), 1000, '8594000230274', 22.90, 4000, 0, 0, 1000, 0, @seed_s_novakovi_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 240 DAY), 500, '8594017144588', 29.90, 1770, 70, 26, 275, 80, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 180 DAY), 750, '8594017140863', 89.90, 3293, 63, 128, 443, 64, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 300 DAY), 350, '8590421061831', 79.90, 2212, 95, 175, 46, 20, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Medokomerc Med luční', DATE_ADD(@seed_today, INTERVAL 600 DAY), 900, '8594003430879', 149.90, 2952, 3, 0, 735, 0, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_condiments);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Opavia BeBe dobré ráno oříškové s medem', DATE_ADD(@seed_today, INTERVAL 150 DAY), 400, '8593894805551', 59.90, 1788, 31, 60, 260, 30, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Alesto Mandle natural', DATE_ADD(@seed_today, INTERVAL 180 DAY), 200, '20724696', 54.90, 1242, 49, 107, 10, 24, @seed_s_novakovi_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 600 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_novakovi_pantry_cans, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Napoletana rajčatová omáčka', DATE_ADD(@seed_today, INTERVAL 360 DAY), 400, '3038354250908', 49.90, 204, 6, 6, 33, 6, @seed_s_novakovi_pantry_cans, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cans);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL 8 DAY), 500, '20051426', 27.90, 1290, 48, 28, 210, 33, @seed_s_novakovi_pantry_bread, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
-- Studentský byt: 35 položek v zásobách.
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '8594001170012', 29.90, 335, 20, 19, 22, 0, @seed_s_studenti_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 8 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL 0 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský eidam 30 % plátky', DATE_ADD(@seed_today, INTERVAL 18 DAY), 100, '8593803326252', 28.90, 265, 29, 16, 1, 0, @seed_s_studenti_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL 1 DAY), 200, '8593807332105', 32.90, 624, 4, 66, 6, 0, @seed_s_studenti_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL 9 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Pikok Kuřecí prsní šunka', DATE_ADD(@seed_today, INTERVAL 5 DAY), 100, '20837112', 29.90, 91, 19, 1, 1, 0, @seed_s_studenti_fridge_protein, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL 20 DAY), 300, '', 44.90, 429, 38, 29, 2, 0, @seed_s_studenti_fridge_protein, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '', 14.90, 175, 4, 1, 35, 13, @seed_s_studenti_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL 6 DAY), 300, '', 34.90, 87, 3, 1, 14, 6, @seed_s_studenti_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL 5 DAY), 300, '', 19.90, 42, 2, 0, 7, 2, @seed_s_studenti_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -1 DAY), 250, '', 29.90, 45, 2, 1, 7, 3, @seed_s_studenti_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -2 DAY), 1000, '8593807204716', 32.90, 660, 33, 39, 46, 0, @seed_s_studenti_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Valašské kefírové mléko nízkotučné', DATE_ADD(@seed_today, INTERVAL 7 DAY), 500, '8594003024139', 22.90, 195, 16, 6, 21, 0, @seed_s_studenti_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 190 DAY), 450, '8594046805054', 27.90, 198, 10, 3, 32, 14, @seed_s_studenti_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 210 DAY), 400, '8590421076538', 19.90, 104, 12, 3, 2, 8, @seed_s_studenti_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 180 DAY), 450, '8590186263877', 32.90, 419, 28, 3, 53, 21, @seed_s_studenti_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables), (@seed_food, @seed_c_studenti_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 120 DAY), 475, '20466190', 89.90, 323, 72, 4, 0, 0, @seed_s_studenti_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 160 DAY), 365, '4001724037576', 69.90, 829, 29, 40, 80, 7, @seed_s_studenti_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 200 DAY), 400, '4770190078702', 89.90, 584, 20, 8, 104, 9, @seed_s_studenti_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Míša tvarohový nanuk', DATE_ADD(@seed_today, INTERVAL 180 DAY), 47, '8594002648008', 19.90, 125, 4, 7, 11, 0, @seed_s_studenti_freezer_sweets, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 450 DAY), 500, '3038351665002', 34.90, 1805, 60, 10, 360, 18, @seed_s_studenti_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 480 DAY), 500, '3038351683808', 34.90, 1805, 60, 10, 360, 18, @seed_s_studenti_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Combino Fusilli z červené čočky', DATE_ADD(@seed_today, INTERVAL 360 DAY), 250, '20143084', 39.90, 850, 60, 4, 136, 16, @seed_s_studenti_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_pasta), (@seed_food, @seed_c_studenti_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 500 DAY), 1000, '8595237415014', 54.90, 3520, 54, 5, 820, 5, @seed_s_studenti_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lagris Rýže kulatozrnná', DATE_ADD(@seed_today, INTERVAL 420 DAY), 1000, '8594004492876', 49.90, 3560, 70, 5, 800, 5, @seed_s_studenti_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Albert Mouka pšeničná hladká', DATE_ADD(@seed_today, INTERVAL 240 DAY), 1000, '8590421045794', 18.90, 3450, 120, 17, 690, 31, @seed_s_studenti_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 240 DAY), 500, '8594017144588', 29.90, 1770, 70, 26, 275, 80, @seed_s_studenti_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 180 DAY), 750, '8594017140863', 89.90, 3293, 63, 128, 443, 64, @seed_s_studenti_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 300 DAY), 350, '8590421061831', 79.90, 2212, 95, 175, 46, 20, @seed_s_studenti_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Opavia BeBe dobré ráno oříškové s medem', DATE_ADD(@seed_today, INTERVAL 150 DAY), 400, '8593894805551', 59.90, 1788, 31, 60, 260, 30, @seed_s_studenti_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Alesto Mandle natural', DATE_ADD(@seed_today, INTERVAL 180 DAY), 200, '20724696', 54.90, 1242, 49, 107, 10, 24, @seed_s_studenti_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 600 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_studenti_pantry_cans, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Napoletana rajčatová omáčka', DATE_ADD(@seed_today, INTERVAL 360 DAY), 400, '3038354250908', 49.90, 204, 6, 6, 33, 6, @seed_s_studenti_pantry_cans, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cans);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL 8 DAY), 500, '20051426', 27.90, 1290, 48, 28, 210, 33, @seed_s_studenti_pantry_bread, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
-- Zelení: 36 položek v zásobách.
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '8594001170012', 29.90, 335, 20, 19, 22, 0, @seed_s_zeleni_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 8 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL 0 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL 11 DAY), 180, '8594008278742', 49.90, 437, 11, 41, 6, 0, @seed_s_zeleni_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL 1 DAY), 200, '8593807332105', 32.90, 624, 4, 66, 6, 0, @seed_s_zeleni_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL 9 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL 12 DAY), 500, '', 14.90, 175, 4, 1, 35, 13, @seed_s_zeleni_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL 6 DAY), 300, '', 34.90, 87, 3, 1, 14, 6, @seed_s_zeleni_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL 5 DAY), 300, '', 19.90, 42, 2, 0, 7, 2, @seed_s_zeleni_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -1 DAY), 250, '', 29.90, 45, 2, 1, 7, 3, @seed_s_zeleni_fridge_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL 4 DAY), 1000, '8593807204716', 32.90, 660, 33, 39, 46, 0, @seed_s_zeleni_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Valašské kefírové mléko nízkotučné', DATE_ADD(@seed_today, INTERVAL 7 DAY), 500, '8594003024139', 22.90, 195, 16, 6, 21, 0, @seed_s_zeleni_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Otma Gurmán kečup jemný extra – otevřený', DATE_ADD(@seed_today, INTERVAL 24 DAY), 520, '8595139797003', 39.90, 697, 8, 3, 151, 5, @seed_s_zeleni_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_condiments);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise ovesný nápoj', DATE_ADD(@seed_today, INTERVAL 5 DAY), 1000, '8590421062685', 39.90, 510, 10, 10, 90, 8, @seed_s_zeleni_fridge_door, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plant_drinks);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 190 DAY), 450, '8594046805054', 27.90, 198, 10, 3, 32, 14, @seed_s_zeleni_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 150 DAY), 350, '8594001041282', 24.90, 133, 5, 2, 25, 9, @seed_s_zeleni_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 210 DAY), 400, '8590421076538', 19.90, 104, 12, 3, 2, 8, @seed_s_zeleni_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 180 DAY), 450, '8590186263877', 32.90, 419, 28, 3, 53, 21, @seed_s_zeleni_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables), (@seed_food, @seed_c_zeleni_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Freshona směs lesního ovoce s višněmi', DATE_ADD(@seed_today, INTERVAL 240 DAY), 750, '20130596', 79.90, 357, 7, 2, 53, 26, @seed_s_zeleni_freezer_produce, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 200 DAY), 400, '4770190078702', 89.90, 584, 20, 8, 104, 9, @seed_s_zeleni_freezer_meals, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 450 DAY), 500, '3038351665002', 34.90, 1805, 60, 10, 360, 18, @seed_s_zeleni_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 480 DAY), 500, '3038351683808', 34.90, 1805, 60, 10, 360, 18, @seed_s_zeleni_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Combino Fusilli z červené čočky', DATE_ADD(@seed_today, INTERVAL 360 DAY), 250, '20143084', 39.90, 850, 60, 4, 136, 16, @seed_s_zeleni_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta), (@seed_food, @seed_c_zeleni_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 500 DAY), 1000, '8595237415014', 54.90, 3520, 54, 5, 820, 5, @seed_s_zeleni_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lagris Rýže kulatozrnná', DATE_ADD(@seed_today, INTERVAL 420 DAY), 1000, '8594004492876', 49.90, 3560, 70, 5, 800, 5, @seed_s_zeleni_pantry_pasta, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Albert Mouka pšeničná hladká', DATE_ADD(@seed_today, INTERVAL 240 DAY), 1000, '8590421045794', 18.90, 3450, 120, 17, 690, 31, @seed_s_zeleni_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Karlova Koruna Mouka pšeničná polohrubá', DATE_ADD(@seed_today, INTERVAL 210 DAY), 1000, '8590077105033', 18.90, 3480, 110, 15, 710, 30, @seed_s_zeleni_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tereos Cukr krupice bílý', DATE_ADD(@seed_today, INTERVAL 730 DAY), 1000, '8594000230274', 22.90, 4000, 0, 0, 1000, 0, @seed_s_zeleni_pantry_baking, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_baking);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 240 DAY), 500, '8594017144588', 29.90, 1770, 70, 26, 275, 80, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 180 DAY), 750, '8594017140863', 89.90, 3293, 63, 128, 443, 64, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 300 DAY), 350, '8590421061831', 79.90, 2212, 95, 175, 46, 20, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Medokomerc Med luční', DATE_ADD(@seed_today, INTERVAL 600 DAY), 900, '8594003430879', 149.90, 2952, 3, 0, 735, 0, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_condiments);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Opavia BeBe dobré ráno oříškové s medem', DATE_ADD(@seed_today, INTERVAL 150 DAY), 400, '8593894805551', 59.90, 1788, 31, 60, 260, 30, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_sweets);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Alesto Mandle natural', DATE_ADD(@seed_today, INTERVAL 180 DAY), 200, '20724696', 54.90, 1242, 49, 107, 10, 24, @seed_s_zeleni_pantry_breakfast, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Napoletana rajčatová omáčka', DATE_ADD(@seed_today, INTERVAL 360 DAY), 400, '3038354250908', 49.90, 204, 6, 6, 33, 6, @seed_s_zeleni_pantry_cans, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cans);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL 8 DAY), 500, '20051426', 27.90, 1290, 48, 28, 210, 33, @seed_s_zeleni_pantry_bread, NULL, NULL, NULL, NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);

-- 5. Spotřeba po běžných porcích: každá domácnost 80 záznamů za posledních 60 dnů.
-- Hmotnosti těstovin/rýže/vloček jsou v suchém stavu. Spotřeba patří pouze členům dané domácnosti.
-- Novákovi
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -55 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -59 DAY), '07:05:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 122 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '08:12:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -54 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '07:19:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 183 DAY), 80, '3038351683808', 5.58, 289, 10, 2, 58, 3, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '12:32:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -44 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -56 DAY), '08:26:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -50 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -55 DAY), '07:33:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -48 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '08:40:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 186 DAY), 90, '3038351665002', 6.28, 325, 11, 2, 65, 3, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '18:20:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 97 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -53 DAY), '07:47:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -47 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '08:54:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -48 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_novakovi_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '07:11:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 249 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '12:53:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -45 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -50 DAY), '08:18:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 71 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -49 DAY), '07:25:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -44 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '08:32:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 42 DAY), 180, '20466190', 34.07, 122, 27, 1, 0, 0, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '18:41:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 133 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -47 DAY), '07:39:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -43 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '08:46:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -33 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '07:53:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 75 DAY), 183, '4001724037576', 35.05, 415, 14, 20, 40, 3, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '12:29:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -39 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -44 DAY), '08:10:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -37 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -43 DAY), '07:17:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 108 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '08:24:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 108 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '18:17:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -36 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -41 DAY), '07:31:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -37 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_novakovi_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '08:38:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -34 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '07:45:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 81 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '12:50:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 82 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -38 DAY), '08:52:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -33 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -37 DAY), '07:09:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 144 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '08:16:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 84 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '18:38:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables), (@seed_food, @seed_c_novakovi_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -32 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -35 DAY), '07:23:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -22 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '08:30:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -28 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '07:37:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 327 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_novakovi_pantry_cans, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '12:26:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -26 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -32 DAY), '08:44:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 119 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -31 DAY), '07:51:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -25 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '08:08:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 120 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '18:14:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -26 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_novakovi_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -29 DAY), '07:15:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -23 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '08:22:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 93 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '07:29:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 93 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '12:47:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -22 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -26 DAY), '08:36:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 155 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -25 DAY), '07:43:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -21 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '08:50:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 216 DAY), 80, '3038351683808', 5.58, 289, 10, 2, 58, 3, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '18:35:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -11 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -23 DAY), '07:07:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -17 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '08:14:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -15 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '07:21:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 219 DAY), 90, '3038351665002', 6.28, 325, 11, 2, 65, 3, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '12:23:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 130 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -20 DAY), '08:28:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -14 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -19 DAY), '07:35:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -15 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_novakovi_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '08:42:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 282 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_novakovi_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '18:11:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -12 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -17 DAY), '07:49:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 104 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '08:06:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -11 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '07:13:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 75 DAY), 180, '20466190', 34.07, 122, 27, 1, 0, 0, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '12:44:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 166 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -14 DAY), '08:20:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -10 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -13 DAY), '07:27:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL 0 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '08:34:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 108 DAY), 183, '4001724037576', 35.05, 415, 14, 20, 40, 3, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '18:32:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -6 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -11 DAY), '07:41:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -4 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '08:48:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 141 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '07:05:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 141 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_novakovi_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '12:20:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -3 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -8 DAY), '08:12:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -4 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_novakovi_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -7 DAY), '07:19:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -1 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_novakovi_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '08:26:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 114 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '18:53:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 115 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -5 DAY), '07:33:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL 0 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_novakovi_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '08:40:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 177 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_novakovi_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '07:47:00'), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 117 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_novakovi_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '12:41:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables), (@seed_food, @seed_c_novakovi_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL 1 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_novakovi_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -2 DAY), '08:54:00'), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL 11 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_novakovi_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -1 DAY), '07:11:00'), NULL, NULL, @seed_u_jana);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 5 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_novakovi_fridge_top, DATE_SUB(@seed_now, INTERVAL 120 MINUTE), NULL, NULL, @seed_u_petr);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 360 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_novakovi_pantry_cans, DATE_SUB(@seed_now, INTERVAL 30 MINUTE), NULL, NULL, @seed_u_jan);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_fish);
-- Studentský byt
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -47 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -59 DAY), '07:14:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -53 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '08:21:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -51 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '07:28:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 243 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_studenti_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '12:37:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 94 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -56 DAY), '08:35:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -50 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -55 DAY), '07:42:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -51 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_studenti_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '08:49:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 36 DAY), 180, '20466190', 34.07, 122, 27, 1, 0, 0, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '18:25:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -48 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -53 DAY), '07:06:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 68 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '08:13:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -47 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '07:20:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 69 DAY), 183, '4001724037576', 35.05, 415, 14, 20, 40, 3, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '12:13:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 130 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -50 DAY), '08:27:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -46 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_studenti_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -49 DAY), '07:34:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -36 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '08:41:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 102 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '18:46:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -42 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -47 DAY), '07:48:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -40 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '08:05:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 105 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '07:12:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 75 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '12:34:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -39 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -44 DAY), '08:19:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -40 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_studenti_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -43 DAY), '07:26:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -37 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '08:33:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 78 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '18:22:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables), (@seed_food, @seed_c_studenti_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 79 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -41 DAY), '07:40:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -36 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '08:47:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 141 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '07:54:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 321 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_studenti_pantry_cans, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '12:10:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -35 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_studenti_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -38 DAY), '08:11:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -25 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -37 DAY), '07:18:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -31 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '08:25:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 114 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '18:43:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -29 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -35 DAY), '07:32:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 116 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '08:39:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -28 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '07:46:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 87 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '12:31:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -29 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_studenti_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -32 DAY), '08:53:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -26 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -31 DAY), '07:10:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 90 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '08:17:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 210 DAY), 80, '3038351683808', 5.58, 289, 10, 2, 58, 3, @seed_s_studenti_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '18:19:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -25 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -29 DAY), '07:24:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 152 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '08:31:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -24 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_studenti_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '07:38:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 213 DAY), 90, '3038351665002', 6.28, 325, 11, 2, 65, 3, @seed_s_studenti_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '12:52:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -14 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -26 DAY), '08:45:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -20 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -25 DAY), '07:52:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -18 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '08:09:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 276 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_studenti_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '18:40:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 127 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -23 DAY), '07:16:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -17 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '08:23:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -18 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_studenti_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '07:30:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Ocean Sea filety z tresky aljašské', DATE_ADD(@seed_today, INTERVAL 69 DAY), 180, '20466190', 34.07, 122, 27, 1, 0, 0, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '12:28:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -15 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -20 DAY), '08:37:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 101 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -19 DAY), '07:44:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -14 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '08:51:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Dr. Oetker Ristorante Pizza Funghi', DATE_ADD(@seed_today, INTERVAL 102 DAY), 183, '4001724037576', 35.05, 415, 14, 20, 40, 3, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '18:16:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 163 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -17 DAY), '07:08:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -13 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_studenti_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '08:15:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL -3 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '07:22:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 135 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_studenti_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '12:49:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -9 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -14 DAY), '08:29:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -7 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -13 DAY), '07:36:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 138 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '08:43:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 108 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '18:37:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -6 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -11 DAY), '07:50:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -7 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_studenti_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '08:07:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -4 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_studenti_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '07:14:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 111 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '12:25:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables), (@seed_food, @seed_c_studenti_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 112 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -8 DAY), '08:21:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -3 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -7 DAY), '07:28:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 174 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '08:35:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Franz Josef Tuňák – pevný podíl', DATE_ADD(@seed_today, INTERVAL 354 DAY), 120, '8595241525402', 39.90, 144, 32, 1, 0, 0, @seed_s_studenti_pantry_cans, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '18:13:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fish);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -2 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_studenti_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -5 DAY), '07:42:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vejce M – 6 ks (jedlý podíl)', DATE_ADD(@seed_today, INTERVAL 8 DAY), 100, '', 14.97, 143, 13, 10, 1, 0, @seed_s_studenti_fridge_protein, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '08:49:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 2 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '07:06:00'), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 147 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_studenti_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '12:46:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL 4 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_studenti_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -2 DAY), '08:13:00'), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 149 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_studenti_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -1 DAY), '07:20:00'), NULL, NULL, @seed_u_eva);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL 5 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_studenti_fridge_dairy, DATE_SUB(@seed_now, INTERVAL 120 MINUTE), NULL, NULL, @seed_u_tereza);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 120 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_studenti_freezer_produce, DATE_SUB(@seed_now, INTERVAL 30 MINUTE), NULL, NULL, @seed_u_martin);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
-- Zelení
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -54 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -59 DAY), '07:23:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -55 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '08:30:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -52 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '07:37:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 63 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -57 DAY), '12:42:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 64 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -56 DAY), '08:44:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -51 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -55 DAY), '07:51:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 126 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '08:08:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 66 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -54 DAY), '18:30:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables), (@seed_food, @seed_c_zeleni_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -50 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -53 DAY), '07:15:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -47 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '08:22:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -45 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '07:29:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 99 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -51 DAY), '12:18:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 100 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -50 DAY), '08:36:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -44 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -49 DAY), '07:43:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -45 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '08:50:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 72 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -48 DAY), '18:51:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -42 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -47 DAY), '07:07:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 74 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '08:14:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -41 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '07:21:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 195 DAY), 80, '3038351683808', 5.58, 289, 10, 2, 58, 3, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -45 DAY), '12:39:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 136 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -44 DAY), '08:28:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -40 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -43 DAY), '07:35:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -37 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '08:42:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 198 DAY), 90, '3038351665002', 6.28, 325, 11, 2, 65, 3, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -42 DAY), '18:27:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -35 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -41 DAY), '07:49:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 110 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '08:06:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -34 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '07:13:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 261 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -39 DAY), '12:15:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -35 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -38 DAY), '08:20:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -32 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -37 DAY), '07:27:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 84 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '08:34:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 114 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_zeleni_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -36 DAY), '18:48:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -31 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -35 DAY), '07:41:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 146 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '08:48:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -30 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '07:05:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 87 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -33 DAY), '12:36:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -27 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -32 DAY), '08:12:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -25 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -31 DAY), '07:19:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 120 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '08:26:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 90 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -30 DAY), '18:24:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables), (@seed_food, @seed_c_zeleni_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -24 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -29 DAY), '07:33:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -25 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '08:40:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -22 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '07:47:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 123 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -27 DAY), '12:12:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 94 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -26 DAY), '08:54:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -21 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -25 DAY), '07:11:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 156 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '08:18:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 96 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -24 DAY), '18:45:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -20 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -23 DAY), '07:25:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -17 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '08:32:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -15 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '07:39:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Penne', DATE_ADD(@seed_today, INTERVAL 219 DAY), 80, '3038351683808', 5.58, 289, 10, 2, 58, 3, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -21 DAY), '12:33:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 130 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -20 DAY), '08:46:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -14 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -19 DAY), '07:53:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -15 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '08:10:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Panzani Špagety', DATE_ADD(@seed_today, INTERVAL 222 DAY), 90, '3038351665002', 6.28, 325, 11, 2, 65, 3, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -18 DAY), '18:21:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_pasta);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -12 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -17 DAY), '07:17:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 104 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '08:24:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -11 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '07:31:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Menu Gold Rýže jasmínová', DATE_ADD(@seed_today, INTERVAL 285 DAY), 75, '8595237415014', 4.12, 264, 4, 0, 62, 0, @seed_s_zeleni_pantry_pasta, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -15 DAY), '12:54:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_rice);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 166 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -14 DAY), '08:38:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -10 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -13 DAY), '07:45:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -7 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '08:52:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Vici Gyoza zeleninové taštičky', DATE_ADD(@seed_today, INTERVAL 138 DAY), 200, '4770190078702', 44.95, 292, 10, 4, 52, 4, @seed_s_zeleni_freezer_meals, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -12 DAY), '18:42:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_meals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -5 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -11 DAY), '07:09:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 140 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '08:16:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -4 DAY), 200, '8594001171583', 18.90, 184, 7, 6, 26, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '07:23:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Česká chuť Špenátový protlak', DATE_ADD(@seed_today, INTERVAL 111 DAY), 150, '8590421076538', 7.46, 39, 5, 1, 1, 3, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -9 DAY), '12:30:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -5 DAY), 250, '8593807204716', 8.23, 165, 8, 10, 12, 0, @seed_s_zeleni_fridge_door, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -8 DAY), '08:30:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Lučina čerstvý sýr', DATE_ADD(@seed_today, INTERVAL -2 DAY), 40, '8594008278742', 11.09, 97, 2, 9, 1, 0, @seed_s_zeleni_fridge_dairy, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -7 DAY), '07:37:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nature’s Promise Arašídová pomazánka jemná', DATE_ADD(@seed_today, INTERVAL 114 DAY), 25, '8590421061831', 5.71, 158, 7, 13, 3, 1, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '08:44:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Agro Jesenice Český hrášek', DATE_ADD(@seed_today, INTERVAL 114 DAY), 150, '8590186263877', 10.97, 140, 9, 1, 18, 7, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -6 DAY), '18:18:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables), (@seed_food, @seed_c_zeleni_legumes);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Milko Řecký jogurt bílý 0 %', DATE_ADD(@seed_today, INTERVAL -1 DAY), 140, '85955790', 22.90, 80, 14, 0, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -5 DAY), '07:51:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Ovesné vločky jemné s vlákninou', DATE_ADD(@seed_today, INTERVAL 176 DAY), 60, '8594017144588', 3.59, 212, 8, 3, 33, 10, @seed_s_zeleni_pantry_breakfast, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '08:08:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL 0 DAY), 100, '20051426', 5.58, 258, 10, 6, 42, 7, @seed_s_zeleni_pantry_bread, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '07:15:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrazivá čerstvost zeleninová směs s kukuřicí', DATE_ADD(@seed_today, INTERVAL 147 DAY), 200, '8594046805054', 12.40, 88, 4, 1, 14, 6, @seed_s_zeleni_freezer_produce, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -3 DAY), '12:51:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL 3 DAY), 150, '8593803311517', 28.90, 179, 17, 11, 5, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -2 DAY), '08:22:00'), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL 5 DAY), 180, '8594001170012', 10.76, 121, 7, 7, 8, 0, @seed_s_zeleni_fridge_top, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -1 DAY), '07:29:00'), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Emco Mysli čokoláda a ořechy', DATE_ADD(@seed_today, INTERVAL 150 DAY), 60, '8594017140863', 7.19, 263, 5, 10, 35, 5, @seed_s_zeleni_pantry_breakfast, DATE_SUB(@seed_now, INTERVAL 120 MINUTE), NULL, NULL, @seed_u_tomas);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cereals);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Nowaco Polévková zeleninová směs', DATE_ADD(@seed_today, INTERVAL 120 DAY), 200, '8594001041282', 14.23, 76, 3, 1, 14, 5, @seed_s_zeleni_freezer_produce, DATE_SUB(@seed_now, INTERVAL 30 MINUTE), NULL, NULL, @seed_u_lucie);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);

-- 6. Vyhozené zbytky: bez konzumenta a bez data konzumace, trvanlivost před vyhozením.
-- Novákovi
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -59 DAY), 120, '8594001170012', 7.18, 80, 5, 4, 5, 0, @seed_s_novakovi_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '19:10:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -54 DAY), 80, '8593803311517', 15.41, 95, 9, 6, 2, 0, @seed_s_novakovi_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '19:19:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL -47 DAY), 80, '8593807332105', 13.16, 250, 2, 26, 2, 0, @seed_s_novakovi_fridge_dairy, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '19:28:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -42 DAY), 200, '8593807204716', 6.58, 132, 7, 8, 9, 0, @seed_s_novakovi_fridge_door, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '19:37:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -35 DAY), 120, '20051426', 6.70, 310, 11, 7, 50, 8, @seed_s_novakovi_pantry_bread, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '19:46:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL -30 DAY), 120, '', 7.96, 17, 1, 0, 3, 1, @seed_s_novakovi_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '19:10:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -23 DAY), 100, '', 11.96, 18, 1, 0, 3, 1, @seed_s_novakovi_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '19:19:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL -18 DAY), 150, '', 17.45, 44, 2, 0, 7, 3, @seed_s_novakovi_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '19:28:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL -11 DAY), 150, '', 4.47, 53, 1, 0, 10, 4, @seed_s_novakovi_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '19:37:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Pikok Kuřecí prsní šunka', DATE_ADD(@seed_today, INTERVAL -6 DAY), 50, '20837112', 14.95, 46, 10, 1, 0, 0, @seed_s_novakovi_fridge_protein, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '19:46:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_novakovi_meat);
-- Studentský byt
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -59 DAY), 120, '8594001170012', 7.18, 80, 5, 4, 5, 0, @seed_s_studenti_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '19:17:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -54 DAY), 80, '8593803311517', 15.41, 95, 9, 6, 2, 0, @seed_s_studenti_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '19:26:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL -47 DAY), 80, '8593807332105', 13.16, 250, 2, 26, 2, 0, @seed_s_studenti_fridge_dairy, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '19:35:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -42 DAY), 200, '8593807204716', 6.58, 132, 7, 8, 9, 0, @seed_s_studenti_fridge_door, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '19:44:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -35 DAY), 120, '20051426', 6.70, 310, 11, 7, 50, 8, @seed_s_studenti_pantry_bread, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '19:53:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL -30 DAY), 120, '', 7.96, 17, 1, 0, 3, 1, @seed_s_studenti_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '19:17:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -23 DAY), 100, '', 11.96, 18, 1, 0, 3, 1, @seed_s_studenti_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '19:26:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL -18 DAY), 150, '', 17.45, 44, 2, 0, 7, 3, @seed_s_studenti_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '19:35:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL -11 DAY), 150, '', 4.47, 53, 1, 0, 10, 4, @seed_s_studenti_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '19:44:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Pikok Kuřecí prsní šunka', DATE_ADD(@seed_today, INTERVAL -6 DAY), 50, '20837112', 14.95, 46, 10, 1, 0, 0, @seed_s_studenti_fridge_protein, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '19:53:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_studenti_meat);
-- Zelení
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt bílý', DATE_ADD(@seed_today, INTERVAL -59 DAY), 120, '8594001170012', 7.18, 80, 5, 4, 5, 0, @seed_s_zeleni_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -58 DAY), '19:24:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_plain);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Madeta Jihočeský cottage', DATE_ADD(@seed_today, INTERVAL -54 DAY), 80, '8593803311517', 15.41, 95, 9, 6, 2, 0, @seed_s_zeleni_fridge_top, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -52 DAY), '19:33:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_cheese);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma čerstvá smetana ke šlehání 33 %', DATE_ADD(@seed_today, INTERVAL -47 DAY), 80, '8593807332105', 13.16, 250, 2, 26, 2, 0, @seed_s_zeleni_fridge_dairy, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -46 DAY), '19:42:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Olma Selské čerstvé mléko plnotučné 3,9 %', DATE_ADD(@seed_today, INTERVAL -42 DAY), 200, '8593807204716', 6.58, 132, 7, 8, 9, 0, @seed_s_zeleni_fridge_door, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -40 DAY), '19:51:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_milk);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Tastino Toastový chléb', DATE_ADD(@seed_today, INTERVAL -35 DAY), 120, '20051426', 6.70, 310, 11, 7, 50, 8, @seed_s_zeleni_pantry_bread, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -34 DAY), '19:15:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_bread);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Okurka salátová – 1 ks', DATE_ADD(@seed_today, INTERVAL -30 DAY), 120, '', 7.96, 17, 1, 0, 3, 1, @seed_s_zeleni_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -28 DAY), '19:24:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Rajčata cherry', DATE_ADD(@seed_today, INTERVAL -23 DAY), 100, '', 11.96, 18, 1, 0, 3, 1, @seed_s_zeleni_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -22 DAY), '19:33:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Paprika červená – 2 ks', DATE_ADD(@seed_today, INTERVAL -18 DAY), 150, '', 17.45, 44, 2, 0, 7, 3, @seed_s_zeleni_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -16 DAY), '19:42:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Mrkev čerstvá', DATE_ADD(@seed_today, INTERVAL -11 DAY), 150, '', 4.47, 53, 1, 0, 10, 4, @seed_s_zeleni_fridge_produce, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -10 DAY), '19:51:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_vegetables);
INSERT INTO `FoodEntity` (`name`, `expiry`, `weight`, `barcode`, `price`, `calories`, `protein`, `fat`, `carb`, `fibre`, `shelf_id`, `consumedAt`, `trashed`, `discardedAt`, `consumer_id`)
VALUES ('Hollandia Selský jogurt jahoda', DATE_ADD(@seed_today, INTERVAL -6 DAY), 80, '8594001171583', 7.56, 74, 3, 2, 10, 0, @seed_s_zeleni_fridge_dairy, NULL, 1, TIMESTAMP(DATE_ADD(@seed_today, INTERVAL -4 DAY), '19:15:00'), NULL);
SET @seed_food = LAST_INSERT_ID();
INSERT INTO `categoryentity_foodentity` (`foodentity_id`, `categoryentity_id`) VALUES (@seed_food, @seed_c_zeleni_fruit_yogurt);

COMMIT;
