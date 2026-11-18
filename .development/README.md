# IIS project 2026

## Lokální vývojové prostředí

http://localhost:8080/~xvoldrv00/


Prostředí zrcadlí produkční kombinaci Apache + FastCGI, PHP 8.4.24 a
MariaDB 11.8.8. Zdrojový adresář `src` je připojen jako obsah produkčního
adresáře `WWW` a aplikace používá prefix `/~xvoldrv00/`.

Spuštění:

```bash
cd .development
docker compose up -d
```

Po změně některého z Dockerfile použijte jednorázově `docker compose up -d --build`.

Aplikace je poté dostupná na:

```text
http://localhost:8080/~xvoldrv00/
```

Požadavek na `http://localhost:8080/` se na produkční prefix přesměruje.

Výchozí lokální databáze:

```text
host z PHP kontejneru: database:3306
host z počítače:       localhost:33060
databáze:              xvoldrv00
uživatel:              iis
heslo:                 iis
root heslo:            root
```

Výchozí hodnoty lze změnit zkopírováním `.development/.env.example` do
`.development/.env`. Databázové schéma se automaticky neimportuje.

## Zachování databáze mezi spuštěními

MariaDB ukládá data do pojmenovaného Docker volume
`iis-project-2026_database-data`, připojeného na `/var/lib/mysql`.
Volume uchovává tabulky, jejich data i evidenci provedených migrací nezávisle
na životnosti kontejneru. Compose používá pevný název projektu `iis-project-2026`;
pro běžnou práci jej nepřepisujte pomocí `-p` nebo `COMPOSE_PROJECT_NAME`,
protože jiný projekt použije jiný volume.

Následující příkazy spouštějte ze složky `.development`.
Pro vypnutí prostředí se zachováním kontejnerů použijte:

```bash
docker compose stop
```

Při další práci stačí:

```bash
docker compose up -d
```

`docker compose down` odstraní kontejnery a síť, ale tento pojmenovaný volume
ponechá; další `up -d` jej znovu připojí. **`docker compose down -v` odstraní
i databázový volume a jeho data.**

Migrace aplikujte při úplně prvním vytvoření schématu v prázdném volume a poté
při přidání nových migrací, nikoli při každém spuštění kontejnerů:

```bash
docker compose exec php php vendor/bin/doctrine-migrations status
docker compose exec php php vendor/bin/doctrine-migrations migrate
```

Příkaz `migrate` provádí pouze dosud neprovedené migrace. Samotné `up -d`
migrace nespouští. Obnovení či sestavení image databázový volume nemaže.

## Systémový administrátor

Migrace `Version20261116190000` vytvoří administrátorský účet bez členství
v domácnosti. Před jejím prvním spuštěním lze v `src/.env` nastavit
`ADMIN_EMAIL` a `ADMIN_PASSWORD` podle `src/.env.example`. Při shodě e-mailu
s existujícím účtem se migrace zastaví; existující účet nepovyšuje.
Pozdější změna těchto hodnot heslo již vytvořeného účtu nemění.

Po přihlášení se administrátor dostane do `/admin`, kde spravuje profily,
hesla a role uživatelů. V `/admin/households` vytváří, přejmenovává a maže
domácnosti, přidává a odebírá členy a určuje správce. Uživatel může patřit
jen do jedné domácnosti; administrátor nemůže být jejím členem ani správcem.
Při odebrání nebo smazání správce domácnost zůstane bez správce, dokud jí
administrátor neurčí jiného. Smazání domácnosti zachová uživatelské účty.
Vlastní účet nelze smazat ani si odebrat administrátorskou roli.

## Archiv pro odevzdání a přípravu nasazení

Následující příkazy se spouštějí z kořene repozitáře. Fungují také ze složky
`.development`. Pro balení je potřeba Python 3.

```bash
make submission
```

`submission` vytvoří `.development/dist/xvoldrv00.zip`: zdrojové kódy,
`doc.html`, obrázky dokumentace, migrace, konfigurační příklady a nástroje
pro sestavení. Soubor `naplneni_db.sql` se do archivu nepřidává.
Vynechá knihovny, Node.js závislosti, sestavený frontend, místní
`.env`, cache a logy. Ověří odkazy na soubory v dokumentaci a limit 5 MB.
Závislosti a frontend se po rozbalení připraví podle návodu v `doc.html`.

Login v názvu archivu lze přepsat:

```bash
make submission LOGIN=xlogin00
```

Stejný archiv slouží jako zdroj pro nasazení. Po rozbalení v jeho složce
`src` nainstalujte závislosti a sestavte frontend:

```bash
composer install --no-dev --prefer-dist --optimize-autoloader
npm ci
npm run build
```

Konfigurace `.env` s `env=prod`, přenos aplikace na server, přístupová práva
a databázové migrace jsou popsané v `doc.html`. Balicí příkaz pouze vytvoří ZIP.

## Produkční připojení k databázi

Pro produkci se lokální síťový DSN nahradí unixovým socketem:

```text
mysql:unix_socket=/var/run/mysql/mysql.sock;dbname=xvoldrv00;charset=utf8mb4
```

Composer je dostupný v PHP kontejneru:

```bash
cd .development
docker compose exec php composer --version
```
