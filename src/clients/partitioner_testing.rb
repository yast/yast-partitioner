# TODO: just temporary client for testing partitioner with different hardware setup
# call with `yast2 partitioner_testing <path_to_yaml>`

require "yast"
require "y2partitioner/clients/main"
require "y2storage"

# fake sysfs_name method as loading it from yaml is not supported and for xml
# I did not find complex enough examples

module Y2Storage
  # just reopening for faking up sysfs_name
  # not production code, only for testing
  class BlkDevice < Device
    # @return [String] "sda2" or "dm-1"
    def sysfs_name
      name.split("/").last
    end
  end
end

arg = Yast::WFM.Args.first
case arg
when /.ya?ml$/
  Y2Storage::StorageManager.fake_from_yaml(arg)
when /.xml$/
  # note: support only xml device graph, not xml output of probing commands
  Y2Storage::StorageManager.fake_from_xml(arg)
else
  raise "Invalid testing parameter #{arg}, expecting foo.yml or foo.xml."
end
Y2Partitioner::Clients::Main.run(allow_commit: false)
