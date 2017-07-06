require "yast"
require "cwm"
require "y2storage"

module Y2Partitioner
  module Widgets
    # Fstab mixin
    module FstabCommon
      def initialize(options)
        textdomain "storage"

        @options = options
      end

      def supported_by_filesystem?
        return false if !@options.filesystem_type

        if respond_to?("supported_filesystems")
          supported_filesystems.include?(@options.filesystem_type.to_sym)
        else
          self.class.const_get("VALUES").all? do |v|
            @options.filesystem_type.supported_fstab_options.include?(v)
          end
        end
      end

      def draw_widget?(widget)
        return true if widget.supported_by_filesystem?

        false
      end

      def draw(widget)
        return Empty() unless draw_widget?(widget)

        Left(widget)
      end

      def draw_with_vspace(widget)
        return [Empty()] unless draw_widget?(widget)

        [Left(widget), VSpacing(1)]
      end

      def delete_from_fstab!(option)
        @options.fstab_options.delete_if { |o| o =~ option }
      end
    end

    # Push button that launch a dialog for set the fstab options
    class FstabOptionsButton < CWM::PushButton
      include FstabCommon

      def label
        _("Fstab options...")
      end

      def handle
        Dialogs::FstabOptions.new(@options).run

        nil
      end
    end

    # FIXME: The help handle does not work without wizard
    # Main widget for set all the available options for a particular filesystem
    class FstabOptions < CWM::CustomWidget
      include FstabCommon

      def initialize(options)
        @options = options

        self.handle_all_events = true
      end

      def init
        disable if !supported_by_filesystem?
      end

      def handle(event)
        case event["ID"]
        when :help
          help = []

          widgets.each do |w|
            help << w.help if w.respond_to? "help"
          end

          Yast::Wizard.ShowHelp(help.join("\n"))
        end

        nil
      end

      def contents
        VBox(
          Left(MountBy.new(@options)),
          Left(VolumeLabel.new(@options)),
          VSpacing(1),
          Left(GeneralOptions.new(@options)),
          Left(FilesystemsOptions.new(@options)),
          * draw_with_vspace(JournalOptions.new(@options)),
          * draw_with_vspace(AclOptions.new(@options)),
          Left(ArbitraryOptions.new(@options))
        )
      end

      def supported_filesystems
        %i(btrfs ext2 ext3 ext4 reiserfs)
      end

    private

      def widgets
        Yast::CWM.widgets_in_contents([self])
      end
    end

    # Input field to set the partition Label
    class VolumeLabel < CWM::InputField
      include FstabCommon

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

    # Group of radio buttons to select the type of identifier to be used for
    # mouth the specific device (UUID, Label, Path...)
    class MountBy < CWM::CustomWidget
      include FstabCommon

      def label
        _("Mount in /etc/fstab by")
      end

      def store
        @options.mount_by = selected_mount_by
      end

      def init
        value = @options.mount_by ? @options.mount_by.to_sym : :uuid
        Yast::UI.ChangeWidget(Id(:mt_group), :Value, value)
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

      def selected_mount_by
        Y2Storage::Filesystems::MountByType.all.detect do |fs|
          fs.to_sym == value
        end
      end

      def value
        Yast::UI.QueryWidget(Id(:mt_group), :Value)
      end
    end

    # A group of options that are general for many filesystem types.
    class GeneralOptions < CWM::CustomWidget
      include FstabCommon

      def contents
        return Empty() unless widgets.any? { |w| draw_widget?(w) }

        VBox(* widgets.map { |w| draw(w) }, VSpacing(1))
      end

      def widgets
        [
          ReadOnly.new(@options),
          Noatime.new(@options),
          MountUser.new(@options),
          Noauto.new(@options),
          Quota.new(@options)
        ]
      end
    end

    # CheckBox to disable the automount option when starting up
    class Noauto < CWM::CheckBox
      include FstabCommon

      VALUES = ["noauto", "auto"].freeze

      def init
        self.value = @options.fstab_options.include?("noauto")
      end

      def store
        delete_from_fstab!(Regexp.union(VALUES))

        @options.fstab_options << "noauto" if value
      end

      def label
        _("Do Not Mount at System &Start-up")
      end
    end

    # CheckBox to enable the read only option ("ro")
    class ReadOnly < CWM::CheckBox
      include FstabCommon
      VALUES = ["rw", "ro"].freeze

      def init
        self.value = @options.fstab_options.include?("ro")
      end

      def store
        delete_from_fstab!(Regexp.union(VALUES))

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

    # CheckBox to enable the noatime option
    class Noatime < CWM::CheckBox
      include FstabCommon
      VALUES = ["noatime", "atime"].freeze

      def init
        self.value = @options.fstab_options.include?("noatime")
      end

      def store
        delete_from_fstab!(Regexp.union(VALUES))

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

    # CheckBox to enable the user option which means allow to mount the
    # filesystem by an ordinary user
    class MountUser < CWM::CheckBox
      include FstabCommon
      VALUES = ["user", "nouser"].freeze

      def init
        self.value = @options.fstab_options.include?("user")
      end

      def store
        delete_from_fstab!(Regexp.union(VALUES))

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

    # CheckBox to enable the use of user quotas
    class Quota < CWM::CheckBox
      include FstabCommon
      VALUES = ["grpquota", "usrquota"].freeze

      def help
        "<p><b>Enable Quota Support:</b>\n" \
        "The file system is mounted with user quotas enabled.\n" \
        "Default is false.</p>\n"
      end

      def init
        self.value = @options.fstab_options.any? { |o| VALUES.include?(o) }
      end

      def store
        delete_from_fstab!(Regexp.union(VALUES))

        @options.fstab_options << "usrquota" if value
        @options.fstab_options << "grpquota" if value
      end

      def label
        _("Enable &Quota Support")
      end
    end

    # ComboBox to specify the journal mode to use by the filesystem
    class JournalOptions < CWM::ComboBox
      include FstabCommon

      VALUES = ["data="].freeze

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
        delete_from_fstab!(/^data=/)

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

    # Custom widget that allows to enable ACL and the use of extended
    # attributes
    class AclOptions < CWM::CustomWidget
      VALUES = ["acl", "eua"].freeze

      include FstabCommon

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

    # A input field that allows to set other options that are not handled by
    # specific widgets
    class ArbitraryOptions < CWM::InputField
      def initialize(options)
        @options = options
      end

      def opt
        %i(hstretch)
      end

      def label
        _("Arbitrary Option &Value")
      end
    end

    # Some options that are mainly specific for one filesystem
    class FilesystemsOptions < CWM::CustomWidget
      include FstabCommon

      def contents
        return Empty() unless widgets.any? { |w| draw_widget?(w) }

        VBox(* widgets.map { |w| draw(w) }, VSpacing(1))
      end

      def widgets
        [
          SwapPriority.new(@options),
          IOCharset.new(@options),
          Codepage.new(@options)
        ]
      end
    end

    # Swap priority
    class SwapPriority < CWM::InputField
      include FstabCommon

      def label
        _("Swap &Priority")
      end

      def init
        i = @options.fstab_options.index { |o| o =~ /^pri=/ }

        self.value = i ? @options.fstab_options[i].gsub(/^pri=/, "") : default
      end

      def store
        delete_from_fstab!(/^pri=/)

        @options.fstab_options << "pri=#{value}"
      end

      def help
        "<p><b>Swap Priority:</b>\nEnter the swap priority. " \
        "Higher numbers mean higher priority.</p>\n"
      end

      def supported_filesystems
        [:swap]
      end

      def default
        42
      end
    end

    # VFAT IOCharset
    class IOCharset < CWM::ComboBox
      include FstabCommon

      def init
        i = @options.fstab_options.index { |o| o =~ /^iocharset=/ }

        self.value = i ? @options.fstab_options[i].gsub(/^iocharset=/, "") : default
      end

      def store
        delete_from_fstab!(/^iocharset/)

        @options.fstab_options << "iocharset=#{value}"
      end

      def label
        _("Char&set for file names")
      end

      def help
        "<p><b>Charset for File Names:</b>\nSet the charset used for display " \
        "of file names in Windows partitions.</p>\n"
      end

      def opt
        %i(editable hstretch)
      end

      def items
        [
          "", "iso8859-1", "iso8859-15", "iso8859-2", "iso8859-5", "iso8859-7",
          "iso8859-9", "utf8", "koi8-r", "euc-jp", "sjis", "gb2312", "big5",
          "euc-kr"
        ].map do |ch|
          [ch, ch]
        end
      end

      def supported_filesystems
        [:vfat]
      end

      def default
        ""
      end
    end

    # VFAT Codepage
    class Codepage < CWM::ComboBox
      include FstabCommon

      def init
        i = @options.fstab_options.index { |o| o =~ /^codepage=/ }

        self.value = i ? @options.fstab_options[i].gsub(/^codepage=/, "") : default
      end

      def store
        @options.fstab_options.delete_if { |o| o =~ /^codepage=/ }

        @options.fstab_options << "codepage=#{value}"
      end

      def label
        _("Code&page for short FAT names")
      end

      def help
        "<p><b>Codepage for Short FAT Names:</b>\nThis codepage is used for " \
        "converting to shortname characters on FAT file systems.</p>\n"
      end

      def opt
        %i(editable hstretch)
      end

      def items
        [
          "", "437", "852", "932", "936", "949", "950"
        ].map do |ch|
          [ch, ch]
        end
      end

      def supported_filesystems
        %i(vfat)
      end

      def default
        ""
      end
    end
  end
end
