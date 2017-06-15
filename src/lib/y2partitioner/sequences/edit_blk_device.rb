require "yast"
require "ui/sequence"
require "y2partitioner/device_graphs"
require "y2partitioner/dialogs/partition_size"
require "y2partitioner/dialogs/partition_type"
require "y2partitioner/format_mount_options"

Yast.import "Wizard"

module Y2Partitioner
  module Sequences
    # BlkDevice edition
    class EditBlkDevice < UI::Sequence
      include Yast::Logger
      # @param partition [Y2Storage::BlkDevice]
      def initialize(partition)
        textdomain "storage"
        @options = FormatMountOptions.new(partition: partition)
        @partition = partition
      end

      def run
        sequence_hash = {
          "ws_start"     => "format_options",
          # FIXME: If encryption password is set in a different step then it
          # allows to go back and reset all the options to not modify the
          # partition at all but since the moment :next is preset the partition
          # will be altered. We could work with a FormatOptions object that
          # could be a Struct or Hash and just set all the options there and
          # format in a extra step at the end of the sequence or we could make
          # the password step part of format_and_mount.
          "format_options" => { next: "password" },
          "password"       => { next: "format_mount" },
          "format_mount"   => { finish: :finish }
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

      def format_options
        @format_dialog ||= Dialogs::FormatAndMount.new(@options)

        @format_dialog.run
      end

      def password
        return :next unless @options.encrypt
        @encrypt_dialog ||= Dialogs::EncryptPassword.new(@options)

        @encrypt_dialog.run
      end

      def format_mount
        @partition.remove_descendants if @options.encrypt || @options.format

        if @options.encrypt
          @partition = @partition.create_encryption(dm_name_for(@partition))
        end

        @partition.create_filesystem(@options.filesystem) if @options.format

        (@partition.filesystem.mount_point = @options.mount_point) if @options.mount

        :finish
      end

    private

      def dm_name_for(partition)
        name = partition.name.split("/").last
        "cr_#{name}"
      end
    end
  end
end
