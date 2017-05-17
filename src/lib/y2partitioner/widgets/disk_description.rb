require "cwm/widget"

Yast.import "HTML"

require "y2partitioner/widgets/blk_device_attributes"

module Y2Partitioner
  module Widgets
    class DiskDescription < CWM::RichText
      include Yast::I18n

      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      def init
        self.value = disk_text
      end

    private

      attr_reader :disk
      alias_method :blk_device, :disk

      include BlkDeviceAttributes

      def partition_text
        # TODO: consider using e.g. erb for this kind of output
        output = ""
        # TRANSLATORS: heading for section about device
        output << Yast::HTML.Heading(_("Device:"))
        output << Yast::HTML.List(device_attributes_list)
        # TRANSLATORS: heading for section about Hard Disk details
        output << Yast::HTML.Heading(_("Hard Disk:"))
        output << Yast::HTML.List(disk_attributes_list)
      end

      def disk_attributes_list
        partition_table = disk.partition_table
        [
          # TRANSLATORS: Disk Vendor
          format(_("Vendor: %s"), "TODO"),
          # TRANSLATORS: Disk Model
          format(_("Model: %s"), "TODO"),
          format(_("Number of Cylinders: %s"), "Do we need it?"),
          format(_("Cylinder Size: %s"), "Do we need it?"),
          # TODO: to_human_string for Y2Storage::DataTransport
          format(_("Bus: %s"), "TODO"),
          format(_("Sector Size: %s"), "Do we need it?"),
          # TRANSLATORS: disk partition table label
          format(_("Disk Label: %s"), partition_table ? partition_table.type.to_human_string : "")
        ]
      end

      def device_attributes_list
        [
          device_name,
          device_size,
          device_udev_by_path.join(Yast::HTML.Newline),
          device_udev_by_id.join(Yast::HTML.Newline)
        ]
      end
    end
  end
end
