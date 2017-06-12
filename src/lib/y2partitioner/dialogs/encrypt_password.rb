require "yast"
require "cwm/dialog"
require "y2partitioner/widgets/encrypt_password"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepFormatMount
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
