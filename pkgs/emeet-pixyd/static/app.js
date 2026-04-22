(function () {
  "use strict";

  htmx.config.timeout = 10000;
  htmx.config.allowEval = false;

  var pendingRequests = new Set();
  var consecutiveErrors = 0;
  var streamRetryDelay = 3000;
  var maxStreamRetryDelay = 30000;
  var maxToasts = 3;

  document.body.addEventListener("doAction", function (e) {
    htmx.ajax("POST", e.detail.url, {
      target: "#status-panel",
      swap: "outerHTML",
    });
  });

  document.addEventListener("htmx:configRequest", function (e) {
    var path = e.detail.pathInfo.requestPath;
    if (path.indexOf("/api/ptz/") === 0) {
      var elt = e.detail.elt;
      if (elt && elt.classList.contains("ptz-slider")) {
        e.detail.parameters.value = elt.value;
      }
    }
  });

  document.addEventListener("input", function (e) {
    if (!e.target.classList.contains("ptz-slider")) return;
    var axis = e.target.id.replace("slider-", "");
    var valEl = document.getElementById("val-" + axis);
    if (!valEl) return;
    var suffix = axis === "zoom" ? "x" : "\u00b0";
    valEl.textContent = e.target.value + suffix;
  });

  function showToast(msg, type) {
    type = type || "success";
    var container = document.getElementById("toast-container");
    while (container.children.length >= maxToasts) {
      container.removeChild(container.firstChild);
    }
    var el = document.createElement("div");
    el.className = "toast toast-" + type;
    el.textContent = msg;
    container.appendChild(el);
    requestAnimationFrame(function () {
      el.classList.add("show");
    });
    setTimeout(function () {
      el.classList.remove("show");
      setTimeout(function () {
        el.remove();
      }, 300);
    }, 2500);
  }

  function showOfflineBanner() {
    var panel = document.getElementById("status-panel");
    if (!panel || panel.querySelector(".offline-banner")) return;
    var banner = document.createElement("div");
    banner.className = "error-banner offline-banner";
    banner.innerHTML =
      '<span class="offline-dot"></span> Daemon unreachable \u2014 reconnecting\u2026';
    panel.insertBefore(banner, panel.firstChild);
  }

  function hideOfflineBanner() {
    var banner = document.querySelector(".offline-banner");
    if (banner) banner.remove();
  }

  function clearErrorBanners() {
    var panel = document.getElementById("status-panel");
    if (!panel) return;
    panel
      .querySelectorAll(".error-banner:not(.offline-banner)")
      .forEach(function (b) {
        b.remove();
      });
  }

  document.addEventListener("htmx:beforeRequest", function (e) {
    var path = e.detail.pathInfo && e.detail.pathInfo.requestPath;
    if (path === "/panel" && document.visibilityState !== "visible") {
      e.detail.xhr.abort();
      return;
    }
    if (path && pendingRequests.has(path)) {
      e.detail.xhr.abort();
      return;
    }
    if (path) pendingRequests.add(path);
    if (path && path.indexOf("/api/ptz/") === 0) {
      var axis = path.split("/").pop();
      var slider = document.getElementById("slider-" + axis);
      if (slider) slider.classList.add("sending");
    }
  });

  document.addEventListener("htmx:afterRequest", function (e) {
    var path = e.detail.pathInfo && e.detail.pathInfo.requestPath;

    if (path) {
      pendingRequests.delete(path);
      if (path.indexOf("/api/ptz/") === 0) {
        var axis = path.split("/").pop();
        var slider = document.getElementById("slider-" + axis);
        if (slider) slider.classList.remove("sending");
      }
    }

    if (e.detail.failed) {
      consecutiveErrors++;
      if (path && path.indexOf("/api/ptz/") === 0) {
        var errAxis = path.split("/").pop();
        var errSlider = document.getElementById("slider-" + errAxis);
        if (errSlider && errSlider.dataset.lastGood !== undefined) {
          errSlider.value = errSlider.dataset.lastGood;
          var valEl = document.getElementById("val-" + errAxis);
          if (valEl) {
            var suffix = errAxis === "zoom" ? "x" : "\u00b0";
            valEl.textContent = errSlider.dataset.lastGood + suffix;
          }
        }
      }
      if (consecutiveErrors >= 3) {
        showOfflineBanner();
      }
      showToast(
        consecutiveErrors >= 3
          ? "Connection lost \u2014 retrying"
          : "Request failed",
        "error"
      );
      return;
    }

    consecutiveErrors = 0;
    hideOfflineBanner();
    clearErrorBanners();

    if (!path) return;

    var labels = {
      "/api/track": "Tracking enabled",
      "/api/idle": "Camera idle",
      "/api/privacy": "Privacy mode on",
      "/api/center": "Camera centered",
      "/api/sync": "State synced",
      "/api/probe": "Probed devices",
    };
    if (labels[path]) showToast(labels[path], "success");
    if (path === "/api/gesture") showToast("Gesture toggled", "info");
    if (path === "/api/auto") showToast("Auto mode toggled", "info");
    if (path.indexOf("/api/audio") === 0)
      showToast("Audio mode changed", "info");

    if (path.indexOf("/api/ptz/") === 0) {
      var okAxis = path.split("/").pop();
      var okSlider = document.getElementById("slider-" + okAxis);
      if (okSlider) okSlider.dataset.lastGood = okSlider.value;
    }
  });

  document.addEventListener("htmx:responseError", function (e) {
    var panel = document.getElementById("status-panel");
    if (!panel || panel.querySelector(".error-banner:not(.offline-banner)"))
      return;
    var banner = document.createElement("div");
    banner.className = "error-banner";
    banner.textContent = "Connection error \u2014 will retry automatically";
    panel.insertBefore(banner, panel.firstChild);
  });

  document.addEventListener("htmx:timeout", function () {
    showToast("Request timed out", "error");
  });

  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "visible") {
      streamRetryDelay = 3000;
    }
  });

  document.addEventListener("keydown", function (e) {
    if (
      e.target.tagName === "INPUT" ||
      e.target.tagName === "TEXTAREA" ||
      e.target.tagName === "SELECT"
    )
      return;
    var map = {
      t: "/api/track",
      i: "/api/idle",
      p: "/api/privacy",
      c: "/api/center",
    };
    var url = map[e.key.toLowerCase()];
    if (!url) return;
    e.preventDefault();
    var badge = document.querySelector(".header-badge");
    if (badge && badge.textContent === "Offline") {
      showToast("Camera offline", "error");
      return;
    }
    htmx.trigger(document.body, "doAction", { url: url });
  });

  (function () {
    var img = document.getElementById("preview-img");
    if (!img) return;
    var retryTimer = null;
    img.addEventListener("error", function () {
      if (retryTimer) return;
      this.style.display = "none";
      var fallback = document.getElementById("preview-fallback");
      if (fallback) {
        fallback.style.display = "flex";
        var label = fallback.querySelector("div:last-child");
        if (label) label.textContent = "Reconnecting\u2026";
      }
      var delay = streamRetryDelay;
      retryTimer = setTimeout(function () {
        retryTimer = null;
        img.src = "/api/stream?" + Date.now();
        img.style.display = "";
        if (fallback) fallback.style.display = "none";
      }, delay);
      streamRetryDelay = Math.min(
        streamRetryDelay * 2,
        maxStreamRetryDelay
      );
    });
  })();
})();
