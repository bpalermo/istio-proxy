"""The extensions compiled into the proxy: Istio's set, plus this repository's.

istio_extensions_build_config.bzl is istio/proxy's
bazel/extension_config/extensions_build_config.bzl, unchanged, and is replaced
by bazel/update_istio.sh. Extensions are added here, not there.
"""

load(
    ":istio_extensions_build_config.bzl",
    _CONTRIB_EXTENSION_PACKAGE_VISIBILITY = "CONTRIB_EXTENSION_PACKAGE_VISIBILITY",
    _ENVOY_CONTRIB_EXTENSIONS = "ENVOY_CONTRIB_EXTENSIONS",
    _ENVOY_EXTENSIONS = "ENVOY_EXTENSIONS",
    _EXTENSIONS = "EXTENSIONS",
    _EXTENSION_CONFIG_VISIBILITY = "EXTENSION_CONFIG_VISIBILITY",
    _EXTENSION_PACKAGE_VISIBILITY = "EXTENSION_PACKAGE_VISIBILITY",
    _LEGACY_ALWAYSLINK = "LEGACY_ALWAYSLINK",
    _MOBILE_PACKAGE_VISIBILITY = "MOBILE_PACKAGE_VISIBILITY",
)

# Extensions of Envoy that Istio does not enable.
ADDED_EXTENSIONS = {
    "envoy.filters.http.geoip": "//source/extensions/filters/http/geoip:config",
    "envoy.geoip_providers.maxmind": "//source/extensions/geoip_providers/maxmind:config",
}

EXTENSIONS = _EXTENSIONS | ADDED_EXTENSIONS

ENVOY_EXTENSIONS = _ENVOY_EXTENSIONS | ADDED_EXTENSIONS
ENVOY_CONTRIB_EXTENSIONS = _ENVOY_CONTRIB_EXTENSIONS

EXTENSION_CONFIG_VISIBILITY = _EXTENSION_CONFIG_VISIBILITY
EXTENSION_PACKAGE_VISIBILITY = _EXTENSION_PACKAGE_VISIBILITY
CONTRIB_EXTENSION_PACKAGE_VISIBILITY = _CONTRIB_EXTENSION_PACKAGE_VISIBILITY
MOBILE_PACKAGE_VISIBILITY = _MOBILE_PACKAGE_VISIBILITY
LEGACY_ALWAYSLINK = _LEGACY_ALWAYSLINK
