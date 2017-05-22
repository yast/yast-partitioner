require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/widgets/disk_description"

module Y2Partitioner
  module Widgets
    class DiskPage < CWM::Page
      def initialize(disk)
        @disk = disk
        id = "disk:" + disk.name
        super(widget_id: id, label: disk.sysfs_name, contents: contents)
      end

      def contents
        VBox(CWM::Tabs.new(
          DiskTab.new(@disk),
          PartitionsTab.new(@disk.partitions)
        ))
      end
    end

    class DiskTab < CWM::Tab
      def initialize(disk)
        @disk = disk
      end

      def label
        textdomain "storage"
        _("&Overview")
      end

      def contents
        @contents ||= VBox(DiskDescription.new(@disk))
      end
    end

    class PartitionsTab < CWM::Tab
      def initialize(partitions)
        @partitions = partitions
      end

      def label
        textdomain "storage"
        _("&Partitions")
      end

      def contents
        @contents ||= VBox(BlkDevicesTable.new(@partitions))
      end
    end
  end
end
