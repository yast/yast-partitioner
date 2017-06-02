require "cwm/widget"
require "cwm/tree_pager"
require "cwm/tabs"

require "y2partitioner/widgets/lvm_lv_table"
require "y2partitioner/widgets/lvm_pv_table"
require "y2partitioner/widgets/lvm_vg_bar_graph"
require "y2partitioner/widgets/lvm_vg_description"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    # A Page for a disk: contains {DiskTab} and {PartitionsTab}
    class LvmVgPage < CWM::Page
      def initialize(lvm_vg, pager)
        textdomain "storage"
        @lvm_vg = lvm_vg
        @pager = pager
        self.widget_id = "lvm_vg:" + lvm_vg.vg_name
      end

      # @macro AW
      def label
        @lvm_vg.vg_name
      end

      # @macro CW
      def contents
        icon = Icons.small_icon(Icons::LVM)
        VBox(
          Left(
            HBox(
              Image(icon, ""),
              Heading(format(_("Volume Group: %s"), "/dev/" + @lvm_vg.vg_name))
            )
          ),
          CWM::Tabs.new(
            LvmVgTab.new(@lvm_vg),
            LvmLvTab.new(@lvm_vg, @pager),
            LvmPvTab.new(@lvm_vg, @pager)
          )
        )
      end
    end

    # A Tab for a disk
    class LvmVgTab < CWM::Tab
      def initialize(lvm_vg)
        textdomain "storage"
        @lvm_vg = lvm_vg
      end

      # @macro AW
      def label
        _("&Overview")
      end

      # @macro CW
      def contents
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents ||= VBox(LvmVgDescription.new(@lvm_vg))
      end
    end

    # A Tab for LVM logical volumes
    class LvmLvTab < CWM::Tab
      def initialize(lvm_vg, pager)
        textdomain "storage"
        @lvm_vg = lvm_vg
        @pager = pager
      end

      # @macro AW
      def label
        _("Log&ical Volumes")
      end

      # @macro CW
      def contents
        @contents ||= VBox(
          LvmVgBarGraph.new(@lvm_vg),
          LvmLvTable.new(@lvm_vg.lvm_lvs, @pager)
        )
      end
    end

    # A Tab for a LVM physical volumes
    class LvmPvTab < CWM::Tab
      def initialize(lvm_vg, pager)
        textdomain "storage"
        @lvm_vg = lvm_vg
        @pager = pager
      end

      # @macro AW
      def label
        _("&Physical Volumes")
      end

      # @macro CW
      def contents
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents ||= VBox(LvmPvTable.new(@lvm_vg.lvm_pvs, @pager))
      end
    end
  end
end
