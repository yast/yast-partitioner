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

        details_rp = CWM::ReplacePoint.new(id: "partitioner_details_pane")
        overview_w = Widgets::Overview.new(staging, details_rp: details_rp)

        contents = MarginBox(
          0.5,
          0.5,
          HBox(
            HWeight(
              30,
              overview_w
            ),
            HWeight(
              70,
              details_rp
            )
          )
        )

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        Yast::CWM.show(contents, caption: _("Partitioner"))
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end
    end
  end
end
