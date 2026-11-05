# Crea plataforma standalone y la aplicacion del LED (se ejecuta con: vitis -s create_vitis_led.py)
import os
import vitis

ws = os.path.dirname(os.path.realpath(__file__))
src_dir = os.path.normpath(os.path.join(ws, "..", "..", "src"))
client = vitis.create_client()
client.update_workspace(ws)

plat = client.create_platform_component(
    name="artyZ720_led",
    hw_design=os.path.join(ws, "..", "vivado", "sys_wrapper.xsa"),
    cpu="ps7_cortexa9_0",
    os="standalone",
)
plat.build()
xpfm = client.find_platform_in_repos("artyZ720_led")

app = client.create_app_component(
    name="app_led",
    platform=xpfm,
    domain="standalone_ps7_cortexa9_0",
    template="empty_application",
)
app.import_files(from_loc=src_dir, files=["led_main.c"], dest_dir_in_cmp="src")
app.build()
vitis.dispose()
print("LED_SW_OK")
