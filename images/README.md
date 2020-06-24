# Experimental Nex-gen Cilium Images

> NOTE: This document is for Cilium developers and community testers, any information given here is not
> currenly officially recommended for production use.

This directory contains build definitions for experimental next-gen Cilium images.

In the initial phase, these images are going to be used by the new CI architecture, and will be integrated
in development and release workflows once image tooling is mature enough.

Goals and objectives:

- stop using registry-hosted builds ([#11334](https://github.com/cilium/cilium/issues/11334))
- implement new CI architecture where images are built prior to test excution
  and same images are tested in all providers under test
- more reliable and determenistic builds
- enhanced dependency composition
- multi-platform support
   - initially the aim is to add `arm64` ([#9898](https://github.com/cilium/cilium/issues/9898))
   - it should be relatively easy to add other architectures in the future

These images are built on top of [`cilium/image-tools`](https://github.com/cilium/image-tools), anyone reading this document
should also read [`cilium/image-tools` documentation](https://github.com/cilium/image-tools/blob/master/README.md).

## Description of Images

### [`builder`](builder/Dockerfile)

This image is based on [`compilers`](https://github.com/cilium/image-tools#imagescompiler) image from `cilium/image-tools`.

It adds Go toolchain and includes `ineffassign`. The aim is to include all of the Go linters as well.

### [`runtime`](runtime/Dockerfile)

This image is based on [`bpftool`](https://github.com/cilium/image-tools#imagesbpftool), [`iproute2`](https://github.com/cilium/image-tools#imagesiproute2) and [`llvm`](https://github.com/cilium/image-tools#imagesllvm) from `cilium/image-tools`.

At present it also includes [`gops`](https://github.com/google/gops) for debugging. as well as Ubuntu user-space for troubleshooting.

### [`cilium`](cilium/Dockerfile)

It include `cilium-agent` and other binaries, including `cilium` & `cilium-health`.

This image is based on `runtime` image, and it constains Ubuntu user-space for troubleshooting.

In coparison to the [official Cilium image](../Dockerfile), this image is missing Envoy & Hubble CLI binaries at present.

### [`operator`](operator/Dockerfile)

This image includes only `cilium-operator` binaries (plus CA certificates), no other binaries or libraries are included.

### [`hubble-relay`](hubble-relay/Dockerfile)

This image includes only `hubble-relay` binary (plus CA certificates), no other binaries or libraries are included.

## Tooling

### Making changes

## `runtime` & `builder`

These images are wholly defined by the contents of the image directory, and are tagged with git tree hash
for the image directory (see [`cilium/image-tools` documentation](https://github.com/cilium/image-tools#usage)
for details). In effect this means that images are only re-built in CI when there are changes to build definitions.

If you are making changes to either of these image, and want to consume those changes in a feature you are working on, it's
recommended to make a PR with required changes first. Once your PR is merged, you want to run `make update-builder-image`
or `make update-runtime-image`. It's possible to test locally, see below.

## `cilium`, `operator` & `hubble-relay`

This image is largely defined by contents of the entire repository, so it's tagged with git commit hash
(or a git tag on release). Thereby a new image is built on every PR merge.

### Building Locally

One should be able to build all of the images locally as long as they have Docker installed with [`buildx` plug-in](https://docs.docker.com/buildx/working-with-buildx/).

E.g. to build a version fo `runtime` image, run:

```
make -C images runtime-image
```

To push the `runtime` image to a registry, use:
```
make -C images runtime-image PUSH=true REGISTRIES=docker.io/<username>
```

To consume new `runtime` image in `cilium` image, you will need to update `images/cilium/Dockerfile` manually.

Building and testing `builder` image locally would be accomplished in very similar manner.

### Testing

Some images have tests, for example when `runtime` image is built, all of the components that it constis are
being tested using `container-structure-test` tool (see [`cilium/image-tools` docs for details](https://github.com/cilium/image-tools#imagestester)).
