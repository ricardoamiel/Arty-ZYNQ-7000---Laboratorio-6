#!/usr/bin/env bash
# Simula en xsim (sin GUI) el FFT y el filtro FIR, y genera las figuras con Python.
# Uso: ./sim_todo.sh            (xfft y fir)
#      ./sim_todo.sh xfft       (solo uno)
set -e
source "$(cd "$(dirname "$0")/.." && pwd)/entorno.sh"
R="$(cd "$(dirname "$0")" && pwd)"; cd "$R"
mkdir -p build resultados
for ip in ${@:-xfft fir}; do
  cp dsp_sim_batch.tcl build/
  ( cd build && vivado -nolog -nojournal -mode batch -source dsp_sim_batch.tcl -tclargs "$ip" | tee "sim_$ip.log" )
  grep -q -i "simulation done\|\$finish" "build/sim_$ip.log" || echo "AVISO: revisar build/sim_$ip.log"
  py=$([ "$ip" = fir ] && echo fir_compiler || echo "$ip")
  "$PY" py/guardar_figuras.py "$py"
done
ls -la resultados
