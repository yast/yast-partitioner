require "yast"
require "cwm"
require "y2storage"
require "y2partitioner/format_mount_options"
require "y2partitioner/dialogs/encrypt_password"

module Y2Partitioner
  module Widgets
    # Format options for {Y2Storage::BlkDevice}
    class FormatOptions < CWM::CustomWidget
      def initialize(options)
        textdomain "storage"

        @options = options

        @encrypt_widget    = EncryptBlkDevice.new(@options.encrypt)
        @filesystem_widget = BlkDeviceFilesystem.new(@options.filesystem.to_s)

        self.handle_all_events = true
      end

      def init
        @options.format ? select_format : select_no_format
      end

      def store
        @options.format = format?
        @options.encrypt = encrypt?
        @options.filesystem = @filesystem_widget.selected_filesystem
      end

      def handle(event)
        case event["ID"]
        when :format_device
          select_format
        when :no_format_device
          select_no_format
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
                    Left(@filesystem_widget)
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
        fstab_options = []

        @mount_point_widget = MountPoint.new(@options.mount_point)
        @fstab_options_widget = FstabOptionsButton.new(fstab_options)

        self.handle_all_events = true
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
      def initialize(filesystem)
        textdomain "storage"

        @filesystem = filesystem
      end

      def init
        self.value = @filesystem
      end

      def label
        _("Filesystem")
      end

      def items
        Y2Storage::Filesystems::Type.all.map do |fs|
          [fs.to_s, fs.to_human_string]
        end
      end

      def store
        @filesystem = value
      end

      def selected_filesystem
        Y2Storage::Filesystems::Type.all.detect do |fs|
          fs.to_s == value
        end
      end
    end

    # MountPoint selector
    class MountPoint < CWM::ComboBox
      def initialize(mount_point)
        @mount_point = mount_point
      end

      def init
        self.value = @mount_point
      end

      def label
        _("Mount Point")
      end

      def opt
        [:editable, :hstretch, :notify]
      end

      def store
        @mount_point = value
      end

      def items
        %w(/root /home /opt /var).map { |mp| [mp, mp] }
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

    # FIME(WIP)
    class FstabOptionsButton < CWM::PushButton
      def initialize(options)
        @options = options
      end

      def label
        _("Fstab options")
      end

      def handle
        Yast::UI.OpenDialog(Opt(:decorated), layout)

        # FIXME: Handle edition
        Yast::UI.UserInput

        Yast::UI.CloseDialog()

        nil
      end

      def layout
        VBox(
          HSpacing(50),
          # heading text
          Left(Heading(_("Fstab Options:"))),
          VStretch(),
          VSpacing(1),
          HBox(HStretch(), HSpacing(1), dialog, HStretch(), HSpacing(1)),
          VSpacing(1),
          VStretch(),
          ButtonBox(
            PushButton(Id(:help), Opt(:helpButton), Yast::Label.HelpButton),
            PushButton(Id(:ok), Opt(:default), Yast::Label.OKButton),
            PushButton(Id(:cancel), Yast::Label.CancelButton)
          )
        )
      end

    private

      def dialog
        VBox(
          mount_by_content,
          TextEntry(Id(:vol_label), Opt(:hstretch), _("Volume &Label")),
          VSpacing(1),
          Left(CheckBox(Id("opt_readonly"), _("Mount &Read-Only"), false)),
          Left(CheckBox(Id("opt_noatime"), _("No &Access Time"), false)),
          Left(CheckBox(Id("opt_user"), _("Mountable by User"), false)),
          Left(
            CheckBox(
              Id("opt_noauto"),
              Opt(:notify),
              _("Do Not Mount at System &Start-up"), false
            )
          ),
          Left(
            CheckBox(
              Id("opt_quota"),
              Opt(:notify),
              _("Enable &Quota Support"),
              false
            )
          ),
        )
      end

      def mount_by_content
        RadioButtonGroup(
          Id(:mt_group),
          VBox(
            # label text
            Left(Label(_("Mount in /etc/fstab by"))),
            HBox(
              VBox(
                Left(RadioButton(Id(:device), _("&Device Name"))),
                Left(RadioButton(Id(:label), _("Volume &Label"))),
                Left(RadioButton(Id(:uuid), _("&UUID")))
              ),
              Top(
                VBox(
                  Left(RadioButton(Id(:id), _("Device &ID"))),
                  Left(RadioButton(Id(:path), _("Device &Path")))
                )
              )
            )
          )
        )
      end
    end
  end
end
