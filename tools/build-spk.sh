#!/bin/sh
# build-spk.sh — assemble a Synology SPK from pre-built ocserv binaries.
#
# Usage:
#   ./tools/build-spk.sh --arch x86_64 --version 1.2.3 --rev 1 \
#                        --bindir /path/to/bins/x86_64
#
# The binaries directory must contain:
#   bin/ocserv
#   bin/ocpasswd
#   bin/occtl
#   lib/*.so.*          (shared libraries bundled with the binary build)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ARCH=""
VERSION=""
REV="1"
BINDIR=""
OUTDIR="${SCRIPT_DIR}/dist"
VPN_PORT="4433"

usage() {
    echo "Usage: $0 --arch ARCH --version VER [--rev REV] --bindir DIR [--outdir DIR] [--port PORT]"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --arch)    ARCH="$2";    shift 2 ;;
        --version) VERSION="$2"; shift 2 ;;
        --rev)     REV="$2";     shift 2 ;;
        --bindir)  BINDIR="$2";  shift 2 ;;
        --outdir)  OUTDIR="$2";  shift 2 ;;
        --port)    VPN_PORT="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

[ -z "${ARCH}" ]    && echo "Missing --arch"    && usage
[ -z "${VERSION}" ] && echo "Missing --version" && usage
[ -z "${BINDIR}" ]  && echo "Missing --bindir"  && usage
[ -d "${BINDIR}" ]  || { echo "bindir not found: ${BINDIR}"; exit 1; }

SPK_NAME="ocserv_${VERSION}-${REV}_${ARCH}.spk"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

echo "==> Building ${SPK_NAME}"

# ── 1. Stage package contents ─────────────────────────────────────────────────
PKG_STAGE="${WORK_DIR}/package"
mkdir -p "${PKG_STAGE}/bin" "${PKG_STAGE}/lib" "${PKG_STAGE}/etc"

# Binaries
for b in ocserv ocpasswd occtl; do
    if [ -f "${BINDIR}/bin/${b}" ]; then
        install -m 755 "${BINDIR}/bin/${b}" "${PKG_STAGE}/bin/${b}"
    else
        echo "WARNING: ${BINDIR}/bin/${b} not found — skipping"
    fi
done

# Shared libraries (bundle everything so the package is self-contained)
if [ -d "${BINDIR}/lib" ]; then
    cp -a "${BINDIR}/lib/." "${PKG_STAGE}/lib/"
fi

# Config template
install -m 644 "${SCRIPT_DIR}/package/etc/ocserv.conf.tpl" \
    "${PKG_STAGE}/etc/ocserv.conf.tpl"

# ── 2. Create package.tgz ─────────────────────────────────────────────────────
echo "==> Creating package.tgz"
(cd "${PKG_STAGE}" && tar czf "${WORK_DIR}/package.tgz" .)

# ── 3. Stage scripts ──────────────────────────────────────────────────────────
SCRIPTS_STAGE="${WORK_DIR}/scripts"
mkdir -p "${SCRIPTS_STAGE}"
for s in installer start-stop-status; do
    install -m 755 "${SCRIPT_DIR}/package/scripts/${s}" "${SCRIPTS_STAGE}/${s}"
done

# ── 4. Stage conf/ ────────────────────────────────────────────────────────────
CONF_STAGE="${WORK_DIR}/conf"
mkdir -p "${CONF_STAGE}"
cp "${SCRIPT_DIR}/package/conf/privilege" "${CONF_STAGE}/privilege"
# Substitute port placeholder in resource file
sed "s|@@VPN_PORT@@|${VPN_PORT}|g" \
    "${SCRIPT_DIR}/package/conf/resource" > "${CONF_STAGE}/resource"

# ── 5. Stage wizard UI ────────────────────────────────────────────────────────
WIZARD_STAGE="${WORK_DIR}/WIZARD_UIFILES"
mkdir -p "${WIZARD_STAGE}"
cp "${SCRIPT_DIR}/package/ui/wizard/install_uifile" \
    "${WIZARD_STAGE}/install_uifile"

# ── 6. Write INFO ─────────────────────────────────────────────────────────────
sed \
    -e "s|@@VERSION@@|${VERSION}|g" \
    -e "s|@@REV@@|${REV}|g" \
    -e "s|@@ARCH@@|${ARCH}|g" \
    "${SCRIPT_DIR}/package/INFO" > "${WORK_DIR}/INFO"

# ── 7. Copy icons (placeholders if missing) ───────────────────────────────────
for size in 72 256; do
    src="${SCRIPT_DIR}/icons/ocserv_${size}.png"
    dst_name="PACKAGE_ICON${size:+_${size}}.PNG"
    [ "${size}" = "72" ] && dst_name="PACKAGE_ICON.PNG"
    if [ -f "${src}" ]; then
        cp "${src}" "${WORK_DIR}/${dst_name}"
    else
        # Create a minimal 1×1 transparent PNG placeholder (8-byte header trick)
        printf '\x89PNG\r\n\x1a\n' > "${WORK_DIR}/${dst_name}"
        echo "WARNING: ${src} not found — placeholder icon used"
    fi
done

# ── 8. Assemble SPK ───────────────────────────────────────────────────────────
mkdir -p "${OUTDIR}"
SPK_PATH="${OUTDIR}/${SPK_NAME}"

(cd "${WORK_DIR}" && tar cf "${SPK_PATH}" \
    INFO \
    PACKAGE_ICON.PNG \
    PACKAGE_ICON_256.PNG \
    package.tgz \
    scripts \
    conf \
    WIZARD_UIFILES)

echo "==> Done: ${SPK_PATH}"
