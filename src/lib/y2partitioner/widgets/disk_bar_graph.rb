require "cwm/widget"

module Y2Partitioner
  module Widgets
    # Widget that is richtext filled with description of partition passed in constructor
    class DiskBarGraph < CWM::CustomWidget
      def initialize(disk)
        @disk = disk
      end

      def contents
        return Empty() unless Yast::UI.HasSpecialWidget(:BarGraph)

        data = @disk.partitions.map do |part|
          # lets use size in MiB, disks are now so big, that otherwise it will overflow
          # even for few TB and we passing values to libyui in too low data. Ignoring anything
          # below 1MiB looks OK for me (JReidinger)
          [part.size.to_i/(2**20), "#{part.sysfs_name}\n#{part.size.to_human_string}"]
        end
        sizes = data.map(&:first)
        labels = data.map{ |i| i[1] }
        BarGraph(sizes, labels)
      end
    end
  end
end
