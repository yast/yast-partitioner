module Y2Partitioner
  class FormatMountOptions
    attr_accessor :filesystem, :role, :encrypt, :type, :format, :mount_point,
                  :mount, :name, :fstab_options, :password

    def initialize(options: {}, partition: nil, role: nil)
      options_for_partition(partition) if partition
      options_for_partition(role) if role

      options.each do |o, v|
        self.send("#{o}=", v) if self.respond_to?("#{o}=")
      end
    end

    def options_for_partition(partition)
      @name = partition.name
      @format  = false
      @encrypt = false
      @type = partition.type.to_sym
      @id = partition.id
      if partition.filesystem
        @filesystem  = partition.filesystem_type.to_s
        @mount_point =  partition.filesystem.mount_point
        @fstab_options = partition.filesystem.fstab_options
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
      end
    end

    def default_filesystem
      "xfs"
    end
  end
end
