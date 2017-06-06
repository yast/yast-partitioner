require "yast"
require "cwm/dialog"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepPartitionType
    class PartitionType < CWM::Dialog
      class Rbs < CWM::RadioButtons
        def initialize(available_types)
          textdomain "storage"
          @ats = available_types
        end

        def label
          _("New Partition Type")
        end

        def help
          # helptext
          _("<p>Choose the partition type for the new partition.</p>")
        end

        def items
          [
            # radio button text
            ["primary", _("&Primary Partition")],
            # radio button text
            ["extended", _("&Extended Partition")],
            # radio button text
            ["logical", _("&Logical Partition")]
          ].find_all { |t, _l| @ats[t] }

        end
      end

      # @param slots [Array<Y2Storage::PartitionTables::PartitionSlot>]
      def initialize(disk, slots)
        @disk = disk
        @slots = slots
        textdomain "storage"
      end

      def title
        # dialog title
        Yast::Builtins.sformat(_("Add Partition on %1"), @disk.name)
      end
          
      def contents
        available_types = Y2Storage::PartitionType.all.map do |ty|
          [ty.to_s, @slots.find { |s| s.possible?(ty) } != nil]
        end.to_h

        # FIXME: ever can change this? or just create?
        type = :none

        HVSquash(Rbs.new(available_types))
      end
    end
  end
end
