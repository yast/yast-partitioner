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

        @format_widget = Widgets::FormatOptions.new(@partition)
        @mount_widget  = Widgets::MountOptions.new(@partition)
      end

      def title
        "Edit Partition #{@partition.name}"
      end

      def contents
        HVSquash(
          HBox(
            @format_widget,
            HSpacing(4),
            @mount_widget
          )
        )
      end
    end
  end
end
