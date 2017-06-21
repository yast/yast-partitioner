require "yast"
require "cwm"
require "y2storage"

module Y2Partitioner
  module Widgets
    # Push button that launch a dialog for set the fstab options
    class FstabOptionsButton < CWM::PushButton
      def initialize(options)
        @options = options
      end

      def label
        _("Fstab options")
      end

      def handle
        Dialogs::FstabOptions.new(@options).run

        nil
      end
    end

    # Main widget for set all the available options for a particular filesystem
    class FstabOptions < CWM::CustomWidget
      def initialize(options)
        textdomain "storage"

        @options = options

        self.handle_all_events = true
      end

      def help
      end

      def store
      end

      def contents
        VBox(
          Left(MountBy.new(@options)),
          Left(VolumeLabel.new(@options)),
          VSpacing(1),
          Left(GeneralOptions.new(@options)),
          Left(FilesystemsOptions.new(@options)),
          VSpacing(1),
          Left(JournalOptions.new(@options)),
          VSpacing(1),
          Left(AclOptions.new(@options)),
          VSpacing(1),
          Left(ArbitraryOptions.new(@options))
        )
      end
    end

    class VolumeLabel < CWM::InputField
      def initialize(options)
        @options = options
      end

      def label
        _("Volume &Label")
      end

      def store
        @options.label = value
      end

      def init
        self.value = @options.label
      end
    end

    class MountBy < CWM::CustomWidget
      def initialize(options)
        textdomain "storage"

        @options = options
      end

      def label
        _("Mount in /etc/fstab by")
      end

      def store
        @options.mount_by = value
      end

      def init
        Yast::UI.ChangeWidget(Id(:mt_group), :Value, @options.mount_by)
      end

      def contents
        RadioButtonGroup(
          Id(:mt_group),
          VBox(
            Left(Label(label)),
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

      def value
        Yast::UI.QueryWidget(Id(:mt_group), :Value)
      end
    end

    class GeneralOptions < CWM::CustomWidget
      def initialize(options)
        textdomain "storage"

        @options = options
      end

      def contents
        VBox(
          Left(ReadOnly.new(@options)),
          Left(Noatime.new(@options)),
          Left(MountUser.new(@options)),
          Left(Noauto.new(@options)),
          Left(Quota.new(@options))
        )
      end
    end

    class Noauto < CWM::CheckBox
      VALUES = ["noauto", "auto"].freeze

      def initialize(options)
        @options = options
      end

      def init
        self.value = @options.fstab_options.include?("noauto")
      end

      def store
        @options.fstab_options.delete_if { |o| VALUES.include?(o) }

        @options.fstab_options << "noauto" if value
      end

      def help
      end

      def label
        _("Do Not Mount at System &Start-up")
      end
    end

    class ReadOnly < CWM::CheckBox
      VALUES = ["rw", "ro"].freeze

      def initialize(options)
        @options = options
      end

      def init
        self.value = @options.fstab_options.include?("ro")
      end

      def store
        @options.fstab_options.delete_if { |o| VALUES.include?(o) }

        @options.fstab_options << "ro" if value
      end

      def help
        "<p><b>Mount Read-Only:</b>\n" \
        "Writing to the file system is not possible. Default is false. During installation\n" \
        "the file system is always mounted read-write.</p>"
      end

      def label
        _("Mount &Read-Only")
      end
    end

    class Noatime < CWM::CheckBox
      VALUES = ["noatime", "atime"].freeze

      def initialize(options)
        @options = options
      end

      def init
        self.value = @options.fstab_options.include?("noatime")
      end

      def store
        @options.fstab_options.delete_if { |o| VALUES.include?(o) }

        @options.fstab_options << "noatime" if value
      end

      def help
        "<p><b>No Access Time:</b>\nAccess times are not " \
        "updated when a file is read. Default is false.</p>\n"
      end

      def label
        _("No &Access Time")
      end
    end

    class MountUser < CWM::CheckBox
      VALUES = ["user", "nouser"].freeze

      def initialize(options)
        @options = options
      end

      def init
        self.value = @options.fstab_options.include?("user")
      end

      def store
        @options.fstab_options.delete_if { |o| VALUES.include?(o) }

        @options.fstab_options << "user" if value
      end

      def help
        "<p><b>Mountable by User:</b>\nThe file system may be " \
        "mounted by an ordinary user. Default is false.</p>\n"
      end

      def label
        _("Mountable by user")
      end
    end

    class Quota < CWM::CheckBox
      VALUES = ["grpquota", "usrquota"].freeze

      def initialize(options)
        @options = options
      end

      def help
        "<p><b>Enable Quota Support:</b>\n" \
        "The file system is mounted with user quotas enabled.\n" \
        "Default is false.</p>\n"
      end

      def init
        self.value = @options.fstab_options.any? { |o| VALUES.include?(o) }
      end

      def store
        @options.fstab_options.delete_if { |o| VALUES.include?(o) }

        @options.fstab_options << "usrquota" if value
        @options.fstab_options << "grpquota" if value
      end

      def label
        _("Enable &Quota Support")
      end
    end

    class JournalOptions < CWM::ComboBox
      def initialize(options)
        @options = options
      end

      def label
        _("Data &Journaling Mode")
      end

      def init
        i = @options.fstab_options.index { |o| o =~ /^data=/ }

        self.value = i ? @options.fstab_options[i].gsub(/^data=/, "") : default
      end

      def store
        @options.fstab_options.delete_if { |o| o =~ /^data=/ }

        @options.fstab_options << "data=#{value}"
      end

      def items
        [
          ["journal", "journal"],
          ["ordered", "ordered"],
          ["writeback", "writeback"]
        ]
      end

      def help
        "<p><b>Data Journaling Mode:</b>\n" \
        "Specifies the journaling mode for file data.\n" \
        "<tt>journal</tt> -- All data is committed to the journal prior to being\n" \
        "written into the main file system. Highest performance impact.<br>\n" \
        "<tt>ordered</tt> -- All data is forced directly out to the main file system\n" \
        "prior to its metadata being committed to the journal. Medium performance impact.<br>\n" \
        "<tt>writeback</tt> -- Data ordering is not preserved. No performance impact.</p>\n"
      end

      def default
        "journal"
      end
    end

    class AclOptions < CWM::CustomWidget
      def initialize(options)
        @options = options
      end

      def contents
        VBox(
          Left(CheckBox(Id("opt_acl"), _("&Access Control Lists (ACL)"), false)),
          Left(CheckBox(Id("opt_eua"), _("&Extended User Attributes"), false))
        )
      end
    end

    class ArbitraryOptions < CWM::InputField
      def initialize(options)
        @options = options
      end

      def opt
        [:hstretch]
      end

      def label
        _("Arbitrary Option &Value")
      end
    end

    class FilesystemsOptions < CWM::CustomWidget
      def initialize(options)
        @options = options
      end

      def contents
        widgets
      end

      def widgets
        case @options.filesystem
        when Y2Storage::Filesystems::Type::SWAP
          SwapPriority.new(@options)
        else
          Empty()
        end
      end
    end

    class SwapPriority < CWM::InputField
      def initialize(options)
        @options = options
      end

      def label
        _("Swap &Priority")
      end

      def init
        42
      end

      def validate
      end

      def help
        "<p><b>Swap Priority:</b>\nEnter the swap priority. " \
        "Higher numbers mean higher priority.</p>\n"
      end
    end
  end
end
