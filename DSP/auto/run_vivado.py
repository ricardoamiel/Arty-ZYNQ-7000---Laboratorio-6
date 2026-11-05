import os
import shutil
import subprocess
import sys
import platform
import logging
import shutil  # Used to find executables

# Setup logging
logging.basicConfig(filename="vivado.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Detect OS
IS_WINDOWS = platform.system() == "Windows"

# Define paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
VIVADO_DIR = os.path.join(PROJECT_ROOT, "build", "vivado")

if IS_WINDOWS:
    VIVADO_DIR = os.path.normpath(VIVADO_DIR)

# Find Vivado executable dynamically
VIVADO_CMD = shutil.which("vivado.bat" if IS_WINDOWS else "vivado")
if not VIVADO_CMD:
    print("❌ Error: Vivado not found in system PATH. Make sure Vivado is installed and added to PATH.")
    sys.exit(1)

def run_vivado(ip="fir"):
    try:
        logging.info(f"Running Vivado for IP: {ip}")
        print(f"🔄 Running Vivado for IP: {ip}...")

        vivado_ip_dir = os.path.join(VIVADO_DIR, ip)
        os.makedirs(vivado_ip_dir, exist_ok=True)

        # Copy necessary TCL scripts
        shutil.copy(os.path.join(PROJECT_ROOT, f"ip_{ip}/tcl/{ip}_sys.tcl"), vivado_ip_dir)
        shutil.copy(os.path.join(PROJECT_ROOT, f"ip_{ip}/tcl/{ip}_hw.tcl"), vivado_ip_dir)
        logging.info(f"Copied TCL scripts to {vivado_ip_dir}")

        # Log file for Vivado output
        vivado_log_path = os.path.join(vivado_ip_dir, "vivado_hw.log")

        with open(vivado_log_path, "w") as log_file:
            command = [VIVADO_CMD, "-nolog", "-nojournal", "-mode", "batch", "-source", f"{ip}_hw.tcl"]
            if IS_WINDOWS:
                command = ["cmd.exe", "/c"] + command

            process = subprocess.Popen(command, cwd=vivado_ip_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            for line in process.stdout:
                print(line, end="")
                log_file.write(line)

            process.wait()

        if process.returncode == 0:
            logging.info("✅ Vivado completed successfully.")
            print(f"✅ {ip} hardware build completed successfully.")
        else:
            logging.error("❌ Vivado failed. Check vivado_hw.log for details.")
            print(f"❌ Vivado failed. Check {vivado_log_path} for details.")

    except Exception as e:
        logging.error(f"❌ Error in Vivado execution: {e}")
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    ip_name = sys.argv[1] if len(sys.argv) > 1 else "fir"
    run_vivado(ip_name)
