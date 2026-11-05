# Agrega la aplicación Hello World (plantilla oficial de Vitis) sobre la plataforma ya creada por run_led.sh sw
import os
import vitis

ws = os.path.dirname(os.path.realpath(__file__))
client = vitis.create_client()
client.update_workspace(ws)
xpfm = client.find_platform_in_repos("artyZ720_led")
app = client.create_app_component(
    name="app_hello",
    platform=xpfm,
    domain="standalone_ps7_cortexa9_0",
    template="hello_world",
)
app.build()
vitis.dispose()
print("HELLO_SW_OK")
