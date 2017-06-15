require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/dialogs/partition_size"

describe "Partition Size widgets" do
  let(:disk) do
    double("Disk",
      name:   "mydisk",
      region: region)
  end
  let(:ptemplate) { double("partition template") }
  let(:slots) { [double("Slot", region: region)] }
  let(:region) do
    double("Region",
      block_size: Y2Storage::DiskSize.new(1000),
      cover?:     true,
      last:       2999,
      length:     1000,
      size:       Y2Storage::DiskSize.new(1_000_000),
      start:      2000)
  end

  describe Y2Partitioner::Dialogs::PartitionSize do
    subject { described_class.new(disk, ptemplate, slots) }

    before do
      allow(Y2Partitioner::Dialogs::PartitionSize::SizeWidget)
        .to receive(:new).and_return(term(:Empty))
    end
    include_examples "CWM::Dialog"
  end

  describe Y2Partitioner::Dialogs::PartitionSize::SizeWidget do
    subject { described_class.new(disk, ptemplate, slots) }

    include_examples "CWM::CustomWidget"
  end

  describe Y2Partitioner::Dialogs::PartitionSize::CustomSizeInput do
    subject { described_class.new(slots) }

    before do
      allow(subject).to receive(:value).and_return nil
    end

    # include_examples "CWM::InputField"
    include_examples "CWM::AbstractWidget"

    describe "#region" do
      it "returns a Region" do
        expect(subject.region).to be_a Y2Storage::Region
      end
    end

    describe "#validate" do
      before do
        allow(subject).to receive(:value)
          .and_return Y2Storage::DiskSize.new(2_000_000)
      end

      it "pops up an error when the size is too big" do
        expect(Yast::Popup).to receive(:Error)
        expect(Yast::UI).to receive(:SetFocus)
        expect(subject.validate).to eq false
      end
    end
  end

  describe Y2Partitioner::Dialogs::PartitionSize::CustomRegion do
    subject { described_class.new(slots) }

    include_examples "CWM::CustomWidget"

    describe "#region" do
      it "returns a Region" do
        expect(subject.region).to be_a Y2Storage::Region
      end
    end
  end
end
