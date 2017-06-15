require "yast"
require "cwm/dialog"
require "ui/greasemonkey"

module Y2Partitioner
  module Dialogs
    # Determine the size of a partition to be created, in the form
    # of a {Y2Storage::Region}.
    # Part of {Sequences::AddPartition}.
    # Formerly MiniWorkflowStepPartitionSize
    class PartitionSize < CWM::Dialog
      # @param disk []
      # @param ptemplate []
      # @param slots []
      def initialize(disk, ptemplate, slots)
        textdomain "storage"
        @disk = disk
        @ptemplate = ptemplate
        @slots = slots
      end

      def title
        # dialog title
        Yast::Builtins.sformat(_("Add Partition on %1"), @disk.name)
      end

      def contents
        HVSquash(SizeWidget.new(@disk, @ptemplate, @slots))
      end

      # Like CWM::RadioButtons but the items are triples, not pairs:
      # The third element is a WidgetTerm.
      class ControllerRadioButtons < CWM::CustomWidget
        def contents
          Frame(
            label,
            MarginBox(
              hspacing, vspacing,
              RadioButtonGroup(Id(widget_id), buttons_with_widgets)
            )
          )
        end

        def hspacing
          1.45
        end

        def vspacing
          0.45
        end

      private

        def buttons_with_widgets
          items = self.items
          widgets = self.widgets
          raise ArgumentError unless items.size == widgets.size

          terms = items.zip(widgets).map do |(id, text), widget|
            VBox(
              Left(RadioButton(Id(id), text)),
              Left(HBox(HSpacing(4), VBox(widget)))
            )
          end
          VBox(*terms)
        end
      end

      # Choose a size (region, really) for a new partition
      # from several options: use maximum, enter size, enter start+end
      class SizeWidget < ControllerRadioButtons
        include Yast
        include Yast::UIShortcuts

        def initialize(disk, ptemplate, slots)
          textdomain "storage"
          @disk = disk
          @ptemplate = ptemplate
          @slots = slots

          # FIXME: how much should we support multiple slots?
          # Maximum size: largest slot
          # Custom size: smallest slot possible
          # Custom region: inside any slot
          @slot = slots.first
          r = @slot.region
          # should Region have a #size?

          @max_size = r.block_size * r.length
        end

        def label
          _("New Partition Size")
        end

        def items
          max_size_label = Builtins.sformat(_("Maximum Size (%1)"),
            @max_size.to_human_string)
          [
            [:max_size, max_size_label],
            [:custom_size, _("Custom Size")],
            [:custom_region, _("Custom Region")]
          ]
        end

        def widgets
          @widgets ||= [
            ::CWM::Empty.new(@empty_id ||= new_id),
            # MinWidth(15, CustomSizeInput.new),
            CustomSizeInput.new,
            CustomRegion.new(@disk, @slots)
          ]
        end

        def init
          Yast::UI.ChangeWidget(Id(:max_size), :Enabled, false)
          Yast::UI.ChangeWidget(Id(:manual_size), :Enabled, false)
        end

        def store
          start_block = Yast::UI.QueryWidget(Id(:start_block), :Value)
          end_block = Yast::UI.QueryWidget(Id(:end_block), :Value)
          len = end_block - start_block + 1
          bsize = @slot.region.block_size # where does this come from?
          region = Y2Storage::Region.create(start_block, len, bsize)
          @ptemplate.region = region
        end

        def new_id
          "id_#{rand 65536}"
        end
      end

      # Enter a human readable size
      class CustomSizeInput < CWM::InputField
        def initialize
          textdomain "storage"
        end

        def label
          _("Size")
        end

        def init
        end

        def store
        end
      end

      # Specify start+end of the region
      class CustomRegion < CWM::CustomWidget
        def initialize(disk, slots)
          @disk = disk
          @slot = slots.first
          textdomain "storage"
        end

        def contents
          min_block = @disk.region.start
          # FIXME: libyui widget overflow :-(
          max_block = min_block + @disk.region.length - 1
          start_block = @slot.region.start
          end_block = start_block + @slot.region.length - 1

          VBox(
            Id(widget_id),
            MinWidth(
              10,
              IntField(
                Id(:start_block),
                _("Start Block"),
                min_block, max_block, start_block
              )
            ),
            MinWidth(
              10,
              IntField(
                Id(:end_block),
                _("End Block"),
                min_block, max_block, end_block
              )
            )
          )
        end
      end
    end
  end
end
