# Custom Istio Proxy

The Istio sidecar proxy image, built the way
[istio/proxy](https://github.com/istio/proxy) and
[istio/istio](https://github.com/istio/istio) build it, with one addition: the
GeoIP HTTP filter and its MaxMind provider are compiled into Envoy.

## What is built

| Target | What it is |
|---|---|
| `//:envoy` | Envoy with Istio's extension set plus GeoIP |
| `//cmd/pilot-agent` | `pilot-agent` from istio/istio, built from source |
| `//:image` | the `linux/amd64` + `linux/arm64` image index |
| `//:image_test` | checks the image's config and files against `testdata/image.yaml` |
| `//:load` | loads the image into a local daemon as `palermo/istio-proxy:latest` |
| `//:push` | pushes the image as `palermo/istio-proxy:<commit>` |

The image has the files of istio/istio's distroless `proxyv2` image at the same
paths, on the same base image.

## Building

Only [Bazelisk](https://github.com/bazelbuild/bazelisk) is needed. The C++
toolchain (LLVM, libc++, sysroot), the Go SDK and the image tooling are
downloaded by Bazel; nothing is taken from the host, and building and testing
need no Docker daemon.

```sh
bazel test //...                  # both architectures, and the image test
bazel build --config=release //:envoy
bazel run //:load
```

`user.bazelrc` is read if present and is not committed; put a remote cache
configuration there.

## What is pinned where

| Pin | Where |
|---|---|
| Envoy commit | `ENVOY_SHA` in `MODULE.bazel` |
| istio/istio commit | `go.mod` and `ISTIO_SHA` in `bazel/versions.bzl` |
| istio/proxy commit | `ISTIO_PROXY_SHA` in `bazel/versions.bzl` |
| Base image | `istio_iptables` in `MODULE.bazel` |

The three commits belong together: the istio/istio commit names the istio/proxy
commit it was built against, which names the Envoy commit.

## Updating

```sh
bazel/update_istio.sh                      # latest istio/istio master
ISTIO_SHA=<commit> bazel/update_istio.sh   # a given commit
```

This moves all three commits and the files that follow them: `go.mod`,
`envoy.bazelrc`, `.bazelversion`, `ENVOY_VERSION.txt`, `MODULE.bazel.lock` and
`bazel/extension_config/istio_extensions_build_config.bzl`. The base image
digest is updated by hand when the script says Istio's has moved.

## Extensions

`bazel/extension_config/istio_extensions_build_config.bzl` is istio/proxy's
file, unchanged. `extensions_build_config.bzl` next to it adds this
repository's extensions to that set; add or remove one there.
