require "yast"
require "y2partitioner/widgets/format_and_mount"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepFormatMount
    class FormatAndMount < CWM::Dialog
      # @param partition [Y2Storage::Partition] FIXME: unsure which type we want
      def initialize(partition)
        @partition = partition
        textdomain "storage"
      end

      def title
        "Edit Partition #{@partition.name}"
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

      # @return [CWM::WidgetTerm]
      def formatting_content
        fs_type = @partition.filesystem_type
        fs_type = fs_type ? fs_type.to_human : ""

        item_plus_indented(
          Label(_("Formatting Options")),
          item_plus_indented(
            RadioButton(_("Format partition")),
            ComboBox(_("File &System"), [fs_type]),
            PushButton(Id(:file_system_options), _("O&ptions..."))
          ),
          item_plus_indented(
            RadioButton(_("Do not format partition")),
            Empty()
          )
        )
      end

      # @return [CWM::WidgetTerm]
      def mounting_content
        mount_point = @partition.filesystem_mountpoint || ""

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
      end

      def contents
        HVSquash(
          HBox(
            Widgets::FormatOptions.new(@partition),
            HSpacing(4),
            Widgets::MountOptions.new(@partition)
          )
        )
      end
    end
  end
end
