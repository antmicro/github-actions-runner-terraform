#!/bin/sh

tfd=terraform-docs
tfd_version=v0.14.1

export PATH=$PATH:`realpath .bin`

ensure_terraform_docs() {
    if [ ! -f .bin/terraform-docs ]; then
        mkdir -p .bin &&
        wget -q https://github.com/$tfd/$tfd/releases/download/$tfd_version/$tfd-$tfd_version-linux-amd64.tar.gz -O - | \
            tar xfz - -C .bin/
    fi
}

make_docs() {
    terraform-docs markdown table . > README.md
}

ensure_terraform_docs
make_docs
