 # Let's build
FROM golang:alpine AS base-image

# Package dependencies
RUN apk --no-cache --no-progress add \
    bash \
    curl \
    gcc \
    git \
    make \
    musl-dev \
    docker \
    tar

#RUN go get -u github.com/docker/swarmkit/...
#RUN go install github.com/docker/swarmkit@latest
RUN mkdir -p /go/src/github.com/docker/
RUN git clone https://github.com/moby/swarmkit.git /go/src/github.com/docker/swarmkit
RUN cd /go/src/github.com/docker/swarmkit && make binaries && cp -rv bin/* /usr/local/bin/
RUN find / -xdev -type f  -name swarmctl

FROM base-image as maker

#RUN go get -u github.com/alecthomas/gometalinter
#RUN go install github.com/alecthomas/gometalinter@latest
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.51.1

RUN golangci-lint --version

ARG license_server_url
ENV PROJECT_WORKING_DIR=/go/src/github.com/docker/swarmkit
WORKDIR "${PROJECT_WORKING_DIR}"

RUN make install

FROM maker as builder
# Prepare fakeroot
RUN mkdir /fakeroot && cp /usr/local/bin/swarmctl /fakeroot/swarmctl

FROM alpine AS base
RUN /bin/sh -c "mkdir -p /var/run"
COPY --from=builder /fakeroot/ /
VOLUME ["/tmp"]
ENTRYPOINT ["/swarmctl"]
