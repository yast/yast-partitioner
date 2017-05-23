require "cwm/tree_pager"

require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    class BlkDevicesPage < CWM::Page
      def initialize(devices)
        @devices = devices
      end

      def label
        "Hard Disks"
      end

      def contents
        return @contents if @contents

        icon = Icons::SMALL_ICONS_PATH + Icons::HD
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents = VBox(
          Left(HBox(
            Image(icon, ""),
            # TRANSLATORS: Heading. String followed by name of partition
            Heading(_("Hard Disks "))
          )),
          BlkDevicesTable.new(@devices)
        )
      end
    end
  end
end


