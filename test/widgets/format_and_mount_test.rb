require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/format_and_mount"

describe Y2Partitioner::Widgets::FormatOptions do
  let(:blk_device) do
    double("Block Device", filesystem_type: "Ext9")
  end
  subject { described_class.new(blk_device) }

  include_examples "CWM::CustomWidget"
end

describe Y2Partitioner::Widgets::MountOptions do
  let(:blk_device) do
    double("Block Device", filesystem_mountpoint: "/foo", filesystem: nil)
  end
  subject { described_class.new(blk_device) }

  include_examples "CWM::CustomWidget"
end

describe Y2Partitioner::Widgets::FstabOptionsButton do
  subject { described_class.new("some options") }
  include_examples "CWM::PushButton"

  describe "#layout" do
    it "produces a Term" do
      expect(subject.layout).to be_a Yast::Term
    end
  end
end
