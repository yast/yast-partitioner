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
        contents = MarginBox(
          0.5,
          0.5,
          HBox(
            HWeight(
              30,
              Widgets::Overview.new(staging)
            ),
            HWeight(
              70,
              Empty() # TODO: replace point ( probably passed to overview )
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
