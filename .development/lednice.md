# FIT lednice

Úkolem zadání je vytvořit informační systém pro správu potravin v domácnostech.
Základní jednotkou je domácnost, která sdružuje uživatele a vlastní libovolný počet spotřebičů (lednice, mrazák) rozdělených na poličky s definovanou maximální nosností.
Na poličce jsou uloženy konkrétní potraviny s datem trvanlivosti, hmotností/objemem, čárovým kódem, cenou a nutričními údaji (kalorická hodnota, bílkoviny, tuky, sacharidy, vláknina na 100 g/ml), zařazené do víceúrovňové kategorie (např. Mléčné výrobky -> Jogurty -> Bílé jogurty).
Systém hlídá, aby součet hmotností potravin na poličce nepřekročil její nosnost, a upozorňuje na končící trvanlivost.
U každé potraviny se dále eviduje, zda a kdy byla zkonzumována nebo vyhozena (v základní variantě vždy celá najednou).
Z těchto záznamů si uživatel nechá vypsat profil spotřeby za zvolené období (den, týden, od–do): co a kdy zkonzumoval, kalorický a nutriční příjem a cenu zkonzumovaných potravin.

Uživatelé budou moci informační systém používat následujícím způsobem:

    administrátor
        spravuje uživatele a domácnosti
        má práva správce domácnosti
    správce domácnosti
        spravuje spotřebiče domácnosti
        spravuje členy domácnosti a katalog kategorií potravin
        má práva registrovaného uživatele
    registrovaný uživatel (člen domácnosti)
        edituje profil, přidává potraviny do spotřebičů
        označuje potraviny jako zkonzumované nebo vyhozené
        vidí obsah spotřebičů domácnosti a svůj profil spotřeby
    host (neregistrovaný uživatel)
        prochází obsah spotřebičů domácnosti bez možnosti editace

Tipy na možná rozšíření:

    konzumace/vyhazování potravin po částech
    grafy kalorického a nutričního profilu v čase
    napojení na externí potravinové databáze dle čárového kódu
    automatické generování nákupního seznamu
    doporučení receptů dle dostupných surovin
