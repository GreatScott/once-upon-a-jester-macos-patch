#!/usr/bin/env bash
set -euo pipefail

BIN=~/Library/Application\ Support/Steam/steamapps/common/Once\ Upon\ a\ Jester/TheatreGame.app/Contents/MacOS/TheatreGame
APP=~/Library/Application\ Support/Steam/steamapps/common/Once\ Upon\ a\ Jester/TheatreGame.app
LLVM_OBJCOPY=/opt/homebrew/opt/llvm/bin/llvm-objcopy
BACKUP=~/Desktop/TheatreGame_audioexists_backup_$(date +%Y%m%d_%H%M%S)

echo "[*] Backing up to $BACKUP"
cp "$BIN" "$BACKUP"

echo "[*] Split slices…"
lipo "$BIN" -thin x86_64 -output /tmp/jester_x86_64
lipo "$BIN" -thin arm64   -output /tmp/jester_arm64

patch_exists () {
  local ARCH=$1
  local SLICE=/tmp/jester_$ARCH

  echo "[*] Patching $ARCH slice…"

  local ADDR
  ADDR=$(nm -arch $ARCH -n "$BIN" | awk '/ T _YYAL_AudioExists$/ {print $1}')
  if [[ -z "$ADDR" ]]; then
    echo "  [!] _YYAL_AudioExists not found on $ARCH"
    return 1
  fi
  echo "  _YYAL_AudioExists at $ADDR"

  local VMADDR FILEOFF
  read VMADDR FILEOFF < <(
    otool -arch $ARCH -l "$BIN" | awk '
      /sectname __text/ {grab=1}
      grab && /addr/ {vmaddr=$2}
      grab && /offset/ {fileoff=$2; print vmaddr, fileoff; exit}
    '
  )

  local OFF_HEX=$(python3 - <<PY
addr = int("$ADDR", 16)
vm   = int("$VMADDR", 16)
fo   = int("$FILEOFF", 10)
print(hex(addr - vm + fo))
PY
)
  local OFF_DEC=$(( $OFF_HEX ))
  echo "  file offset: $OFF_HEX"

  if [[ "$ARCH" == "x86_64" ]]; then
    # B8 01 00 00 00 C3   => mov eax,1 ; ret
    printf '\xB8\x01\x00\x00\x00\xC3' | dd of="$SLICE" bs=1 seek=$OFF_DEC conv=notrunc status=none
  else
    # 20 00 80 52 C0 03 5F D6 => mov w0,#1 ; ret
    printf '\x20\x00\x80\x52\xC0\x03\x5F\xD6' | dd of="$SLICE" bs=1 seek=$OFF_DEC conv=notrunc status=none
  fi
}

patch_exists x86_64
patch_exists arm64

echo "[*] Recombine…"
lipo -create /tmp/jester_x86_64 /tmp/jester_arm64 -output "$BIN"

echo "[*] Strip signature blob (ignore if it errors)…"
$LLVM_OBJCOPY --remove-section __TEXT,__code_signature "$BIN" || true

echo "[*] Re-sign…"
codesign --force --deep --sign - "$APP"

echo "[+] Done. If Steam overwrites it, just re-run this script."

