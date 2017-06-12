require "yast"
require "ui/sequence"
require "y2partitioner/device_graphs"
require "y2partitioner/dialogs/partition_size"
require "y2partitioner/dialogs/partition_type"

Yast.import "Wizard"

module Y2Partitioner
  module Sequences
    # BlkDevice edition
    class EditBlkDevice < UI::Sequence
      include Yast::Logger
      # @param disk [Y2Storage::Disk]
      def initialize(partition)
        textdomain "storage"
        @partition = partition
      end

      def run
        sequence_hash = {
          "ws_start"     => "format_mount",
          "format_mount" => { next: "password", finish: :finish },
          "password"     => { finish: :finish }
        }

        sym = nil
        DeviceGraphs.instance.transaction do
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

      def format_mount
        @dialog ||= Dialogs::FormatAndMount.new(@partition)

        @dialog.run
      end

      def password
        if @partition.encryption
          ret = Dialogs::EncryptPassword.new(@partition).run

          (ret == :next) ? :finish : ret
        else
          :finish
        end
      end
    end
  end
end
