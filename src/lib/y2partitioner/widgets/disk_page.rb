require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/widgets/disk_bar_graph"
require "y2partitioner/widgets/disk_description"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    # A Page for a disk: contains {DiskTab} and {PartitionsTab}
    class DiskPage < CWM::Page
      def initialize(disk, pager)
        textdomain "storage"
        @disk = disk
        @pager = pager
        self.widget_id = "disk:" + disk.name
      end

      # @macro AW
      def label
        @disk.sysfs_name
      end

      # @macro CW
      def contents
        icon = Icons.small_icon(Icons::HD)
        VBox(
          Left(
            HBox(
              Image(icon, ""),
              Heading(format(_("Hard Disk: %s"), @disk.name))
            )
          ),
          CWM::Tabs.new(
            DiskTab.new(@disk),
            PartitionsTab.new(@disk, @pager)
          )
        )
      end
    end

    # A Tab for a disk
    class DiskTab < CWM::Tab
      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      # @macro AW
      def label
        _("&Overview")
      end

      # @macro CW
      def contents
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents ||= VBox(DiskDescription.new(@disk))
      end
    end

    # A Tab for disk partitions
    class PartitionsTab < CWM::Tab
      # A temporary UI to make a simple change to the system
      # so that we can then test writing it.
      class AddTestingPartitionButton < CWM::PushButton
        # Y2Storage::Disk
        def initialize(disk)
          @disk = disk
        end

        def label
          "If there is no partition table, make a GPT table"
        end

        def handle
          pt = @disk.partition_table
          p pt
          if pt.nil?
            type = Y2Storage::PartitionTables::Type.new("gpt")
            @disk.create_partition_table(type)
          end
          pt = @disk.partition_table
          p pt
          nil
        end
      end

      def initialize(disk, pager)
        textdomain "storage"
        @disk = disk
        @pager = pager
      end

      # @macro AW
      def label
        _("&Partitions")
      end

      # @macro CW
      def contents
        @contents ||= VBox(
          DiskBarGraph.new(@disk),
          BlkDevicesTable.new(@disk.partitions, @pager),
          AddTestingPartitionButton.new(@disk)
        )
      end
    end
  end
end
