# encoding: utf-8

# Copyright (c) [2017] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "y2storage"

module Y2Storage
  # FIXME: Monkey patch of Y2Storage::PartitionId it should moved to
  # yast2-storage-ng
  class PartitionId
    include Yast::I18n
    extend Yast::I18n

    TRANSLATIONS = {
      dos12:              N_("DOS12"),
      dos16:              N_("DOS16"),
      dos32:              N_("DOS32"),
      swap:               N_("Linux Swap"),
      linux:              N_("Lnux"),
      lvm:                N_("Linux LVM"),
      raid:               N_("Linux RAID"),
      esp:                N_("EFI System Partition"),
      bios_boot:          N_("BIOS Boot Partition"),
      prep:               N_("PReP Boot Partition"),
      ntfs:               N_("NTFS"),
      extended:           N_("Extended"),
      windows_basic_data: N_("Windows Data Partition"),
      microsoft_reserved: N_("Microsoft Reserved Partition"),
      diag:               N_("Diagnostics Partition"),
      unknown:            N_("Unknown")
    }.freeze
    private_constant :TRANSLATIONS

    def to_human_string
      textdomain "storage"

      string = TRANSLATIONS[to_sym] or raise "Unhandled Partition ID '#{inspect}'"

      _(string)
    end

    def formattable?
      !%i[lvm raid esp prep bios_boot unknown].include?(to_sym)
    end

    def encryptable?
    end
  end

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
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::LINUX
        },
        ext2:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS,
          supports_format:     true,
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::LINUX
        },
        ext3:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS + ["data="],
          supports_format:     true,
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::LINUX
        },
        ext4:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + EXT_FSTAB_OPTIONS + ["data="],
          supports_format:     true,
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::LINUX
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
          fstab_options:       ["priority"],
          supports_format:     true,
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::SWAP
        },
        vfat:     {
          fstab_options:       COMMON_FSTAB_OPTIONS + ["dev", "nodev", "iocharset="],
          supports_format:     true,
          supports_encryption: true
        },
        xfs:      {
          fstab_options:       COMMON_FSTAB_OPTIONS + ["usrquota", "grpquota"],
          supports_format:     true,
          supports_encryption: true,
          partition_id:        Y2Storage::PartitionId::LINUX
        },
        iso9669:  {
          fstab_options:       ["acl", "noacl"],
          supports_format:     false,
          supports_encryption: false
        },
        udf:      {
          fstab_options: ["acl", "noacl"]
        }
      }.freeze

      def supported_fstab_options
        MOUNT_OPTIONS[to_sym][:fstab_options] || []
      end

      def encryptable?
        MOUNT_OPTIONS[to_sym][:supports_encryption] || false
      end

      def formattable?
        MOUNT_OPTIONS[to_sym][:supports_format] || false
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
    # @return [Y2Storage::PartitionId]
    attr_accessor :partition_id
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
      @partition_id = Y2Storage::PartitionId::LINUX
      @fstab_options = []
    end

    def options_for_partition(partition)
      @name = partition.name
      @type = partition.type
      @partition_id = partition.id

      @mount_point = partition.respond_to?("mount_point") ? partition.mount_point : ""

      fs = partition.filesystem

      return unless fs

      @filesystem_type = partition.filesystem_type
      @mount_point = fs.mount_point
      @mount_by = fs.mount_by if fs.mount_by
      @label = fs.label
      @fstab_options = fs.fstab_options
    end

    def options_for_windows_partition(_partition_id)
      @filesystem_type = Y2Storage::Filesystems::Type::VFAT
    end

    def options_for_partition_id(partition_id)
      return options_for_windows_partition(partition_id) if partition_id.is?(:windows_system)

      case partition_id
      when Y2Storage::PartitionId::SWAP
        options_for_role(:swap)
      when Y2Storage::PartitionId::ESP
        options_for_role(:efi_boot)
      else
        @filesystem_type = partition_id.formattable? ? default_fs : nil
      end
    end

    # FIXME: To be implemented mainly for {Sequences::AddPartition}
    def options_for_role(role)
      case role
      when :swap
        @mount_point = "swap"
        @filesystem_type = Y2Storage::Filesystems::Type::SWAP
        @partition_id = Y2Storage::PartitionId::SWAP
        @mount_by = Y2Storage::Filesystems::MountByType::DEVICE
      when :efi_boot
        @mount_point = "/boot/efi"
        @partition_id = Y2Storage::PartitionId::ESP
      when :raw
        @partition_id = Y2Storage::PartitionId::LVM
      else
        @mount_point = ""
        @filesystem = (role == :system) ? default_fs : default_home_fs
        @partition_id = Y2Storage::PartitionId::LINUX
      end
    end

    def default_fs
      Y2Storage::Filesystems::Type::BTRFS
    end

    def default_home_fs
      Y2Storage::Filesystems::Type::XFS
    end

    def used_mount_points
      dg = DeviceGraphs.instance.current

      Y2Storage::Mountable.all(dg).map(&:mount_point).compact
    end
  end
end
