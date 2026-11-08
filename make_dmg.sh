#!/usr/bin/env bash
# Creates MacSpaceSniffer.dmg — a standard drag-to-Applications disk image.
# Usage: bash make_dmg.sh [AppBundle]
set -euo pipefail

APP="${1:-MacSpaceSniffer.app}"
VOL="MacSpaceSniffer"
DMG_FINAL="${VOL}.dmg"
DMG_SCRATCH="${VOL}-scratch.dmg"

if [[ ! -d "$APP" ]]; then
    echo "❌  $APP not found — run 'make bundle' first" >&2
    exit 1
fi

echo "▸ Cleaning previous artifacts…"
rm -f "$DMG_FINAL" "$DMG_SCRATCH"

# ── 1. Create a writable scratch image (200 MB is plenty) ──────────────────
echo "▸ Creating scratch image…"
hdiutil create \
    -megabytes 200 \
    -volname "$VOL" \
    -fs HFS+ \
    -ov \
    "$DMG_SCRATCH" \
    > /dev/null

# ── 2. Mount the scratch image ─────────────────────────────────────────────
echo "▸ Mounting scratch image…"
MOUNT_PT="/Volumes/$VOL"
hdiutil attach -readwrite -noverify -noautoopen "$DMG_SCRATCH" > /dev/null
sleep 1   # let Finder register the volume

# ── 3. Populate: app + Applications shortcut ──────────────────────────────
echo "▸ Copying ${APP}…"
cp -r "$APP" "$MOUNT_PT/"
ln -s /Applications "$MOUNT_PT/Applications"

# ── 4. Set Finder window geometry & icon positions via AppleScript ─────────
echo "▸ Setting window layout…"
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$VOL"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 460}
        set theViewOpts to icon view options of container window
        set arrangement of theViewOpts to not arranged
        set icon size of theViewOpts to 100
        set position of item "$APP" to {145, 185}
        set position of item "Applications" to {375, 185}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sleep 1

# ── 5. Lock permissions, flush, unmount ───────────────────────────────────
echo "▸ Finalising volume…"
chmod -Rf go-w "$MOUNT_PT" 2>/dev/null || true
sync
hdiutil detach "$MOUNT_PT" -quiet

# ── 6. Convert scratch to compressed read-only DMG ────────────────────────
echo "▸ Compressing…"
hdiutil convert "$DMG_SCRATCH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL" \
    > /dev/null

rm -f "$DMG_SCRATCH"

SIZE=$(du -sh "$DMG_FINAL" | cut -f1)
echo ""
echo "✅  ${DMG_FINAL}  (${SIZE})"
echo "   Open with:  open \"${DMG_FINAL}\""
