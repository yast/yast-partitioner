require "cwm/widget"

require "y2partitioner/icons"
require "expert_partitioner/tree_views/partition"

Yast.import "Hostname"

module Y2Partitioner
  module Widgets
    # Widget representing partitioner overview.
    #
    # It has replace point where it displays more details about selected element
    # in partitioning.
    #
    # TODO: abstract treewidget from it
    class Overview < CWM::Tree
      # creates new widget for given device graph
      # @param [Y2Storage::Devicegraph] device_graph
      def initialize(device_graph)
        textdomain "storage"
        self.handle_all_events = true
        @hostname = Yast::Hostname.CurrentHostname
        @opened = [:all]
        @device_graph = device_graph
      end

      def label
        _("System View")
      end

      def find_tree_item
        item_path = Yast::UI.QueryWidget(Id(widget_id), :CurrentBranch)
        ti = CWM::TreeItem.new(nil, nil, children: items)
        until item_path.empty?
          front = item_path.shift
          ti = ti.children.fetch(front) # must find it
        end
        ti
      end

      # handles widgets. As it is with notify, it will get any click on Item
      def handle(event)
        id = event["ID"]
        # TODO: pass events to child widgets
        return nil unless id == widget_id

        ti = find_tree_item
        details = ti.data
        # and here we need to work out an adaptation of what Tabs#handle does!


        itype = nil
        case itype
        when "disk"
          disk = Y2Storage::Disk.find_by_name(@device_graph, iname)
          view = ExpertPartitioner::DiskTreeView.new(disk)
          details = wrap_view(view)
        when "partition"
          partition = Y2Storage::Partition.find_by_name(@device_graph, iname)
          view = ExpertPartitioner::PartitionTreeView.new(partition)
          details = wrap_view(view)
        when "lvm_vg"
          vg = Y2Storage::LvmVg.find_by_vg_name(@device_graph, iname)
          view = ExpertPartitioner::LvmVgTreeView.new(vg)
          details = wrap_view(view)
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
        ].map { |i| [i.id, i] }.to_h
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

      def partition_items(disk)
        disk.partitions.map do |partition|
          y2partition = Y2Storage::Partition.find_by_name(@device_graph, partition.name)
          view = ExpertPartitioner::PartitionTreeView.new(y2partition)
          pane_term = view.create
          id = "partition:" + partition.name
          item_for(id, partition.sysfs_name, pane: pane_term)
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

      def item_for(id, title, icon: nil, pane: nil, subtree: [])
        children = subtree.map { |i| [i.id, i] }.to_h
        CWM::TreeItem.new(id, title, icon: icon, open: open?(id), data: pane, children: children)
      end

      def open?(id)
        @opened.include?(id)
      end
    end
  end
end
