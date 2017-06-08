require_relative "../test_helper"

# require "cwm/rspec"
require "y2partitioner/widgets/overview"

describe Y2Partitioner::Widgets::OverviewTree do
  let(:device_graph) do
    double("Device Graph",
      disks: [], lvm_vgs: [])
  end
  subject { described_class.new(device_graph) }

  # TODO: shared_examples for CWM::Tree?
  # include_examples "CWM::CustomWidget"
end
