require "cwm/widget"

Yast.import "HTML"

require "y2partitioner/widgets/blk_device_attributes"

module Y2Partitioner
  # CWM widgets for partitioner
  module Widgets
    # Widget that is richtext filled with description of logical volume passed in constructor
    class LvmLvDescription < CWM::RichText
      include Yast::I18n

      # @param lvm_lv [Y2Storage::LvmLv] to describe
      def initialize(_lvm_lv)
        textdomain "storage"
        @partition = partition
      end

      # inits widget content
      def init
        self.value = lv_text
      end

      # @macro AW
      def help
        _("Textual description of LVM Logical Volume")
      end

    private

      attr_reader :lvm_lv
      alias_method :blk_device, :lvm_lv

      include BlkDeviceAttributes

      def lv_text
        # TODO: consider using e.g. erb for this kind of output
        # TRANSLATORS: heading for section about device
        output = Yast::HTML.Heading(_("Device:"))
        output << Yast::HTML.List(device_attributes_list)
        output = Yast::HTML.Heading(_("LVM:"))
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
        val = if device.stripes <= 1
          device.stripes.to_i
        else
          "#{device.stripes}(#{device.stripes_size.to_human_string})"
        end

        # TRANSLATORS: value for number of LVM stripes
        format(_("Stripes: %s"), val)
      end
    end
  end
end
