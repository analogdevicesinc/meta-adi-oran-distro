#!/usr/bin/env python3

#-------------------------------------------------------------------------------------
# adi_generate_its_from_fit -- Generates an .its file from a FIT image using dumpimage
#
# adi_generate_its_from_fit <fit_image>
#
# Arguments:
#   <fit_image>   path to the FIT image
#
# Returns 0 on success, 1 on failure
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------------------

# python ttp dumpimage templates

template_image = """
 Image {{ number }} ({{ name }})
  Description:  {{ description | ORPHRASE }}
  Type:         {{ type | ORPHRASE }}
  Compression:  {{ compression | ORPHRASE }}
  Architecture: {{ arch }}
  OS:           {{ os }}
  Load Address: {{ load_address }}
  Entry Point:  {{ entry_point }}
  Hash algo:    {{ hash_algo }}
"""

template_configuration = """
 Configuration  {{ number }} ({{ name }})
  Description:  {{ description | ROW }}
  Kernel:       {{ kernel }}
  Init Ramdisk: {{ ramdisk }}
  FDT:          {{ dtb }}
  Hash algo:    {{ hash_algo }}
  Sign algo:    {{ sign_algo }}
  Sign padding: {{ sign_padding }}
"""

# Device-tree parts

fdt_header_to_images = """\
/dts-v1/;

/ {
    description = "%s";
    #address-cells = <1>;

    images {\
"""

fdt_images_to_configurations = """\
    };

    configurations {
        default = "%s";\
"""

fdt_end = """\
    };
};
"""

# Indentation
IND_08 = ' ' * 8;
IND_12 = ' ' * 12;
IND_16 = ' ' * 16;

#-------------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------------
def parse_dumpimage(dumpimage_data):
    from ttp import ttp
    import json
    # Parse against templates
    parser = ttp()
    parser.add_template(template_image)
    parser.add_template(template_configuration)
    parser.add_input(dumpimage_data)
    parser.parse()
    # Get images/configs info
    images_json  = json.loads(parser.result(format="json")[0])[0]
    configs_json = json.loads(parser.result(format="json")[1])
    return images_json, configs_json

def replace_value(data, key, old_value, new_value):
    import re
    return re.sub('%s.*%s' % (key, old_value), "%-13s %s" % (key, new_value), data)

def remove_lines_containing_unavailable(data):
    import re
    return re.sub('.*unavailable.*', "", data)

def adapt_to_fdt_names(data):
    data = replace_value(data, "Type:",         "Kernel Image",     "kernel")
    data = replace_value(data, "Type:",         "Flat Device Tree", "flat_dt")
    data = replace_value(data, "Type:",         "RAMDisk Image",    "ramdisk")
    data = replace_value(data, "Compression:",  "gzip compressed",  "gzip")
    data = replace_value(data, "Compression:",  "uncompressed",     "none")
    data = replace_value(data, "Architecture:", "AArch64",          "arm64")
    data = replace_value(data, "OS:",           "Linux",            "linux")
    data = replace_value(data, "OS:",           "Linux",            "linux")
    data = remove_lines_containing_unavailable (data)
    return data

def get_json_field(json, image_num, field_name):
    return json[0][image_num]["%s" % field_name]

def print_parameter(json, format, param_name):
    if param_name in json.keys():
        print(format % json[param_name])

def print_images(json):
    for image in json:
        print_parameter(image, IND_08 + '%s {', 'name')
        print_parameter(image, IND_12 + 'description = \"%s\";', 'description')
        print_parameter(image, IND_12 + 'data = /incbin/(\"%s\");', 'name')
        print_parameter(image, IND_12 + 'type = \"%s\";', 'type')
        print_parameter(image, IND_12 + 'arch = \"%s\";', 'arch')
        print_parameter(image, IND_12 + 'os = \"%s\";', 'os')
        print_parameter(image, IND_12 + 'compression = \"%s\";', 'compression')
        print_parameter(image, IND_12 + 'load = <%s>;', 'load_address')
        print_parameter(image, IND_12 + 'entry = <%s>;', 'entry_point')
        print(IND_12 + 'hash-1 {')
        print_parameter(image, IND_16 + 'algo = \"%s\";', 'hash_algo')
        print(IND_12 + '};')
        print(IND_08 + '};')

def print_configs(json, fdt_secondary_name):
    for config in json:
        print_parameter(config, IND_08 + '%s {', 'name')
        print_parameter(config, IND_12 + 'description = \"%s\";', 'description')
        print_parameter(config, IND_12 + 'kernel = \"%s\";', 'kernel')
        print_parameter(config, IND_12 + 'fdt = \"%s\";', 'dtb')
        print(IND_12 + 'fdt-secondary = \"%s\";' % fdt_secondary_name)
        print_parameter(config, IND_12 + 'ramdisk = \"%s\";', 'ramdisk')
        print(IND_12 + 'hash-1 {')
        print_parameter(config, IND_16 + 'algo = \"%s\";', 'hash_algo')
        print(IND_12 + '};')
        print(IND_12 + 'signature-1 {')
        print(IND_16 + 'algo = \"%s\";' % config['sign_algo'].split(':')[0])
        print(IND_16 + 'key-name-hint = \"%s\";' % config['sign_algo'].split(':')[1])
        print_parameter(config, IND_16 + 'padding = \"%s\";', 'sign_padding')
        print(IND_16 + 'sign-images = \"kernel\", \"fdt\", \"fdt-secondary\", \"ramdisk\";')
        print(IND_12 + '};')
        print(IND_08 + '};')

#-------------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------------
import sys
import subprocess
import re

# Get FIT image path
fit_image = sys.argv[1]

# Verify FIT image
ret = subprocess.run("dumpimage -l %s | grep \"FIT description\" > /dev/null" % fit_image, shell=True, capture_output=True, text=True)
if ret.returncode != 0:
    print("\"%s\" is not a FIT image" % fit_image)
    sys.exit(1)
data =  ret.stdout

# Run 'dumpimage -l'
ret = subprocess.run("dumpimage -l %s" % fit_image, shell=True, capture_output=True, text=True)
if ret.returncode != 0:
    print("Cannot dumpimage -l %s" % fit_image)
    sys.exit(1)
data =  ret.stdout

# Gather single variables
fit_description       = re.search('(?<=FIT description: ).*', data).group(0)
default_configuration = re.search('(?<=Default Configuration: ).*', data).group(0).replace('\'','')

# Adapt dumpimage naming to fdt (AArch64->arm64, Linux->linux,...)
data = adapt_to_fdt_names(data)

# Get images and configs from dumpimage
images_json, configs_json = parse_dumpimage(data)

# Print device-tree
print(fdt_header_to_images % fit_description)
print_images(images_json)
print(fdt_images_to_configurations % default_configuration)
print_configs(configs_json, images_json[2]['name'])
print(fdt_end)
