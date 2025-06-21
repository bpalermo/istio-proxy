set -ex

# Explicitly stamp.
BAZEL_BUILD_ARGS="${BAZEL_BUILD_ARGS} --stamp"
CONFIG_PARAMS="--config=release"

ARCH_NAME="k8"
case "$(uname -m)" in
  aarch64) ARCH_NAME="aarch64";;
esac

BAZEL_OUT="$(bazel info ${BAZEL_BUILD_ARGS} output_path)/${ARCH_NAME}-opt/bin"

bazel build ${BAZEL_BUILD_ARGS} ${CONFIG_PARAMS} //:envoy_tar

docker build -f ./Dockerfile --tag istio-proxy:latest "${BAZEL_OUT}"
