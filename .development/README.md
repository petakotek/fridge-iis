# IIS project 2026

## Lokální vývojové prostředí

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

## Další nastavení

Pro produkci se lokální síťový DSN nahradí unixovým socketem:

```text
mysql:unix_socket=/var/run/mysql/mysql.sock;dbname=xvoldrv00;charset=utf8mb4
```

Composer je dostupný v PHP kontejneru:

```bash
cd .development
docker compose exec php composer --version
```
