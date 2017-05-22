require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/icons"
require "y2partitioner/widgets/blk_devices_table"
require "y2partitioner/widgets/disk_page"
require "y2partitioner/widgets/partition_description"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
    # A dummy page for prototyping
    class GenericPage < CWM::Page
      attr_reader :label, :contents

      def initialize(id, label, contents)
        self.widget_id = id
        @label = label
        @contents = contents
      end
    end

    class PartitionPage < CWM::Page
      # @param [Y2Storage::Partition] partition
      def initialize(partition)
        @partition = partition
        self.widget_id = "partition:" + partition.name
      end

      def label
        @partition.sysfs_name
      end

      def contents
        # FIXME: this is called dozens of times per single click!!
        return @contents if @contents
        rt_w = PartitionDescription.new(@partition)
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents = VBox(rt_w)
      end
    end

    # Widget representing partitioner overview.
    #
    # It has replace point where it displays more details
    # about selected element in partitioning.
    class Overview < CWM::TreePager
      attr_reader :tree_widget

      # creates new widget for given device graph
      # @param [Y2Storage::Devicegraph] device_graph
      def initialize(device_graph)
        textdomain "storage"
        @hostname = Yast::Hostname.CurrentHostname
        @device_graph = device_graph
        super(*items, label: _("System View"))
      end

    private

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
        bdt_w = BlkDevicesTable.new(@device_graph.disks)
        item_for(:hd, _("Hard Disks"), icon:    Icons::HD,
                                       widget:  bdt_w,
                                       subtree: disks_items)
      end

      def disks_items
        @device_graph.disks.map do |disk|
          page = DiskPage.new(disk)
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
          id = "lvm_lv" + lv.name
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
        contents = widget ? VBox(widget) : Empty()
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
