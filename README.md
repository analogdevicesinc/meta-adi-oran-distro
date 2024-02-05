# meta-adi-oran-distro

This Yocto layer defines the base Linux distro used in ADI O-RAN applications.
This includes a complete general-purpose userspace, but does not include the
software specific to O-RAN networking (those are provided in a separate layer).

## Dependencies

oe-core (kirkstone)
meta-mono

Although not required, this layer is typically used together with the
"meta-adi-oran-bsp" layer.

## Licensing

Recipes are released under the MIT license. See `COPYING.MIT` for details.

## Patches

Please submit any patches against the meta-adi-oran-distro layer to the O-RAN
Support mailing list (pci_support@analog.com).

## SystemD vs SysVInit

Officially, this layer only supports SysVInit. Un-officially, support for SystemD
is mostly working. To enable support for SystemD, add the following to your local
configuration file:

    ADI_CC_SYSTEMD_INIT = "1"

## Custom "BUILD_VERSION"

Init script can setup custom "BUILD_VERSION" using the below variable, then
it will be integrated into the /etc/os-release file for identifying the rootfs 
custom version(for wic image). e.g.:

    ADI_CC_BUILD_VERSION = "0.8.0"

## Connectivity 

Whether the build is using SystemD and netplan or SysVInit and if-up-down as IP 
configurator the configuration is the same. The 10/25G QSFP interfaces are given 
static IP addresses in different ranges while the 1G RJ45 interface uses DHCP but 
has a fallback address should DHCP fails. The fallback address is 
configurable by adding the following to your local configuration file:

    ADI_CC_FALLBACK_ADDRESS = “xxx.xxx.xxx.xxx/xx”
