require "yast"
require "cwm"
require "y2storage"
require "y2partitioner/format_mount_options"
require "y2partitioner/dialogs/fstab_options"
require "y2partitioner/widgets/fstab_options"

module Y2Partitioner
  module Widgets
    # Format options for {Y2Storage::BlkDevice}
    class FormatOptions < CWM::CustomWidget
      def initialize(options, mount_widget)
        textdomain "storage"

        @options = options

        @encrypt_widget    = EncryptBlkDevice.new(@options.encrypt)
        @filesystem_widget = BlkDeviceFilesystem.new(@options)
        @mount_widget = mount_widget

        self.handle_all_events = true
      end

      def init
        @options.format ? select_format : select_no_format
      end

      def store
        @options.format = format?
        @options.encrypt = encrypt?
      end

      def handle(event)
        case event["ID"]
        when :format_device
          select_format
        when :no_format_device
          select_no_format
        when @filesystem_widget.widget_id
          store

          @mount_widget.reload
        end

        nil
      end

      def contents
        Frame(
          _("Format Options"),
          MarginBox(
            1.45,
            0.5,
            VBox(
              RadioButtonGroup(
                Id(:format),
                VBox(
                  Left(RadioButton(Id(:format_device), Opt(:notify), _("Format device"))),
                  HBox(
                    HSpacing(4),
                    VBox(
                      Left(@filesystem_widget),
                      Left(FormatOptionsButton.new(@options))
                    )
                  ),
                  Left(RadioButton(Id(:no_format_device), Opt(:notify), _("Do not format device")))
                )
              ),
              Left(@encrypt_widget)
            )
          )
        )
      end

    private

      # FIXME: This method has been copied from {Y2Storage::Proposal::Encrypter}
      # and should be moved probably to {Y2Storage::Encription}
      def dm_name_for(device)
        name = device.name.split("/").last
        "cr_#{name}"
      end

      def select_format
        @filesystem_widget.enable
        Yast::UI.ChangeWidget(Id(:format_device), :Value, true)
        @format = true
      end

      def select_no_format
        @filesystem_widget.disable
        Yast::UI.ChangeWidget(Id(:no_format_device), :Value, true)
        @format = false
      end

      def format?
        Yast::UI::QueryWidget(Id(:format_device), :Value)
      end

      def encrypt?
        @encrypt_widget.value
      end
    end

    # Mount options for {Y2Storage::BlkDevice}
    class MountOptions < CWM::CustomWidget
      def initialize(options)
        textdomain "storage"

        @options = options

        @mount_point_widget = MountPoint.new(@options)
        @fstab_options_widget = FstabOptionsButton.new(@options)

        self.handle_all_events = true
      end

      def reload
        @mount_point_widget.init
      end

      def init
        if @options.mount
          @fstab_options_widget.enable
          Yast::UI.ChangeWidget(Id(:mount_device), :Value, true)
        else
          @mount_point_widget.disable
          @fstab_options_widget.disable
          Yast::UI.ChangeWidget(Id(:no_mount_device), :Value, true)
        end
      end

      def contents
        Frame(
          _("Mount Options"),
          MarginBox(
            1.45,
            0.5,
            VBox(
              RadioButtonGroup(
                Id(:mount),
                VBox(
                  Left(RadioButton(Id(:mount_device), Opt(:notify), _("Mount device"))),
                  HBox(
                    HSpacing(4),
                    VBox(
                      Left(@mount_point_widget),
                      Left(@fstab_options_widget)
                    )
                  ),
                  Left(RadioButton(Id(:no_mount_device), Opt(:notify), _("Do not mount device")))
                )
              )
            )
          )
        )
      end

      def handle(event)
        case event["ID"]
        when :mount_device
          @mount_point_widget.enable
          @fstab_options_widget.enable
        when :no_mount_device
          @fstab_options_widget.disable
          @mount_point_widget.disable
        end

        nil
      end

      def store
        @options.mount = mount?
        @options.mount_point = @mount_point_widget.value

        nil
      end

    private

      def mount?
        Yast::UI.QueryWidget(Id(:mount_device), :Value)
      end
    end

    # BlkDevice Filesystem selector
    class BlkDeviceFilesystem < CWM::ComboBox
      def initialize(options)
        textdomain "storage"

        @options = options
      end

      def opt
        [:hstretch, :notify]
      end

      def init
        self.value = @options.filesystem_type.to_sym
      end

      def handle
        store

        nil
      end

      def label
        _("Filesystem")
      end

      def items
        Y2Storage::Filesystems::Type.all.select { |fs| supported?(fs) }.map do |fs|
          [fs.to_sym, fs.to_human_string]
        end
      end

      def supported?(fs)
        [:btrfs, :ext2, :ext3, :ext4, :vfat, :xfs, :reiserfs].include?(fs.to_sym)
      end

      def store
        @options.filesystem_type = Y2Storage::Filesystems::Type.find(value)
      end
    end

    class FormatOptionsButton < CWM::PushButton
      def initialize(options)
        @options = options
      end

      def opt
        [:hstretch, :notify]
      end

      def label
        _("Options...")
      end

      def handle
        #Dialogs::FormatOptions.new(@options).run

        nil
      end

    end
    # MountPoint selector
    class MountPoint < CWM::ComboBox
      def initialize(options)
        @options = options
      end

      def init
        self.value = @options.mount_point
      end

      def label
        _("Mount Point")
      end

      def opt
        [:editable, :hstretch, :notify]
      end

      def store
        @options.mount_point = value
      end

      def items
        %w(/root /home /srv /tmp /opt /var).map { |mp| [mp, mp] }
      end
    end

    # Encryption selector
    class EncryptBlkDevice < CWM::CheckBox
      def initialize(encrypt)
        @encrypt = encrypt
      end

      def label
        _("Encrypt Device")
      end

      def init
        self.value = @encrypt
      end

      def store
        @encrypt = value
      end
    end

    # Format option
    class InodeSize < CWM::ComboBox
      SIZES = ["auto", "512", "1024", "2048", "4096"].freeze

      def initialize(options)
        @options = options
      end

      def label
        _("&Inode Size")
      end

      def help
      end

      def items
        SIZES.map { |s| [s, s] }
      end
    end

    # Format option
    class BlockSize < CWM::ComboBox
      SIZES = ["auto", "512", "1024", "2048", "4096"].freeze

      def initialize(options)
        @options = options
      end

      def label
        _("Block &Size in Bytes")
      end

      def help
        "<p><b>Block Size:</b>\nSpecify the size of blocks in bytes. " \
          "Valid block size values are 512, 1024, 2048 and 4096 bytes " \
          "per block. If auto is selected, the standard block size of " \
          "4096 is used.</p>\n"
      end

      def items
        SIZES.map { |s| [s, s] }
      end
    end
  end
end
