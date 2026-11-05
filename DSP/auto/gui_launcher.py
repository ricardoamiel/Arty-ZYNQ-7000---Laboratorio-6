import tkinter as tk
from tkinter import messagebox
import subprocess
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

def run_command(command):
    try:
        # Using check=True will raise an exception on nonzero exit code.
        subprocess.run(command, shell=True, check=True)
        messagebox.showinfo("Success", f"{command} executed successfully!")
    except Exception as e:
        messagebox.showerror("Error", f"Failed to execute {command}.\nError: {e}")

root = tk.Tk()
root.title("Vivado & Vitis Automation")
root.geometry("300x500")

tk.Label(root, text="Select an action:", font=("Arial", 12)).pack(pady=10)

# Add target (IP core) selection option menu
tk.Label(root, text="Select target (IP):", font=("Arial", 10)).pack(pady=5)
target_var = tk.StringVar(root)
target_var.set("fir")  # default target
ip_targets = ["fir", "cic", "dds", "xfft"]
tk.OptionMenu(root, target_var, *ip_targets).pack(pady=5)

# Add clean target option menu
tk.Label(root, text="Select clean target:", font=("Arial", 10)).pack(pady=5)
clean_target = tk.StringVar(root)
clean_target.set("all")  # default clean target
clean_options = ["all", "sim", "vivado", "vitis"]
tk.OptionMenu(root, clean_target, *clean_options).pack(pady=5)

# Action buttons
tk.Button(root, text="Run Vivado", 
          command=lambda: run_command(f"python {SCRIPT_DIR}/run_vivado.py {target_var.get()}"), 
          width=20).pack(pady=5)
tk.Button(root, text="Run Simulation", 
          command=lambda: run_command(f"python {SCRIPT_DIR}/run_sim.py {target_var.get()}"), 
          width=20).pack(pady=5)
tk.Button(root, text="Run Vitis", 
          command=lambda: run_command(f"python {SCRIPT_DIR}/run_vitis.py {target_var.get()}"), 
          width=20).pack(pady=5)
tk.Button(root, text="Clean Build", 
          command=lambda: run_command(f"python {SCRIPT_DIR}/clean.py {clean_target.get()}"), 
          width=20).pack(pady=5)

root.mainloop()
