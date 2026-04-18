(function() {
	'use strict';

	var pendingRequests = new Set();
	var debounceTimer = null;

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

	var consecutiveErrors = 0;

	document.addEventListener('htmx:afterRequest', function(e) {
		if (e.detail.failed) {
			consecutiveErrors++;
			if (consecutiveErrors >= 3) {
				showToast('Connection lost — retrying', 'error');
			} else {
				showToast('Request failed', 'error');
			}
			return;
		}

		consecutiveErrors = 0;

		clearErrorBanners();

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
		if (path.indexOf('/api/ptz/') === 0) {
			var axis = path.split('/').pop();
			var slider = document.getElementById('slider-' + axis);
			if (slider) slider.dataset.lastGood = slider.value;
		}
	});

	document.addEventListener('htmx:beforeRequest', function(e) {
		var path = e.detail.pathInfo && e.detail.pathInfo.requestPath;
		if (!path) return;
		if (pendingRequests.has(path)) {
			e.detail.xhr.abort();
			return;
		}
		pendingRequests.add(path);
	});

	document.addEventListener('htmx:afterRequest', function(e) {
		var path = e.detail.pathInfo && e.detail.pathInfo.requestPath;
		if (path) pendingRequests.delete(path);
	});

	document.addEventListener('htmx:responseError', function(e) {
		var panel = document.getElementById('status-panel');
		if (!panel) return;
		var existing = panel.querySelectorAll('.error-banner');
		if (existing.length > 0) return;
		var banner = document.createElement('div');
		banner.className = 'error-banner';
		banner.textContent = 'Connection error — will retry automatically';
		panel.insertBefore(banner, panel.firstChild);
	});

	function clearErrorBanners() {
		var panel = document.getElementById('status-panel');
		if (!panel) return;
		panel.querySelectorAll('.error-banner').forEach(function(b) { b.remove(); });
	}

	document.addEventListener('keydown', function(e) {
		if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
		var map = { 't': '/api/track', 'i': '/api/idle', 'p': '/api/privacy', 'c': '/api/center' };
		var url = map[e.key.toLowerCase()];
		if (url) {
			e.preventDefault();
			htmx.trigger(document.body, 'doAction', { url: url });
		}
	});

	document.addEventListener('visibilitychange', function() {
		if (debounceTimer) clearTimeout(debounceTimer);
		if (document.visibilityState === 'visible') {
			debounceTimer = setTimeout(function() {
				var panel = document.getElementById('status-panel');
				if (panel) htmx.trigger(panel, 'refresh');
			}, 200);
		}
	});

	var previewImg = document.getElementById('preview-img');
	if (previewImg) {
		previewImg.addEventListener('error', function() {
			this.style.display = 'none';
			var fallback = document.getElementById('preview-fallback');
			if (fallback) fallback.style.display = 'flex';
		});
	}
})();
