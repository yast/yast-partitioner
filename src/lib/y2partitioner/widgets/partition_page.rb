require "cwm/tree_pager"

require "y2partitioner/widgets/partition_description"

module Y2Partitioner
  module Widgets
    class PartitionPage < CWM::Page
      # @param [Y2Storage::Partition] partition
      def initialize(partition)
        @partition = partition
        self.widget_id = "partition:" + partition.name
      end

      def label
        @partition.sysfs_name
      end

      def contents
        # FIXME: this is called dozens of times per single click!!
        return @contents if @contents
        rt_w = PartitionDescription.new(@partition)
        icon = Icons::SMALL_ICONS_PATH + Icons::HD_PART
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents = VBox(
          Left(HBox(
            Image(icon, ""),
            # TRANSLATORS: Heading. String followed by name of partition
            Heading(_("Partition: ") + @partition.name)
          )),
          rt_w
        )
      end
    end
  end
end
