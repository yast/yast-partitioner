require "yast"
require "y2storage"

module Y2Partitioner
  class FormatMountOptions
    attr_accessor :filesystem, :role, :encrypt, :type, :format, :mount_point,
      :mount_by, :mount, :name, :fstab_options, :password, :label

    def initialize(options: {}, partition: nil, role: nil)
      options_for_partition(partition) if partition
      options_for_partition(role) if role

      options.each do |o, v|
        send("#{o}=", v) if respond_to?("#{o}=")
      end
    end

    def options_for_partition(partition)
      fs = partition.filesystem
      @name = partition.name
      @format  = false
      @encrypt = false
      @type = partition.type.to_sym
      @id = partition.id
      @mount_by = Y2Storage::Filesystems::MountByType::UUID
      if fs
        @filesystem  = partition.filesystem_type.to_s
        @mount_point = fs.mount_point
        (@mount_by = fs.mount_by) if fs.mount_by
        @label = fs.label
        @fstab_options = fs.fstab_options
      else
        @mount_point   = partition.respond_to?("mount_point") ? partition.mount_point : ""
        @filesystem    = default_fs
        @fstab_options = []
      end

      @mount = @mount_point && !@mount_point.empty?
    end

    def options_for_role(role)
      case role
      when :swap
        @format      = true
        @mount_point = "swap"
        @filesystem  = :swap
      when :efi_boot
        @mount_point = "/boot/efi"
        @format      = true
      when :raw
        @format      = false
      else
        @mount_point = ""
        @filesystem = default_filesystem
      end
    end

    def default_filesystem
      "xfs"
    end
  end
end
