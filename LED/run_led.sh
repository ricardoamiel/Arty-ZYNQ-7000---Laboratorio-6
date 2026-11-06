#!/usr/bin/env bash
# Uso: ./run_led.sh hw | sw | prog | hello | prog_hello | prog_pl | todo
#   hw   : Vivado crea el diseño, genera bitstream, .xsa y reportes de potencia
#   sw   : Vitis crea la plataforma standalone y compila led_main.c
#   prog : programa la Arty Z7-20 por USB (JTAG) y ejecuta la aplicación (necesita xsdb de cualquier Vitis)
#   hello : compila la aplicación Hello World (plantilla de Vitis)
#   prog_hello : graba la placa con el Hello World
#   prog_pl : graba solo el bitstream con Vivado (LD2 y LD3), sin Vitis
set -e
source "$(cd "$(dirname "$0")/.." && pwd)/entorno.sh"
R="$(cd "$(dirname "$0")" && pwd)"
B="$R/build"; mkdir -p "$B/vivado" "$B/vitis" "$B/hw"

hw() {
  cd "$B/vivado"
  vivado -nolog -nojournal -mode batch -source "$R/tcl/led_hw.tcl" | tee vivado_led.log
  grep -q LED_HW_OK vivado_led.log
  rm -rf "$B/hw"/*; unzip -q -o sys_wrapper.xsa -d "$B/hw"; cp sys_wrapper.bit "$B/hw/"
  grep -A3 "Total On-Chip Power" reportes/power.rpt || true
}
sw() {
  # Vitis 2025.2 no acepta rutas con espacios al leer el .xsa: si la ruta tiene espacios se usa ~/.lab6_vitis_led
  V="$B/vitis"; case "$B" in *" "*) V="${VITIS_BASE_LED:-$HOME/.lab6_vitis_led}/build/vitis" ;; esac
  rm -rf "$(dirname "$(dirname "$V")")/build" "$V"; mkdir -p "$V" "$(dirname "$V")/vivado" "$(dirname "$(dirname "$V")")/src"
  cp "$B/vivado/sys_wrapper.xsa" "$(dirname "$V")/vivado/"; cp "$R/src/led_main.c" "$(dirname "$(dirname "$V")")/src/"
  cp "$R/tcl/create_vitis_led.py" "$V/"
  ( cd "$V" && vitis -s create_vitis_led.py | tee vitis_led.log )
  grep -q LED_SW_OK "$V/vitis_led.log"
  [ "$V" = "$B/vitis" ] || { rm -rf "$B/vitis"; ln -s "$V" "$B/vitis"; }
}
prog_pl() {
  vivado -nolog -nojournal -mode batch -source "$R/tcl/program_pl.tcl" -tclargs "$B/hw/sys_wrapper.bit"
}
hello() {
  [ -d "$B/vitis/artyZ720_led" ] || sw
  cp "$R/tcl/create_vitis_hello.py" "$B/vitis/"; rm -rf "$B/vitis/app_hello"
  cd "$B/vitis"; vitis -s create_vitis_hello.py | tee vitis_hello.log
  grep -q HELLO_SW_OK vitis_hello.log
}
prog() {
  # $1 = app_led (por defecto) o app_hello. Acepta también un ELF copiado en build/elf/
  APP=${1:-app_led}
  ELF=$( { find "$B/vitis/$APP" -name "$APP.elf" 2>/dev/null; ls "$B/elf/$APP.elf" 2>/dev/null; } | head -1)
  [ -n "$ELF" ] || { echo "Falta $APP.elf: ejecutar ./run_led.sh sw (o hello) primero"; exit 1; }
  xsdb "$R/tcl/program.tcl" "$B/hw" "$ELF"
  echo "Para ver los mensajes del ARM: screen /dev/ttyUSB1 115200"
}
case "${1:-todo}" in
  hw) hw ;; sw) sw ;; hello) hello ;; prog) prog app_led ;; prog_hello) prog app_hello ;; prog_pl) prog_pl ;;
  todo) hw; sw; prog ;;
  *) echo "uso: $0 hw|sw|prog|hello|prog_hello|prog_pl|todo"; exit 1 ;;
esac
