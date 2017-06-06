require "yast"
require "cwm/dialog"
require "ui/greasemonkey"

module Y2Partitioner
  module Dialogs
    # Formerly MiniWorkflowStepPartitionSize
    class PartitionSize < CWM::Dialog
      include Yast
      include Yast::UIShortcuts

      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      def title
        # dialog title
        Yast::Builtins.sformat(_("Add Partition on %1"), @disk.name)
      end

      def contents
        max_size_k = 1234
        cyl_count = 666

        contents = HVSquash(
          # frame heading
          term(
            :FrameWithMarginBox,
            _("New Partition Size"),
            RadioButtonGroup(
              Id(:size),
              VBox(
                term(
                  :LeftRadioButton,
                  Id(:max_size),
                  Opt(:notify),
                  # radio button text, %1 is replaced by size
                  Builtins.sformat(
                    _("Maximum Size (%1)"),
                    # Storage.KByteToHumanString(max_size_k)
                    max_size_k
                  )
                ),
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
                ),
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
                        Id(:start_cyl),
                        _("Start Cylinder"),
                        0,
                        cyl_count,
                        # Region.Start(region)
                        111
                      )
                    ),
                    MinWidth(
                      10,
                      IntField(
                        Id(:end_cyl),
                        _("End Cylinder"),
                        0,
                        cyl_count,
                        # Region.End(region)
                        222
                      )
                    )
                  )
                )
              )
            )
          )
        )
        ::UI::Greasemonkey.transform(contents)
      end
    end
  end
end
