require_relative "../test_helper"

require "y2partitioner/clients/main"

describe Y2Partitioner::Clients::Main do
  subject { described_class }

  describe ".run" do
    before do
      allow(Yast::Wizard).to receive(:OpenDialog)
      allow(Yast::Wizard).to receive(:CloseDialog)
      allow(Yast::CWM).to receive(:show)
      allow(Yast::Stage).to receive(:initial).and_return(false)
    end

    it "opens wizard outside of initial stage" do
      expect(Yast::Wizard).to receive(:OpenDialog)
      allow(Yast::Stage).to receive(:initial).and_return(false)

      subject.run

      expect(Yast::Wizard).to_not receive(:OpenDialog)
      allow(Yast::Stage).to receive(:initial).and_return(true)

      subject.run
    end
  end
end
