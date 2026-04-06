set -e

QMLLINT="${QMLLINT:-}"
if [ -z "$QMLLINT" ]; then
    if [ -x /usr/lib/qt6/bin/qmllint ]; then
        QMLLINT=/usr/lib/qt6/bin/qmllint
    elif command -v qmllint6 >/dev/null 2>&1; then
        QMLLINT=qmllint6
    elif command -v qmllint >/dev/null 2>&1; then
        QMLLINT=qmllint
    else
        echo "Error: qmllint not found. Install qt6-declarative." >&2
        exit 1
    fi
fi

cd "$(dirname "$0")"

IMPORT_ARGS="-I qml -I qml/services -I qml/wallpaper -I qml/components"

if [ $# -gt 0 ]; then
    exec $QMLLINT $IMPORT_ARGS "$@"
else
    exec $QMLLINT $IMPORT_ARGS \
        shell.qml \
        qml/*.qml \
        qml/services/*.qml \
        qml/wallpaper/*.qml \
        qml/components/*.qml
fi
