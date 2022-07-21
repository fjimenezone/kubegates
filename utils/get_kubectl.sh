#!/usr/bin/env bash

: ${DEBUG:="false"}
: ${VERIFY_CHECKSUM:="true"}
: ${KUBECTL_INSTALL_DIR:="../bin"}

HAS_CURL="$(type "curl" &> /dev/null && echo true || echo false)"
HAS_WGET="$(type "wget" &> /dev/null && echo true || echo false)"
HAS_OPENSSL="$(type "openssl" &> /dev/null && echo true || echo false)"

discoverArch() {
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

discoverOS() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    case "$OS" in
        mingw*|cygwin*) OS="windows";;
    esac
}

verifyRequirements() {
    local supported="darwin-amd64\ndarwin-arm64\nlinux-amd64"
    if ! echo "$supported" | grep -q "$OS-$ARCH"; then
        echo "No prebuilt binary for $OS-$ARCH."
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

versionSelection() {
    if [[ -z $DESIRED_VERSION ]]; then
        local latest_release_url="https://dl.k8s.io/release/stable.txt"
        if [[ $HAS_CURL == "true" ]]; then
            TAG=$(curl -Ls $latest_release_url)
        elif [[ $HAS_WGET == "true" ]]; then
            TAG=$(wget $latest_release_url -qO -)
        fi
    else
        TAG=$DESIRED_VERSION
    fi
}

isVersionInstalled() {
    if [[ -f $KUBECTL_INSTALL_DIR/$BINARY_NAME ]]; then
        local version=$($KUBECTL_INSTALL_DIR/$BINARY_NAME version --short --client)
        version=${version##* }
        if [[ $version == $TAG ]]; then
            echo "Installed kubectl-$version is already ${DESIRED_VERSION:-latest}"
            return 0
        else
            echo "kubectl-$TAG is available."
            return 1
        fi
    else
        return 1
    fi
}

downloadFile() {
    DOWNLOAD_URL="https://dl.k8s.io/release/$TAG/bin/$OS/$ARCH/kubectl"
    CHECKSUM_URL="$DOWNLOAD_URL.sha256"
    KUBECTL_TMP_DIR="$(mktemp -dt kubectl-installer)"
    KUBECTL_TMP_FILE="$KUBECTL_TMP_DIR/kubectl"
    KUBECTL_SUM_FILE="$KUBECTL_TMP_DIR/kubectl.sha256"
    echo "Downloading $DOWNLOAD_URL to $KUBECTL_TMP_DIR"
    if [[ $HAS_CURL == "true" ]]; then
        curl -SsL "$CHECKSUM_URL" -o "$KUBECTL_SUM_FILE"
        curl -SsL "$DOWNLOAD_URL" -o "$KUBECTL_TMP_FILE"
    elif [[ $HAS_WGET == "true" ]]; then
        wget -q -O "$KUBECTL_SUM_FILE" "$CHECKSUM_URL"
        wget -q -O "$KUBECTL_TMP_FILE" "$DOWNLOAD_URL"
    fi
}

verifyFile() {
    if [[ $VERIFY_CHECKSUM == "true" ]]; then
        verifyChecksum
    fi
}

installFile() {
    KUBECTL_BIN="$KUBECTL_TMP_FILE"
    echo "Preparing to install $BINARY_NAME into $KUBECTL_INSTALL_DIR"
    chmod +x $KUBECTL_BIN
    mv -v "$KUBECTL_BIN" "$KUBECTL_INSTALL_DIR/$BINARY_NAME"
}

verifyChecksum() {
    printf "Verifying checksum... "
    local sum=$(openssl sha1 -sha256 $KUBECTL_TMP_FILE)
    sum=${sum##* }
    local expected_sum=$(cat $KUBECTL_SUM_FILE)
    if [[ "$sum" != "$expected_sum" ]]; then
        echo "SHA sum of $KUBECTL_TMP_FILE does not match. Aborting."
        exit 1
    fi
    echo "Done."
}

atExit() {
    result=$?
    if [[ $result != "0" ]]; then
        if [[ -n "$INPUT_ARGUMENTS" ]]; then
            echo "Failed to install $BINARY_NAME with the arguments provided: $INPUT_ARGUMENTS"
            help
        else
            echo "Failed to install $BINARY_NAME"
        fi
        echo -e "\tVisit https://kubernetes.io/docs/tasks/tools"
    fi
    cleanUp
    exit $result
}

help() {
    echo "Accepted cli arguments are:"
    echo -e "\t[--help|-h ] ->> prints this help"
    echo -e "\t[--version|-v <desired_version>]" 
    echo -e "\te.g. --version v1.23.5"
}

cleanUp() {
    if [[ -d "${KUBECTL_TMP_DIR:-}" ]]; then
        rm -rf "$KUBECTL_TMP_DIR"
    fi
}

# Execution

# Stop execution on any error
trap "atExit" EXIT
set -e

if [[ $DEBUG == "true" ]]; then
    set -x
fi

export INPUT_ARGUMENTS="${@}"
set -u
while [[ $# -gt 0 ]]; do
    case $1 in
        '--version'|-v)
             shift
             if [[ $# -ne 0 ]]; then
                 export DESIRED_VERSION="$1"
             else
                 echo -e "Please provide the desired version. e.g. --version v1.23.5 or -v v1.23.5"
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

discoverArch
discoverOS
verifyRequirements
versionSelection
: ${BINARY_NAME:="kubectl-$TAG"}
if ! isVersionInstalled; then
  downloadFile
  verifyFile
  installFile
fi
