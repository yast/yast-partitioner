require "yast"

require "cwm/table"

require "y2partitioner/icons"
require "y2partitioner/widgets/blk_devices_table"

module Y2Partitioner
  module Widgets
    # Table widget to represent given list of Y2Storage::LvmLvs together.
    class LvmPvTable < CWM::Table
      include BlkDevicesTable

      # @param pvs [Array<Y2Storage::LvmPv] devices to display
      # @param pager [CWM::Pager] table have feature, that double click change content of pager
      #   if someone do not need this feature, make it only optional
      def initialize(pvs, pager)
        textdomain "storage"
        @pvs = pvs
        @pager = pager
      end

      # table items. See CWM::Table#items
      def items
        @pvs.map do |pv|
          device = pv.plain_blk_device
          [
            id_for_device(device), # use name as id
            device.name,
            device.size.to_human_string,
            # TODO: dasd format use "X", check it
            device.exists_in_probed? ? "" : _(BlkDevicesTable::FORMAT_FLAG),
            encryption_value_for(device),
            type_for(device)
          ]
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
          _("Type")
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
                   "<b>Type</b> is description for type of device.<br>"
        ), format_flag: BlkDevicesTable::FORMAT_FLAG)
      end

    private

      attr_reader :pager
    end
  end
end
