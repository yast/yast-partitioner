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
    # (which is useful if the orig one was the `staging` one)
    # otherwise (also for an exception) @dg points to the old one.
    # @yieldreturn [Boolean]
    # @return What the block returned
    def transaction(&block)
      old_dg = current
      self.class.functional_transaction(old_dg) do |new_dg|
        begin
          self.current = new_dg
          res = block.call
          self.current = old_dg if !res
          res
        rescue
          self.current = old_dg
          raise
        end
      end
    end

    # Run a block with a **duplicate** of *old_dg*.
    # If the block returns a truthy value,
    # new_dg is **copy**ed to old_dg.
    # @param old_dg [Devicegraph]
    # @yieldparam new_dg, [Devicegraph]
    # @yieldreturn [Boolean]
    # @return What the block returned
    def self.functional_transaction(old_dg, &block)
      new_dg = old_dg.duplicate
      accepted = block.call(new_dg)
      new_dg.copy(old_dg) if accepted
      accepted
    end
  end
end
