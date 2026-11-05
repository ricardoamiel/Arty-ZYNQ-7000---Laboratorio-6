# Lee los reportes report_power de Vivado y genera potencia_auto.tex con las tablas del informe.
# Uso: python extraer_potencia.py
import os, re

BASE = os.path.dirname(os.path.abspath(__file__))
REPORTES = {
    "LED (PS + PL)": os.path.join(BASE, "..", "LED", "build", "vivado", "reportes", "power.rpt"),
    "FFT (xFFT + DMA)": os.path.join(BASE, "..", "DSP", "build", "vivado", "power_xfft.rpt"),
    "FIR (4 filtros + DMA)": os.path.join(BASE, "..", "DSP", "build", "vivado", "power_fir.rpt"),
}
RESUMEN = [("Total On-Chip Power (W)", "Potencia total en chip (W)"),
           ("Dynamic (W)", "Potencia dinámica (W)"),
           ("Device Static (W)", "Potencia estática (W)"),
           ("Junction Temperature (C)", "Temperatura de unión (°C)")]
COMPONENTES = ["Clocks", "Slice Logic", "Signals", "Block RAM", "DSPs", "I/O", "PS7"]

def leer(path):
    txt = open(path, errors="ignore").read()
    def valor(nombre):
        m = re.search(r"\|\s*" + re.escape(nombre) + r"\s*\|\s*([0-9.<]+)", txt)
        return m.group(1) if m else "n.d."
    return {k: valor(k) for k, _ in RESUMEN} | {c: valor(c) for c in COMPONENTES}

# Copia local de los reportes en informe/reportes (se versiona en git; build/ no)
LOCAL = os.path.join(BASE, "reportes")
os.makedirs(LOCAL, exist_ok=True)
import shutil
datos = {}
for i, (n, p) in enumerate(REPORTES.items()):
    copia = os.path.join(LOCAL, ["power_led.rpt", "power_xfft.rpt", "power_fir.rpt"][i])
    if os.path.exists(p):
        shutil.copy(p, copia)
    if os.path.exists(copia):
        datos[n] = leer(copia)
out = []
if not datos:
    out.append(r"\textbf{Pendiente:} ejecutar las implementaciones para obtener los reportes de potencia.")
else:
    cols = list(datos)
    out.append(r"\begin{table}[H]\centering\caption{Resumen de potencia estimada por Vivado (report\_power).}\label{tab:pot_resumen}")
    out.append(r"\begin{tabular}{l" + "c" * len(cols) + r"}\toprule")
    out.append("Parámetro & " + " & ".join(cols) + r"\\\midrule")
    for k, et in RESUMEN:
        out.append(et + " & " + " & ".join(datos[c][k] for c in cols) + r"\\")
    out.append(r"\bottomrule\end{tabular}\end{table}")
    out.append(r"\begin{table}[H]\centering\caption{Potencia dinámica por componente (W).}\label{tab:pot_comp}")
    out.append(r"\begin{tabular}{l" + "c" * len(cols) + r"}\toprule")
    out.append("Componente & " + " & ".join(cols) + r"\\\midrule")
    for c in COMPONENTES:
        # Vivado omite los componentes que el diseño no usa: se reportan como 0
        out.append(c.replace("PS7", "PS7 (procesador)") + " & " + " & ".join(datos[x][c].replace("n.d.", "0") for x in cols) + r"\\")
    out.append(r"\bottomrule\end{tabular}\end{table}")
    # Potencia dinámica de la PL = dinámica total menos PS7
    pl = []
    for x in cols:
        try: pl.append(f"{float(datos[x]['Dynamic (W)']) - float(datos[x]['PS7']):.3f}")
        except ValueError: pl.append("n.d.")
    out.append(r"\begin{table}[H]\centering\caption{Potencia dinámica atribuible solo a la lógica programable (dinámica total menos PS7).}\label{tab:pot_pl}")
    out.append(r"\begin{tabular}{l" + "c" * len(cols) + r"}\toprule")
    out.append(" & " + " & ".join(cols) + r"\\\midrule")
    out.append("PL dinámica (W) & " + " & ".join(pl) + r"\\")
    out.append(r"\bottomrule\end{tabular}\end{table}")
open(os.path.join(BASE, "potencia_auto.tex"), "w").write("\n".join(out) + "\n")
print("potencia_auto.tex generado con:", list(datos) or "ningún reporte")
