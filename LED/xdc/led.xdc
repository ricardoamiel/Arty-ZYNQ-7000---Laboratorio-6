## Arty Z7-20: LEDs LD0 a LD3 y switch SW0 (manual de referencia de Digilent)
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led_ps[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led_ps[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led_pl[0]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led_pl[1]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw0}]
