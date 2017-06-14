require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/overview"

describe Y2Partitioner::Widgets::OverviewTreePager do
  let(:device_graph) do
    double("Device Graph",
      disks: [], lvm_vgs: [])
  end
  subject { described_class.new(device_graph) }

  include_examples "CWM::Pager"
end
