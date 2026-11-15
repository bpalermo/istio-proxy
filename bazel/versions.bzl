"""The Istio commits this build corresponds to.

scripts/update_istio.sh keeps these in step with go.mod. The Envoy commit is in
MODULE.bazel.
"""

# istio/istio commit pilot-agent and the bootstrap template are built from.
# Must be the commit go.mod requires istio.io/istio at.
ISTIO_SHA = "f19147879ffbc702f832fd63f1a60fcb8b7af488"

# istio/proxy commit that istio/istio commit pins (istio.deps), which is where
# the Envoy pin and //bazel/extension_config were taken from. Reported by the
# proxy as ISTIO_META_ISTIO_PROXY_SHA.
ISTIO_PROXY_SHA = "4c11f0bd59e6ac516ff84495e30b019e8f913c92"
