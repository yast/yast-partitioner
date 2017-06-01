require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/widgets/disk_table"
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
          DiskTable.new(@disk.partitions, @pager)
        )
      end
    end
  end
end
