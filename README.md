# Kaniko image with tools

This is an alternative container image for
[Google Container Tools Kaniko](https://github.com/GoogleContainerTools/kaniko),
extended with the installed utilities bash, curl, jq and others.

The reason for the appearance of this container is the need to execute
additional logic inside the container in the CI pipelines. The original
kaniko image is delivered on the basis of a scratch image, and the debug
container has no version tags and contains only busybox from the utilities.

> **ℹ️ This container image is generated automatically every day.**

Extends the original container image using the following utilities:

* bash
* git
* tar
* xz
* gzip
* bzip2
* curl
* coreutils
* openssl
* jq
* yq
* pushrm
