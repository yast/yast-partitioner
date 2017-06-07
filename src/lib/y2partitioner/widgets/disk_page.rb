require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/sequences/add_partition"
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
      # Add a partition
      class AddButton < CWM::PushButton
        # Y2Storage::Disk
        def initialize(disk)
          textdomain "storage"
          @disk = disk
        end

        def label
          _("Add...")
        end

        def handle
          slots = slots!
          return nil if slots.empty?
          res = Sequences::AddPartition.new(@disk, slots).run
          res == :finish ? :redraw : nil
        end

      private

        # FIXME: stolen from Y2Storage::Proposal::PartitionCreator
        # Make it DRY
        def partition_table(disk)
          disk.partition_table || disk.create_partition_table(disk.preferred_ptable_type)
        end

        # also tells the user if there's a problem
        def slots!
          pt = partition_table(@disk)
          slots = pt.unused_partition_slots
          if slots.empty?
            Yast::Popup.Error(
              Yast::Builtins.sformat(
                _("It is not possible to create a partition on %1."),
                @disk.name
              )
            )
          end
          slots
        end
      end

      # Edit a partition
      class EditButton < CWM::PushButton
        # Constructor
        #
        # @param disk [Y2Storage::Disk]
        # @param table [Y2Storage::Widgets::BlkDevicesTable]
        def initialize(disk, table)
          textdomain "storage"
          @disk  = disk
          @table = table
        end

        def label
          _("Edit...")
        end

        def handle
          name = @table.value[/table:partition:(.*)/, 1]
          partition = @disk.partitions.detect { |p| p.name == name }

          Dialogs::FormatAndMount.new(partition).run

          :redraw
        end
      end

      def initialize(disk, pager)
        textdomain "storage"
        @disk = disk
        @pager = pager
      end

      def initial
        true
      end

      # @macro AW
      def label
        _("&Partitions")
      end

      # @macro CW
      def contents
        @partitions_table = BlkDevicesTable.new(@disk.partitions, @pager)
        @contents ||= VBox(
          DiskBarGraph.new(@disk),
          @partitions_table,
          HBox(
            AddButton.new(@disk),
            EditButton.new(@disk, @partitions_table)
          )
        )
      end
    end
  end
end
