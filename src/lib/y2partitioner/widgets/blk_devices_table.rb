require "yast"

require "cwm/table"

require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    # Table widget to represent given list of Y2Storage::BlkDevice.
    class BlkDevicesTable < CWM::Table
      include Yast::I18n
      extend Yast::I18n

      # @param blk_devices [Array<Y2Storage::BlkDevice>] devices to display
      # @param pager [CWM::Pager] table have feature, that double click change content of pager
      #   if someone do not need this feature, make it only optional
      def initialize(blk_devices, pager)
        textdomain "storage"
        @blk_devices = blk_devices
        @pager = pager
      end

      # @macro seeAbstractWidget
      def opt
        [:notify]
      end

      # @macro seeAbstractWidget
      def handle
        id = value[/table:(.*)/, 1]
        @pager.handle("ID" => id)
      end

      # TRANSLATORS: table header, "F" stands for Format flag. Keep it short,
      # ideally single letter.
      FORMAT_FLAG = N_("F")

      # headers of table
      def header
        [
          # TRANSLATORS: table header, Device is physical name of block device
          # like partition or disk e.g. "/dev/sda1"
          _("Device"),
          # TRANSLATORS: table header, size of block device e.g. "8.00 GiB"
          Right(_("Size")),
          Center(_(FORMAT_FLAG)),
          # TRANSLATORS: table header, flag if device is encrypted. Keep it short,
          # ideally three letters. Keep in sync with Enc used later for format marker.
          Center(_("Enc")),
          # TRANSLATORS: table header, type of disk or partition. Can be longer. E.g. "Linux swap"
          _("Type"),
          # TRANSLATORS: table header, Files system type. Can be empty E.g. "BtrFS"
          _("FS Type"),
          # TRANSLATORS: table header, disk or partition label. Can be empty.
          _("Label"),
          # TRANSLATORS: table header, where is device mounted. Can be empty. E.g. "/" or "/home"
          _("Mount Point"),
          # TRANSLATORS: table header, which sector is the first one for device. E.g. "0"
          Right(_("Start")),
          # TRANSLATORS: table header, which sector is the the last for device. E.g. "126"
          Right(_("End"))
        ]
      end

      # @macro seeAbstractWidget
      def help
        format(_(
                 "Table shows selected devices with its attributes.<br>" \
                   "<b>Device</b> is kernel name for device.<br>" \
                   "<b>Size</b> is size of device in reasonable units. " \
                   "Units can be different for each device.<br>" \
                   "<b>%{format_flag}</b> is flag if device is going to be formatted.<br>" \
                   "<b>Enc</b> is flag is content on device will be encrypted.<br>" \
                   "<b>Type</b> is description for type of device.<br>" \
                   "<b>FS Type</b> is description of filesystem on device.<br>" \
                   "<b>Label</b> is label for given device if set.<br>" \
                   "<b>Mount Point</b> is where device is mounted or empty if not.<br>" \
                   "<b>Start</b> is the first sector on device.<br>" \
                   "<b>End</b> is the last sector on device.<br>"
        ), format_flag: FORMAT_FLAG)
      end

      # table items. See CWM::Table#items
      def items
        @blk_devices.map do |device|
          [
            id_for_device(device), # use name as id
            device.name,
            device.size.to_human_string,
            device.exists_in_probed? ? "" : _(FORMAT_FLAG), # TODO: dasd format use "X", check it
            encryption_value_for(device),
            type_for(device),
            fs_type_for(device),
            device.filesystem_label || "",
            device.filesystem_mountpoint || "",
            device.region.start,
            device.region.end
          ]
        end
      end

    private

      def encryption_value_for(device)
        return "" unless device.encrypted?

        if Yast::UI.GetDisplayInfo["HasIconSupport"]
          icon_path = Icons.small_icon(Icons::ENCRYPTED)
          cell(icon(icon_path))
        else
          "E"
        end
      end

      # helper to generate id that can be later used in handle
      # @note keep in sync with ids used in overview widget
      def id_for_device(device)
        res = "table:"
        if device.is?(:partition)
          res << "partition:#{device.name}"
        elsif device.is?(:disk)
          res << "disk:#{device.name}"
        elsif device.is?(:encryption)
          res << "encryption:#{device.name}"
        elsif device.is?(:lvm_lv)
          res << "lvm_lv:#{device.lv_name}"
        else
          raise "unsuported type #{device.inspect}"
        end

        res
      end

      def type_for(_device)
        # TODO: add PartitionType#to_human_string to yast2-storage-ng.
        # TODO: also type for disks. Old one: https://github.com/yast/yast-storage/blob/master/src/modules/StorageFields.rb#L517
        #   for disk, lets add it to partitioner, unless someone else need it
        "TODO"
      end

      def fs_type_for(device)
        fs_type = device.filesystem_type

        fs_type ? fs_type.to_human : ""
      end
    end
  end
end
