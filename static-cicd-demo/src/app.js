(function () {
  const buildInfo = window.__BUILD_INFO__ || {
    version: "local-dev",
    buildTime: "unknown",
    environment: "local"
  };

  document.getElementById("app-version").textContent = buildInfo.version;
  document.getElementById("build-time").textContent = buildInfo.buildTime;
  document.getElementById("environment").textContent = buildInfo.environment;
})();
