require "cwm/widget"

require "y2partitioner/icons"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
    # Widget representing partitioner overview.
    #
    # It has replace point where it displays more details about selected element
    # in partitioning.
    #
    # TODO: abstract treewidget from it
    class Overview < CWM::CustomWidget
      def initialize
        self.handle_all_events = true
        @opened = [:all]
      end

      def contents
        Tree(Id(:tree), Opt(:notify), _("System View"), items)
      end

      def handle(event)
        id = event["ID"]
        log.info "handling id #{id}"

        nil
      end

    private

      def items
        [
          Item(
            Id(:all),
            term(:icon, Icons::ALL),
            open?(:all),
            "machine", # TODO: stuck getting hostname on my pc Yast::Hostname.CurrentHostname,
            machine_items
          ),
          # TODO: only if there is graph support UI.HasSpecialWidget(:Graph)
          device_graph_item,
          mount_graph_item,
          summary_item,
          settings_item
        ]
      end

      def device_graph_item
        Item(
          Id(:devicegraph),
          term(:icon, Icons::GRAPH),
          _("Device Graph"),
          open?(:devicegraph)
        )
      end

      def mount_graph_item
        Item(
          Id(:mountgraph),
          term(:icon, Icons::GRAPH),
          _("Mount Graph"),
          open?(:mountgraph)
        )
      end

      def summary_item
        Item(
          Id(:summary),
          term(:icon, Icons::SUMMARY),
          _("Installation Summary"),
          open?(:summary)
        )
      end

      def settings_item
        Item(
          Id(:settings),
          term(:icon, Icons::SETTINGS),
          _("Settings"),
          open?(:settings)
        )
      end

      def machine_items
        [
          harddisk_items,
          raid_items,
          lvm_items,
          crypt_files_items,
          device_mapper_items,
          nfs_items,
          btrfs_items,
          tmpfs_items,
          unused_items
        ]
      end

      def harddisk_items
        Item(
          Id(:hd),
          term(:icon, Icons::HD),
          _("Hard Disks"),
          open?(:hd),
          [] # TODO: real disks subtree
        )
      end

      def raid_items
        Item(
          Id(:raid),
          term(:icon, Icons::RAID),
          _("RAID"),
          open?(:raid),
          [] # TODO: real MD subtree
        )
      end

      def lvm_items
        Item(
          Id(:lvm),
          term(:icon, Icons::LVM),
          _("Volume Management"),
          open?(:lvm),
          [] # TODO: real LVM subtree
        )
      end

      def crypt_files_items
        Item(
          Id(:loop),
          term(:icon, Icons::LOOP),
          _("Crypt Files"),
          open?(:loop),
          [] # TODO: real subtree
        )
      end

      def device_mapper_items
        Item(
          Id(:dm),
          term(:icon, Icons::DM),
          _("Device Mapper"),
          open?(:dm),
          [] # TODO: real subtree
        )
      end

      def nfs_items
        Item(
          Id(:nfs),
          term(:icon, Icons::NFS),
          _("NFS"),
          open?(:nfs),
          [] # TODO: real subtree
        )
      end

      def btrfs_items
        Item(
          Id(:btrfs),
          term(:icon, Icons::NFS),
          _("Btrfs"),
          open?(:btrfs),
          [] # TODO: real subtree
        )
      end

      def tmpfs_items
        Item(
          Id(:tmpfs),
          term(:icon, Icons::NFS),
          _("tmpfs"),
          open?(:tmpfs),
          [] # TODO: real subtree
        )
      end

      def unused_items
        Item(
          Id(:unused),
          term(:icon, Icons::UNUSED),
          _("Unused Devices"),
          open?(:unused),
          [] # TODO: real subtree
        )
      end

      def open?(id)
        @opened.include?(id)
      end

      def term(*args)
        Yast::Term.new(*args)
      end
    end
  end
end
