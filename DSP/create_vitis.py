#!/usr/bin/env python
import os
import sys
import vitis

# Determine which IP core to build; default is "fir"
if len(sys.argv) > 1:
    ip = sys.argv[1]
else:
    ip = "fir"

# Create a Vitis client object
client = vitis.create_client()

# Set Vitis Workspace relative to this script's location.
script_dir = os.path.dirname(os.path.realpath(__file__))
root_dir = os.path.dirname(os.path.dirname(script_dir))

client.update_workspace(script_dir)


# Define names for platform and application component.
# (Platform remains constant here, while the app name is based on the IP core.)
plat_name = "artyZ720"
comp_name = "app_" + ip

# Create and build the platform component.
# Adjust the hw_design path as needed.
hw_design_path = os.path.join(script_dir, "sys_wrapper.xsa")
platform_obj = client.create_platform_component(
    name=plat_name,
    hw_design=hw_design_path,
    cpu="ps7_cortexa9_0",
    os="standalone"
)
platform_obj.build()

# Retrieve the platform xpfm path from the repositories.
platform_xpfm = client.find_platform_in_repos(plat_name)

# Create and build the application component.
# Here we use an "empty_application" template.
app = client.create_app_component(
    name=comp_name,
    platform=platform_xpfm,
    domain="standalone_ps7_cortexa9_0",
    template="empty_application"
)

# Set source folder based on IP core.
file_src = os.path.join(root_dir, "ip_" + ip)
# Assume the source file is named <ip>_main.c (e.g., fir_main.c, dds_main.c, etc.)
src_file = ip + "_main.c"

app.import_files(from_loc=file_src, files=[src_file], dest_dir_in_cmp='src')
app.set_app_config(key='USER_LINK_LIBRARIES', values='-lm')

# Build the application component.
app.build()

# Dispose the client.
vitis.dispose()

