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

### Notes for adrv904x-rd-ru

The adrv904x-rd-ru platform has multiple interfaces:

* eth0 - management port, dhcp-enabled, falls back to 192.168.1.30/24
* eth1 - MSP access for PTP PHC, dhcp-enabled, falls back to 192.168.2.31/24
* etile0/etile1 - 10G / 25G SFP interfaces O-RAN C/U plane data, configured by driver

## Modifiable user/group database

User/group database (/etc/passwd, /etc/group, etc.) can be moved to the writable
data partition (/data/active) using the following variable. This is useful when
the read-only-rootfs feature is enabled but add/remove/modify user/group
functionality is required.

NOTE: Moving these files to writable storage removes them from the secure boot
chain-of-trust and makes them potentially vulnerable to offline attacks.
ADI does not recommend using this feature.

    ADI_CC_USER_DB_ON_DATA_PART = "1"

