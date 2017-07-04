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
      # @param partition [Y2Storage::BlkDevice]
      def initialize(partition)
        textdomain "storage"
        @partition = partition
      end

      def run
        sequence_hash = {
          "ws_start"     => "format_mount",
          # FIXME: If encryption password is set in a different step then it
          # allows to go back and reset all the options to not modify the
          # partition at all but since the moment :next is preset the partition
          # will be altered. We could work with a FormatOptions object that
          # could be a Struct or Hash and just set all the options there and
          # format in a extra step at the end of the sequence or we could make
          # the password step part of format_and_mount.
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

          ret == :next ? :finish : ret
        else
          :finish
        end
      end
    end
  end
end
