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
      # @param allow_commit [Boolean] can we pass the point of no return
      def self.run(allow_commit: true)
        textdomain "storage"

        smanager = Y2Storage::StorageManager.instance
        system = smanager.y2storage_probed
        current = smanager.y2storage_staging
        DeviceGraphs.create_instance(system, current)

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        res = nil
        loop do
          contents = MarginBox(
            0.5,
            0.5,
            Widgets::OverviewTreePager.new(DeviceGraphs.instance.current)
          )
          res = Yast::CWM.show(contents, caption: _("Partitioner"), skip_store_for: [:redraw])
          break if res != :redraw
        end

        # Running system: presenting "Expert Partitioner: Summary" step now
        # ep-main.rb SummaryDialog
        if res == :next && should_commit?(allow_commit)
          smanager.staging = DeviceGraphs.instance.current
          smanager.commit
        end
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end

      # Ask whether to proceed with changing the disks;
      # or inform that we will not do it.
      # @return [Boolean] proceed
      def self.should_commit?(allow_commit)
        if allow_commit
          q = "Modify the disks and potentially destroy your data?"
          Yast::Popup.ContinueCancel(q)
        else
          m = "Nothing gets written, because the device graph is fake."
          Yast::Popup.Message(m)
          false
        end
      end
    end
  end
end
