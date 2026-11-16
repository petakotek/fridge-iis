<?php declare(strict_types=1);

namespace App\Model\Common;

/** The external food database could not be reached or returned an invalid response. */
final class ProductLookupException extends \RuntimeException
{
}
