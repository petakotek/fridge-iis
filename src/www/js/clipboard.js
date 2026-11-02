async function copyToClipboard(value) {
	if (navigator.clipboard?.writeText) {
		await navigator.clipboard.writeText(value);
		return;
	}

	const input = document.createElement('textarea');
	input.value = value;
	input.style.position = 'fixed';
	input.style.opacity = '0';
	document.body.append(input);
	input.select();
	const copied = document.execCommand('copy');
	input.remove();
	if (!copied) {
		throw new Error('Clipboard is unavailable.');
	}
}

document.querySelectorAll('[data-copy-text], [data-copy-url]').forEach((button) => {
	button.addEventListener('click', async () => {
		const status = button.closest('.card')?.querySelector('.copy-status');
		const isUrl = button.hasAttribute('data-copy-url');
		const value = isUrl
			? new URL(button.dataset.copyUrl, document.baseURI).href
			: button.dataset.copyText;

		try {
			await copyToClipboard(value);
			if (status) status.textContent = isUrl ? 'Odkaz byl zkopírován.' : 'Token byl zkopírován.';
		} catch {
			if (status) status.textContent = isUrl
				? 'Odkaz se nepodařilo zkopírovat. Pošlete místo něj token.'
				: 'Token se nepodařilo zkopírovat. Označte jej a zkopírujte ručně.';
		}
	});
});
