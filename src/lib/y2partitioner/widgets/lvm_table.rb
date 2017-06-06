require "yast"

require "cwm/table"

require "y2partitioner/icons"
require "y2partitioner/widgets/blk_devices_table"

module Y2Partitioner
  module Widgets
    # Table widget to represent given list of Y2Storage::LvmVgs and Y2Storage::LvmLvs together.
    # For displaying Y2Storage::LvmLvs only use specialized class (see LvmLvTable)
    class LvmTable < CWM::Table
      include BlkDevicesTable

      # @param lvms [Array<Y2Storage::LvmVg|Y2Storage::LvmLv] devices to display
      # @param pager [CWM::Pager] table have feature, that double click change content of pager
      #   if someone do not need this feature, make it only optional
      def initialize(lvms, pager)
        textdomain "storage"
        @lvms = lvms
        @pager = pager
      end

      # table items. See CWM::Table#items
      def items
        @lvms.map do |device|
          res = [
            id_for_device(device), # use name as id
            lvm_name(device),
            device.size.to_human_string,
            # TODO: dasd format use "X", check it
            device.exists_in_probed? ? "" : _(BlkDevicesTable::FORMAT_FLAG),
            encryption_value_for(device),
            type_for(device),
            fs_type_for(device)
          ]
          res + device_specific_items(device)
        end
      end

      # headers of table
      def header
        [
          # TRANSLATORS: table header, Device is physical name of block device
          # like partition or disk e.g. "/dev/sda1"
          _("Device"),
          # TRANSLATORS: table header, size of block device e.g. "8.00 GiB"
          Right(_("Size")),
          Center(_(BlkDevicesTable::FORMAT_FLAG)),
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
          # TRANSLATORS: table header, type of metadata
          _("PE Size"),
          # TRANSLATORS: table header, number of LVM LV stripes
          _("Stripes")
        ]
      end

      # @macro seeAbstractWidget
      def help
        # TODO: proofread it and test it on real user, if it need improvement
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
                   "TODO<br>"
        ), format_flag: BlkDevicesTable::FORMAT_FLAG)
      end

    private

      attr_reader :pager

      def lvm_name(device)
        # TODO: discuss this with ancor where it make sense to have it in y2-storage
        device.is_a?(Y2Storage::LvmVg) ? "/dev/#{device.vg_name}" : device.name
      end

      def lvm_lv_stripes(device)
        return device.stripes.to_s if device.stripes <= 1

        "#{device.stripes}(#{device.stripes_size.to_human_string})"
      end

      def device_specific_items(device)
        case device
        when Y2Storage::LvmVg
          [
            "",
            "",
            device.extent_size.to_human_string,
            ""
          ]
        when Y2Storage::LvmLv
          [
            device.filesystem_label || "",
            device.filesystem_mountpoint || "",
            "",
            lvm_lv_stripes(device)
          ]
        else
          raise "Invalid device #{device.inspect}"
        end
      end
    end
  end
end
