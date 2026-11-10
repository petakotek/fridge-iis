<?php declare(strict_types=1);

namespace App\Presentation\Food;

use App\Model\Entity\FoodEntity;
use App\Model\Entity\HouseholdEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\FoodService;
use App\Model\Services\ShelfService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;
use Nette\Forms\Controls\TextInput;
use Nette\Forms\Form as FormAlias;

final class FoodPresenter extends AuthenticatedPresenter
{
    private HouseholdEntity $household;
    private FoodEntity $food;

    /** @var array<int, ShelfEntity> */
    private array $availableShelves = [];

    public function __construct(
        UserService                       $users,
        private readonly FoodService      $foods,
        private readonly ShelfService     $shelves,
        private readonly ApplianceService $appliances,
    ) {
        parent::__construct($users);
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

    public function actionDefault(?int $shelfId = null, string $status = 'active'): void
    {
        if (!in_array($status, ['active', 'consumed', 'trashed'], true)) {
            $this->error('Neplatný stav potravin.', 404);
        }
        $this->loadAvailableShelves();
        $selectedShelf = $shelfId !== null ? $this->loadShelf($shelfId) : null;
        $foods = [];
        foreach ($selectedShelf !== null ? [$selectedShelf] : $this->availableShelves as $shelf) {
            array_push($foods, ...match ($status) {
                'active' => $this->foods->getFoodsByShelf($shelf),
                'consumed' => $this->foods->getConsumedFoodsByShelf($shelf, $this->currentUser),
                'trashed' => $this->foods->getTrashedFoodsByShelf($shelf),
            });
        }
        if ($status !== 'active') {
            usort($foods, static function (FoodEntity $first, FoodEntity $second) use ($status): int {
                $firstDate = $status === 'consumed' ? $first->getConsumedAt() : $first->getDiscardedAt();
                $secondDate = $status === 'consumed' ? $second->getConsumedAt() : $second->getDiscardedAt();
                return ($secondDate <=> $firstDate) ?: ($second->getId() <=> $first->getId());
            });
        }
        $this->template->foods = $foods;
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
        $this->template->hasShelves = $this->availableShelves !== [];
    }

    public function actionDetail(int $id): void
    {
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

    private function foodForm(string $label): Form
    {
        $form = new Form;
        $form->addText('name', 'Název potraviny')->addFilter('trim')
            ->setRequired('Zadejte název potraviny.')
            ->addRule(FormAlias::MinLength, 'Zadejte název potraviny.', 1)
            ->addRule(FormAlias::MaxLength, 'Název může mít nejvýše 255 znaků.', 255)
            ->setHtmlAttribute('autofocus', true);
        $form->addText('expiry', 'Datum spotřeby')->setHtmlType('date')
            ->setNullable()
            ->addRule(static function (TextInput $input): bool {
                $date = \DateTime::createFromFormat('!Y-m-d', $input->getValue());
                return $date !== false && $date->format('Y-m-d') === $input->getValue();
            }, 'Zadejte platné datum spotřeby.');
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
            ->addRule(Form::MaxLength, 'Čárový kód může mít nejvýše 13 znaků.', 13);
        $form->addFloat('price', 'Cena (Kč)')->setDefaultValue(0)
            ->setRequired('Zadejte cenu.')
            ->addRule(Form::Range, 'Cena musí být od 0 do 99999999,99 Kč.', [0, 99999999.99]);
        foreach ([
            'weight' => 'Hmotnost (g)',
            'calories' => 'Energie (kcal)',
            'protein' => 'Bílkoviny (g)',
            'fat' => 'Tuky (g)',
            'carb' => 'Sacharidy (g)',
            'fibre' => 'Vláknina (g)',
        ] as $name => $label) {
            $form->addInteger($name, $label)->setRequired('Vyplňte pole ' . $label . '.')
                ->addRule(Form::Range, 'Zadejte celé číslo od ' . ($name === 'weight' ? '1' : '0') . ' do 2147483647.', [$name === 'weight' ? 1 : 0, 2147483647]);
            if ($name !== 'weight') {
                $form[$name]->setDefaultValue(0);
            }
        }
        $form->onSuccess[] = function (Form $form, $data): void {
            $shelf = $this->loadShelf((int) $data->shelfId);
            try {
                $food = $this->foods->addFood(
                    $data->name, $data->barcode, $data->price, $data->calories,
                    $data->protein, $data->fat, $data->carb, $data->fibre, $data->weight,
                    $shelf, $this->household, $this->currentUser,
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
            $this->redirect('default', ['shelfId' => $shelf->getId()]);
        };
        return $form;
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
        ]);
        $form->onSuccess[] = function (Form $form, $data): void {
            $this->assertActiveFood();
            try {
                $this->food->setName($data->name);
                $this->food->setExpiry($data->expiry !== null ? \DateTime::createFromFormat('!Y-m-d', $data->expiry) : null);
                $this->foods->updateFood($this->food, $this->household, $this->currentUser);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Potravinu se nepodařilo upravit. Zkontrolujte zadané údaje.');
                return;
            }
            $this->flashMessage('Potravina byla upravena.');
            $this->redirect('detail', ['id' => $this->food->getId()]);
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
            $this->redirect('default', [
                'shelfId' => $this->food->getShelf()->getId(),
                'status' => $this->food->isConsumed() ? 'consumed' : ($this->food->isTrashed() ? 'trashed' : 'active'),
            ]);
        };
        return $form;
    }
}
