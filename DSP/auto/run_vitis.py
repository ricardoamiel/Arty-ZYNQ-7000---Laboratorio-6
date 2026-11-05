#!/usr/bin/env python
import os
import shutil
import subprocess
import sys
import platform
import logging

# Setup logging
logging.basicConfig(filename="vitis.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Detect OS
IS_WINDOWS = platform.system() == "Windows"

# Define paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
VITIS_DIR = os.path.join(PROJECT_ROOT, "build", "vitis")

if IS_WINDOWS:
    VITIS_DIR = os.path.normpath(VITIS_DIR)

# Find Vitis executable dynamically
VITIS_CMD = shutil.which("vitis.bat" if IS_WINDOWS else "vitis")
if not VITIS_CMD:
    print("❌ Error: Vitis not found in system PATH. Make sure Vitis is installed and added to PATH.")
    sys.exit(1)

def run_vitis(ip="fir"):
    try:
        logging.info(f"Running Vitis for IP: {ip}")
        print(f"🔄 Running Vitis for IP: {ip}...")

        os.makedirs(VITIS_DIR, exist_ok=True)

        # Copy necessary files
        shutil.copy(os.path.join(PROJECT_ROOT, "create_vitis.py"), VITIS_DIR)
        shutil.copy(os.path.join(PROJECT_ROOT, "build", "vivado", "sys_wrapper.xsa"), VITIS_DIR)
        logging.info("Copied create_vitis.py and sys_wrapper.xsa to Vitis build directory.")

        # Log file for Vitis output
        vitis_log_path = os.path.join(VITIS_DIR, "vitis_build.log")

        with open(vitis_log_path, "w") as log_file:
            command = [VITIS_CMD, "-s", "create_vitis.py", ip]
            if IS_WINDOWS:
                command = ["cmd.exe", "/c"] + command

            process = subprocess.Popen(command, cwd=VITIS_DIR, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            for line in process.stdout:
                print(line, end="")
                log_file.write(line)

            process.wait()

        if process.returncode == 0:
            logging.info("✅ Vitis project build completed successfully.")
            print(f"✅ {ip} Vitis project build completed successfully.")
            # Launch the Vitis IDE in GUI mode using the workspace flag (-w)
            print("🔄 Launching Vitis IDE in GUI mode...")
            command_gui = [VITIS_CMD, "-w", VITIS_DIR]
            if IS_WINDOWS:
                command_gui = ["cmd.exe", "/c"] + command_gui
            subprocess.Popen(command_gui, cwd=VITIS_DIR)
        else:
            logging.error("❌ Vitis build failed. Check vitis_build.log for details.")
            print(f"❌ Vitis build failed. Check {vitis_log_path} for details.")

    except Exception as e:
        logging.error(f"❌ Error in Vitis execution: {e}")
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    ip_name = sys.argv[1] if len(sys.argv) > 1 else "fir"
    run_vitis(ip_name)
