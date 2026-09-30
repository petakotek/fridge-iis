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

Pro produkci se lokální síťový DSN nahradí unixovým socketem:

```text
mysql:unix_socket=/var/run/mysql/mysql.sock;dbname=xvoldrv00;charset=utf8mb4
```

Composer je dostupný v PHP kontejneru:

```bash
cd .development
docker compose exec php composer --version
```
