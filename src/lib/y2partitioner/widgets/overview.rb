require "cwm/widget"

require "y2partitioner/icons"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
    # Widget representing partitioner overview.
    #
    # It have replace point where it display more details about selected element
    # in partitioning.
    #
    # TODO: abstract treewidget from it
    class Overview < CWM::CustomWidget
      def initialize
        self.handle_all_events = true
        @opened = []
      end

      def contents
        Tree(Id(:tree), Opt(:notify), _("System View"), items)
      end

      def handle(event)
        id = event["ID"]
        log.info "handling id #{id}"

        nil
      end

    private

      def items
        [
          Item(
            Id(:all),
            term(:icon, Icons::ALL),
            open?(:all),
            "machine", # TODO: stuck getting hostname on my pc Yast::Hostname.CurrentHostname,
            subitems
          )
        ]
      end

      def subitems
        [
          harddisk_items
        ]
      end

      def harddisk_items
        Item(
          Id(:hd),
          term(:icon, Icons::HD),
          _("Hard Disks"),
          open?(:hd),
          [] # TODO: real disks subtree
        )
      end

      def open?(id)
        @opened.include?(id)
      end

      def term(*args)
        Yast::Term.new(*args)
      end
    end
  end
end
