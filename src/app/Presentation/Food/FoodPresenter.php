<?php declare(strict_types=1);

namespace App\Presentation\Food;

use App\Model\Common\FoodNutrition;
use App\Model\Common\ProductLookupException;
use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\FoodService;
use App\Model\Services\CategoryService;
use App\Model\Entity\CategoryEntity;
use App\Model\Services\ProductLookupService;
use App\Model\Services\ShelfService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;
use Nette\Application\Attributes\Persistent;
use Nette\Forms\Controls\SubmitButton;
use Nette\Forms\Controls\TextInput;
use Nette\Forms\Form as FormAlias;
use Nette\Utils\Paginator;

final class FoodPresenter extends AuthenticatedPresenter
{
    /** @var array<string, mixed> */
    #[Persistent]
    public array $returnTo = [];

    private HouseholdEntity $household;
    private FoodEntity $food;

    /** @var array<int, ShelfEntity> */
    private array $availableShelves = [];

    public function __construct(
        UserService                       $users,
        private readonly FoodService      $foods,
        private readonly ShelfService     $shelves,
        private readonly ApplianceService $appliances,
        private readonly ProductLookupService $productLookup,
        private readonly CategoryService $categories,
    ) {
        parent::__construct($users);
    }

    public function renderDefault(): void
    {
        $this->template->household = $this->household;
    }

    protected function startup(): void
    {
        parent::startup();
        $household = $this->currentUser->getHousehold();
        if ($household === null) {
            $this->flashMessage('Pro správu potravin se nejprve připojte k domácnosti.', 'error');
            $this->redirect('Home:default');
        }
        $this->household = $household;
    }

    public function actionDefault(?int $shelfId = null, string $status = 'active', int $page = 1): void
    {
        $this->returnTo = [];
        if (!in_array($status, ['active', 'consumed', 'trashed'], true)) {
            $this->error('Neplatný stav potravin.', 404);
        }
        $this->loadAvailableShelves();
        $selectedShelf = $shelfId !== null ? $this->loadShelf($shelfId) : null;
        $paginator = new Paginator;
        $paginator->setItemsPerPage(15);
        $paginator->setItemCount($this->foods->getFoodCount(
            $this->household, $selectedShelf, $status, $this->currentUser,
        ));
        $paginator->setPage($page);
        $this->template->foods = $this->foods->getFoods(
            $this->household,
            $paginator->getItemsPerPage(),
            $paginator->getOffset(),
            $selectedShelf,
            $status,
            $this->currentUser,
        );
        $this->template->paginator = $paginator;
        $this->template->foodNavigation = [
            'source' => 'foods', 'shelfId' => $shelfId,
            'status' => $status, 'page' => $paginator->getPage(),
        ];
        $this->template->status = $status;
        $this->template->selectedShelf = $selectedShelf;
        $this->template->hasShelves = $this->availableShelves !== [];
    }

    public function actionAdd(?int $shelfId = null): void
    {
        $this->loadAvailableShelves();
        if ($shelfId !== null) {
            $this->loadShelf($shelfId);
        }
        $this->prepareNavigation($shelfId !== null ? [
            'source' => 'shelf', 'shelfId' => $shelfId,
        ] : []);
        $this->template->hasShelves = $this->availableShelves !== [];
    }

    public function actionDetail(int $id, ?int $shelfId = null): void
    {
        if ($shelfId !== null && $this->returnTo === []) {
            $this->returnTo = ['source' => 'shelf', 'shelfId' => $shelfId];
        }
        $this->loadFood($id);
    }

    public function actionEdit(int $id): void
    {
        $this->loadFood($id);
        $this->assertActiveFood();
    }

    public function actionDelete(int $id): void
    {
        $this->loadFood($id);
        $this->confirmation('Smazat potravinu', 'Potravina bude trvale smazána.', 'button-danger');
    }

    public function actionConsume(int $id): void
    {
        $this->loadFood($id);
        $this->assertActiveFood();
        $this->confirmation('Spotřebovat potravinu', 'Potravina bude označena jako spotřebovaná.', 'button-primary');
    }

    public function actionTrash(int $id): void
    {
        $this->loadFood($id);
        $this->assertActiveFood();
        $this->confirmation('Vyhodit potravinu', 'Potravina bude označena jako vyhozená.', 'button-danger');
    }

    public function actionRestore(int $id): void
    {
        $this->loadFood($id);
        $this->assertInactiveFood();
        $this->confirmation('Vrátit do zásob', 'Potravina bude vrácena na původní polici. Označení spotřeby nebo vyhození bude zrušeno.', 'button-primary');
    }

    private function loadAvailableShelves(): void
    {
        foreach ($this->appliances->getAppliances($this->household) as $appliances) {
            foreach ($this->shelves->getShelves($appliances) as $shelves) {
                $this->availableShelves[$shelves->getId()] = $shelves;
            }
        }
    }

    private function loadShelf(int $id): ShelfEntity
    {
        try {
            $shelf = $this->shelves->getShelfById($id);
        } catch (\DomainException) {
            $this->error('Police nebyla nalezena.', 404);
        }
        if ($shelf->getAppliance()?->getHousehold() !== $this->household) {
            $this->error('Police nebyla nalezena.', 404);
        }
        return $shelf;
    }

    private function loadFood(int $id): void
    {
        $food = $this->foods->getFoodById($id);
        if ($food === null || $food->getShelf()->getAppliance()?->getHousehold() !== $this->household) {
            $this->error('Potravina nebyla nalezena.', 404);
        }
        $this->food = $food;
        $this->template->food = $food;
        $this->prepareNavigation([
            'status' => $food->isConsumed() ? 'consumed' : ($food->isTrashed() ? 'trashed' : 'active'),
        ]);
    }

    /** @param array<string, mixed> $fallback */
    private function prepareNavigation(array $fallback = []): void
    {
        $navigation = array_replace(
            ['source' => 'foods', 'shelfId' => null, 'status' => 'active', 'page' => 1, 'detail' => false],
            $this->returnTo === [] ? $fallback : $this->returnTo,
        );
        if (!in_array($navigation['source'], ['foods', 'shelf'], true)
            || !in_array($navigation['status'], ['active', 'consumed', 'trashed'], true)) {
            $this->error('Neplatný návrat na seznam potravin.', 404);
        }
        $page = filter_var($navigation['page'], FILTER_VALIDATE_INT);
        $navigation['page'] = $page === false ? 1 : max(1, $page);
        $navigation['detail'] = in_array($navigation['detail'], [true, 1, '1'], true);
        $shelf = null;
        if ($navigation['shelfId'] !== null) {
            $shelfId = filter_var($navigation['shelfId'], FILTER_VALIDATE_INT);
            if ($shelfId === false || $shelfId < 1) {
                $this->error('Police nebyla nalezena.', 404);
            }
            $shelf = $this->loadShelf($shelfId);
            $navigation['shelfId'] = $shelfId;
            if (isset($this->food) && $this->food->getShelf() !== $shelf) {
                $this->error('Potravina není na vybrané polici.', 404);
            }
        }
        if ($navigation['source'] === 'shelf' && $shelf === null) {
            $this->error('Police nebyla nalezena.', 404);
        }
        // Only known parameters and internal destinations are allowed in return links.
        $this->returnTo = array_intersect_key($navigation, array_flip(['source', 'shelfId', 'status', 'page', 'detail']));
        [$backDestination, $backParameters] = $this->returnTarget(false);
        [$cancelDestination, $cancelParameters] = $this->returnTarget();
        $this->template->returnShelf = $shelf;
        $this->template->foodNavigation = $this->returnTo;
        $this->template->detailNavigation = array_replace($this->returnTo, ['detail' => true]);
        $this->template->backDestination = $backDestination;
        $this->template->backParameters = $backParameters;
        $this->template->backLabel = $backDestination === 'Shelf:detail' ? 'Zpět na polici' : 'Zpět na potraviny';
        $this->template->cancelDestination = $cancelDestination;
        $this->template->cancelParameters = $cancelParameters;
        $this->template->cancelLabel = $cancelDestination === 'Food:detail' ? 'Zpět na potravinu' : $this->template->backLabel;
    }

    /** @return array{string, array<string, mixed>} */
    private function returnTarget(bool $allowDetail = true): array
    {
        if ($allowDetail && ($this->returnTo['detail'] ?? false) && isset($this->food)) {
            return ['Food:detail', ['id' => $this->food->getId(), 'returnTo' => array_replace($this->returnTo, ['detail' => false])]];
        }
        if (($this->returnTo['source'] ?? 'foods') === 'shelf') {
            return ['Shelf:detail', ['id' => $this->returnTo['shelfId'], 'page' => $this->returnTo['page']]];
        }
        return ['Food:default', [
            'shelfId' => $this->returnTo['shelfId'] ?? null,
            'status' => $this->returnTo['status'] ?? 'active',
            'page' => $this->returnTo['page'] ?? 1,
            'returnTo' => [],
        ]];
    }

    private function assertActiveFood(): void
    {
        if ($this->food->isConsumed() || $this->food->isTrashed()) {
            $this->error('Potravina již byla spotřebována nebo vyhozena.', 409);
        }
    }

    private function assertInactiveFood(): void
    {
        if (!$this->food->isConsumed() && !$this->food->isTrashed()) {
            $this->error('Potravina je již v zásobách.', 409);
        }
    }

    /** @return array<int, string> */
    private function categoryOptions(): array
    {
        $options = [];
        foreach ($this->categories->getCategories($this->household) as $category) {
            $path = [];
            for ($ancestor = $category; $ancestor !== null; $ancestor = $ancestor->getParent()) {
                $path[] = $ancestor->getName();
            }
            $options[$category->getId()] = implode(' / ', array_reverse($path));
        }
        asort($options);
        return $options;
    }

    /**
     * @param array<int, int|string> $ids
     * @return array<int, CategoryEntity>
     */
    private function selectedCategories(array $ids): array
    {
        return array_map(fn($id) => $this->categories->getCategoryById((int) $id), $ids);
    }

    private function foodForm(string $label): Form
    {
        $form = new Form;
        $form->addText('name', 'Název potraviny')->addFilter('trim')
            ->setRequired('Zadejte název potraviny.')
            ->addRule(FormAlias::MinLength, 'Zadejte název potraviny.', 1)
            ->addRule(FormAlias::MaxLength, 'Název může mít nejvýše 255 znaků.', 255)
            ->setHtmlAttribute('autofocus', true);
        $form->addText('expiry', 'Minimální trvanlivost')->setHtmlType('date')
            ->setNullable()
            ->addRule(static function (TextInput $input): bool {
                $date = \DateTime::createFromFormat('!Y-m-d', $input->getValue());
                return $date !== false && $date->format('Y-m-d') === $input->getValue();
            }, 'Zadejte platné datum spotřeby.');
        $form->addMultiSelect('categoryIds', 'Kategorie', $this->categoryOptions());
        $form->addSubmit('send', $label);
        return $form;
    }

    protected function createComponentAddForm(): Form
    {
        if ($this->getAction() !== 'add') {
            $this->error('Stránka nebyla nalezena.', 404);
        }
        $form = $this->foodForm('Přidat potravinu');
        $options = array_map(function ($shelf) {
            return $shelf->getAppliance()->getName() . ' / ' . $shelf->getName();
        }, $this->availableShelves);

        $form->addSelect('shelfId', 'Police', $options)->setPrompt('Vyberte polici')
            ->setRequired('Vyberte polici.')
            ->setDefaultValue($this->getParameter('shelfId'));
        $form->addText('barcode', 'Čárový kód')
            ->setHtmlAttribute('inputmode', 'numeric')
            ->addRule(Form::MaxLength, 'Čárový kód může mít nejvýše 13 znaků.', 13)
            ->addCondition(Form::Filled)
                ->addRule(Form::Pattern, 'Čárový kód musí mít 8–13 číslic.', '\d{8,13}');
        $form->addFloat('price', 'Cena (Kč)')->setDefaultValue(0)
            ->setRequired('Zadejte cenu.')
            ->addRule(Form::Range, 'Cena musí být od 0 do 99999999,99 Kč.', [0, 99999999.99]);
        $form->addInteger('weight', 'Hmotnost celého balení (g)')
            ->setRequired('Zadejte hmotnost celého balení v gramech.')
            ->addRule(Form::Range, 'Zadejte celé číslo od 1 do 2147483647.', [1, 2147483647]);
        $form->addSelect('nutritionBasis', 'Výživové údaje zadávám', [
            '100g' => 'Na 100 g',
            '100ml' => 'Na 100 ml',
            'package' => 'Za celé balení',
        ])->setDefaultValue('100g')->setRequired('Vyberte, pro jaké množství platí výživové údaje.');
        $form->addFloat('volume', 'Objem celého balení (ml)')->setNullable()
            ->addRule(Form::Range, 'Objem musí být od 0,001 do 2147483647 ml.', [0.001, 2147483647])
            ->addConditionOn($form['nutritionBasis'], Form::Equal, '100ml')
                ->setRequired('Pro údaje na 100 ml zadejte objem celého balení.')
                ->toggle('food-volume');
        foreach ([
            'calories' => 'Energie (kcal)',
            'protein' => 'Bílkoviny (g)',
            'fat' => 'Tuky (g)',
            'carb' => 'Sacharidy (g)',
            'fibre' => 'Vláknina (g)',
        ] as $name => $label) {
            $form->addFloat($name, $label)->setDefaultValue(0)
                ->setRequired('Vyplňte pole ' . $label . '.')
                ->addRule(Form::Range, 'Zadejte číslo od 0 do 2147483647.', [0, 2147483647]);
        }
        // Loading values per 100 g/ml needs neither package amount nor the other food fields.
        $form->addSubmit('lookup', 'Načíst podle kódu')
            ->setValidationScope([$form['barcode'], $form['nutritionBasis']])
            ->onClick[] = $this->lookupBarcode(...);
        $form->onSuccess[] = function (Form $form, $data): void {
            // Nette runs onSuccess after the lookup button's onClick too; only the save button may add food.
            if ($form->isSubmitted() !== $form['send']) {
                return;
            }
            $nutrients = [];
            try {
                foreach (['calories', 'protein', 'fat', 'carb', 'fibre'] as $key) {
                    $nutrients[$key] = FoodNutrition::toPackage(
                        $data->$key, $data->nutritionBasis, $data->weight, $data->volume,
                    );
                }
            } catch (\InvalidArgumentException) {
                $form->addError('Výživové údaje za celé balení musí být v rozsahu 0 až 2147483647. Zkontrolujte hodnoty a množství.');
                return;
            }
            $shelf = $this->loadShelf((int) $data->shelfId);
            try {
                $food = $this->foods->addFood(
                    $data->name, $data->barcode, $data->price, $nutrients['calories'],
                    $nutrients['protein'], $nutrients['fat'], $nutrients['carb'], $nutrients['fibre'], $data->weight,
                    $shelf, $this->household, $this->currentUser,
                    $this->selectedCategories($data->categoryIds),
                );
                if ($data->expiry !== null) {
                    $food->setExpiry(\DateTime::createFromFormat('!Y-m-d', $data->expiry));
                    $this->foods->updateFood($food, $this->household, $this->currentUser);
                }
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Potravinu se nepodařilo přidat. Zkontrolujte údaje a volnou kapacitu police.');
                return;
            }
            $this->flashMessage('Potravina byla přidána.');
            if ($this->returnTo['source'] === 'shelf') {
                $this->redirect('Shelf:detail', ['id' => $shelf->getId()]);
            }
            $this->redirect('default', [
                'shelfId' => $this->returnTo['shelfId'] !== null ? $shelf->getId() : null,
                'status' => 'active', 'page' => 1, 'returnTo' => [],
            ]);
        };
        return $form;
    }

    private function lookupBarcode(SubmitButton $button): void
    {
        $form = $button->getForm();
        $barcode = trim((string) $form['barcode']->getValue());
        if ($barcode === '') {
            $form['barcode']->addError('Zadejte čárový kód.');
            return;
        }
        try {
            $product = $this->productLookup->lookup($barcode);
        } catch (\InvalidArgumentException) {
            $form['barcode']->addError('Čárový kód musí mít 8–13 číslic.');
            return;
        } catch (ProductLookupException) {
            $this->flashMessage('Databáze potravin je nedostupná, vyplňte údaje ručně.', 'error');
            return;
        }

        if ($product === null) {
            $this->flashMessage('Produkt s tímto kódem nebyl nalezen, vyplňte údaje ručně.', 'error');
            return;
        }

        // OFF uses the _100g suffix for both 100 g and 100 ml. The user checks the unit on the label.
        // Keep the original precision and convert only when saving, using the final package amount.
        $values = ['nutritionBasis' => $form['nutritionBasis']->getValue() === '100ml' ? '100ml' : '100g'];
        foreach (['calories', 'protein', 'fat', 'carb', 'fibre'] as $key) {
            // Clear missing values so previous input cannot be mixed with the loaded nutrition basis.
            $values[$key] = $product[$key];
        }
        if ($product['name'] !== null && trim((string) $form['name']->getValue()) === '') {
            $values['name'] = $product['name'];
        }
        $form->setValues($values);
        $this->flashMessage('Načteny výživové údaje na 100 g/ml. Podle obalu vyberte správnou jednotku, zkontrolujte hodnoty a doplňte chybějící údaje.');
    }

    protected function createComponentEditForm(): Form
    {
        if ($this->getAction() !== 'edit') {
            $this->error('Stránka nebyla nalezena.', 404);
        }
        $form = $this->foodForm('Uložit změny');
        $form->setDefaults([
            'name' => $this->food->getName(),
            'expiry' => $this->food->getExpiry()?->format('Y-m-d'),
            'categoryIds' => $this->food->getCategories()->map(fn(CategoryEntity $category) => $category->getId())->toArray(),
        ]);
        $form->onSuccess[] = function (Form $form, $data): void {
            $this->assertActiveFood();
            try {
                $this->food->setName($data->name);
                $this->food->setExpiry($data->expiry !== null ? \DateTime::createFromFormat('!Y-m-d', $data->expiry) : null);
                $this->foods->updateFood(
                    $this->food, $this->household, $this->currentUser,
                    $this->selectedCategories($data->categoryIds),
                );
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Potravinu se nepodařilo upravit. Zkontrolujte zadané údaje.');
                return;
            }
            $this->flashMessage('Potravina byla upravena.');
            [$destination, $parameters] = $this->returnTarget();
            $this->redirect($destination, $parameters);
        };
        return $form;
    }

    private function confirmation(string $label, string $message, string $buttonClass): void
    {
        $this->setView('confirm');
        $this->template->confirmationLabel = $label;
        $this->template->confirmationMessage = $message;
        $this->template->buttonClass = $buttonClass;
    }

    protected function createComponentConfirmationForm(): Form
    {
        $action = $this->getAction();
        $label = match ($action) {
            'delete' => 'Smazat potravinu',
            'consume' => 'Spotřebovat potravinu',
            'trash' => 'Vyhodit potravinu',
            'restore' => 'Vrátit do zásob',
            default => $this->error('Stránka nebyla nalezena.', 404),
        };
        $form = new Form;
        $form->addSubmit('send', $label);
        $form->onSuccess[] = function (Form $form) use ($action): void {
            // Capture the destination before Doctrine removes the food and clears its ID.
            [$destination, $parameters] = $this->returnTarget($action !== 'delete');
            try {
                if ($action === 'delete') {
                    $this->foods->removeFood($this->food);
                } elseif ($action === 'restore') {
                    $this->assertInactiveFood();
                    $this->foods->restoreFood($this->food, $this->currentUser);
                } else {
                    $this->assertActiveFood();
                    if ($action === 'consume') {
                        $this->foods->consumeFood($this->food, $this->currentUser);
                    } else {
                        $this->foods->trashFood($this->food);
                    }
                }
            } catch (\DomainException) {
                $form->addError($action === 'restore'
                    ? 'Potravinu se nepodařilo vrátit do zásob. Zkontrolujte volnou kapacitu police.'
                    : 'Operaci s potravinou se nepodařilo dokončit.');
                return;
            }
            $this->flashMessage(match ($action) {
                'delete' => 'Potravina byla smazána.',
                'consume' => 'Potravina byla spotřebována.',
                'trash' => 'Potravina byla vyhozena.',
                'restore' => 'Potravina byla vrácena do zásob.',
            });
            $this->redirect($destination, $parameters);
        };
        return $form;
    }
}
