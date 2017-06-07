require "yast"
require "cwm/dialog"
require "ui/greasemonkey"

module Y2Partitioner
  module Dialogs
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
        VBox(SizeWidget.new(@disk, @ptemplate, @slots))
      end

      class SizeWidget < CWM::CustomWidget
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

        def max_size_term
          term(
            :LeftRadioButton,
            Id(:max_size),
            Opt(:notify),
            # radio button text, %1 is replaced by size
            Builtins.sformat(
              _("Maximum Size (%1)"),
              @max_size.to_human_string
            )
          )
        end

        def manual_size_term
          # radio button text
          term(
            :LeftRadioButtonWithAttachment,
            Id(:manual_size),
            Opt(:notify),
            _("Custom Size"),
            VBox(
              Id(:manual_size_attachment),
              MinWidth(
                15,
                InputField(Id(:size_input), Opt(:shrinkable), _("Size"))
              )
            )
          )
        end

        def manual_region_term
          min_block = @disk.region.start
          # FIXME: libyui widget overflow :-(
          max_block = min_block + @disk.region.length - 1
          start_block = @slot.region.start
          end_block = start_block + @slot.region.length - 1

          # radio button text
          term(
            :LeftRadioButtonWithAttachment,
            Id(:manual_region),
            Opt(:notify),
            _("Custom Region"),
            VBox(
              Id(:manual_region_attachment),
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
          )
        end

        def contents
          contents = HVSquash(
            # frame heading
            term(
              :FrameWithMarginBox,
              _("New Partition Size"),
              RadioButtonGroup(
                Id(:size),
                VBox(
                  max_size_term,
                  manual_size_term,
                  manual_region_term
                )
              )
            )
          )
          ::UI::Greasemonkey.transform(contents)
        end
      end
    end
  end
end
