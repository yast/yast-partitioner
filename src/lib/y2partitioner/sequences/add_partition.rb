require "ostruct"
require "yast"
require "ui/sequence"
require "y2partitioner/dialogs/partition_size"
require "y2partitioner/dialogs/partition_type"

Yast.import "Wizard"

module Y2Partitioner
  module Sequences
    # formerly EpCreatePartition, DlgCreatePartition
    class AddPartition < UI::Sequence
      include Yast::Logger
      # @param disk [Y2Storage::Disk]
      def initialize(disk, slots)
        @disk = disk
        @slots = slots
        # collecting params of partition to be created?
        @ptemplate = Struct.new(:type, :region).new
      end

      def run
        sequence_hash = {
          "ws_start"     => "type",
          "type"         => { next: "size" },
          "size"         => { next: "role", finish: :finish },
          "role"         => { next: "format_mount" },
          "format_mount" => { next: "password", finish: :finish },
          "password"     => { finish: :finish }
        }

        sequence_hash = abortable(sequence_hash)
        aliases = from_methods(sequence_hash)
        Yast::Wizard.OpenNextBackDialog
        res = self.class.run(aliases, sequence_hash)
        Yast::Wizard.CloseDialog

        ptable = @disk.partition_table
        name = next_free_primary_partition_name(@disk.name, ptable)
        ptable.create_partition(name, @ptemplate.region, @ptemplate.type)

        res
      end

      def type
        Dialogs::PartitionType.run(@disk, @ptemplate, @slots)
      end

      def size
        Dialogs::PartitionSize.run(@disk, @ptemplate, @slots)
      end

      def role
        log.info "TODO: Partition ROLE dialog"
        :next
      end

      def format_mount
        # FIXME: where to get this while creating?
        partition = OpenStruct.new
        partition.name = "fake name"
        partition.filesystem_mountpoint = "fake mount point"
        Dialogs::FormatAndMount.new(partition).run
      end

      def password
        log.info "TODO: Partition PASSWORD dialog"
        :finish
      end

    private

      # FIXME: stolen from Y2Storage::Proposal::PartitionCreator
      def next_free_primary_partition_name(disk_name, ptable)
        # FIXME: This is broken by design. create_partition needs to return
        # this information, not get it as an input parameter.
        part_names = ptable.partitions.map(&:name)
        1.upto(ptable.max_primary) do |i|
          dev_name = "#{disk_name}#{i}"
          return dev_name unless part_names.include?(dev_name)
        end
        raise NoMorePartitionSlotError
      end
    end
  end
end
