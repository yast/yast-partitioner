Yast.import "CWM"
Yast.import "Stage"
Yast.import "Wizard"

module Y2Partitioner
  module Clients
    class Main
      extend Yast::I18n
      extend Yast::UIShortcuts

      def self.run
        textdomain "storage"

        contents = HBox(
        )

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        Yast::CWM.show(contents, caption: _("Partitioner"))
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end
    end
  end
end
