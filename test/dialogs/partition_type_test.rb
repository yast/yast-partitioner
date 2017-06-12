require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/dialogs/partition_type"

# FIXME: remove these once they are in cwm/rspec
# (a duplicate definition does work)
RSpec.shared_examples "CWM::Dialog" do
  describe "#contents" do
    it "produces a Term" do
      expect(subject.contents).to be_a Yast::Term
    end
  end

  describe "#title" do
    it "produces a String or nil" do
      expect(subject.title).to be_a(String).or be_nil
    end
  end
end

RSpec.shared_examples "CWM::RadioButtons" do
  include_examples "CWM::AbstractWidget"
  include_examples "CWM::ItemsSelection"
end

describe Y2Partitioner::Dialogs::PartitionType do
  let(:disk) { double("Disk", name: "mydisk") }
  let(:ptemplate) { double("partition template") }
  let(:slots) { [] }

  subject { described_class.new(disk, ptemplate, slots) }
  before do
    allow(Y2Partitioner::Dialogs::PartitionType::TypeChoice)
      .to receive(:new).and_return(term(:Empty))
  end
  include_examples "CWM::Dialog"
end

describe Y2Partitioner::Dialogs::PartitionType::TypeChoice do
  let(:ptemplate) { double("partition template") }
  let(:slots) { [double("Slot", :"possible?" => true)] }

  subject { described_class.new(ptemplate, slots) }

  include_examples "CWM::RadioButtons"
end
