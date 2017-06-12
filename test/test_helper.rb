ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)
# Find cwm/rspec
$LOAD_PATH << File.expand_path("..", __FILE__)

require "yast"
require "yast/rspec"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  src_location = File.expand_path("../../src", __FILE__)
  # track all ruby files under src
  SimpleCov.track_files("#{src_location}/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

require "y2storage"
require "y2partitioner/device_graphs"

def devicegraph_stub(name)
  path = File.join(File.dirname(__FILE__), "data", name)
  storage = Y2Storage::StorageManager.fake_from_yaml(path)
  storage.probed.copy(storage.staging)

  dgs = Y2Partitioner::DeviceGraphs.instance
  dgs.current = storage.staging
  dgs.original = storage.probed

  storage
end
