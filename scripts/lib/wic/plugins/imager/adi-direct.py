import logging

from wic.plugins.imager.direct import DirectPlugin, PartitionedImage
from wic.misc import get_bitbake_var

logger = logging.getLogger('wic')

class AdiDirectPlugin(DirectPlugin):

    name = 'adi-direct'

    def __init__(self, wks_file, rootfs_dir, bootimg_dir, kernel_dir,
                 native_sysroot, oe_builddir, options):
        super().__init__(wks_file, rootfs_dir, bootimg_dir, kernel_dir,
                         native_sysroot, oe_builddir, options)
        image_path = self._full_path(self.workdir, self.parts[0].disk, "direct")
        self._image = AdiPartitionedImage(image_path, self.ptable_format,
                                          self.parts, self.native_sysroot,
                                          options.extra_space)


class AdiPartitionedImage(PartitionedImage):

    def layout_partitions(self):
        PartitionedImage.layout_partitions(self)
        img_total_size = int(get_bitbake_var("IMAGE_TOTAL_SIZE"))
        if self.min_size > img_total_size:
            logger.warning(f'Partitions sizes exceed IMAGE_TOTAL_SIZE by {self.min_size - img_total_size} bytes. Image will not be truncated.')
        self.min_size = max(self.min_size, img_total_size)
