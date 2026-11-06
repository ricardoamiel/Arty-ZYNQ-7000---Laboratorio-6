#!/usr/bin/env bash
# Toma capturas reales de la interfaz de Vivado en una pantalla virtual (Xvfb), sin abrir ventanas.
# Uso: ./capturar.sh bd <proyecto.xpr> <nombre>      Block Design (PNG de la UI + SVG/PDF vectorial)
#      ./capturar.sh ondas <proyecto_sim.xpr> <nombre>  Visor de ondas de la simulación
set -e
source "$(cd "$(dirname "$0")/.." && pwd)/entorno.sh" >/dev/null
modo=$1; xpr=$(realpath "$2"); nombre=$3; extra=""
if [ -n "$4" ]; then extra=$(mktemp --suffix=.wcfg); cp "$4" "$extra"; fi   # open_wave_config no acepta rutas con espacios
D="$(cd "$(dirname "$0")" && pwd)"; out="$D/$nombre"; rm -f "$out.listo"
disp=:$((90 + RANDOM % 9))
Xvfb $disp -screen 0 2560x1440x24 >/dev/null 2>&1 & XP=$!
trap 'kill $VP $XP 2>/dev/null || true' EXIT
sleep 2
cd /tmp && DISPLAY=$disp vivado -nolog -nojournal -mode gui -source "$D/abrir_$modo.tcl" -tclargs "$xpr" "$out" $extra >"$out.log" 2>&1 & VP=$!
rm -f "$out.esperando" "$out.seguir"
for i in $(seq 1 600); do [ -f "$out.esperando" ] && break; sleep 1; done
sleep 5
python3 "$D/xteclas.py" $disp maximizar 2560 1440 || true   # requiere python-xlib (pip install --user python-xlib)
sleep 8; touch "$out.seguir"
for i in $(seq 1 600); do [ -f "$out.listo" ] && break; sleep 1; done
[ -f "$out.listo" ] || { echo "No se abrió a tiempo, revisar $out.log"; exit 1; }
sleep 20                                   # tiempo para que la interfaz termine de dibujar
sleep 3
import -display $disp -window root "$out.png"
[ -f "$out.svg" ] && rsvg-convert -f pdf -o "$out.pdf" "$out.svg"
rm -f "$out.listo" "$out.esperando" "$out.seguir"
echo "Captura: $out.png $( [ -f "$out.pdf" ] && echo "y $out.pdf" )"
