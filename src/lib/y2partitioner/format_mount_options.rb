require "yast"
require "y2storage"

module Y2Storage
  module Filesystems
    class Type
      MOUNT_OPTIONS = {
        btrfs:    {
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "defaults"]


        },
        ext2:     {
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "defaults", "dev", "nodev",
                          "usrquota", "grpquota", "acl", "noacl"]


        },
        ext3:     {
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "defaults", "dev", "nodev",
                          "usrquota", "grpquota", "data=", "acl", "noacl"]

        },
        ext4:     {
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "defaults", "dev", "nodev",
                          "usrquota", "grpquota", "data=", "acl", "noacl"]
        },
        hfs:      {
          fstab_options: []
        },
        hfsplus:  {
          fstab_options: []
        },
        jfs:      {
          fstab_options:  []
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
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "defaults", "dev", "nodev",
                          "iocharset="]
        },
        xfs:      {
          fstab_options: ["async", "atime", "noatime", "user", "nouser", "auto",
                          "noauto", "ro", "rw", "usrquota", "grpquota"]
        },
        iso9669:  {
          fstab_options: ["acl", "noacl"]
        },
        udf:      {
          fstab_options: ["acl", "noacl"]
        }
      }

      def supported_fstab_options
        MOUNT_OPTIONS[to_sym][:fstab_options] || []
      end
    end
  end
end

module Y2Partitioner
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
      @format   = false
      @encrypt  = false
      @mount_by = Y2Storage::Filesystems::MountByType::UUID
      @filesystem_type    = default_fs
      @fstab_options = []
    end

    def options_for_partition(partition, defaults = false)
      @name = partition.name
      @type = partition.type
      @id = partition.id
      @mount_point   = partition.respond_to?("mount_point") ? partition.mount_point : ""

      options_for_filesystem(partition.filesystem) if partition.filesystem
      fs = partition.filesystem
      if fs
        @filesystem_type  = partition.filesystem_type
        @mount_point = fs.mount_point
        @mount_by = fs.mount_by if fs.mount_by
        @label = fs.label
        @fstab_options = fs.fstab_options
      end
    end

    def options_for_role(role)
      case role
      when :swap
        @format      = true
        @mount_point = "swap"
        @filesystem_type  = Y2Storage::Filesystems::Type::SWAP
      when :efi_boot
        @mount_point = "/boot/efi"
        @format      = true
      when :raw
        @format      = false
      else
        @mount_point = ""
        @filesystem = default_fs
      end
    end

    def options_for_filesystem(filesystem)
      case filesystem.type
      when Y2Storage::Filesystems::Type::SWAP
        @mount_point = "swap"
      when Y2Storage::Filesystems::Type::EXT2
      when Y2Storage::Filesystems::Type::EXT3
      when Y2Storage::Filesystems::Type::EXT4
      when Y2Storage::Filesystems::Type::XFS
      when Y2Storage::Filesystems::Type::BTRFS
      else
      end
    end

    def default_fs
      Y2Storage::Filesystems::Type::BTRFS
    end
  end
end
