require "yast"

Yast.import "Mode"

module Y2Partitioner
  module Widgets
    # Helper methods for generating widget helps.
    module Help
      extend Yast::I18n

      def included(_target)
        textdomain "storage"
      end

      # return translated text for given field in table or description
      # TODO: old yast2-storage method, need some cleaning
      def helptext_for(field)
        ret = "<p>"

        case field
        when :bios_id
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>BIOS ID</b> shows the BIOS ID of the hard\ndisk. This field can be empty."
            )
        when :bus
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Bus</b> shows how the device is connected to\nthe system. " \
                "This field can be empty, e.g. for multipath disks."
            )
        when :chunk_size
          # helptext for table column and overview entry
          ret <<
            _("<b>Chunk Size</b> shows the chunk size for RAID\ndevices.")
        when :cyl_size
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Cylinder Size</b> shows the size of the\ncylinders of the hard disk."
            )
        when :sector_size
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Sector Size</b> shows the size of the\nsectors of the hard disk."
            )
        when :device
          # helptext for table column and overview entry
          ret <<
            _("<b>Device</b> shows the kernel name of the\ndevice.")
        when :disk_label
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Disk Label</b> shows the partition table\ntype of the disk, " \
              "e.g <tt>MSDOS</tt> or <tt>GPT</tt>."
            )
        when :encrypted
          # helptext for table column and overview entry
          ret <<
            _("<b>Encrypted</b> shows whether the device is\nencrypted.")
        when :end_cyl
          # helptext for table column and overview entry
          ret <<
            _("<b>End Cylinder</b> shows the end cylinder of\nthe partition.")
        when :fc_fcp_lun
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>LUN</b> shows the Logical Unit Number for\nFibre Channel disks."
            )
        when :fc_port_id
          # helptext for table column and overview entry
          ret <<
            _("<b>Port ID</b> shows the port id for Fibre\nChannel disks.")
        when :fc_wwpn
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>WWPN</b> shows the World Wide Port Name for\nFibre Channel disks."
            )
        when :file_path
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>File Path</b> shows the path of the file for\nan encrypted loop device."
            )
        when :format
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Format</b> shows some flags: <tt>F</tt>\nmeans the device " \
              "is selected to be formatted."
            )
        when :fs_id
          # helptext for table column and overview entry
          ret << _("<b>FS ID</b> shows the file system id.")
        when :fs_type
          # helptext for table column and overview entry
          ret << _("<b>FS Type</b> shows the file system type.")
        when :label
          # helptext for table column and overview entry
          ret <<
            _("<b>Label</b> shows the label of the file\nsystem.")
        when :lvm_metadata
          # helptext for table column and overview entry
          ret << _(
            "<b>Metadata</b> shows the LVM metadata type for\nvolume groups."
          )
        when :model
          # helptext for table column and overview entry
          ret << _("<b>Model</b> shows the device model.")
        when :mount_by
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Mount by</b> indicates how the file system\n" \
                "is mounted: (Kernel) by kernel name, (Label) by file system label, (UUID) by\n" \
                "file system UUID, (ID) by device ID, and (Path) by device path.\n"
            )
          if Yast::Mode.normal
            # helptext for table column and overview entry
            ret << " " <<
              _(
                "A question mark (?) indicates that\n" \
                  "the file system is not listed in <tt>/etc/fstab</tt>. It is either mounted\n" \
                  "manually or by some automount system. When changing settings for this volume\n" \
                  "YaST will not update <tt>/etc/fstab</tt>.\n"
              )
          end
        when :mount_point
          # helptext for table column and overview entry
          ret <<
            _("<b>Mount Point</b> shows where the file system\nis mounted.")
          if Yast::Mode.normal
            # helptext for table column and overview entry
            ret <<
              _(
                "An asterisk (*) after the mount point\n" \
                  "indicates a file system that is currently not mounted (for example, " \
                  "because it\nhas the <tt>noauto</tt> option set in <tt>/etc/fstab</tt>)."
              )
          end
        when :num_cyl
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Number of Cylinders</b> shows how many\ncylinders the hard disk has."
            )
        when :parity_algorithm
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Parity Algorithm</b> shows the parity\nalgorithm for RAID devices with " \
              "RAID type 5, 6 or 10."
            )
        when :pe_size
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>PE Size</b> shows the physical extent size\nfor LVM volume groups."
            )
        when :raid_version
          # helptext for table column and overview entry
          ret << _("<b>RAID Version</b> shows the RAID version.")
        when :raid_type
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>RAID Type</b> shows the RAID type, also\ncalled RAID level, for RAID devices."
            )
        when :size
          # helptext for table column and overview entry
          ret << _("<b>Size</b> shows the size of the device.")
        when :start_cyl
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Start Cylinder</b> shows the start cylinder\nof the partition."
            )
        when :stripes
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Stripes</b> shows the stripe number for LVM\nlogical volumes and, if greater " \
              "than one, the stripe size  in parenthesis.\n"
            )
        when :type
          # helptext for table column and overview entry
          ret <<
            _("<b>Type</b> gives a general overview about the\ndevice type.")
        when :udev_id
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Device ID</b> shows the persistent device\nIDs. This field can be empty.\n"
            )
        when :udev_path
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Device Path</b> shows the persistent device\npath. This field can be empty."
            )
        when :used_by
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>Used By</b> shows if a device is used by\ne.g. RAID or LVM. " \
              "If not, this column is empty.\n"
            )
        when :uuid
          # helptext for table column and overview entry
          ret <<
            _(
              "<b>UUID</b> shows the Universally Unique\nIdentifier of the file system."
            )
        when :vendor
          # helptext for table column and overview entry
          ret << _("<b>Vendor</b> shows the device vendor.")
        else
          raise "Unknown field #{field}"
        end

        ret << "</p>"
      end
    end
  end
end
