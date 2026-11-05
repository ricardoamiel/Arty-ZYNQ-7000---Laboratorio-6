import shutil
import os
import sys
import logging

# Setup logging
logging.basicConfig(filename="clean.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Define project paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BUILD_DIR = os.path.join(PROJECT_ROOT, "build")

# Available cleaning targets
CLEAN_TARGETS = {
    "sim": os.path.join(BUILD_DIR, "sim"),
    "vivado": os.path.join(BUILD_DIR, "vivado"),
    "vitis": os.path.join(BUILD_DIR, "vitis"),
}

def clean(target=None):
    """
    Cleans the entire build directory or specific project directories.
    
    :param target: Name of the subdirectory to clean (sim, vivado, vitis).
                   If None, cleans the entire build directory.
    """
    try:
        if target:
            if target in CLEAN_TARGETS:
                dir_to_remove = CLEAN_TARGETS[target]
                print(f"Cleaning {target} directory: {dir_to_remove} ...")
                logging.info(f"Cleaning {target} directory: {dir_to_remove}")
            else:
                print(f"❌ Error: Unknown clean target '{target}'. Use 'sim', 'vivado', 'vitis', or 'all'.")
                return
        else:
            dir_to_remove = BUILD_DIR
            print(f"Cleaning entire build directory: {dir_to_remove} ...")
            logging.info(f"Cleaning entire build directory: {dir_to_remove}")

        shutil.rmtree(dir_to_remove, ignore_errors=True)
        print(f"✅ Successfully cleaned {target if target else 'all'}.")

    except Exception as e:
        logging.error(f"❌ Error during cleanup: {e}")
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    # Get target from command-line arguments
    target = sys.argv[1] if len(sys.argv) > 1 else None
    clean(target)
