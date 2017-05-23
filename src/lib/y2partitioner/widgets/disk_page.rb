require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/widgets/disk_description"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    class DiskPage < CWM::Page
      def initialize(disk)
        textdomain "storage"
        @disk = disk
        self.widget_id = "disk:" + disk.name
      end

      def label
        @disk.sysfs_name
      end

      def contents
        icon = Icons.small_icon(Icons::HD)
        VBox(
          Left(HBox(
            Image(icon, ""),
            Heading(format(_("Hard Disk: %s"), @disk.name))
          )),
          CWM::Tabs.new(
           DiskTab.new(@disk),
            PartitionsTab.new(@disk.partitions)
          )
        )
      end
    end

    class DiskTab < CWM::Tab
      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      def label
        _("&Overview")
      end

      def contents
        @contents ||= VBox(DiskDescription.new(@disk))
      end
    end

    class PartitionsTab < CWM::Tab
      def initialize(partitions)
        textdomain "storage"
        @partitions = partitions
      end

      def label
        _("&Partitions")
      end

      def contents
        @contents ||= VBox(BlkDevicesTable.new(@partitions))
      end
    end
  end
end
