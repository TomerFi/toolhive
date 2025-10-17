# Build the manager binary
FROM registry.redhat.io/ubi10/go-toolset:1.24 as builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the Go sources
ARG CODE_DIR
COPY ${CODE_DIR}/ .

# Build
USER root
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} go build -o manager ./main.go

# Use minimal base image to package the manager binary
FROM registry.access.redhat.com/ubi10/ubi-minimal:10.0
WORKDIR /
RUN yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical && yum clean all

COPY --from=builder /workspace/manager .
COPY LICENSE /licenses/LICENSE

LABEL name="toolhive-operator" \
      vendor="Stacklok" \
      maintainer="Stacklok" \
      org.opencontainers.image.source="https://github.com/stacklok/toolhive" \
      org.opencontainers.image.title="toolhive-operator" \
      org.opencontainers.image.vendor="Stacklok"

USER default

ENTRYPOINT ["/manager"]
