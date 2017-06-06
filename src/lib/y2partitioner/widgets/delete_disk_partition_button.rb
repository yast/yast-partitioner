require "yast"
require "cwm"

Yast.import "Popup"

module Y2Partitioner
  module Widgets
    class DeleteDiskPartitionButton < CWM::PushButton

      def initialize(device: nil, table: nil, device_graph: nil)
        textdomain "storage"

        if !device && (!table || !device_graph)
          raise ArgumentError,
            "At least device or combination of table and device_graph have to be set"
        end
        @device = device
        @table = table
        @device_graph = device_graph
      end

      def label
        _("Dele&te...")
      end

      def handle
        device = if @device
          @device
        else
          # TODO: make it generic as it is used on several places
          id = @table.value
          if id.start_with?("table:partition")
            partition_name = id[/table:partition:(.*)/, 1]
            Y2Storage::Partition.find_by_name(@device_graph, partition_name)
          elsif id.start_with?("table:disk")
            disk_name = id[/table:disk:(.*)/, 1]
            Y2Storage::Disk.find_by_name(@device_graph, partition_name)
          else
            raise "Unknown id in table '#{id}'"
          end
        end

        # TODO: check for children that will die and if there are, use confirm_recursive_delete
        ret = Yast::Popup.YesNo(
          # TRANSLATORS %s is device to be deleted
          format(_("Really delete %s?"), device.name)
        )

        return nil unless ret

        partition_table = device.partition_table
        if device.is?(:disk)
          partition_table.partitions.each { |p| partition_table.delete_partition(p) }
        else
          partition_table.delete_partition(device)
        end

        :redraw
      end

    private

      # TODO: copy and pasted code from old storage, feel free to improve
      def confirm_recursive_delete(device, devices, headline, text_before, text_after)
        devices = deep_copy(devices)
        button_box = ButtonBox(
          PushButton(Id(:yes), Opt(:okButton), Yast::Label.DeleteButton),
          PushButton(
            Id(:no_button),
            Opt(:default, :cancelButton),
            Yast::Label.CancelButton
          )
        )

        display_info = Yast::UI.GetDisplayInfo || {}
        has_image_support = display_info["HasImageSupport"]

        layout = VBox(
          VSpacing(0.4),
          HBox(
            has_image_support ? Top(Image(Yast::Icon.IconPath("question"))) : Empty(),
            HSpacing(1),
            VBox(
              Left(Heading(headline)),
              VSpacing(0.2),
              Left(Label(text_before)),
              VSpacing(0.2),
              Left(RichText(Yast::HTML.List(devices.sort))),
              VSpacing(0.2),
              Left(Label(text_after)),
              button_box
            )
          )
        )

        Yast::UI.OpenDialog(layout)
        ret = UI.UserInput
        Yast::UI.CloseDialog

        ret == :yes
      end
    end
  end
end
