#!/usr/bin/env python3
"""Build the source submission archive, including everything needed to prepare deployment."""

import argparse
from html.parser import HTMLParser
import os
from pathlib import Path
import re
import tempfile
from urllib.parse import unquote, urlsplit
from zipfile import ZipFile, ZIP_DEFLATED


PROJECT = Path(__file__).resolve().parent.parent
DIST = PROJECT / '.development' / 'dist'
SUBMISSION_LIMIT = 5_000_000


class DocumentationLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.paths = set()

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ('src', 'href') and value:
                url = urlsplit(value)
                if url.path and not url.scheme and not url.netloc:
                    self.paths.add(unquote(url.path))


def excluded(path):
    parts = path.relative_to(PROJECT).parts
    if path.name.lower() == 'readme' or path.name.lower().startswith('readme.'):
        return True
    if path.name.startswith('.env') and path.name != '.env.example':
        return True
    if path.name in ('.git', '.idea', '.vscode', '__pycache__', 'node_modules'):
        return True
    if parts[0] == '.development' or parts[:2] in (('src', 'temp'), ('src', 'log')):
        return True
    return parts[:2] == ('src', 'vendor') or parts[:3] == ('src', 'www', 'assets')


def files(entry):
    if entry.is_file():
        if not excluded(entry):
            yield entry
        return
    for directory, folders, names in os.walk(entry, followlinks=False):
        folder = Path(directory)
        folders[:] = sorted(name for name in folders if not excluded(folder / name))
        for name in sorted(names):
            path = folder / name
            if not excluded(path):
                yield path


def build(login):
    if not re.fullmatch(r'[a-zA-Z0-9_-]+', login):
        raise ValueError('LOGIN smí obsahovat pouze písmena, číslice, podtržítko a pomlčku.')
    entries = [PROJECT / name for name in (
        'src', 'docs', 'doc.html',
    )]
    output = DIST / (login + '.zip')

    for entry in entries:
        if not entry.exists():
            raise ValueError(f'Chybí součást archivu: {entry.relative_to(PROJECT)}')

    DIST.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix='.' + login + '-', suffix='.zip', dir=DIST)
    os.close(descriptor)
    temporary = Path(temporary)
    try:
        with ZipFile(temporary, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
            for entry in entries:
                for path in files(entry):
                    if path.is_symlink():
                        raise ValueError(f'Symbolický odkaz nelze zabalit: {path.relative_to(PROJECT)}')
                    archive.write(path, path.relative_to(PROJECT).as_posix())
            links = DocumentationLinks()
            links.feed((PROJECT / 'doc.html').read_text())
            for name in links.paths:
                if name not in archive.namelist():
                    raise ValueError(f'Dokumentace odkazuje na soubor, který není v archivu: {name}')

        size = temporary.stat().st_size
        if size > SUBMISSION_LIMIT:
            raise ValueError(f'Odevzdávací archiv má {size} bajtů, limit je {SUBMISSION_LIMIT}.')
        temporary.replace(output)
        print(f'Archiv: {output.relative_to(PROJECT)} ({size / 1024:.0f} KiB)')
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--login', default='xvoldrv00')
    arguments = parser.parse_args()
    try:
        build(arguments.login)
    except (OSError, ValueError) as error:
        parser.exit(1, f'Balení selhalo: {error}\n')
