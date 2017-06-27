require "yast"
require "y2storage"

module Y2Storage
  module Filesystems
    # FIXME: Temporal Monkey patching of fstab options per filesystem type. It
    # could/should be moved to yast2-storage-ng.
    class Type
      COMMON_FSTAB_OPTIONS = ["async", "atime", "noatime", "user", "nouser",
                              "auto", "noauto", "ro", "rw", "defaults"].freeze
      EXT_FSTAB_OPTIONS = ["dev", "nodev", "usrquota", "grpquota", "acl",
                           "noacl"].freeze

      MOUNT_OPTIONS = {
        btrfs:    {
          fstab_options:       COMMON_FSTAB_OPTIONS,
          supports_format:     true,
          supports_encryption: true
        },
        ext2:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS,
          supports_format:     true,
          supports_encryption: true
        },
        ext3:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS + ["data="],
          supports_format:     true,
          supports_encryption: true
        },
        ext4:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS + ["data="],
          supports_format:     true,
          supports_encryption: true
        },
        hfs:      {
          fstab_options: []
        },
        hfsplus:  {
          fstab_options: []
        },
        jfs:      {
          fstab_options: []
        },
        msdos:    {
          fstab_options: []
        },
        nilfs2:   {
          fstab_options: []
        },
        ntfs:     {
          fstab_options: []
        },
        reiserfs: {
          fstab_options: []
        },
        swap:     {
          fstab_options: ["priority"]
        },
        vfat:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + ["dev", "nodev", "iocharset="],
          supports_format:     true,
          supports_encryption: true
        },
        xfs:      {
          fstab_options:       COMMON_FSTAB_OPTIONS + ["usrquota", "grpquota"],
          supports_format:     true,
          supports_encryption: true
        },
        iso9669:  {
          fstab_options: ["acl", "noacl"]
        },
        udf:      {
          fstab_options: ["acl", "noacl"]
        }
      }.freeze

      def supported_fstab_options
        MOUNT_OPTIONS[to_sym][:fstab_options] || []
      end
    end
  end
end

module Y2Partitioner
  # Helper class to store and remember format and mount options during
  # different dialogs avoiding the direct modification of the blk_device being
  # edited
  class FormatMountOptions
    # @return [Y2Storage::Filesystem::Type]
    attr_accessor :filesystem_type
    # @return [:system, :data, :swap, :boot_efi]
    attr_accessor :role
    # @return [Boolean]
    attr_accessor :encrypt
    # @return [Y2Storage::PartitionType]
    attr_accessor :partition_type
    # @return [String]
    attr_accessor :mount_point
    # @return [Y2Storage::Filesystems::MountBy]
    attr_accessor :mount_by
    # @return [Boolean]
    attr_accessor :format
    # @return [Boolean]
    attr_accessor :mount
    # @return [String]
    attr_accessor :name
    # @return [Array<String>]
    attr_accessor :fstab_options
    # @return [String]
    attr_accessor :password
    # @return [String]
    attr_accessor :label

    # Constructor
    #
    # @param options [Hash]
    # @param partition [Y2Storage::BlkDevice]
    # @param role [Symbol]
    def initialize(options: {}, partition: nil, role: nil)
      set_defaults!

      options_for_role(role) if role
      options_for_partition(partition) if partition

      @mount = @mount_point && !@mount_point.empty?

      options.each do |o, v|
        send("#{o}=", v) if respond_to?("#{o}=")
      end
    end

    def set_defaults!
      @format = false
      @encrypt = false
      @mount_by = Y2Storage::Filesystems::MountByType::UUID
      @filesystem_type = default_fs
      @fstab_options = []
    end

    def options_for_partition(partition)
      @name = partition.name
      @type = partition.type
      @id = partition.id
      @mount_point = partition.respond_to?("mount_point") ? partition.mount_point : ""

      fs = partition.filesystem
      if fs
        @filesystem_type = partition.filesystem_type
        @mount_point = fs.mount_point
        @mount_by = fs.mount_by if fs.mount_by
        @label = fs.label
        @fstab_options = fs.fstab_options
      end
    end

    # FIXME: To be implemented mainly for {Sequences::AddPartition}
    def options_for_role(role)
      case role
      when :swap
        @format = true
        @mount_point = "swap"
        @filesystem_type = Y2Storage::Filesystems::Type::SWAP
      when :efi_boot
        @mount_point = "/boot/efi"
        @format = true
      when :raw
        @format = false
      else
        @mount_point = ""
        @filesystem = default_fs
      end
    end

    def default_fs
      Y2Storage::Filesystems::Type::BTRFS
    end

    def used_mount_points
      dg = DeviceGraphs.instance.current

      Y2Storage::Mountable.all(dg).map(&:mount_point).compact
    end
  end
end
