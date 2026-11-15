#!/bin/bash
# Field Notebook wallpapers: night paper, hairline topo contours in forest ink,
# grain, vignette, and the lscaturchio.xyz signature as a wall label.
set -euo pipefail
OUT="${1:-$HOME/.config/omarchy/themes/field-notebook/backgrounds}"
# The site signature, if that checkout is here; without it the plates carry
# only the wall label.
SIG="${FN_SIGNATURE:-$HOME/code/lscaturchio.xyz/public/signature.png}"
W=2560 H=1440
NIGHT="#111317" PEN="#42a979" FAINT="#767c87"
FONT=$(fc-match -f '%{file}' 'BlexMono Nerd Font:medium' 2>/dev/null || true)
[[ $FONT == *Blex* ]] || FONT=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font')
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$OUT"

# Signature → pen-green alpha mask.
# The PNG may carry its own transparency or be ink on white; build the mask
# from whichever it is, so the strokes alone take the pen colour.
if [[ -r $SIG ]]; then
  if [[ $(magick identify -format '%A' "$SIG") == [Bb]lend || $(magick identify -format '%A' "$SIG") == True ]]; then
    magick "$SIG" -alpha extract -resize 420x "$tmp/mask.png"
  else
    magick "$SIG" -colorspace gray -negate -resize 420x "$tmp/mask.png"
  fi
  magick "$tmp/mask.png" -level 5%,85% \( +clone -fill "$PEN" -colorize 100 \) +swap \
    -alpha off -compose copy_opacity -composite -channel A -evaluate multiply 0.62 +channel "$tmp/sig.png"
else
  magick -size 1x1 xc:none "$tmp/sig.png"
fi

n=0
for seed in 7 42 1312; do
  n=$((n+1))
  magick -seed $seed -size 320x180 plasma:fractal -colorspace gray -blur 0x14 -auto-level \
    -resize ${W}x${H}\! -blur 0x6 -auto-level "$tmp/h.png"
  magick "$tmp/h.png" +dither -posterize 30 -morphology EdgeIn Diamond:1 -threshold 1% "$tmp/minor.png"
  magick "$tmp/h.png" +dither -posterize 7 -morphology EdgeIn Diamond:1 -morphology Dilate Disk:1 -threshold 1% "$tmp/major.png"
  magick -size ${W}x${H} radial-gradient:white-black -level 0%,170% -negate "$tmp/vig.png"
  magick -size ${W}x${H} xc:"$NIGHT" \
    \( "$tmp/minor.png" -background "$PEN" -alpha shape -channel A -evaluate multiply 0.22 +channel \) -composite \
    \( "$tmp/major.png" -background "$PEN" -alpha shape -channel A -evaluate multiply 0.42 +channel \) -composite \
    \( "$tmp/vig.png" -background "#0a0b0d" -alpha shape -channel A -evaluate multiply 0.55 +channel \) -composite \
    \( -size ${W}x${H} xc:gray50 +noise Gaussian -colorspace gray -alpha set -channel A -evaluate set 4% +channel \) -compose overlay -composite \
    -compose over "$tmp/sig.png" -gravity southeast -geometry +110+150 -composite \
    -font "$FONT" -pointsize 15 -kerning 3.5 -fill "$FAINT" -gravity southeast \
    -annotate +112+108 "FIELD NOTEBOOK  ·  PLATE $(printf '%02d' $n)  ·  LSCATURCHIO.XYZ" \
    -quality 92 "$OUT/$n-field-notebook-topo.png"
  echo "wrote $OUT/$n-field-notebook-topo.png"
done
