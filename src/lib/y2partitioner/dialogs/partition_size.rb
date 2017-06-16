require "y2storage"
require "yast"
require "cwm/dialog"

Yast.import "Popup"

module Y2Storage
  # Monkey-patched Region to get a size
  class Region
    # @return [Y2Storage::DiskSize] {#block_size} * {#length}
    def size
      block_size * length
    end

    # #cover? like Range#cover?

    # @param block [Fixnum] disk block number
    # @return [Boolean] is *block* inside the region?
    def cover?(block)
      start <= block && block <= self.end
    end
  end

  # Monkey-patched DiskSize to get #human_floor
  class DiskSize
    # A human readable representation that does not exceed the exact size.
    #
    # If we have 4.999 GiB of space and prefill the "Size" widget
    # with a "5.00 GiB" it will then fail validation. We must round down.
    #
    # @see to_human_string
    def human_floor
      return "unlimited" if unlimited?
      float, unit_s = human_string_components
      "#{(float * 100).floor / 100.0} #{unit_s}"
    end

    # A human readable representation that is at least the exact size.
    #
    # (This seems unnecessary because actual minimum sizes
    # have few significant digits, but we use it for symmetry)
    #
    # @see to_human_string
    def human_ceil
      return "unlimited" if unlimited?
      float, unit_s = human_string_components
      "#{(float * 100).ceil / 100.0} #{unit_s}"
    end
  end
end

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

      # Like CWM::RadioButtons but each RB has a subordinate indented widget.
      # This is kind of like Pager, but all Pages being visible at once,
      # and enabled/disabled.
      # Besides `items` there are also `widgets`
      class ControllerRadioButtons < CWM::CustomWidget
        def initialize
          self.handle_all_events = true
        end

        def contents
          Frame(
            label,
            MarginBox(
              hspacing, vspacing,
              RadioButtonGroup(Id(widget_id), buttons_with_widgets)
            )
          )
        end

        # @return [Array<Array(String,String)>]
        abstract_method :items

        # FIXME: allow {WidgetTerm}
        # @return [Array<AbstractWidget>]
        abstract_method :widgets

        def hspacing
          1.45
        end

        def vspacing
          0.45
        end

        def handle(event)
          eid = event["ID"]
          @ids ||= items.map(&:first)
          @ids.zip(widgets).each do |id, widget|
            if id == eid
              widget.enable
            else
              widget.disable
            end
          end
          nil
        end

        def value
          Yast::UI.QueryWidget(Id(widget_id), :CurrentButton)
        end

        def value=(val)
          Yast::UI.ChangeWidget(Id(widget_id), :CurrentButton, val)
        end

      private

        def buttons_with_widgets
          items = self.items
          widgets = self.widgets
          raise ArgumentError unless items.size == widgets.size

          terms = items.zip(widgets).map do |(id, text), widget|
            VBox(
              Left(RadioButton(Id(id), Opt(:notify), text)),
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
          @largest_region = @slots.map(&:region).max_by(&:size)
        end

        def label
          _("New Partition Size")
        end

        def items
          max_size_label = Yast::Builtins.sformat(_("Maximum Size (%1)"),
            @largest_region.size.human_floor)
          [
            [:max_size, max_size_label],
            [:custom_size, _("Custom Size")],
            [:custom_region, _("Custom Region")]
          ]
        end

        def widgets
          @widgets ||= [
            MaxSizeDummy.new(@largest_region),
            CustomSizeInput.new(@slots),
            CustomRegion.new(@slots)
          ]
        end

        def init
          self.value = :max_size
          # trigger disabling the other subwidgets
          handle("ID" => value)
        end

        def store
          v = value
          @ids ||= items.map(&:first)
          w = widgets[@ids.index(v)]
          w.store
          @ptemplate.region = w.region
        end
      end

      # An invisible widget that knows a Region
      class MaxSizeDummy < CWM::Empty
        attr_reader :region

        def initialize(region)
          @region = region
        end

        def store
          # nothing to do, that's OK
        end
      end

      # Enter a human readable size
      class CustomSizeInput < CWM::InputField
        # @return [Y2Storage::DiskSize]
        attr_accessor :size

        # @return [Y2Storage::DiskSize]
        attr_reader :min_size, :max_size

        def initialize(slots)
          textdomain "storage"
          @slots = slots
          largest_region = @slots.map(&:region).max_by(&:size)
          @size = @max_size = largest_region.size
          @min_size = Y2Storage::DiskSize.new(1)
        end

        # @return [Y2Storage::Region] of the smallest slot
        #   that can contain the chosen size
        def parent_region
          regions = @slots.map(&:region)
          suitable_rs = regions.find_all { |r| r.size >= size }
          suitable_rs.min_by(&:size)
        end

        # @return [Y2Storage::Region] create it in the smallest slot
        #   that can contain the chosen size
        def region
          parent = parent_region
          bsize = parent.block_size
          length = (size.to_i / bsize.to_i.to_f).ceil
          Y2Storage::Region.create(parent.start, length, bsize)
        end

        def label
          _("Size")
        end

        def init
          self.value = size
        end

        def store
          self.size = value
        end

        def validate
          v = value
          if v.nil? || v > max_size
            min_s = min_size.human_ceil
            max_s = max_size.human_floor
            Yast::Popup.Error(
              Yast::Builtins.sformat(
                # error popup, %1 and %2 are replaced by sizes
                _("The size entered is invalid. Enter a size between %1 and %2."),
                min_s, max_s
              )
            )
            # TODO: Let CWM set the focus
            Yast::UI.SetFocus(Id(widget_id))
            false
          else
            true
          end
        end

        # @return [Y2Storage::DiskSize,nil]
        def value
          Y2Storage::DiskSize.from_human_string(super)
        rescue ArgumentError
          nil
        end

        # @param v [Y2Storage::DiskSize]
        def value=(v)
          super(v.human_floor)
        end
      end

      # Specify start+end of the region
      class CustomRegion < CWM::CustomWidget
        def initialize(slots)
          raise ArgumentError if slots.empty?
          textdomain "storage"
          @regions = slots.map(&:region)

          largest_region = @regions.max_by(&:size)
          self.start_block = largest_region.start
          self.end_block = largest_region.end
        end

        attr_accessor :start_block, :end_block

        def contents
          min_block = @regions.map(&:start).min
          # FIXME: libyui widget overflow :-(
          max_block = @regions.map(&:end).max

          int_field = lambda do |id, label, val|
            MinWidth(
              10,
              IntField(Id(id), label, min_block, max_block, val)
            )
          end
          VBox(
            Id(widget_id),
            int_field.call(:start_block, _("Start Block"), start_block),
            int_field.call(:end_block, _("End Block"), end_block)
          )
        end

        def store
          self.start_block = Yast::UI.QueryWidget(Id(:start_block), :Value)
          self.end_block = Yast::UI.QueryWidget(Id(:end_block), :Value)
        end

        def validate
          # starting block must be in a region,
          # ending block must be in the same region
          store
          parent = @regions.find { |r| r.cover?(start_block) }
          return true if parent && parent.cover?(end_block)
          # TODO: a better description why
          # error popup
          Yast::Popup.Error(_("The region entered is invalid."))
          Yast::UI.SetFocus(Id(:start_block))
          false
        end

        def region
          len = end_block - start_block + 1
          bsize = @regions.first.block_size # where does this come from?
          Y2Storage::Region.create(start_block, len, bsize)
        end
      end
    end
  end
end
