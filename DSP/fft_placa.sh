#!/usr/bin/env bash
# FFT e IFFT ejecutadas en la Arty Z7-20: la FPGA calcula y el ARM inyecta la señal cuadrada por DMA.
# Uso: ./fft_placa.sh hw | sw | prog | todo
#   hw   : Vivado genera el diseño de la FFT (bitstream y .xsa)      unos 25 min
#   sw   : Vitis compila xfft_main.c (señal cuadrada)                  unos 3 min
#   prog : graba la placa, ejecuta, lee la DDR y grafica               1 min (placa conectada, JP4 en JTAG)
set -e
source "$(cd "$(dirname "$0")/.." && pwd)/entorno.sh"
R="$(cd "$(dirname "$0")" && pwd)"; cd "$R"
hw() {
  "$PY" auto/run_vivado.py xfft
  cp build/vivado/sys_wrapper.xsa build/vivado/sys_wrapper_xfft.xsa
}
# Vitis 2025.2 no acepta rutas con espacios al leer el .xsa: se compila en un workspace sin espacios
BASE="${VITIS_BASE:-$HOME/.lab6_vitis}"
W="$BASE/build/xfft"
sw() {
  rm -rf "$BASE"; mkdir -p "$W" "$BASE/ip_xfft"
  cp ip_xfft/xfft_main.c "$BASE/ip_xfft/"
  cp create_vitis.py "$W/"; cp build/vivado/sys_wrapper_xfft.xsa "$W/sys_wrapper.xsa"
  ( cd "$W" && vitis -s create_vitis.py xfft | tee "$R/build/vitis_xfft.log" )
  ELF=$(find "$W" -name "app_xfft.elf" | head -1)
  [ -n "$ELF" ] && mkdir -p build/elf && cp "$ELF" build/elf/ && echo "XFFT_SW_OK"
}
prog() {
  H="$R/build/placa/hw"; mkdir -p "$H"
  unzip -q -o build/vivado/sys_wrapper_xfft.xsa -d "$H"
  ELF="$R/build/elf/app_xfft.elf"
  xsdb tcl_placa_fft.tcl "$(ls "$H"/*.bit | head -1)" "$H/ps7_init.tcl" "$ELF" "$R/build/placa"
  "$PY" py/xfft_cuadrada.py placa
}
case "${1:-todo}" in
  hw) hw ;; sw) sw ;; prog) prog ;; todo) hw; sw; prog ;;
  *) echo "uso: $0 hw|sw|prog|todo"; exit 1 ;;
esac
