# Ejecuta un script de py/ sin ventana y guarda sus figuras en resultados/<nombre>_N.pdf y .svg (vectorial)
import os, sys, runpy
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

nombre = sys.argv[1]                      # xfft o fir_compiler
os.makedirs("resultados", exist_ok=True)

def guardar(*a, **k):
    for i in plt.get_fignums():
        for ext in ("pdf", "svg"):       # formatos vectoriales para el informe
            plt.figure(i).savefig(f"resultados/{nombre}_{i}.{ext}", bbox_inches="tight")
        print(f"figura guardada: resultados/{nombre}_{i}.pdf y .svg")
    plt.close("all")

plt.show = guardar
runpy.run_path(os.path.join("py", nombre + ".py"), run_name="__main__")
