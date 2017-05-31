require "ui/installation_dialog"
require "yast"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < UI::Dialog
      def initialize
        super
        Yast.import "Popup"
        textdomain "storage"
      end

      def create_dialog
        # recreating the look of MiniWorkflow
        help = ""
        have_back = true
        have_next = true
        Yast::Wizard.OpenNextBackDialog
        Yast::Wizard.SetContents(dialog_title, dialog_content,
          help, have_back, have_next)
        # FIXME: UI::Dialog raises if we return nil, WTF
        true
      end

      def close_dialog
        Yast::Wizard.CloseDialog
      end

      def dialog_title
        "Edit Partition /dev/fixme"
      end

      def dialog_content
        VBox(
          HBox(
            VBox(
              Label(_("Formatting Options")),
              RadioButton(_("Format partition")),
              PushButton(Id(:file_system_options), _("O&ptions...")),
              RadioButton(_("Do not format partition"))
            ),
            VBox(
              Label(_("Mounting Options")),
              RadioButton(_("Mount partition")),
              PushButton(Id(:fstab_options), _("Fs&tab Options...")),
              RadioButton(_("Do not mount partition"))
            )
          )
        )
      end

      def next_handler
        finish_dialog(:next)
      end

      def back_handler
        finish_dialog(:back)
      end

      # Formerly :fs_options -> FileSystemOptions
      def file_system_options_handler
        Yast::Popup.Message("Fake #{__method__}")
      end

      # Formerly :fstab_options -> FstabOptions
      def fstab_options_handler
        Yast::Popup.Message("Fake #{__method__}")
      end
    end
  end
end
