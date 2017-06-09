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
      def initialize(disk_name)
        textdomain "storage"
        @disk_name = disk_name
        # collecting params of partition to be created?
        @ptemplate = Struct.new(:type, :region).new
      end

      def disk
        Y2Storage::Disk.find_by_name($dgm.dg, @disk_name)
      end

      def run
        sequence_hash = {
          "ws_start"      => "preconditions",
          "preconditions" => { next: "type" },
          "type"          => { next: "size" },
          "size"          => { next: "role", finish: :finish },
          "role"          => { next: "format_mount" },
          "format_mount"  => { next: "password", finish: :finish },
          "password"      => { finish: :finish }
        }

        sym = nil
        $dgm.transaction do
          sym = wizard_next_back do
            super(sequence: sequence_hash)
          end

          sym == :finish
        end
        sym
      end

      # FIXME: move to Wizard
      def wizard_next_back(&block)
        Yast::Wizard.OpenNextBackDialog
        block.call
      ensure
        Yast::Wizard.CloseDialog
      end

      def preconditions
        pt = partition_table(disk)
        slots = pt.unused_partition_slots
        if slots.empty?
          Yast::Popup.Error(
            Yast::Builtins.sformat(
              _("It is not possible to create a partition on %1."),
              @disk_name
            )
          )
          return :back
        end
        @slots = slots
        :next
      end
      skip_stack :preconditions

      def type
        Dialogs::PartitionType.run(disk, @ptemplate, @slots)
      end

      def size
        Dialogs::PartitionSize.run(disk, @ptemplate, @slots)
      end

      def role
        log.info "TODO: Partition ROLE dialog"
        :next
      end

      def format_mount
        ptable = disk.partition_table
        name = next_free_primary_partition_name(@disk_name, ptable)
        partition = ptable.create_partition(name, @ptemplate.region, @ptemplate.type)
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

      # FIXME: stolen from Y2Storage::Proposal::PartitionCreator
      # Make it DRY
      def partition_table(disk)
        disk.partition_table || disk.create_partition_table(disk.preferred_ptable_type)
      end
    end
  end
end
