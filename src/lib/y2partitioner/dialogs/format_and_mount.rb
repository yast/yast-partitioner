require "ui/installation_dialog"
require "yast"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < UI::Dialog
      # @param partition [Y2Storage::Partition] FIXME: unsure which type we want
      def initialize(partition)
        @partition = partition
        super()
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
        "Edit Partition %s" % @partition.name
      end

      # A generalized GreaseMonkey.Left*WithAttachment
      #
      # If you say
      #   item_plus_indented(Button1, Button2, Button3, Button4)
      # You will see
      #   Button1
      #       Button2
      #       Button3
      #       Button4
      def item_plus_indented(heading_item, *indented_items)
        VBox(
          Left(heading_item),
          HBox(
            HSpacing(4),
            VBox(*indented_items)
          )
        )
      end

      def dialog_content
        fs_type = @partition.filesystem_type
        fs_type = fs_type ? fs_type.to_human : ""
        mount_point = @partition.filesystem_mountpoint || ""

        HVSquash(
          HBox(
            item_plus_indented(
              Label(_("Formatting Options")),
              item_plus_indented(
                RadioButton(_("Format partition")),
                ComboBox(_("File &System"), [fs_type]),
                PushButton(Id(:file_system_options), _("O&ptions...")),
              ),
              item_plus_indented(
                RadioButton(_("Do not format partition")),
                Empty()
              )
            ),
            HSpacing(4),
            item_plus_indented(
              Label(_("Mounting Options")),
              item_plus_indented(
                RadioButton(_("Mount partition")),
                ComboBox(_("&Mount Point"), [mount_point]),
                PushButton(Id(:fstab_options), _("Fs&tab Options..."))
              ),
              item_plus_indented(
                RadioButton(_("Do not mount partition")),
                Empty()
              )
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

      def abort_handler
        finish_dialog(:abort)
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
