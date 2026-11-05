#!/usr/bin/env bash
# Busca Vivado y Vitis en esta máquina y los agrega al PATH (cualquier versión y ubicación).
# Se puede forzar con: export XIL_VIVADO=/ruta/a/Vivado/settings64.sh  y  XIL_VITIS=/ruta/a/Vitis/settings64.sh
buscar() {   # $1 = Vivado o Vitis
  for raiz in "$HOME/Xilinx" "$HOME/AMD" /tools/Xilinx /opt/Xilinx /opt/xilinx /opt/AMD /tools/AMD; do
    [ -d "$raiz" ] || continue
    # 2025.x: <raiz>/<version>/<Herramienta>/settings64.sh ; 2024.x y anteriores: <raiz>/<Herramienta>/<version>/settings64.sh
    find "$raiz" -maxdepth 3 -path "*$1*" -name settings64.sh 2>/dev/null
  done | sort -V | tail -1
}
# Python con numpy y matplotlib (se detecta antes de que Vivado o Vitis cambien el PATH)
if [ -z "$PY" ]; then
  for c in python3 python /usr/bin/python3; do
    if command -v "$c" >/dev/null && "$c" -c "import numpy, matplotlib" 2>/dev/null; then PY=$(command -v "$c"); break; fi
  done
fi
export PY
if ! command -v vivado >/dev/null; then
  f=${XIL_VIVADO:-$(buscar Vivado)}; [ -n "$f" ] && source "$f"
fi
if ! command -v vitis >/dev/null; then
  f=${XIL_VITIS:-$(buscar Vitis)}; [ -n "$f" ] && source "$f"
fi
command -v vivado >/dev/null && echo "Vivado: $(vivado -version 2>/dev/null | head -1)" || echo "AVISO: no se encontró Vivado"
command -v vitis  >/dev/null && echo "Vitis : $(command -v vitis)" || echo "AVISO: no se encontró Vitis"
[ -n "$PY" ] && echo "Python: $PY" || echo "AVISO: no hay Python con numpy y matplotlib (pip3 install --user numpy matplotlib)"
