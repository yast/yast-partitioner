require "cwm/tree_pager"
require "y2partitioner/device_graphs"
require "y2partitioner/widgets/overview"
require "y2partitioner/device_graphs"
require "y2storage"

Yast.import "CWM"
Yast.import "Popup"
Yast.import "Stage"
Yast.import "Wizard"

# Work around YARD inability to link across repos/gems:
# (declaring macros here works because YARD sorts by filename size(!))

# @!macro [new] seeAbstractWidget
#   @see http://www.rubydoc.info/github/yast/yast-yast2/CWM%2FAbstractWidget:${0}
# @!macro [new] seeCustomWidget
#   @see http://www.rubydoc.info/github/yast/yast-yast2/CWM%2FCustomWidget:${0}

# The main module for this package
module Y2Partitioner
  # YaST "clients" are the CLI entry points
  module Clients
    # Main entry point to see partitioner configuration
    class Main
      extend Yast::I18n
      extend Yast::UIShortcuts
      extend Yast::Logger

      # Run the client
      def self.run
        textdomain "storage"

        DeviceGraphs.instance.original = Y2Storage::StorageManager.instance.y2storage_probed
        DeviceGraphs.instance.current = Y2Storage::StorageManager.instance.y2storage_staging.dup

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        res = nil
        loop do
          contents = MarginBox(
            0.5,
            0.5,
            CWM::TreePager.new(Widgets::OverviewTree.new(DeviceGraphs.instance.current))
          )
          res = Yast::CWM.show(contents, caption: _("Partitioner"), skip_store_for: [:redraw])
          break if res != :redraw
        end

        # Running system: presenting "Expert Partitioner: Summary" step now
        # ep-main.rb SummaryDialog
        if res == :next && Yast::Popup.ContinueCancel("(potentially) d3stR0y Ur DATA?!??")
          Y2Storage::StorageManager.instance.staging = DeviceGraphs.instance.current
          Y2Storage::StorageManager.instance.commit
        end
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end
    end
  end
end
