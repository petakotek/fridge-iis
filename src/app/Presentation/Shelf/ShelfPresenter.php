<?php declare(strict_types=1);

namespace App\Presentation\Shelf;

use App\Model\Entity\ApplianceEntity;
use App\Model\Entity\ShelfEntity;
use App\Model\Services\ApplianceService;
use App\Model\Services\FoodService;
use App\Model\Services\ShelfService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;
use Nette\Utils\Paginator;

final class ShelfPresenter extends AuthenticatedPresenter
{
    private const CapacityWarningPercent = 90;

    private ApplianceEntity $appliance;
    private ShelfEntity $shelf;

    public function __construct(UserService $users, private ApplianceService $appliances, private ShelfService $shelves, private FoodService $foods)
    {
        parent::__construct($users);
    }

    protected function startup(): void
    {
        parent::startup();
        if ($this->getAction() !== 'detail' && $this->currentUser->getHousehold()?->getModerator() !== $this->currentUser) {
            $this->error('Přístup odepřen.', 403);
        }
    }

    public function actionCreate(int $applianceId): void
    {
        try {
            $appliance = $this->appliances->getApplianceById($applianceId);
        } catch (\InvalidArgumentException) {
            $this->error('Spotřebič nebyl nalezen.', 404);
        }
        $this->selectAppliance($appliance);
    }
    public function actionDetail(int $id, int $page = 1): void {
        $this->loadShelf($id);
        $household = $this->appliance->getHousehold();
        $totalWeight = $this->shelf->getShelfCapacity();
        $usedWeight = $this->shelves->getUsedWeight($this->shelf);
        $this->template->capacity = [
            'used' => $usedWeight,
            'total' => $totalWeight,
            'remaining' => max(0, $totalWeight - $usedWeight),
            'percent' => floor($usedWeight * 1000 / $totalWeight) / 10,
            'warningWeight' => $totalWeight * self::CapacityWarningPercent / 100,
            'nearLimit' => $usedWeight * 100 >= $totalWeight * self::CapacityWarningPercent,
            'full' => $usedWeight >= $totalWeight,
        ];
        $paginator = new Paginator;
        $paginator->setItemsPerPage(12);
        $paginator->setItemCount($this->foods->getFoodCount($household, $this->shelf, 'active'));
        $paginator->setPage($page);
        $this->template->foods = $this->foods->getFoods(
            $household,
            $paginator->getItemsPerPage(),
            $paginator->getOffset(),
            $this->shelf,
            'active',
        );
        $this->template->paginator = $paginator;
        $this->template->foodNavigation = [
            'source' => 'shelf', 'shelfId' => $id, 'page' => $paginator->getPage(),
        ];
        $this->template->isModerator = $household->getModerator() === $this->currentUser;
    }

    public function actionEdit(int $id, bool $fromDetail = false, int $page = 1): void
    {
        $this->loadShelf($id);
        $this->template->fromDetail = $fromDetail;
        $this->template->returnPage = max(1, $page);
    }

    public function actionDelete(int $id, bool $fromDetail = false, int $page = 1): void
    {
        $this->loadShelf($id);
        $this->template->fromDetail = $fromDetail;
        $this->template->returnPage = max(1, $page);
    }

    private function loadShelf(int $id): void
    {
        try {
            $this->shelf = $this->shelves->getShelfById($id);
        } catch (\DomainException) {
            $this->error('Police nebyla nalezena.', 404);
        }
        $this->selectAppliance($this->shelf->getAppliance());
        $this->template->shelf = $this->shelf;
    }

    private function selectAppliance(?ApplianceEntity $appliance): void
    {
        if ($appliance === null || $appliance->getHousehold() !== $this->currentUser->getHousehold()) {
            $this->error('Spotřebič nebyl nalezen.', 404);
        }
        $this->appliance = $appliance;
        $this->template->appliance = $appliance;
    }

    private function shelfForm(string $label): Form
    {
        $form = new Form;
        $form->addText('name', 'Název police')->setRequired('Zadejte název police.')
            ->addRule(Form::MaxLength, 'Název může mít nejvýše 255 znaků.', 255);
        $form->addInteger('capacity', 'Kapacita (g)')->setRequired('Zadejte kapacitu police.')
            ->addRule(Form::Range, 'Kapacita musí být celé číslo od 1 do 2147483647.', [1, 2147483647]);
        $form->addSubmit('send', $label);
        return $form;
    }

    protected function createComponentCreateForm(): Form
    {
        $form = $this->shelfForm('Přidat polici');
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $shelf = $this->shelves->addShelf($this->currentUser->getHousehold(), $this->currentUser, $data->capacity, $this->appliance, $data->name);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Polici se nepodařilo přidat. Zkontrolujte název a kapacitu.');
                return;
            }
            $this->flashMessage('Police byla přidána.');
            $this->redirect('detail', ['id' => $shelf->getId()]);
        };
        return $form;
    }

    protected function createComponentEditForm(): Form
    {
        $form = $this->shelfForm('Uložit změny');
        $form->setDefaults(['name' => $this->shelf->getName(), 'capacity' => $this->shelf->getShelfCapacity()]);
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $this->shelves->updateShelf($this->currentUser->getHousehold(), $this->currentUser, $this->shelf, $data->name, $data->capacity);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Polici se nepodařilo upravit. Zkontrolujte název a kapacitu; kapacita nesmí být menší než hmotnost uložených potravin.');
                return;
            }
            $this->flashMessage('Police byla upravena.');
            if ($this->template->fromDetail) {
                $this->redirect('detail', ['id' => $this->shelf->getId(), 'page' => $this->template->returnPage]);
            }
            $this->redirect('Appliance:detail', ['id' => $this->appliance->getId()]);
        };
        return $form;
    }

    protected function createComponentDeleteForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Smazat polici');
        $form->onSuccess[] = function (Form $form): void {
            try {
                $this->shelves->removeShelf($this->currentUser->getHousehold(), $this->currentUser, $this->shelf);
            } catch (\DomainException) {
                $form->addError('Polici se nepodařilo smazat.');
                return;
            }
            $this->flashMessage('Police byla smazána.');
            $this->redirect('Appliance:detail', ['id' => $this->appliance->getId()]);
        };
        return $form;
    }
}
