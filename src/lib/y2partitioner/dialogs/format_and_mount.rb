require "yast"
require "y2partitioner/widgets/format_and_mount"

module Y2Partitioner
  module Dialogs
    # Which filesystem (and options) to use and where to mount it (with options).
    # Part of {Sequences::AddPartition} and {Sequences::EditBlkDevice}.
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < CWM::Dialog
      # @param options [Y2Partitioner::FormatMountOptions]
      def initialize(options)
        textdomain "storage"

        @options = options
        @format_widget = Widgets::FormatOptions.new(@options)
        @mount_widget  = Widgets::MountOptions.new(@options)
      end

      def title
        "Edit Partition #{@options.name}"
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
