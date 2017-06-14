require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/dialogs/partition_size"

describe Y2Partitioner::Dialogs::PartitionSize do
  let(:disk) { double("Disk", name: "mydisk") }
  let(:ptemplate) { double("partition template") }
  let(:slots) { [] }

  subject { described_class.new(disk, ptemplate, slots) }
  before do
    allow(Y2Partitioner::Dialogs::PartitionSize::SizeWidget)
      .to receive(:new).and_return(term(:Empty))
  end
  include_examples "CWM::Dialog"
end

describe Y2Partitioner::Dialogs::PartitionSize::SizeWidget do
  let(:disk) do
    double("Disk",
      name:   "mydisk",
      region: region)
  end
  let(:ptemplate) { double("partition template") }
  let(:slots) { [double("Slot", region: region)] }
  let(:region) do
    double("Region",
      block_size: Y2Storage::DiskSize.new(10),
      start:      5,
      length:     20)
  end

  subject { described_class.new(disk, ptemplate, slots) }

  include_examples "CWM::CustomWidget"
end
