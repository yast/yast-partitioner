require "cwm/widget"

Yast.import "HTML"

module Y2Partitioner
  module Widgets
    class PartitionDescription < CWM::RichText
      include Yast::I18n

      def initialize(partition)
        textdomain "storage"
        @partition = partition
      end

      def init
        self.value = partition_text
      end

    private

      attr_reader :partition

      def partition_text
        # TODO: consider using e.g. erb for this kind of output
        output = ""
        # TRANSLATORS: heading for section about device
        output << Yast::HTML.Heading(_("Device:"))
        output << Yast::HTML.List(device_attributes_list)
        # TRANSLATORS: heading for section about Filesystem on device
        output << Yast::HTML.Heading(_("File System:"))
        output << Yast::HTML.List(filesystem_attributes_list)
      end

      def filesystem_attributes_list
        fs_type = partition.filesystem_type
        [
          # TRANSLATORS: File system and its type as human string
          format(_("File System: %s"), fs_type ? fs_type.to_human : ""),
          # TRANSLATORS: File system and its type as human string
          format(_("Mount Point: %s"), partition.filesystem_mountpoint || ""),
          # TRANSLATORS: Label associated with file system
          format(_("Label: %s"), partition.filesystem_label || ""),
        ]
      end

      def device_attributes_list
        [
          # TRANSLATORS: here device stands for kernel path to device
          format(_("Device: %s"), partition.name),
          # TRANSLATORS: size of partition
          format(_("Size: %s"), partition.size.to_human_string),
          # TRANSLATORS: If partition is encrypted. Answer is Yes/No
          format(_("Encrypted: %s"),  partition.encrypted? ? _("Yes") : _("No"),
          # maybe move it to own class this helpers
          device_path,
          device_id,
          # TRANSLATORS: accronym for Filesystem Identifier
          format(_("FS ID: %s"), "TODO")
        ]
      end

      def device_path
        paths = partition.udev_paths
        if paths.size > 1
          res = paths.each_with_index.map do |path, index|
            # TRANSLATORS: Device path is where on motherboard is device connected,
            # %i is number when there are more paths
            format(_("Device Path %i: %s"), index + 1, path)
          end
          res.join(Yast::HTML.Newline)
        else
          # TRANSLATORS: Device path is where on motherboard is device connected
          format(_("Device Path: %s"), paths.first)
        end
      end

      def device_id
        ids = partition.udev_ids
        if ids.size > 1
          res = paths.each_with_index.map do |id, index|
            # TRANSLATORS: Device ID is udev ID for device,
            # %i is number when there are more paths
            format(_("Device ID %i: %s"), index + 1, id)
          end
          res.join(Yast::HTML.Newline)
        else
          # TRANSLATORS: Device ID is udev ID for device,
          format(_("Device ID: %s"), ids.first)
        end
      end
    end
  end
end
