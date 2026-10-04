Nette Web Project
=================

## Databázové migrace

Změny databázového schématu spravujeme pomocí Doctrine Migrations. Migrační soubory
jsou uložené v `src/migrations` a verzujeme je v Gitu.

Všechny příkazy níže spouštěj **z kořene repozitáře**, kde se nachází složka
`.development`, nikoliv ze složky `src`, ve které je tento README.

### Po stažení změn z Gitu

Při prvním spuštění projektu připrav `src/.env` podle `src/.env.example`
a nastav připojení k databázi. Existující `.env` nepřepisuj; případné nové
proměnné doplň podle ukázkového souboru.

Spusť PHP kontejner a databázi:

```bash
docker compose -f .development/compose.yaml up -d php
```

Nainstaluj závislosti podle aktuálního `composer.lock`:

```bash
docker compose -f .development/compose.yaml exec php composer install
```

Aplikuj dosud neprovedené migrace:

```bash
docker compose -f .development/compose.yaml exec php php vendor/bin/doctrine-migrations migrate
```

Doctrine eviduje provedené migrace v databázi a již aplikované migrace znovu
nespouští. **Po `git pull` negeneruj novou migraci pro změny, které už mají
migrační soubor.**

Aktuální stav zobrazíš příkazem:

```bash
docker compose -f .development/compose.yaml exec php php vendor/bin/doctrine-migrations status
```

### Vytvoření nové migrace po změně entity

Nejprve aplikuj existující migrace podle předchozího postupu, aby lokální databáze
odpovídala aktuálnímu stavu projektu. Potom uprav mapování entit a ověř jeho
správnost:

```bash
docker compose -f .development/compose.yaml exec php php bin/check_doctrine.php
```

Vygeneruj novou migraci:

```bash
docker compose -f .development/compose.yaml exec php php vendor/bin/doctrine-migrations diff
```

Příkaz porovná mapování entit s aktuální databází a vytvoří soubor v
`src/migrations`. Samotné změny databázového schématu ještě neprovede. Díky
sdílené složce Dockeru se soubor vytvořený v kontejneru objeví i lokálně v projektu.
Změna běžné PHP metody bez změny mapování migraci nevyžaduje.

**Vygenerovaný soubor vždy zkontroluj**, zejména mazání tabulek nebo sloupců,
přejmenování a pravidla cizích klíčů. Automaticky vytvořená migrace může potřebovat
ruční úpravu nebo doplnění převodu existujících dat.

SQL před provedením zobrazíš pomocí:

```bash
docker compose -f .development/compose.yaml exec php php vendor/bin/doctrine-migrations migrate --dry-run
```

Potom migraci aplikuj:

```bash
docker compose -f .development/compose.yaml exec php php vendor/bin/doctrine-migrations migrate
```

Do stejného commitu zahrň změny entit i nový migrační soubor. Pokud se změnily
závislosti, přidej také `src/composer.json` a `src/composer.lock`. Již sdílené nebo
aplikované migrace nepřepisuj; další změny řeš novou migrací.

Před migrací databáze s důležitými daty vytvoř zálohu. Náhled `--dry-run`
nenahrazuje ověření migrace na testovací databázi.
