import os
import shutil
import subprocess
import sys
import platform
import logging
import shutil

# Setup logging
logging.basicConfig(filename="simulation.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Detect OS
IS_WINDOWS = platform.system() == "Windows"

# Define paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
SIM_DIR = os.path.join(PROJECT_ROOT, "build")

if IS_WINDOWS:
    SIM_DIR = os.path.normpath(SIM_DIR)

# Find Vivado executable dynamically
VIVADO_CMD = shutil.which("vivado.bat" if IS_WINDOWS else "vivado")
if not VIVADO_CMD:
    print("❌ Error: Vivado not found in system PATH. Make sure Vivado is installed and added to PATH.")
    sys.exit(1)

def run_sim(ip="fir"):
    try:
        logging.info(f"Running simulation for IP: {ip}")
        print(f"🔄 Running simulation for IP: {ip}...")

        os.makedirs(SIM_DIR, exist_ok=True)

        # Copy simulation TCL script
        shutil.copy(os.path.join(PROJECT_ROOT, "dsp_sim.tcl"), SIM_DIR)
        logging.info(f"Copied dsp_sim.tcl to {SIM_DIR}")

        # Log file for simulation output
        sim_log_path = os.path.join(SIM_DIR, "vivado_sim.log")

        with open(sim_log_path, "w") as log_file:
            command = [VIVADO_CMD, "-mode", "batch", "-source", "dsp_sim.tcl", "-tclargs", ip]
            if IS_WINDOWS:
                command = ["cmd.exe", "/c"] + command

            process = subprocess.Popen(command, cwd=SIM_DIR, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            for line in process.stdout:
                print(line, end="")
                log_file.write(line)

            process.wait()

        if process.returncode == 0:
            logging.info("✅ Simulation completed successfully.")
            print(f"✅ {ip} simulation completed successfully.")
        else:
            logging.error("❌ Simulation failed. Check vivado_sim.log for details.")
            print(f"❌ Simulation failed. Check {sim_log_path} for details.")

    except Exception as e:
        logging.error(f"❌ Error in simulation execution: {e}")
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    ip_name = sys.argv[1] if len(sys.argv) > 1 else "fir"
    run_sim(ip_name)
