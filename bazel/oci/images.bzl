load("@rules_oci//oci:pull.bzl", "oci_pull")

def oci_images():
    oci_pull(
        name = "istio_release_iptables",
        digest = "sha256:3760912212dc7882551b88d3362c42c1038715cff7bf4cd30f9ac0c9f491dd05",
        image = "gcr.io/istio-release/iptables",
        platforms = [
            "linux/amd64",
            "linux/arm64",
        ],
    )
