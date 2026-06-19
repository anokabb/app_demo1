{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    // Serve CanvasKit from this app's own bundle instead of fetching it from
    // www.gstatic.com at runtime — avoids a permanent blank screen when that
    // CDN is unreachable or blocked (ad blockers, restrictive networks, etc).
    canvasKitBaseUrl: "canvaskit/"
  }
});
