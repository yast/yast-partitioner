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
    def sysfs_name
      name.split("/").last
    end
  end
end

arg = Yast::WFM.Args.first
storage = Y2Storage::StorageManager.fake_from_yaml(arg)
storage.probed.copy(storage.staging)
Y2Partitioner::Clients::Main.run
