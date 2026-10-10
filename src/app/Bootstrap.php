<?php declare(strict_types=1);

namespace App;

use Nette;
use Nette\Bootstrap\Configurator;


class Bootstrap
{
	private readonly Configurator $configurator;
	private readonly string $rootDir;


	public function __construct()
	{
		$this->rootDir = dirname(__DIR__);
		$this->configurator = new Configurator;
		$this->configurator->setTempDirectory($this->rootDir . '/temp');
	}


	public function bootWebApplication(): Nette\DI\Container
	{
		$this->initializeEnvironment();
		$this->setupContainer();
		return $this->configurator->createContainer();
	}


	public function initializeEnvironment(): void
	{
        // při následném nasazení aplikace nastavíme debugMode na false, je to z toho důvodu, že v produkci se používá
        // přímý build aplikace, ne debugMode; v tomto režimu se aplikace stále refreshuje. POZOR NA TO KLUCI!!!
        $this->configurator->setDebugMode(true);
		$this->configurator->enableTracy($this->rootDir . '/log');

		$this->configurator->createRobotLoader()
			->addDirectory(__DIR__)
			->register();
	}


	private function setupContainer(): void
	{
		$this->configurator->addDynamicParameters([
			'env' => parse_ini_file($this->rootDir . '/.env', scanner_mode: INI_SCANNER_RAW) ?: [],
		]);

		$configDir = $this->rootDir . '/config';
		$this->configurator->addConfig($configDir . '/common.neon');
		$this->configurator->addConfig($configDir . '/services.neon');
	}
}
