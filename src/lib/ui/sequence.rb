require "yast"
Yast.import "Sequencer"

# FIXME: once the API is reviewed, move this to yast-yast2
module UI
  # A {UI::Sequence} is an object-oriented interface for the good old
  # {Yast::SequencerClass Yast::Sequencer}.
  # In the simple case it runs a sequence of dialogs
  # connected by Back and Next buttons.
  class Sequence
    # A drop-in replacement for
    # {Yast::SequencerClass#Run Yast::Sequencer.Run}
    # but smarter:
    # - TODO: auto :abort (see {#abortable})
    # - TODO: lambdas (see {#from_methods})
    # - TODO: be explicit about who opens the dialogs
    #
    # @param aliases
    # @param sequence
    def self.run(aliases, sequence)
      Yast::Sequencer.Run(aliases, sequence)
    end

    # Add {:abort => :abort} transitions if missing
    # (an :abort from a dialog should :abort the whole sequence)
    def abortable(sequence_hash)
      # TODO: implement this, see also MiniWorkflow
      sequence_hash
    end

    # Make `aliases` from `sequence_hash` assuming there is a method
    # for each alias.
    # @return [Hash{id => Proc}] aliases
    def from_methods(sequence_hash)
      sequence_hash.keys.map do |name|
        next nil if name == "ws_start"
        [name, method(name)]
      end.compact.to_h
    end
  end
end
