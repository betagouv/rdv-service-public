module Montrose
  class Recurrence
    # https://github.com/rossta/montrose/issues/113
    def as_json
      to_hash.as_json
    end
  end
end
