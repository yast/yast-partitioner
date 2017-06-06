require "cwm/widget"

Yast.import "HTML"

require "y2partitioner/widgets/blk_device_attributes"
require "y2partitioner/widgets/lvm_lv_attributes"

module Y2Partitioner
  # CWM widgets for partitioner
  module Widgets
    # Widget that is richtext filled with description of logical volume passed in constructor
    class LvmLvDescription < CWM::RichText
      include Yast::I18n

      # @param lvm_lv [Y2Storage::LvmLv] to describe
      def initialize(lvm_lv)
        textdomain "storage"
        @lvm_lv = lvm_lv
      end

      # inits widget content
      def init
        self.value = lv_text
      end

      # @macro seeAbstractWidget
      def help
        # TODO: proofread it and test it on real user, if it need improvement
        _("Textual description of LVM Logical Volume")
      end

    private

      attr_reader :lvm_lv
      alias_method :blk_device, :lvm_lv

      include BlkDeviceAttributes
      include LvmLvAttributes

      def lv_text
        # TODO: consider using e.g. erb for this kind of output
        # TRANSLATORS: heading for section about device
        output = Yast::HTML.Heading(_("Device:"))
        output << Yast::HTML.List(device_attributes_list)
        output << Yast::HTML.Heading(_("LVM:"))
        output << Yast::HTML.List([stripes])
        output << fs_text
      end

      def device_attributes_list
        [
          device_name,
          device_size,
          device_encrypted
        ]
      end

      def stripes
        # TRANSLATORS: value for number of LVM stripes
        format(_("Stripes: %s"), stripes_info(lvm_lv))
      end
    end
  end
end
