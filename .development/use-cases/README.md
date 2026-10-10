# Případy užití — Lednice

Podklady: [lednice.md](../lednice.md), [obecne_zadani.md](../obecne_zadani.md),
[sablona.md](../sablona.md)
a doplnění požadavků na registraci, členství a sdílení pomocí tokenu.
Diagramy popisují požadované chování, nikoli stav implementace.

## Soubory

| Graphviz soubor | Obsah |
| --- | --- |
| [06-souhrn.dot](06-souhrn.dot) | Stručný samostatný diagram všech rolí a hlavních funkcí; bez rozpadu na jednotlivé CRUD operace a podpůrné případy. |
| [00-prehled.dot](00-prehled.dot) | Souhrnný přehled funkcí a dědičnost rolí. |
| [01-ucet-a-pristup.dot](01-ucet-a-pristup.dot) | Registrace, přihlášení, profil, založení domácnosti a přístup přes token. |
| [02-clenstvi-a-token.dot](02-clenstvi-a-token.dot) | Žádosti, schválení a zamítnutí, správa členů a sdíleného tokenu. |
| [03-spotrebice-policky-kategorie.dot](03-spotrebice-policky-kategorie.dot) | Správa spotřebičů, poliček, nosnosti a víceúrovňových kategorií. |
| [04-potraviny-a-spotreba.dot](04-potraviny-a-spotreba.dot) | Obsah spotřebičů, přidání potravin, konzumace, vyhození a vlastní profil spotřeby. |
| [05-administrace.dot](05-administrace.dot) | Správa uživatelských účtů a systémových rolí. |

Čísla případů užití jsou napříč soubory stejná. Opakovaný uzel představuje
tentýž případ, nikoli další funkci. Přehled `00` používá souhrnné ovály
s odkazy na čísla podrobných případů; úplný rozpad je v diagramech `01–05`.
Nový souhrn `06` číslování nepotřebuje a lze jej číst samostatně.

## Je nutné diagram odevzdávat?

[Šablona dokumentace](../sablona.md) uvádí:

> (Diagram případů užití není nutné vkládat, pokud IS implementuje role a případy užití definované zadáním.)

Tuto větu vykládáme jako možnost vynechat diagram případů užití z `doc.html`,
pokud hotová aplikace realizuje role, jejich oprávnění a požadované činnosti
ze zadání. Hodnotitel pak může vycházet přímo ze zadání. Nejde o výjimku
z implementace požadavků ani o zrušení analýzy a návrhu z obecného zadání.
Věta neříká „pouze případy ze zadání“, takže z ní nevyvozujeme zákaz rozšíření.
Jde o interpretaci dodaného textu, nikoli potvrzený výklad vyučujícího.

Aby šlo tuto možnost využít, výsledná aplikace musí zachovat:

- všechny role a dědičnost práv uvedenou v `lednice.md`;
- všechny povinné funkce: správu uživatelů, profilů, domácností, členů,
  spotřebičů, poliček a kategorií, evidenci potravin, kontrolu nosnosti,
  upozornění na trvanlivost, konzumaci/vyhození a vlastní profil spotřeby;
- registraci a prohlížení pro hosta bez editace, přihlášení/odhlášení,
  ukončení relace při nečinnosti a pravidla validace z obecného zadání.

Samostatně dál platí požadavky na dokumentaci: uvést existující testovací
zástupce rolí (hosta lze popsat jako nepřihlášený přístup přes ukázkový odkaz),
popsat přiřazení případů užití ke skutečným presenterům/službám, dodat video,
**grafické schéma relační databáze**, instalaci a známé nedostatky.
Výjimka se týká jen diagramu případů užití, nikoli databázového diagramu.

### Posouzení našeho návrhu

Návrh pokrývá povinné role a funkce; žádnou z nich vědomě neodebírá.
Zohledňuje opravený text zadání: administrátor pouze spravuje uživatele
a nedědí oprávnění správce domácnosti. Původní diagramy tuto již vyškrtnutou
dědičnost obsahovaly; v aktuálních zdrojích a exportech je odstraněna.
Sdílený odkaz/token zadání přímo uvádí. Žádosti o členství, schvalování,
kopírování a obměna tokenu konkretizují registraci, správu členů a sdílení.
Podle výše uvedeného výkladu tato doplnění sama o sobě nevyžadují diagram,
ale jejich chování je vhodné stručně popsat v dokumentaci.

Výslovné rozšíření oprávnění je **založení domácnosti libovolným registrovaným
uživatelem**, zatímco zadání tuto činnost vypisuje pod správcem. Náš návrh ji
správci zachovává a navíc umožňuje běžnému uživateli stát se správcem založením
vlastní domácnosti. Považujeme to za slučitelné doplnění, nelze ale tvrdit,
že jde o doslovně totožné rozdělení oprávnění. V dokumentaci je potřeba tento
přechod role vysvětlit; při striktním požadavku na shodu rolí by bylo nutné
omezit založení na již existujícího správce, nebo přiložit souhrnný diagram
vysvětlující rozšířený návrh. Samotný diagram nenahrazuje povinné funkce.

**Stav k 10. 10. 2026:** návrh je obsahově slučitelný se zadáním s výše popsaným
rozšířením. Implementace v tomto checkoutu podmínku zatím nesplňuje:
`src/app/Presentation/Home/HomePresenter.php` je prázdný presenter
a `Home/default.latte` je výchozí uvítací stránka Nette; v aplikačních zdrojích
zatím nejsou realizovány uvedené doménové funkce. Diagramy jsou návrh, ne důkaz
hotové implementace. Vynechání diagramu lze opřít o splněné zadání až po
implementaci a ověření těchto funkcí.

## Jak číst diagramy

- Panáček s názvem označuje roli, ovál případ užití a rámeček hranici systému.
- Plná čára bez šipky spojuje aktéra s jeho případem užití.
- Plná šipka s prázdným trojúhelníkem míří od specializované role k roli,
  jejíž práva dědí: správce → člen → registrovaný uživatel.
  Administrátor stojí mimo tuto hierarchii a spravuje uživatele.
- Přerušovaná šipka `«include»` míří k povinné zahrnuté činnosti.
- Přerušovaná šipka `«extend»` míří od podmíněného rozšíření k základnímu
  případu; podmínka je uvedena u šipky.
- Poznámky popisují podmínky, výsledky a pravidla. Tečkovaná čára není procesní tok.

Diagramy případů užití nevyjadřují časové pořadí operací. Například UC02
zahrnuje registraci i žádost, ale jejich pořadí stanoví scénář níže.
Přihlášení je předpoklad chráněných operací, proto se neopakuje jako `include`.
Automatické ukončení relace při nečinnosti je pravidlo systému uvedené u UC03.

## Role a scénáře členství

Host je neregistrovaný uživatel. Registrovaný uživatel může existovat bez členství
v jakékoli domácnosti. Členství a role správce se vztahují ke konkrétní domácnosti:
správce jedné domácnosti tím nezískává správu jiné. Správce dědí práva člena
a přes něj registrovaného uživatele; obě domácí role jsou v zadání zařazeny
pod registrovaným uživatelem. Administrátor je samostatná role pro správu
uživatelů a systémových rolí, nikoli nadřazená role správce domácnosti.
Samotné oprávnění administrátora neposkytuje členství, přístup k domácnostem
ani správu jejich obsahu. Přihlášení a odhlášení má explicitně podle obecného
zadání. Registrace se z hosta nedědí do přihlášených rolí.

1. **Samostatná registrace:** host provede UC01 s tokenem nebo bez tokenu,
   včetně možnosti registrace z detailu domácnosti bez žádosti o členství.
   Získá účet, ale nevznikne žádost ani členství. Přítomnost tokenu sama o sobě
   žádost neodesílá. Může následně založit domácnost nebo požádat o členství přes token.
2. **Registrace se žádostí z detailu domácnosti:** tato volba je hostovi dostupná
   pouze při prohlížení detailu dané domácnosti přes platný token. Samotná znalost
   tokenu mimo detail nestačí k zahájení tohoto scénáře. Host otevře odkaz nebo
   zadá token (UC07). Systém ověří token (UC08) a zobrazí detail s obsahem
   domácnosti (UC27). Host může zvolit jen UC01 bez žádosti, nebo zvolí UC02,
   zaregistruje se (UC01) a jako nově registrovaný uživatel odešle žádost (UC09)
   ke stejné domácnosti. Kontext tokenu se zachová a při žádosti znovu ověří.
   Samotné odeslání žádosti neuděluje členství.
3. **Žádost existujícího uživatele:** přihlášený uživatel s platným tokenem
   odešle UC09 pro domácnost určenou tokenem. Platí i pro uživatele, který už
   je členem nebo správcem jiné domácnosti.
4. **Založení domácnosti:** kterýkoli přihlášený registrovaný uživatel provede
   UC06. Vznikne domácnost a zakladatel se ihned stane jejím správcem se všemi
   právy člena. Nepotřebuje předem roli správce ani schválení žádosti.
5. **Vyřízení žádosti:** správce vybere čekající žádost své domácnosti.
   Přijetí (UC10) zahrnuje vytvoření členství (UC12); zamítnutí (UC11) členství
   nevytvoří. Zamítnutí žádosti samo o sobě nezneplatňuje sdílený token.
6. **Sdílení:** správce může předat odkaz s tokenem (UC15), zkopírovat samotný
   token (UC16) nebo jej přegenerovat (UC17). Nový token nahradí původní;
   starý token a odkazy s ním přestanou fungovat pro další přístup i nové žádosti.
   Existující členství tím nejsou dotčena. Token poskytuje pouze prohlížení,
   nikoli editaci nebo automatické přijetí do domácnosti.

## Seznam případů užití

| ID | Případ užití | Aktér / vyvolání |
| --- | --- | --- |
| UC01 | Zaregistrovat se | Host s tokenem i bez tokenu; samostatně bez žádosti, nebo jako součást UC02. |
| UC02 | Zaregistrovat se a požádat o členství v prohlížené domácnosti | Host pouze z detailu dané domácnosti zpřístupněného platným tokenem. |
| UC03 | Přihlásit se | Registrovaný uživatel nebo administrátor, jméno/e-mail a heslo. |
| UC04 | Odhlásit se | Přihlášený registrovaný uživatel nebo administrátor. |
| UC05 | Upravit vlastní profil | Přihlášený uživatel. |
| UC06 | Vytvořit domácnost a stát se jejím správcem | Přihlášený uživatel. |
| UC07 | Prohlédnout domácnost přes sdílený odkaz / token | Host nebo registrovaný uživatel. |
| UC08 | Ověřit token a určit příslušnou domácnost | Povinná součást UC07 a UC09. |
| UC09 | Požádat o členství v domácnosti pomocí tokenu | Přihlášený uživatel; také součást UC02. |
| UC10 | Přijmout žádost o členství | Správce domácnosti. |
| UC11 | Zamítnout žádost o členství | Správce domácnosti. |
| UC12 | Přidat žadatele mezi členy domácnosti | Povinná součást UC10. |
| UC13 | Odebrat člena z domácnosti | Správce domácnosti. |
| UC14 | Změnit roli člena (člen / správce) | Správce domácnosti. |
| UC15 | Sdílet / poslat odkaz s tokenem domácnosti | Správce domácnosti. |
| UC16 | Zkopírovat token domácnosti | Správce domácnosti. |
| UC17 | Přegenerovat token domácnosti | Správce domácnosti. |
| UC18 | Přidat spotřebič do domácnosti | Správce domácnosti. |
| UC19 | Upravit spotřebič | Správce domácnosti. |
| UC20 | Odebrat spotřebič | Správce domácnosti. |
| UC21 | Přidat poličku a určit její maximální nosnost | Správce domácnosti. |
| UC22 | Upravit poličku včetně maximální nosnosti | Správce domácnosti. |
| UC23 | Odebrat poličku | Správce domácnosti. |
| UC24 | Přidat kategorii včetně podkategorie | Správce domácnosti. |
| UC25 | Upravit kategorii a její nadřazenou kategorii | Správce domácnosti. |
| UC26 | Odebrat kategorii | Správce domácnosti. |
| UC27 | Prohlédnout obsah spotřebičů domácnosti | Člen; pro nečlena povinná součást UC07 po ověření tokenu. |
| UC28 | Přidat potravinu na poličku spotřebiče | Člen domácnosti. |
| UC29 | Ověřit nosnost poličky | Povinná součást UC28 a UC22. |
| UC30 | Označit potravinu jako zkonzumovanou | Člen domácnosti. |
| UC31 | Označit potravinu jako vyhozenou | Člen domácnosti. |
| UC32 | Zobrazit vlastní profil spotřeby za zvolené období | Člen domácnosti. |
| UC33 | Zobrazit upozornění na končící trvanlivost | Podmíněné rozšíření UC27. |
| UC34 | Přidat uživatelský účet a nastavit jeho roli | Administrátor. |
| UC35 | Upravit uživatelský účet | Administrátor. |
| UC36 | Deaktivovat uživatelský účet | Administrátor. |
| UC37 | Změnit systémovou roli (uživatel / administrátor) | Administrátor. |

Práva uvedená pro člena dědí správce; administrátor domácí práva nedědí.
UC08, UC12 a UC29 jsou podpůrné činnosti, nikoli samostatné cíle
uživatele. U správy objektů je výběr z přehledu součástí operace, nejde o další UC.

## Pokrytí zadání a návrhová rozhodnutí

Ze zadání je zahrnuta celá základní varianta: lednice i mrazáky, poličky s nosností,
víceúrovňové kategorie, údaje o potravinách, hlídání trvanlivosti, konzumace či
vyhození celé položky a vlastní profil spotřeby za den, týden nebo interval od–do.
Profil obsahuje seznam konzumace s časy, kalorický a nutriční příjem a cenu
zkonzumovaných potravin. Povinné údaje a pravidla jsou rozepsané u diagramu `04`.

Obecné zadání doplňuje správu účtů a rolí, přihlášení/odhlášení, ukončení relace
při nečinnosti a validace. Pravidla formulářů (odlišení povinných údajů, zachování
správně vyplněných polí po chybě, nápověda formátu, vhodné předvyplnění data,
výběr objektů místo opisování ID) platí napříč případy užití. Nejsou samostatnými
uživatelskými cíli. Totéž platí pro konzistenci databáze a kontrolu oprávnění.

Následující volby konkretizují místa, která zadání podrobně neurčuje:

- **Účty:** používá se deaktivace místo fyzického mazání, což obecné zadání
  výslovně umožňuje. Historie spotřeby tak zůstává zachována.
- **Správa členů a kategorií:** zahrnuje změnu domácí role, odebrání členství
  a vytvoření/úpravu/odebrání kategorií. Katalog je v návrhu veden u domácnosti.
- **Konzistence:** nelze odebrat posledního aktivního správce domácnosti ani
  posledního aktivního administrátora systému. Duplicitní čekající žádosti
  a duplicitní členství se nevytvářejí. Mazání používané poličky, spotřebiče
  či kategorie se odmítne; hierarchie kategorií nesmí obsahovat cyklus.
- **Konzument:** při označení potraviny za zkonzumovanou se zaznamená
  přihlášený uživatel jako konzument. Vyhození se eviduje zvlášť a nezapočítává
  se do nutričního příjmu ani ceny zkonzumovaných potravin.
- **Objem a nosnost:** u potraviny evidované v ml je pro kontrolu nosnosti
  potřeba evidovat i hmotnost. Nutriční výpočet použije množství v jednotce,
  ke které se vztahují hodnoty na 100 g/ml.
- **Upozornění:** návrh je zobrazuje při prohlížení obsahu spotřebičů, včetně
  prohlížení přes token. Konkrétní předstih před datem trvanlivosti není zadán.
- **Sdílení:** UC15 umožňuje získat a předat odkaz; nevyžaduje e-mailovou
  integraci. Domácnost dostane počáteční token při vytvoření. Přegenerování
  zneplatní původní token, ale neruší členství ani již podané čekající žádosti.

Volitelná rozšíření ze zadání (částečná konzumace, grafy, externí databáze,
nákupní seznamy a recepty) nejsou do základních diagramů přidána.

## Vykreslení

Panáčci používají znak U+1FBC5 z fontu **Noto Sans Symbols2**. Font je potřeba
mít nainstalovaný při vykreslení DOT i při otevření/editaci SVG na jiném počítači;
SVG ponechává panáčky a popisky jako textové objekty.

Z kořene repozitáře lze vygenerovat SVG všech diagramů pomocí Graphviz:

```bash
mkdir -p .development/use-cases/generated
for source in .development/use-cases/*.dot; do
    name=$(basename "$source" .dot)
    dot -Tsvg "$source" -o ".development/use-cases/generated/$name.svg"
done
```

Adresář `.development/dist/` je již ignorován Gitem. Pro PDF nebo PNG stačí
změnit `-Tsvg` a příponu výstupu na `-Tpdf`/`.pdf` nebo `-Tpng`/`.png`.
