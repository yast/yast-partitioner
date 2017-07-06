require "yast"
require "ui/sequence"
require "y2partitioner/device_graphs"
require "y2partitioner/dialogs/partition_size"
require "y2partitioner/dialogs/partition_type"
require "y2partitioner/dialogs/encrypt_password"
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
          "ws_start"       => "format_options",
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
        @partition.id = @options.partition_id
        @partition.remove_descendants if @options.encrypt || @options.format

        if @options.encrypt
          @partition = @partition.create_encryption(dm_name_for(@partition))
        end

        @partition.create_filesystem(@options.filesystem_type) if @options.format

        if @options.mount
          @partition.filesystem.mount_point = @options.mount_point
          @partition.filesystem.mount_by = @options.mount_by
          @partition.filesystem.label = @options.label
          @partition.filesystem.fstab_options = @options.fstab_options
        else
          @partition.filesystem.mount_point = ""
        end

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
