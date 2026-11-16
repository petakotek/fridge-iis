<?php declare(strict_types=1);

namespace App\Presentation\Category;

use App\Model\Entity\CategoryEntity;
use App\Model\Services\CategoryService;
use App\Model\Services\UserService;
use App\Presentation\Accessory\AuthenticatedPresenter;
use Nette\Application\UI\Form;
use Nette\Forms\Form as FormAlias;

final class CategoryPresenter extends AuthenticatedPresenter
{
    private CategoryEntity $selectedCategory;
    private ?CategoryEntity $initialParent = null;

    public function __construct(UserService $users, private CategoryService $categories)
    {
        parent::__construct($users);
    }

    protected function startup(): void
    {
        parent::startup();
        if ($this->getAction() !== 'default' && $this->currentUser->getHousehold()?->getModerator() !== $this->currentUser) {
            $this->error('Přístup odepřen.', 403);
        }
    }

    public function renderDefault(): void
    {
        $household = $this->currentUser->getHousehold();
        $this->template->household = $household;
        $children = [];
        foreach ($household !== null ? $this->categories->getCategories($household) : [] as $category) {
            $children[$category->getParent()?->getId() ?? 0][] = $category;
        }
        $this->template->categoryChildren = $children;
        $this->template->isModerator = $household?->getModerator() === $this->currentUser;
    }

    public function actionCreate(?int $parentId = null): void
    {
        if ($parentId !== null) {
            $this->initialParent = $this->getHouseholdCategory($parentId);
        }
    }

    public function actionEdit(int $id): void
    {
        $this->loadCategory($id);
    }

    public function actionDelete(int $id): void
    {
        $this->loadCategory($id);
    }

    private function loadCategory(int $id): void
    {
        $this->selectedCategory = $this->getHouseholdCategory($id);
        $this->template->category = $this->selectedCategory;
    }

    private function getHouseholdCategory(int $id): CategoryEntity
    {
        try {
            $category = $this->categories->getCategoryById($id);
        } catch (\InvalidArgumentException) {
            $this->error('Kategorie nebyla nalezena.', 404);
        }
        if ($category->getHousehold() !== $this->currentUser->getHousehold()) {
            $this->error('Kategorie nebyla nalezena.', 404);
        }
        return $category;
    }

    /** @return array<int, string> */
    private function parentOptions(?CategoryEntity $excludedCategory): array
    {
        $options = [];
        foreach ($this->categories->getCategories($this->currentUser->getHousehold()) as $category) {
            $path = [];
            for ($ancestor = $category; $ancestor !== null; $ancestor = $ancestor->getParent()) {
                // A category cannot be moved under itself or any of its descendants.
                if ($ancestor === $excludedCategory) {
                    continue 2;
                }
                $path[] = $ancestor->getName();
            }
            $options[$category->getId()] = implode(' / ', array_reverse($path));
        }
        // sort array
        asort($options);
        return $options;
    }

    private function categoryForm(string $submitLabel, ?CategoryEntity $excludedCategory = null): Form
    {
        $form = new Form;
        $form->addText('name', 'Název kategorie')
            ->setRequired('Zadejte název kategorie.')
            ->addRule(FormAlias::MaxLength, 'Název může mít nejvýše 50 znaků.', 50);
        $form->addSelect('parent', 'Nadřazená kategorie', $this->parentOptions($excludedCategory))
            ->setPrompt('Bez nadřazené kategorie');
        $form->addSubmit('send', $submitLabel);
        return $form;
    }

    protected function createComponentCreateForm(): Form
    {
        $form = $this->categoryForm('Přidat kategorii');
        $form->setDefaults(['parent' => $this->initialParent?->getId()]);
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $parent = $data->parent !== null ? $this->getHouseholdCategory((int) $data->parent) : null;
                $this->categories->addCategory($this->currentUser->getHousehold(), $data->name, $this->currentUser, $parent);
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Kategorii se nepodařilo přidat. Zkontrolujte název.');
                return;
            }
            $this->flashMessage('Kategorie byla přidána.');
            $this->redirect('default');
        };
        return $form;
    }

    protected function createComponentEditForm(): Form
    {
        $form = $this->categoryForm('Uložit změny', $this->selectedCategory);
        $form->setDefaults([
            'name' => $this->selectedCategory->getName(),
            'parent' => $this->selectedCategory->getParent()?->getId(),
        ]);
        $form->onSuccess[] = function (Form $form, $data): void {
            try {
                $parent = $data->parent !== null ? $this->getHouseholdCategory((int) $data->parent) : null;
                $this->categories->moveCategory(
                    $this->currentUser->getHousehold(), $this->selectedCategory, $parent, $this->currentUser,
                );
                $this->categories->updateCategoryName(
                    $this->currentUser->getHousehold(), $this->selectedCategory, $data->name, $this->currentUser,
                );
            } catch (\DomainException|\InvalidArgumentException) {
                $form->addError('Kategorii se nepodařilo upravit. Zkontrolujte název a nadřazenou kategorii.');
                return;
            }
            $this->flashMessage('Kategorie byla upravena.');
            $this->redirect('default');
        };
        return $form;
    }

    protected function createComponentDeleteForm(): Form
    {
        $form = new Form;
        $form->addSubmit('send', 'Smazat kategorii');
        $form->onSuccess[] = function (Form $form): void {
            try {
                $this->categories->removeCategory(
                    $this->currentUser->getHousehold(), $this->selectedCategory, $this->currentUser,
                );
            } catch (\DomainException) {
                $form->addError('Kategorii nelze smazat, pokud obsahuje podkategorie nebo je přiřazena k potravinám.');
                return;
            }
            $this->flashMessage('Kategorie byla smazána.');
            $this->redirect('default');
        };
        return $form;
    }
}
