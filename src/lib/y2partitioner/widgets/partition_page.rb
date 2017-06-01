require "cwm/tree_pager"

require "y2partitioner/widgets/partition_description"
require "y2partitioner/dialogs/format_and_mount"

module Y2Partitioner
  module Widgets
    # A Page for a partition
    class PartitionPage < CWM::Page
      # Edit a partition
      class EditButton < CWM::PushButton
        # @param partition [Y2Storage::Partition] FIXME: unsure which type we want
        def initialize(partition)
          # do we need this in every little tiny class?
          textdomain "storage"
          @partition = partition
        end

        def label
          _("Edit...")
        end

        def opt
          [:key_F4]
        end

        def handle
          # Formerly:
          # EpEditPartition -> DlgEditPartition -> (MiniWorkflow:
          #   MiniWorkflowStepFormatMount, MiniWorkflowStepPassword)
          Dialogs::FormatAndMount.new(@partition).run
          nil # stay in UI loop
        end
      end

      # @param [Y2Storage::Partition] partition
      def initialize(partition)
        textdomain "storage"

        @partition = partition
        self.widget_id = "partition:" + partition.name
      end

      # @macro AW
      def label
        @partition.sysfs_name
      end

      # @macro CW
      def contents
        # FIXME: this is called dozens of times per single click!!
        return @contents if @contents

        icon = Icons.small_icon(Icons::HD_PART)
        @contents = VBox(
          Left(
            HBox(
              Image(icon, ""),
              # TRANSLATORS: Heading. String followed by name of partition
              Heading(format(_("Partition: "), @partition.name))
            )
          ),
          PartitionDescription.new(@partition),
          EditButton.new(@partition)
        )
      end
    end
  end
end
