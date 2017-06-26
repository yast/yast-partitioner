require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/overview"

describe Y2Partitioner::Widgets::OverviewTreePager do
  subject { described_class.new(Y2Storage::StorageManager.instance.y2storage_staging) }

  include_examples "CWM::Pager"
end
