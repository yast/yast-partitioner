require "yast"
require "y2partitioner/widgets/format_and_mount"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < CWM::Dialog
      # @param partition [Y2Storage::Partition] FIXME: unsure which type we want
      def initialize(partition)
        @partition = partition
        textdomain "storage"
      end

      def title
        "Edit Partition #{@partition.name}"
      end

      def contents
        HVSquash(
          HBox(
            Widgets::FormatOptions.new(@partition),
            HSpacing(4),
            Widgets::MountOptions.new(@partition)
          )
        )
      end
    end
  end
end
