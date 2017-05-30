require "cwm/tree_pager"

require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    # A Page for block devices: contains a {BlkDevicesTable}
    class BlkDevicesPage < CWM::Page
      include Yast::I18n

      def initialize(devices, pager)
        textdomain "storage"

        @devices = devices
        @pager = pager
      end

      # @macro AW
      def label
        _("Hard Disks")
      end

      # @macro CW
      def contents
        return @contents if @contents

        icon = Icons.small_icon(Icons::HD)
        @contents = VBox(
          Left(
            HBox(
              Image(icon, ""),
              # TRANSLATORS: Heading. String followed by name of partition
              Heading(_("Hard Disks "))
            )
          ),
          BlkDevicesTable.new(@devices, @pager)
        )
      end
    end
  end
end
