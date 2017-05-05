# TODO: just temporary client for testing partitioner with different hardware setup
# call with `yast2 partitioner_testing <path_to_yaml>`

require "yast"
require "y2partitioner/clients/main"
require "y2storage"

arg = Yast::WFM.Args.first
storage = Y2Storage::StorageManager.fake_from_yaml(arg)
storage.probed.copy(storage.staging)
Y2Partitioner::Clients::Main.run
