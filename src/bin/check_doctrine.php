<?php declare(strict_types=1);

require dirname(__DIR__) . '/vendor/autoload.php';

$container = (new App\Bootstrap())->bootWebApplication();
$entityManager = $container->getByType(Doctrine\ORM\EntityManagerInterface::class);
// The existing DECIMAL price is represented as float in the application.
$errors = (new Doctrine\ORM\Tools\SchemaValidator($entityManager, validatePropertyTypes: false))->validateMapping();

foreach ($errors as $entity => $messages) {
    foreach ($messages as $message) {
        fwrite(STDERR, "$entity: $message\n");
    }
}

if ($errors !== []) {
    exit(1);
}

echo "Doctrine association mapping is valid.\n";
