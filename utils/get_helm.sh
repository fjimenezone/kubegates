#!/usr/bin/env bash

: ${DEBUG:="false"}
: ${VERIFY_CHECKSUM:="false"}
: ${HELM_INSTALL_DIR:="../bin"}

HAS_CURL="$(type "curl" &> /dev/null && echo true || echo false)"
HAS_WGET="$(type "wget" &> /dev/null && echo true || echo false)"
HAS_OPENSSL="$(type "openssl" &> /dev/null && echo true || echo false)"

discover_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        armv5*) ARCH="armv5";;
        armv6*) ARCH="armv6";;
        armv7*) ARCH="arm";;
        aarch64) ARCH="arm64";;
        x86) ARCH="386";;
        x86_64) ARCH="amd64";;
        i686) ARCH="386";;
        i386) ARCH="386";;
    esac
}  

discover_os() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')

    case "$OS" in
        mingw*|cygwin*) OS="windows";;
    esac
}

verify_support() {
    local supported="darwin-amd64\ndarwin-arm64\nlinux-386\nlinux-amd64\nlinux-arm\nlinux-arm64\nlinux-ppc64le\nlinux-s390x\nwindows-amd64"
    if ! echo "$supported" | grep -q "$OS-$ARCH"; then
        echo "No prebuilt binary for $OS-$ARCH."
        echo "To build from source, go to https://github.com/helm/helm"
        exit 1
    fi

    if [[ $HAS_CURL != "true" ]] && [[ $HAS_WGET != "true" ]]; then
        echo "Either curl or wget is required"
        exit 1
    fi

    if [[ $VERIFY_CHECKSUM == "true" ]] && [[ $HAS_OPENSSL != "true" ]]; then
        echo "In order to verify checksum, openssl must first be installed."
        echo "Please install openssl or set VERIFY_CHECKSUM=false in your environment."
        exit 1
    fi
}

version_selection() {
    if [[ -z $DESIRED_VERSION ]]; then
        local latest_release_url="https://github.com/helm/helm/releases"
        if [[ $HAS_CURL == "true" ]]; then
            TAG=$(curl -Ls $latest_release_url | grep -om1 'href="/helm/helm/releases/tag/v3.[0-9]*.[0-9]*')
        elif [[ $HAS_WGET == "true" ]]; then
            TAG=$(wget $latest_release_url -O - 2>&1 | grep -om1 'href="/helm/helm/releases/tag/v3.[0-9]*.[0-9]*')
        else
            printf "curl or wget needed\n" >&2
            exit 1
        fi
        TAG=${TAG##*/}
    else
        TAG=$DESIRED_VERSION
    fi
}

version_installed() {
    if [[ -f $HELM_INSTALL_DIR/$BINARY_NAME ]]; then
        local version=$($HELM_INSTALL_DIR/$BINARY_NAME version --template="{{ .Version }}")
        if [[ $version == $TAG ]]; then
            echo "Installed helm-$TAG is already ${DESIRED_VERSION:-latest}"
            return 0
        else
            echo "helm-$TAG is available."
            return 1
        fi
    else
        return 1
    fi
}

download_file() {
    HELM_DIST="helm-$TAG-$OS-$ARCH.tar.gz"
    DOWNLOAD_URL="https://get.helm.sh/$HELM_DIST"
    CHECKSUM_URL="$DOWNLOAD_URL.sha256"
    HELM_TMP_ROOT="$(mktemp -dt helm-installer)"
    HELM_TMP_FILE="$HELM_TMP_ROOT/$HELM_DIST"
    HELM_SUM_FILE="$HELM_TMP_ROOT/$HELM_DIST.sha256"
    echo "Downloading $DOWNLOAD_URL"
    if [[ $HAS_CURL == "true" ]]; then
        curl -SsL "$CHECKSUM_URL" -o "$HELM_SUM_FILE"
        curl -SsL "$DOWNLOAD_URL" -o "$HELM_TMP_FILE"
    elif [[ $HAS_WGET == "true" ]]; then
        wget -q -O "$HELM_SUM_FILE" "$CHECKSUM_URL"
        wget -q -O "$HELM_TMP_FILE" "$DOWNLOAD_URL"
    fi
}

verify_file() {
    [[ $VERIFY_CHECKSUM == "true" ]] && verify_checksum || :
}

# installFile installs the Helm binary.
install_file() {
    HELM_TMP="$HELM_TMP_ROOT/$BINARY_NAME"
    mkdir -p "$HELM_TMP"
    tar xf "$HELM_TMP_FILE" -C "$HELM_TMP"
    HELM_TMP_BIN="$HELM_TMP/$OS-$ARCH/helm"
    echo "Preparing to install $BINARY_NAME into $HELM_INSTALL_DIR"
    mv -v "$HELM_TMP_BIN" "$HELM_INSTALL_DIR/$BINARY_NAME"
}

verify_checksum() {
    printf "Verifying checksum... "
    local sum=$(openssl sha1 -sha256 $HELM_TMP_FILE)
    sum=${sum##* }
    local expected_sum=$(cat $HELM_SUM_FILE)
    if [[ "$sum" != "$expected_sum" ]]; then
        echo "SHA sum of $HELM_TMP_FILE does not match. Aborting."
        exit 1
    fi
    echo "Done."
}


at_exit() {
    result=$?
    if [[ "$result" != "0" ]]; then
        if [[ -n "$INPUT_ARGUMENTS" ]]; then
            echo "Failed to install $BINARY_NAME with the arguments provided: $INPUT_ARGUMENTS"
            help
        else
            echo "Failed to install $BINARY_NAME"
        fi
        echo -e "\tFor support, go to https://github.com/helm/helm."
    fi
    clean_up
    exit $result
}

# help provides possible cli installation arguments
help () {
    echo "Accepted cli arguments are:"
    echo -e "\t[--help|-h ] ->> prints this help"
    echo -e "\t[--version|-v <desired_version>] . When not defined it fetches the latest release from GitHub"
    echo -e "\te.g. --version v3.0.0 or -v canary"
}

clean_up() {
    [[ -d "${HELM_TMP_ROOT:-}" ]] && rm -rf "$HELM_TMP_ROOT" || :
}

# Execution

# Stop execution on any error
trap "at_exit" EXIT
set -e

# Set debug if desired
[[ $DEBUG == "true" ]] && set -x || :

# Parsing input arguments (if any)
export INPUT_ARGUMENTS="${@}"
set -u
while [[ $# -gt 0 ]]; do
    case $1 in
        '--version'|-v)
             shift
             if [[ $# -ne 0 ]]; then
                 export DESIRED_VERSION="$1"
             else
                 echo -e "Please provide the desired version. e.g. --version v3.0.0 or -v canary"
                 exit 0
             fi
             ;;
        '--help'|-h)
             help
             exit 0
             ;;
        *) exit 1
             ;;
    esac
    shift
done
set +u

discover_arch
discover_os
verify_support
version_selection
: ${BINARY_NAME:="helm-$TAG"}
if ! version_installed; then
    download_file
    verify_file
    install_file
fi
