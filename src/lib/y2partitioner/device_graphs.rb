require "singleton"

module Y2Partitioner
  # Object that holds and manipulates of storage device graphs.
  class DeviceGraphs
    include Singleton

    attr_accessor :current
    attr_accessor :original

    # Run a block with a **duplicate** of @dg.
    # If the block returns a truthy value,
    # the new dg is copied to the old one
    # (which is useful if the orig one was the `current` one)
    # otherwise (also for an exception) @dg points to the old one.
    # @yieldreturn [Boolean]
    # @return What the block returned
    def transaction(&block)
      old_dg = current.dup
      begin
        res = block.call

        self.current = old_dg if !res
      rescue
        self.current = old_dg
        raise
      end

      res
    end
  end
end
