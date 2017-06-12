require "cwm/pager"

require "y2partitioner/widgets/partition_description"

module Y2Partitioner
  module Widgets
    # A Page for a partition
    class PartitionPage < CWM::Page
      # @param [Y2Storage::Partition] partition
      def initialize(partition)
        textdomain "storage"

        @partition = partition
        self.widget_id = "partition:" + partition.name
      end

      # @macro seeAbstractWidget
      def label
        @partition.sysfs_name
      end

      # @macro seeCustomWidget
      def contents
        # FIXME: this is called dozens of times per single click!!
        return @contents if @contents

        icon = Icons.small_icon(Icons::HD_PART)
        @contents = VBox(
          Left(
            HBox(
              Image(icon, ""),
              # TRANSLATORS: Heading. String followed by name of partition
              Heading(format(_("Partition: "), @partition.name))
            )
          ),
          PartitionDescription.new(@partition)
        )
      end
    end
  end
end
