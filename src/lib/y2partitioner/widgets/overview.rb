require "cwm/widget"
require "cwm/tree"

require "y2partitioner/icons"
require "y2partitioner/widgets/blk_devices_page"
require "y2partitioner/widgets/disk_page"
require "y2partitioner/widgets/partition_page"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
    # A dummy page for prototyping
    # FIXME: remove it when no longer needed
    class GenericPage < CWM::Page
      attr_reader :label, :contents

      def initialize(id, label, contents)
        self.widget_id = id
        @label = label
        @contents = contents
      end
    end

    # Widget representing partitioner overview.
    #
    # It has replace point where it displays more details
    # about selected element in partitioning.
    class OverviewTree < CWM::Tree

      # creates new widget for given device graph
      # @param [Y2Storage::Devicegraph] device_graph
      def initialize(device_graph)
        textdomain "storage"
        @hostname = Yast::Hostname.CurrentHostname
        @device_graph = device_graph
      end

      def label
        _("System View")
      end

      def items
        @items ||=
          [
            item_for(:all, @hostname, icon: Icons::ALL, subtree: machine_items),
            # TODO: only if there is graph support UI.HasSpecialWidget(:Graph)
            item_for(:devicegraph, _("Device Graph"), icon: Icons::GRAPH),
            # TODO: only if there is graph support UI.HasSpecialWidget(:Graph)
            item_for(:mountgraph, _("Mount Graph"), icon: Icons::GRAPH),
            item_for(:summary, _("Installation Summary"), icon: Icons::SUMMARY),
            item_for(:settings, _("Settings"), icon: Icons::SETTINGS)
          ]
      end

    private

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
        blk_devices = @device_graph.disks.reduce([]) do |acc, disk|
          acc << disk
          acc.concat(disk.partitions)
        end
        page = BlkDevicesPage.new(blk_devices, self)
        CWM::PagerTreeItem.new(page, children: disks_items, icon: Icons::HD)
      end

      def disks_items
        @device_graph.disks.map do |disk|
          page = DiskPage.new(disk, self)
          CWM::PagerTreeItem.new(page, children: partition_items(disk))
        end
      end

      def partition_items(disk)
        disk.partitions.map do |partition|
          page = PartitionPage.new(partition)
          CWM::PagerTreeItem.new(page)
        end
      end

      def raid_items
        # TODO: real MD subtree
        item_for(:raid, _("RAID"), icon: Icons::RAID, subtree: [])
      end

      def lvm_items
        item_for(:lvm, _("Volume Management"), icon:    Icons::LVM,
                                               subtree: lvm_vgs_items)
      end

      def lvm_vgs_items
        @device_graph.lvm_vgs.map do |vg|
          id = "lvm_vg:" + vg.vg_name
          item_for(id, vg.vg_name, subtree: lvm_lvs_items(vg))
        end
      end

      def lvm_lvs_items(vg)
        vg.lvm_lvs.map do |lv|
          id = "lvm_lv:" + lv.name
          item_for(id, lv.lv_name)
        end
      end

      def crypt_files_items
        # TODO: real subtree
        item_for(:loop, _("Crypt Files"), icon: Icons::LOOP, subtree: [])
      end

      def device_mapper_items
        # TODO: real subtree
        item_for(:dm, _("Device Mapper"), icon: Icons::DM, subtree: [])
      end

      def nfs_items
        item_for(:nfs, _("NFS"), icon: Icons::NFS)
      end

      def btrfs_items
        item_for(:btrfs, _("Btrfs"), icon: Icons::NFS)
      end

      def tmpfs_items
        item_for(:tmpfs, _("tmpfs"), icon: Icons::NFS)
      end

      def unused_items
        item_for(:unused, _("Unused Devices"), icon: Icons::UNUSED)
      end

      def item_for(id, label, widget: nil, icon: nil, subtree: [])
        text = id.to_s.split(":", 2)[1] || id.to_s
        widget ||= Heading(text)
        contents = VBox(widget)
        page = GenericPage.new(id, label, contents)
        CWM::PagerTreeItem.new(page,
          icon: icon, open: open?(id), children: subtree)
      end

      def open?(id)
        id == :all
      end
    end
  end
end
