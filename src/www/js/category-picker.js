(() => {
	const normalize = (text) => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('cs');
	const create = (tag, className, text) => {
		const node = document.createElement(tag);
		if (className) node.className = className;
		if (text) node.textContent = text;
		return node;
	};

	document.querySelectorAll('[data-category-picker]').forEach((root) => {
		const select = root.querySelector('select[multiple]');
		if (!select || select.disabled || root.dataset.enhanced) return;

		const options = Array.from(select.options, (option) => ({ option, search: normalize(option.textContent) }));
		const source = root.querySelector('[data-category-source]');
		const help = root.querySelector('[data-category-help]');
		const selected = create('ul', 'category-picker-selected');
		selected.setAttribute('aria-label', 'Vybrané kategorie');
		const input = create('input', 'category-picker-search');
		input.type = 'text';
		input.id = `${select.id}-search`;
		input.placeholder = 'Hledat kategorii…';
		input.autocomplete = 'off';
		input.spellcheck = false;
		input.setAttribute('role', 'combobox');
		input.setAttribute('aria-autocomplete', 'list');
		input.setAttribute('aria-expanded', 'false');
		input.setAttribute('aria-labelledby', `${select.id}-label`);
		input.setAttribute('aria-describedby', help.id);
		const menu = create('div', 'category-picker-menu');
		menu.hidden = true;
		const results = create('div', 'category-picker-results');
		results.id = `${select.id}-results`;
		results.setAttribute('role', 'listbox');
		input.setAttribute('aria-controls', results.id);
		const message = create('div', 'category-picker-message');
		message.setAttribute('role', 'status');
		message.setAttribute('aria-live', 'polite');
		menu.append(results, message);
		let suggestions = [];
		let activeIndex = -1;

		const close = () => {
			menu.hidden = true;
			input.setAttribute('aria-expanded', 'false');
			input.removeAttribute('aria-activedescendant');
			activeIndex = -1;
		};

		const activate = (index) => {
			activeIndex = index;
			Array.from(results.children).forEach((node, position) => {
				node.setAttribute('aria-selected', String(position === index));
			});
			const active = results.children[index];
			if (active) {
				input.setAttribute('aria-activedescendant', active.id);
				active.scrollIntoView({ block: 'nearest' });
			} else {
				input.removeAttribute('aria-activedescendant');
			}
		};

		const renderResults = () => {
			const words = normalize(input.value.trim()).split(/\s+/).filter(Boolean);
			const matches = options.filter(({ option, search }) => !option.selected && !option.disabled && words.every((word) => search.includes(word)));
			suggestions = matches.slice(0, 8);
			results.replaceChildren(...suggestions.map(({ option }, index) => {
				const node = create('div', 'category-picker-option', option.textContent);
				node.id = `${select.id}-result-${index}`;
				node.dataset.index = index;
				node.setAttribute('role', 'option');
				return node;
			}));
			message.textContent = matches.length > 8
				? `Zobrazeno 8 z ${matches.length} kategorií. Upřesněte hledání.`
				: matches.length > 0
					? `Nalezené kategorie: ${matches.length}. Vyberte kliknutím nebo klávesou Enter.`
					: options.every(({ option }) => option.selected || option.disabled)
						? 'Všechny dostupné kategorie jsou vybrané.'
						: 'Žádná odpovídající kategorie.';
			menu.hidden = false;
			input.setAttribute('aria-expanded', 'true');
			activate(suggestions.length ? 0 : -1);
		};

		const renderSelected = () => {
			selected.replaceChildren(...Array.from(select.selectedOptions, (option) => {
				const item = create('li');
				const remove = create('button', 'category-picker-tag');
				remove.type = 'button';
				remove.disabled = option.disabled;
				remove.setAttribute('aria-label', `Odebrat kategorii ${option.textContent}`);
				const cross = create('span', '', '×');
				cross.setAttribute('aria-hidden', 'true');
				remove.append(create('span', '', option.textContent), cross);
				remove.addEventListener('click', () => {
					option.selected = false;
					select.dispatchEvent(new Event('change', { bubbles: true }));
					input.focus();
				});
				item.append(remove);
				return item;
			}));
			selected.hidden = select.selectedOptions.length === 0;
		};

		const choose = (index) => {
			const suggestion = suggestions[index];
			if (!suggestion) return;
			suggestion.option.selected = true;
			input.value = '';
			select.dispatchEvent(new Event('change', { bubbles: true }));
			input.focus();
		};

		input.addEventListener('focus', renderResults);
		input.addEventListener('input', renderResults);
		input.addEventListener('keydown', (event) => {
			if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
				event.preventDefault();
				if (menu.hidden) {
					renderResults();
					if (event.key === 'ArrowUp') activate(suggestions.length - 1);
				} else if (suggestions.length) {
					const direction = event.key === 'ArrowDown' ? 1 : -1;
					activate((activeIndex + direction + suggestions.length) % suggestions.length);
				}
			} else if (event.key === 'Enter') {
				event.preventDefault();
				if (!menu.hidden) choose(activeIndex);
			} else if (event.key === 'Escape') {
				event.preventDefault();
				close();
			}
		});
		results.addEventListener('mousedown', (event) => event.preventDefault());
		results.addEventListener('click', (event) => {
			const target = event.target.closest('[data-index]');
			if (target) choose(Number(target.dataset.index));
		});
		root.addEventListener('focusout', (event) => {
			if (!root.contains(event.relatedTarget)) close();
		});
		select.addEventListener('change', () => {
			renderSelected();
			if (document.activeElement === input) renderResults();
		});
		select.form?.addEventListener('reset', (event) => queueMicrotask(() => {
			if (event.defaultPrevented) return;
			input.value = '';
			renderSelected();
			close();
		}));

		source.before(selected, input, menu);
		renderSelected();
		source.hidden = true;
		help.textContent = 'Hledejte podle názvu nebo nadřazené kategorie. Můžete vybrat více kategorií.';
		root.dataset.enhanced = 'true';
	});
})();
