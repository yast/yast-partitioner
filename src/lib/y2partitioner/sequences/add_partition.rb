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
      def initialize(disk)
        @disk = disk
        # collecting params of partition to be created?
        @params = {}
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
        res
      end

      def type
        Dialogs::PartitionType.new(@disk).run
      end

      def size
        Dialogs::PartitionSize.new(@disk).run
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
    end
  end
end
