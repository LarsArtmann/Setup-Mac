document.addEventListener('input', function(e) {
	if (!e.target.classList.contains('ptz-slider')) return;
	var axis = e.target.id.replace('slider-', '');
	var valEl = document.getElementById('val-' + axis);
	if (!valEl) return;
	var suffix = axis === 'zoom' ? 'x' : '\u00b0';
	valEl.textContent = e.target.value + suffix;
});

function showToast(msg, type) {
	type = type || 'success';
	var container = document.getElementById('toast-container');
	var el = document.createElement('div');
	el.className = 'toast toast-' + type;
	el.textContent = msg;
	container.appendChild(el);
	requestAnimationFrame(function() { el.classList.add('show'); });
	setTimeout(function() {
		el.classList.remove('show');
		setTimeout(function() { el.remove(); }, 300);
	}, 2500);
}

document.addEventListener('htmx:afterRequest', function(e) {
	if (e.detail.failed) {
		showToast('Request failed', 'error');
		return;
	}
	var path = e.detail.pathInfo && e.detail.pathInfo.requestPath;
	if (!path) return;
	var labels = {
		'/api/track': 'Tracking enabled',
		'/api/idle': 'Camera idle',
		'/api/privacy': 'Privacy mode on',
		'/api/center': 'Camera centered',
		'/api/sync': 'State synced',
		'/api/probe': 'Probed devices'
	};
	if (labels[path]) showToast(labels[path], 'success');
	if (path === '/api/gesture') {
		showToast('Gesture toggled', 'info');
	}
	if (path === '/api/auto') showToast('Auto mode toggled', 'info');
	if (path.indexOf('/api/audio') === 0) showToast('Audio mode changed', 'info');
});

document.addEventListener('keydown', function(e) {
	if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
	var map = { 't': '/api/track', 'i': '/api/idle', 'p': '/api/privacy', 'c': '/api/center' };
	var url = map[e.key.toLowerCase()];
	if (url) {
		e.preventDefault();
		htmx.trigger(document.body, 'doAction', { url: url });
	}
});
