# Envía clics y atajos de teclado a una pantalla X (Xvfb) con XTest. Requiere python-xlib.
# Uso: python3 xteclas.py :99 click 1452 115 | tecla ctrl+0 | maximizar 2560 1440
import sys, time
from Xlib import X, XK, display
from Xlib.ext import xtest

d = display.Display(sys.argv[1])
accion = sys.argv[2]
if accion == "click":
    x, y = int(sys.argv[3]), int(sys.argv[4])
    xtest.fake_input(d, X.MotionNotify, x=x, y=y); d.sync(); time.sleep(0.3)
    xtest.fake_input(d, X.ButtonPress, 1); d.sync(); time.sleep(0.1)
    xtest.fake_input(d, X.ButtonRelease, 1); d.sync()
elif accion == "tecla":
    nombres = {"ctrl": "Control_L", "shift": "Shift_L", "alt": "Alt_L"}
    codigos = [d.keysym_to_keycode(XK.string_to_keysym(nombres.get(k, k))) for k in sys.argv[3].split("+")]
    for c in codigos:
        xtest.fake_input(d, X.KeyPress, c); d.sync(); time.sleep(0.05)
    for c in reversed(codigos):
        xtest.fake_input(d, X.KeyRelease, c); d.sync(); time.sleep(0.05)
elif accion == "maximizar":
    # Sin gestor de ventanas no hay botón de maximizar: se redimensiona la ventana directamente en el servidor X
    ancho, alto = int(sys.argv[3]), int(sys.argv[4])
    raiz = d.screen().root
    def recorrer(w):
        for h in w.query_tree().children:
            nombre = h.get_wm_name() or ""
            if "Vivado" in nombre or "Vitis" in nombre:
                h.configure(x=0, y=0, width=ancho, height=alto)
                print("ventana ajustada:", nombre)
            recorrer(h)
    recorrer(raiz)
    d.sync()
time.sleep(0.5)
