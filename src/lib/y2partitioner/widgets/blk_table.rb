require "yast"

require "cwm/table"

require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    class BlkTable
      include Yast::I18n

      def initialize(blk_devices)
        textdomain "storage"
        @blk_devices = blk_devices
      end

      def header
        [
          # TRANSLATORS: table header, Device is physical name of block device
          # like partition or disk e.g. "/dev/sda1"
          _("Device"),
          # TRANSLATORS: table header, size of block device e.g. "8.00 GiB"
          Right(_("Size")),
          # TRANSLATORS: table header, "F" stands for Format flag. Keep it short,
          # ideally single letter. Keep in sync with F used later for format marker.
          Center(_("F")),
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

      def items
        @blk_devices.map do |device|
          [
            device.name, # use name as id
            device.name,
            device.size.to_human_string,
            device.exists_in_probed ? "" : "F", # TODO: dasd format use "X", investigate it
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
          icon_path = Icons::SMALL_ICONS_PATH + Icons::ENCRYPTED
          cell(icon(icon_path))
        else
          "E"
        end
      end

      def type_for(device)
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
