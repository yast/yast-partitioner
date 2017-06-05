require "yast"
require "ui/event_dispatcher"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepPartitionSize
    # FIXME: InnerDialog?!
    class PartitionSize
      include Yast::UIShortcuts
      include Yast::Logger
      include Yast::I18n

      include UI::EventDispatcher

      def initialize(_disk)
        textdomain "storage"
      end

      def run
        Yast::UI.ReplaceWidget(Id(:contents), contents)
        event_loop
      end

      def help
        # helptext
        _("<p>Choose the size for the new partition.</p>")
      end

      def contents
        Label("fake partition size dialog")
      end

      def next_handler
        finish_dialog(:next)
      end
    end
  end
end
