require "yast"
require "cwm/dialog"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepPartitionSize
    class PartitionSize < CWM::Dialog

      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      def title
        # dialog title
        Yast::Builtins.sformat(_("Add Partition on %1"), @disk.name)
      end

      def contents
        Label("fake partition size dialog")
      end
    end
  end
end
