require "yast"
require "ui/event_dispatcher"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepPartitionType
    # FIXME: InnerDialog?!
    class PartitionType
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

      def next_handler
        finish_dialog(:next)
      end

      def help
        # helptext
        _("<p>Choose the partition type for the new partition.</p>")
      end

      def contents
        # FIXME: get actual data
        available_types = {
          primary:  true,
          extended: true,
          logical:  true
        }
        # FIXME: ever can change this? or just create?
        type = :none

        rbs = VBox()
        mk_item = lambda(id, label) do
          if available_types[id]
            rbs << Left(RadioButton(Id(id), label, type == id))
          end
        end
        # radio button text
        mk_item.call(:primary, _("&Primary Partition"))
        # radio button text
        mk_item.call(:extended, _("&Extended Partition"))
        # radio button text
        mk_item.call(:logical, _("&Logical Partition"))

        HVSquash(
          Frame(
            # heading for a frame in a dialog
            _("New Partition Type"),
            MarginBox(
              1.45, 0.45,
              RadioButtonGroup(Id(:partition_type), rbs)
            )
          )
        )
      end
    end
  end
end
