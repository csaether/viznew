class Tuphash

  attr_reader :thash

  def initialize
    @thash = Hash.new
    @keycount = 0
  end

  def store( tup, value, ahash = @thash, curdim = 0 )
    dimkey = tup[curdim]
    if curdim == (tup.count - 1)
      unless ahash.has_key?( dimkey )
        @keycount += 1
      end
      ahash[ dimkey ] = value
      return
    end

    ahash[ dimkey ] = Hash.new unless ahash.has_key?( dimkey )
    store( tup, value, ahash[ dimkey ], curdim + 1 )
  end

  def find( tup, ahash = @thash, curdim = 0 )
    dimkey = tup[curdim]
    if curdim == (tup.count - 1)
      return ahash[ dimkey ]
    end
    return nil unless ahash.has_key?( dimkey )
    find( tup, ahash[ dimkey ], curdim + 1 )
  end
end
