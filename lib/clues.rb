class Clues

  attr :binsizes, true
  attr_accessor :scalefactor
  attr_reader :binhash
  attr_reader :dimsmm
  attr_reader :populatedbins
  attr_reader :mdihash
  attr_reader :mdirad

  def initialize( bs = [1,1] )
    self.binsizes = bs
    @scalefactor = 6.0
  end

  def binsizes=( bs )
    @binsizes = bs
    @binsizes.count.times{|i| @binsizes[i] = @binsizes[i].to_i}
    @binhash = Hash.new
#    @bintups =nil
    @dimsmm = Array.new( dims )
    @populatedbins = 0
    @mdirad = nil
    @mdihash = Tuphash.new
  end

  def dims
    @binsizes.count
  end

  def gbinlow
    x = Array.new dims
    dims.times do |d|
      x[d] = (dimsmm[d][0]/@binsizes[d]).floor*@binsizes[d]
    end
    return x
  end

  def gbinhi
    x = Array.new dims
    dims.times do |d|
      x[d] = (dimsmm[d][1]/@binsizes[d]).floor*@binsizes[d]
    end
    return x
  end

  def dhashcurse( ahash, tup, curdim = 0 )

    binval = (tup[curdim]/@binsizes[curdim]).floor*@binsizes[curdim]
    if curdim == (dims - 1)
      unless ahash.has_key?( binval )
        ahash[ binval ] = Array.new
        @populatedbins += 1
      end
      ahash[ binval ].push tup
      return
    end

    ahash[ binval ] = Hash.new unless ahash.has_key?( binval )
    dhashcurse( ahash[ binval ], tup, curdim + 1 )      
  end

  def tups2bins( tuplesarr )
    raise "inconsistent dimensions" unless tuplesarr[0].count == dims

    dims.times do |dim|
      if @dimsmm[dim].nil?
        min = max = tuplesarr[0][dim]
      else
        min = @dimsmm[dim][0]
        max = @dimsmm[dim][1]
      end
      1.upto( tuplesarr.count - 1) do |i|
        v =  tuplesarr[i][dim]
        min = v if v < min
        max = v if v > max
      end
      @dimsmm[dim] = [min, max]
    end

    tuplesarr.each do |tup|
      dhashcurse( @binhash, tup )
    end

    nil
  end

  def tupcurse( ahash, granges, dim = 0 )
=begin
  chase down all of the tuples within the grid boxes described
  by the granges
=end
    retups = []
    if dim == (dims - 1)  # at max recurse
      granges[dim].step(@binsizes[dim]) do |gv|
        retups += ahash[gv] if ahash.has_key? gv
      end
      return retups
    end

    granges[dim].step(@binsizes[dim]) do |gv|
      if ahash.has_key? gv
        retups += tupcurse( ahash[gv], granges, dim + 1 )
      end
    end
    return retups
  end

  def incubes( tup, valranges, dim = 0 )
    if dim == (dims - 1)
      return valranges[dim] === tup[dim]
    end
    return false unless valranges[dim] === tup[dim]

    incubes( tup, valranges, dim + 1 )
  end

  def bboxtups( center, gridistance = 0 )
=begin
  gridistance of one is the binsize for a given dimension
  for the given center point and griddistance, work out the 
  grid box ranges, then accumlate all of the tuples in those boxes.
  using floor is important
  we could do the inranges test as part of tupcurse, but that would
  mean passing in both the grid and valranges, and doing them separately
  allows different selection methods to be called.  not very convincing, but
  not worth changing.
  a grid box is identified by the lowest value in each dimension, so a
  2 d box of [0,0] has all of its members from 0 to binsizes[dim] for
  a given dimension.  passing a grid distance of zero is a special case which
  just returns the members of the hypercube.  this allows the results of
  bintups, which returns the "lower left hand" coordinates for a given cube,
  to be used to get all of the elements in a cube.
=end
    gridranges = Array.new dims
    boxranges = Array.new dims
    dims.times do |i|
      low = center[i] - (gridistance*binsizes[i])
      lowg = (low/binsizes[i]).floor*binsizes[i]
      hi = center[i] + (gridistance*binsizes[i])
      hig = (hi/binsizes[i]).floor*binsizes[i]
      gridranges[i] = lowg..hig  # includes hi
      boxranges[i] = low..hi  # includes hi
    end

    posstups = tupcurse( @binhash, gridranges )

    return posstups if gridistance == 0
    # now collect just the tuples that satisfy all of the conditions
    posstups.select{ |tup| incubes( tup, boxranges ) }
  end

  def inballs( center, radius, tup )
    radsqsum = 0.0
    dims.times do |i|
      d = (center[i] - tup[i]).to_f/@binsizes[i].to_f
      radsqsum += d*d
    end
    Math.sqrt( radsqsum ) <= radius ? true : false
  end

  def balltups( center, radius )
    gridranges = Array.new dims
    dims.times do |i|
      low = center[i] - (radius*binsizes[i])
      lowg = (low/binsizes[i]).floor*binsizes[i]
      hi = center[i] + (radius*binsizes[i])
      hig = (hi/binsizes[i]).floor*binsizes[i]
      gridranges[i] = lowg...hig
    end

    posstups = tupcurse( @binhash, gridranges )

    # now collect just the tuples that satisfy all of the conditions
    posstups.select{ |tup| inballs( center, radius, tup ) }
  end

  def rbintups( ahash = @binhash, dim = 0, ptup = [] )

    ptups = []
    if dim == (dims - 1)
      ahash.keys.sort.each do |kfin|
        ptups.push ptup + [kfin]
      end
      return ptups
    end
    ahash.keys.sort.each do |kthis|
      rbintups(ahash[kthis], dim+1, ptup + [kthis]).each do |ares|
        ptups.push ares
      end
    end
    return ptups
  end

  def bintups
#    return @bintups unless @bintups.nil?
#    @bintups = rbintups
    rbintups
  end

  def mdinertia( center, dist = 0, hyballs = false )
    ccent = center
    maxdelta = dist.to_f
    if dist == 0
      center.count.times do |i|
        maxdelta = 0.5
        ccent[i] = center[i] + @binsizes[i]*0.5
      end
    end
    tups = hyballs ? balltups( center, dist ) : bboxtups( center, dist )
    zzzs = [0,0,0]
    if tups.blank?
      return [ 0,0,0, [zzzs, zzzs, zzzs ] ]  # fix for dims
    end
    minertiasum = 0.0
    tups.each do |tup|
      dims.times do |dim|
        gdist = (ccent[dim] - tup[dim])/@binsizes[dim].to_f
        onedist = gdist/maxdelta
        aweight = onedist*onedist*scalefactor.to_f + 0.1

        minertiasum += aweight
      end
    end
    meandevs = Array.new dims
    dims.times do |dim|
      md = Ma.stdev( tups.collect{|t| t[dim]} )
      unless md[0].nil?
        2.times{|i| md[i] = (100.0*md[i]).to_i/100.0}
      else
        md = zzzs
      end
      meandevs[dim] = md
    end
    n = tups.count * dims
    d = (100.0*n/minertiasum).to_i/100.0
    return [ d, n*d, tups.count, meandevs ]
  end

  def dumbdobinmdi( granges, tup = [], dim = 0 )
    if dim == (dims - 1)  # at max recurse
      granges[dim].step(@binsizes[dim]) do |dv|
        t = Array.new(tup).push dv
next
        mdi = mdinertia( t, @mdirad, true )  # balls
        next if mdi.empty?  # nada
        @mdihash.store t, mdi
      end
      return nil
    end

    granges[dim].step( @binsizes[dim] ) do |dv|
      t = Array.new( tup ).push dv
      dumbdobinmdi( granges, t, dim + 1 )
    end
    nil
  end

  def dumbstorebinmdi( hyperrad )
    gmins = gbinlow
    gmaxs = gbinhi
    granges = Array.new dims
    dims.times do |dim|
      x = binsizes[dim]*(hyperrad.ceil)
      granges[dim] = (gmins[dim] - x)..(gmaxs[dim] + x)
    end
    @mdirad = hyperrad
    @mdihash = Tuphash.new
debugger
    dobinmdi( granges )
  end

  def prtup( tup )
    tup.count.times do |d|
      print tup[d]
      if (d + 1) == tup.count
        puts
      else
        print ", "
      end
    end
  end

  def cursebinplus( tups = bintups, dim = 0 )
=begin
 still not right - need to fabricate tups for those we don't
 have, right?  recursively?  going to repeat a lot?
=end
    uvals = tups.collect{|t| t[dim]}.uniq  # this dim's values that exist
    findim = dim == (dims - 1)  # final dimension?
    bindelta = (@mdirad.ceil)*binsizes[dim]

    uvals.each do |cval|
      ctups = tups.select{|t| t[dim] == cval}
      stups = Array.new ctups
      mr = (cval - bindelta)..(cval + bindelta)  # range to generate
      # generate tups for neighbors in this dimension
      mr.step(@binsizes[dim]) do |dval|  # delta val
        next if dval == cval
        ctups.each do |tup|
          dtup = Array.new tup
          dtup[dim] = dval  # replacing cval
          stups.push dtup
        end
      end
      if findim
        stups.each do |stup|
          next unless @mdihash.find( stup ).nil?
          @mdihash.store stup, mdinertia( stup, @mdirad )
#          prtup stup
        end
      else
        cursebinplus( stups, dim + 1 )
      end
    end
    nil
  end

  def genbinmdiplus( hyperrad )  # bintups plus neighboring cubes

    @mdihash = Tuphash.new
    @mdirad = hyperrad
    cursebinplus
  end

  def neighfind( ahash, granges, dim = 0 )
=begin
  return all of the neighboring bintups that exist
=end

    if dim == (dims - 1)  # at max recurse
      exists = []
      granges[dim].step(@binsizes[dim]) do |gv|
        if ahash.has_key?( gv ) # && gv != cbintup[dim]
          exists.push [ gv ]
        end
      end
      return exists
    end

    tups = []
    granges[dim].step(@binsizes[dim]) do |gv|
      if ahash.has_key?( gv ) # && gv != cbintup[dim]
        partups = neighfind( ahash[gv], granges, dim + 1 )
        next if partups.empty?
        partups = partups.collect{|t| t.insert 0, gv}  #  insert us
        tups += partups
      end
    end
    return tups
  end

  def neighbortups( cbintup, span = 1 ) # center bintup
    granges = Array.new dims
    dims.times do |i|
      s = (span.to_i)*@binsizes[i]
      granges[i] = (cbintup[i] - s)..(cbintup[i] + s)
    end

    neighfind( @binhash, granges )
  end

  def biggest( cbintup )

    nbors = neighbortups cbintup
    maxt = nil
    maxmdi = 0.0
    nbors.each do |nbor|
      nmdi = @mdihash.find nbor
      next if nmdi.empty?
      nval = nmdi[1] # inverse md
      if nval > maxmdi
        maxmdi = nval
        maxt = nbor
      end
    end
    maxt
  end

  def newt( mdresult )
    [mdresult[3][0][0], mdresult[3][1][0], mdresult[3][2][0]]
  rescue Exception => e  # really $!
    puts e
debugger
  end

  def convergemdi( startup, rad = @mdirad )
    lastup = startup
    lastres = nil
    10.times do |i|
      lastres = mdinertia( lastup, rad, true )
      nextup = newt( lastres )
      break if nextup[0].nil?
      break if nextup == lastup
      lastup = newt( lastres )
    end
    lastres
  end
end
