FROM gcr.io/distroless/base-nossl-debian12:nonroot
ADD --chown=65532:65532 envoy_tar.tar.gz /usr/local/bin/
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/envoy"]
