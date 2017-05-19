require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/icons"
require "expert_partitioner/tree_views/partition"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
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

      # FIXME: leftover from the previous prototype
      def keepme(itype, iname)
        itype = nil
        case itype
        when "disk"
          disk = Y2Storage::Disk.find_by_name(@device_graph, iname)
          view = ExpertPartitioner::DiskTreeView.new(disk)
          _details = wrap_view(view)
        when "partition"
          partition = Y2Storage::Partition.find_by_name(@device_graph, iname)
          view = ExpertPartitioner::PartitionTreeView.new(partition)
          _details = wrap_view(view)
        when "lvm_vg"
          vg = Y2Storage::LvmVg.find_by_vg_name(@device_graph, iname)
          view = ExpertPartitioner::LvmVgTreeView.new(vg)
          _details = wrap_view(view)
        else
          details = CWM::PushButton.new
          details.define_singleton_method(:label, -> { "Todo, #{items.inspect}" })
        end

        nil
      end

    private

      # @param v [ExpertPartitioner::TreeView]
      # @return [CWM::AbstractWidget]
      def wrap_view(v)
        ui_term = v.create
        w = CWM::CustomWidget.new
        w.define_singleton_method(:contents, -> { ui_term })
        w
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
        item_for(:hd, _("Hard Disks"), icon: Icons::HD, subtree: disks_items)
      end

      def disks_items
        @device_graph.disks.map do |disk|
          id = "disk:" + disk.name
          item_for(id, disk.sysfs_name, subtree: partition_items(disk))
        end
      end

      # @param [String]
      # @return [CWM::Page]
      def partition_page_for(partition_name, id:, label:)
        # the widget id of page must match the item id of its selector item
        page = CWM::Page.new(widget_id: id, label: label, contents: nil)
        dg = @device_graph
        page.define_singleton_method(:contents) do
          # FIXME: this is called dozens of times per single click!!
          return @contents if @contents
          y2partition = Y2Storage::Partition.find_by_name(dg, partition_name)
          view = ExpertPartitioner::PartitionTreeView.new(y2partition)
          @contents = view.create
        end
        page
      end

      def partition_items(disk)
        disk.partitions.map do |partition|
          id = "partition:" + partition.name
          page = partition_page_for(partition.name,
            id: id, label: partition.sysfs_name)
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

      def item_for(id, label, icon: nil, subtree: [])
        page = CWM::Page.new(widget_id: id, label: label, contents: Empty())
        CWM::PagerTreeItem.new(page,
          icon: icon, open: open?(id), children: subtree)
      end

      def open?(id)
        id == :all
      end
    end
  end
end
