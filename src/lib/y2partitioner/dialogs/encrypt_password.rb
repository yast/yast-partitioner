require "yast"
require "cwm/dialog"
require "y2partitioner/widgets/encrypt_password"

module Y2Partitioner
  module Dialogs
    # Ask for a password to assign to an encrypted device.
    # Part of {Sequences::AddPartition} and {Sequences::EditBlkDevice}.
    # Formerly MiniWorkflowStepPassword
    class EncryptPassword < CWM::Dialog
      def initialize(blk_device)
        textdomain "storage"

        @blk_device = blk_device
      end

      def title
        _("Encryption password for %s") % @blk_device.plain_device.name
      end

      def contents
        HVSquash(
          Widgets::EncryptPassword.new(@blk_device)
        )
      end
    end
  end
end
