require "yast"
require "y2partitioner/widgets/format_and_mount"

module Y2Partitioner
  module Dialogs
    # Which filesystem (and options) to use and where to mount it (with options).
    # Part of {Sequences::AddPartition} and {Sequences::EditBlkDevice}.
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < CWM::Dialog
      # @param options [Y2Partitioner::FormatMount::Options]
      def initialize(options)
        textdomain "storage"

        @options = options
      end

      def title
        "Edit Partition #{@options.name}"
      end

      def contents
        HVSquash(
          HBox(
            Widgets::FormatOptions.new(@options),
            HSpacing(5),
            Widgets::MountOptions.new(@options)
          )
        )
      end

      def cwm_show
        ret = nil

        loop do
          ret = super

          break if ret != :redraw
        end

        ret
      end

      def skip_store_for
        [:redraw]
      end
    end
  end
end
