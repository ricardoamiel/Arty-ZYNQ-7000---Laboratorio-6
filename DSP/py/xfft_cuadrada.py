# Análisis de la FFT con la señal cuadrada que inyecta el ARM (xfft_main.c).
# Fuente "sim": binarios y VCD del testbench xfft_square_tb (build/xfft_sq_*).
# Fuente "placa": volcados de la DDR leídos con xsdb (build/placa/*.bin, little endian).
# Uso: python3 py/xfft_cuadrada.py [sim|placa]
import os
import sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

FUENTE = sys.argv[1] if len(sys.argv) > 1 else "sim"
N, PERIODO, AMP, FS = 2048, 64, 16000, 100e6
OUT = "resultados"
os.makedirs(OUT, exist_ok=True)
plt.rcParams.update({"font.size": 9, "axes.grid": True, "grid.alpha": 0.3})


def guardar(fig, nombre):
    for ext in ("pdf", "svg"):
        fig.savefig(f"{OUT}/{nombre}.{ext}", bbox_inches="tight")
    plt.close(fig)
    print(f"figura: {OUT}/{nombre}.pdf y .svg")


def leer_sim(ruta):
    w = np.fromfile(ruta, dtype=">u4")              # palabra de 32 bits: [31:16] imag, [15:0] real
    re = (w & 0xFFFF).astype(np.uint16).view(np.int16)
    im = (w >> 16).astype(np.uint16).view(np.int16)
    return re.astype(float) + 1j * im.astype(float)


def leer_placa(ruta):
    d = np.fromfile(ruta, dtype="<i2").reshape(-1, 2)  # bytes en DDR: re (LE), im (LE)
    return d[:, 0].astype(float) + 1j * d[:, 1].astype(float)


if FUENTE == "sim":
    x, X, y = (leer_sim(f"build/xfft_sq_{n}.bin") for n in ("input", "fwd_out", "inv_out"))
    sufijo, origen = "sim", "simulación (xsim)"
else:
    x, X, y = (leer_placa(f"build/placa/{n}.bin") for n in ("entrada", "fft", "ifft"))
    sufijo, origen = "placa", "Arty Z7-20 (FPGA + ARM)"

x, X, y = x[:N], X[:N], y[:N]
ref = np.fft.fft(x)
k = np.arange(N)
k0 = N // PERIODO
escala = np.abs(X[k0]) / np.abs(ref[k0])
err_fft = np.max(np.abs(X - ref * escala)) / np.max(np.abs(ref * escala))
sim_ifft = np.abs(np.vdot(x, y)) / np.linalg.norm(x) / np.linalg.norm(y)

print(f"Fuente: {origen}")
print(f"Muestras: entrada {len(x)}, FFT {len(X)}, IFFT {len(y)}")
print(f"Fundamental en k = {k0} ({k0 * FS / N / 1e6:.4f} MHz)")
for m in range(0, 7):
    kk = k0 * m
    print(f"  k={kk:4d}  |X| FPGA={np.abs(X[kk]):9.1f}   |X| numpy*escala={np.abs(ref[kk]) * escala:9.1f}")
print(f"Escala FPGA/numpy = {escala:.6f} (1/{1 / escala:.0f})")
print(f"Error máximo relativo FFT frente a numpy escalado = {err_fft:.4f}")
print(f"Similitud entrada frente a IFFT = {sim_ifft:.6f}; amplitud IFFT máx = {np.abs(y.real).max():.0f}")

# Figura 1: entrada, espectro y reconstrucción
fig, ax = plt.subplots(3, 1, figsize=(8, 8))
t = np.arange(N) / FS * 1e6
ax[0].plot(t[:256], x.real[:256], "b", lw=1.2, drawstyle="steps-post")
ax[0].set(title="Entrada inyectada por el ARM: señal cuadrada (periodo 64 muestras, 1.5625 MHz)",
          xlabel="Tiempo (µs)", ylabel="Amplitud")
f = k * FS / N / 1e6
mitad = N // 2
ax[1].stem(f[:mitad], np.abs(X[:mitad]), linefmt="b-", markerfmt="bo", basefmt=" ", label="FFT en la FPGA")
ax[1].plot(f[:mitad], np.abs(ref[:mitad]) * escala, "rx", ms=4, label="numpy.fft escalada")
ax[1].set_xlim(0, 25)
ax[1].set(title=f"Magnitud de la FFT ({origen}): armónicos impares en k = 32, 96, 160, ...",
          xlabel="Frecuencia (MHz)", ylabel="|X[k]|")
ax[1].legend()
ax[2].plot(t[:256], x.real[:256], "b", lw=2.5, alpha=0.4, label="Entrada", drawstyle="steps-post")
ax[2].plot(t[:256], y.real[:256], "r--", lw=1, label="Salida de la IFFT", drawstyle="steps-post")
ax[2].set(title="Reconstrucción con la FFT inversa", xlabel="Tiempo (µs)", ylabel="Amplitud")
ax[2].legend(loc="upper right")
fig.tight_layout()
guardar(fig, f"xfft_cuadrada_{sufijo}")


# Diagrama de tiempo a partir del VCD de la simulación
def leer_vcd(ruta):
    ids, nombres, ancho, datos = {}, {}, {}, {}
    tiempo = 0
    with open(ruta) as fh:
        for linea in fh:
            p = linea.split()
            if not p:
                continue
            if p[0] == "$var":
                ids.setdefault(p[3], []).append(p[4])
                ancho[p[4]] = int(p[2])
                datos[p[4]] = []
            elif p[0].startswith("#"):
                tiempo = int(p[0][1:])
            elif p[0][0] in "01xz" and len(p) == 1:
                for n in ids.get(p[0][1:], []):
                    datos[n].append((tiempo, p[0][0]))
            elif p[0][0] == "b" and len(p) == 2:
                for n in ids.get(p[1], []):
                    datos[n].append((tiempo, p[0][1:]))
    return datos, ancho


def valor_en(serie, ts, ancho):
    out, j, v = [], 0, "0"
    for tt in ts:
        while j < len(serie) and serie[j][0] <= tt:
            v = serie[j][1]
            j += 1
        try:
            n = int(v, 2)
        except ValueError:
            n = 0
        out.append(n)
    return np.array(out)


def a_signed16(v):
    v = v & 0xFFFF
    return np.where(v >= 0x8000, v - 0x10000, v)


if FUENTE == "sim" and os.path.exists("build/xfft_sq.vcd"):
    d, w = leer_vcd("build/xfft_sq.vcd")
    unidad = 1e-3  # timescale 1ps en el VCD: 1000 por ns

    def serie(nombre, ts):
        return valor_en(d[nombre], ts, w[nombre])

    t_in = [tt for tt, v in d["s_axis_xfft_tvalid"] if v == "1"]
    t_fft = [tt for tt, v in d["m_axis_fft_tvalid"] if v == "1"]
    t_ifft = [tt for tt, v in d["m_axis_ifft_tvalid"] if v == "1"]
    ini_in, ini_fft, ini_ifft = t_in[0] * unidad, t_fft[0] * unidad, t_ifft[0] * unidad
    print(f"Primera muestra de entrada: {ini_in:.0f} ns; primera salida FFT: {ini_fft:.0f} ns; "
          f"primera salida IFFT: {ini_ifft:.0f} ns")
    print(f"Latencia de la FFT (fin de entrada a inicio de salida aprox.): {ini_fft - ini_in - N * 10:.0f} ns")

    senales = [("aresetn", "aresetn"), ("s_config_fft_tvalid", "config FFT tvalid"),
               ("s_axis_xfft_tvalid", "entrada tvalid"), ("s_axis_xfft_tready", "entrada tready"),
               ("s_axis_xfft_tlast", "entrada tlast"), ("m_axis_fft_tvalid", "FFT salida tvalid"),
               ("m_axis_fft_tlast", "FFT salida tlast"), ("m_axis_ifft_tvalid", "IFFT salida tvalid"),
               ("m_axis_ifft_tlast", "IFFT salida tlast")]

    def diagrama(t0, t1, paso, titulo, nombre, con_reloj, datos_bus):
        ts = np.arange(t0, t1, paso / unidad)
        tns = ts * unidad
        filas = (["aclk"] if con_reloj else []) + [s for s, _ in senales]
        etiquetas = (["aclk"] if con_reloj else []) + [e for _, e in senales]
        if datos_bus:
            filas.append("s_axis_xfft_tdata")
            etiquetas.append("entrada tdata (real)")
        n = len(filas)
        fig, ax = plt.subplots(figsize=(10, 0.42 * n + 1.3))
        for i, s in enumerate(filas):
            y0 = n - 1 - i
            ax.axhline(y0 - 0.1, color="0.85", lw=0.6)
            v = serie(s, ts)
            if s == "s_axis_xfft_tdata":
                re = a_signed16(v)
                if paso >= 10:      # vista general: forma de onda escalada
                    ax.step(tns, y0 + 0.1 + 0.6 * (re / AMP + 1) / 2, where="post", color="g", lw=0.8)
                else:               # zoom: bus con su valor en cada tramo
                    cambios = np.r_[0, np.nonzero(np.diff(re))[0] + 1, len(re)]
                    for a, b in zip(cambios[:-1], cambios[1:]):
                        xa, xb = tns[a], tns[min(b, len(tns) - 1)]
                        ax.plot([xa, xb], [y0 + 0.1, y0 + 0.1], "g", lw=0.9)
                        ax.plot([xa, xb], [y0 + 0.7, y0 + 0.7], "g", lw=0.9)
                        ax.plot([xa, xa], [y0 + 0.1, y0 + 0.7], "g", lw=0.9)
                        if xb - xa > (tns[-1] - tns[0]) * 0.06:
                            ax.text((xa + xb) / 2, y0 + 0.4, str(int(re[a])), ha="center", va="center", fontsize=7)
                continue
            v = (v > 0).astype(float)
            color = "k" if s == "aclk" else "tab:blue"
            ax.step(tns, y0 + 0.7 * v, where="post", color=color, lw=0.9)
            if s != "aclk":
                ax.fill_between(tns, y0, y0 + 0.7 * v, step="post", color=color, alpha=0.18, lw=0)
        ax.set_yticks([n - 1 - i + 0.35 for i in range(n)])
        ax.set_yticklabels(etiquetas)
        ax.set_ylim(-0.2, n)
        ax.set_xlim(tns[0], tns[-1])
        ax.set_xlabel("Tiempo (ns)")
        ax.set_title(titulo)
        ax.grid(True, axis="x", alpha=0.3)
        ax.grid(False, axis="y")
        fig.tight_layout()
        guardar(fig, nombre)

    t_fin_sim = max(s[-1][0] for s in d.values() if s)
    diagrama(0, t_fin_sim, 20,
             "Diagrama de tiempo completo: configuración, trama de entrada, salida FFT y salida IFFT",
             "diagrama_tiempo_general", False, True)
    diagrama((ini_in - 40) / unidad, (ini_in + 400) / unidad, 1,
             "Inicio de la trama de entrada: protocolo AXI4 Stream (tvalid y tready a 100 MHz)",
             "diagrama_tiempo_inicio", True, True)
    fin_in = t_in[-1] * unidad
    diagrama((fin_in - 300) / unidad, (fin_in + 100) / unidad, 1,
             "Fin de la trama de entrada: tlast marca la muestra 2048",
             "diagrama_tiempo_fin_trama", True, True)
