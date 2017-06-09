module Y2Partitioner
  class DevicegraphMutator
    def initialize(original_device_graph, device_graph)
      @original_graph = original_device_graph
      @dg = device_graph
    end

    attr_reader :dg
    attr_reader :original_graph

    # Run a block with a **duplicate** of @dg.
    # If the block returns a truthy value,
    # the new dg is copied to the old one
    # (which is useful if the orig one was the `staging` one)
    # otherwise (also for an exception) @dg points to the old one.
    # @yieldreturn [Boolean]
    # @return What the block returned
    def transaction(&block)
      old_dg = @dg
      self.class.functional_transaction(old_dg) do |new_dg|
        begin
          @dg = new_dg
          res = block.call
          @dg = old_dg if !res
          res
        rescue
          @dg = old_dg
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
