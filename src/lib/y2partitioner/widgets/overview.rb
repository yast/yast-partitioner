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
    class Overview < CWM::CustomWidget
      # creates new widget for given device graph
      # @param [Y2Storage::Devicegraph] device_graph
      # @param [CWM::ReplacePoint] details_rp replace-point for the details pane
      def initialize(device_graph, details_rp:)
        textdomain "storage"
        self.handle_all_events = true
        @hostname = Yast::Hostname.CurrentHostname
        @opened = [:all]
        @device_graph = device_graph
        @details_rp = details_rp
      end

      # content of widget
      def contents
        Tree(Id(:tree), Opt(:notify), _("System View"), items)
      end

      # handles widgets. As it is with notify, it will get any click on Item
      def handle(event)
        id = event["ID"]
        return nil unless id == :tree

        items = Yast::UI.QueryWidget(Id(:tree), :CurrentBranch)
        last = items.last
        if last.to_s.start_with? "partition:"
          pname = last.sub("partition:", "")
          partition = Y2Storage::Partition.find_by_name(@device_graph, pname)
          wterm = ExpertPartitioner::PartitionTreeView.new(partition)
          details = CWM::CustomWidget.new
          details.define_singleton_method(:contents, -> { wterm.create })
        else
          details = CWM::PushButton.new
          details.define_singleton_method(:label, -> { "Todo, #{items.inspect}" })
        end
        @details_rp.replace(details)

        nil
      end

    private

      def items
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

      def partition_items(disk)
        disk.partitions.map do |partition|
          id = "partition:" + partition.name
          item_for(id, partition.sysfs_name)
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

      def item_for(id, title, icon: nil, subtree: [])
        args = [Id(id)]
        args << term(:icon, icon) if icon
        args << title
        args << open?(id)
        args << subtree
        Item(*args)
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
