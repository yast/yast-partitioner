require "cwm/tree_pager"
require "y2partitioner/widgets/overview"
require "y2storage"

Yast.import "CWM"
Yast.import "Stage"
Yast.import "Wizard"

module Y2Partitioner
  module Clients
    # Main entry point to see partitioner configuration
    class Main
      extend Yast::I18n
      extend Yast::UIShortcuts

      def self.run
        textdomain "storage"

        staging = Y2Storage::StorageManager.instance.y2storage_staging
        overview_w = CWM::TreePager.new(Widgets::OverviewTree.new(staging))

        contents = MarginBox(
          0.5,
          0.5,
          overview_w
        )

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        Yast::CWM.show(contents, caption: _("Partitioner"))
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end
    end
  end
end
