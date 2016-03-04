class ObsChgsController < ApplicationController
  def range

    redirect_to :action => :index, :mindiff => params[:mindiff],
        :maxdiff => params[:maxdiff]
  end

  # GET /obs_chgs
  # GET /obs_chgs.xml
  def index

    @conditions = nil
    order = params[:sort]
    unless params[:mindiff].blank? || params[:maxdiff].blank?
      @conditions = ['wattdiff > ? and wattdiff < ?',
                    params[:mindiff], params[:maxdiff] ]
      order = 'ramp' if order.blank?
    end
    @obs_chgs = ObsChg.where(@conditions).order(order).paginate( :page => params[:page])
#      :order => order, :conditions => @conditions

    unless @conditions.nil?
      wattvals=[]
      rampvals=[]
      varvals=[]
      tranvals=[]
      @obs_chgs.each do |oc|
        wattvals.push( oc.wattdiff )
        rampvals.push( oc.ramp )
        varvals.push( oc.vardiff )
        tranvals.push( oc.trancycs )
      end

      @wattmd = Ma.stdev wattvals
      @rampmd = Ma.stdev rampvals
      @varmd = Ma.stdev varvals
      @tranmd = Ma.stdev tranvals
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @obs_chgs }
    end
  end

  def csvout

    @conditions = nil
    unless params[:mindiff].blank? || params[:maxdiff].blank?
      @conditions = ['wattdiff > ? and wattdiff < ?',
                    params[:mindiff], params[:maxdiff] ]
    end
    @obs_chgs = ObsChg.where @conditions

    csvdata = FasterCSV.generate do |line|
      line << ['WattChg', 'Ramp', 'TranCnt', 'Name']
      @obs_chgs.each do |oc|
        line << [oc.wattdiff, (oc.ramp*10).to_i/10.0, oc.trancycs, oc.cname]
      end
    end
    send_data csvdata, :type => :csv, :filename => 'data.csv'
  end


  # GET /obs_chgs/1
  # GET /obs_chgs/1.xml
  def show

    @obs_chg = ObsChg.find(params[:id])

  end

  # GET /obs_chgs/new
  # GET /obs_chgs/new.xml
  def new
byebug
    @obs_chg = ObsChg.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @obs_chg }
    end
  end

  # GET /obs_chgs/1/edit
  def edit
    @obs_chg = ObsChg.find(params[:id])
  end

  # POST /obs_chgs
  # POST /obs_chgs.xml
  def create
    @obs_chg = ObsChg.new(params[:obs_chg])

    respond_to do |format|
      if @obs_chg.save
        flash[:notice] = 'ObsChg was successfully created.'
        format.html { redirect_to(@obs_chg) }
        format.xml  { render :xml => @obs_chg, :status => :created, :location => @obs_chg }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @obs_chg.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /obs_chgs/1
  # PUT /obs_chgs/1.xml
  def update  # only called for new/edit start of run currently
    @obs_chg = ObsChg.find(params[:id])

    chgsig = ChgSig.find params[:obs_chg][:chg_sig]
    sigchg = @obs_chg.chg_sig == chgsig ? false : true
    sigchg = false if chgsig.load_descs.empty?

    if @obs_chg.run_ons.count == 0
      chgsig.load_descs.each do |ld|
        Run.create! :load_desc => ld, :on_chg => @obs_chg,
          :start_time => @obs_chg.pwr_datum.dtime
      end
    elsif sigchg && @obs_chg.run_ons.count == 1 && chgsig.load_descs.count == 1
      r = @obs_chg.run_ons[0]
      r.load_desc = chgsig.load_descs[0]
      r.off_chg = nil  # if there is one
      r.duration = nil # if there was one
      r.save!
    else
      sigchg = false
    end

    if sigchg
      @obs_chg.update_attribute :training, true
      @obs_chg.update_attribute :chg_sig, chgsig
    end

    respond_to do |format|
      if sigchg
        flash[:notice] = 'ObsChg was successfully updated.'
      else
        flash[:notice] = 'No change to signature.'
      end
      format.html { redirect_to(url_for :action => :index,
      :page => (@obs_chg.id - ObsChg.first.id)/ObsChg.per_page + 1 )}
      format.xml  { head :ok }
    end
  end

  def backmatch
    @obs_chg = ObsChg.find(params[:id])

    @candidatesA = ChgSig.endrunchoices @obs_chg
    # array of [distance, run, chgsig]
  end

  def endrun

    run = Run.find( params[:runid] )
    obs_chg = ObsChg.find( params[:id] )

    run.off_chg = obs_chg
    run.duration = obs_chg.pwr_datum.dtime - run.start_time
    run.save!
    obs_chg.chg_sig = ChgSig.find params[:offcsid]
    obs_chg.training = true
    obs_chg.save!
    run.on_chg.update_attribute :training, true
    
    redirect_to( url_for :action => :index, :controller => 'obs_chgs',
         :page => (obs_chg.id - ObsChg.first.id)/ObsChg.per_page + 1)
  end

  # DELETE /obs_chgs/1
  # DELETE /obs_chgs/1.xml
  def destroy
    @obs_chg = ObsChg.find(params[:id])
    @obs_chg.destroy

    respond_to do |format|
      format.html { redirect_to(obs_chgs_url) }
      format.xml  { head :ok }
    end
  end

  def shot

    @obs_chg = ObsChg.find(params[:id])
    @adata = []
    @vdata = []
    @cycnum = []
    precyc = @obs_chg.precycnum
    postcyc = @obs_chg.postcycnum
    (precyc - 1).upto(postcyc) do |cyci|
      next if (cyci > precyc+1) && (cyci < postcyc-1)
      bd = Bdcycle.find_by_cyclenum cyci
      avals, vvals = bd.get_avg_values(64, true)
      @adata.push avals
      @vdata.push vvals if @vdata.empty?
      @cycnum.push cyci
    end
    @lowdistsa = []
    @hidistsa = []
    bd = Bdcycle.find_by_cyclenum precyc-1
    ptperslice = 32
    baseslices = bd.get_fft_slices ptperslice
    cnteach = baseslices[0].count
    precyc.upto(postcyc) do |cyci|
      next if (cyci > precyc+1) && (cyci < postcyc-1)
      bd = Bdcycle.find_by_cyclenum cyci
      currslices = bd.get_fft_slices ptperslice
      numslices = baseslices.count < currslices.count ? baseslices.count : currslices.count
      lowdists = Array.new numslices
      hidists = Array.new numslices
      numslices.times do |i|
        lowdists[i] = Arr.eucdist( baseslices[i].slice(0, 1),
                                   currslices[i].slice(0, 1) )
        hidists[i] = Arr.eucdist( baseslices[i].slice(1,cnteach-1),
                                currslices[i].slice(1,cnteach-1) )
      end
      @lowdistsa.push lowdists
      @hidistsa.push hidists
    end
    newpower = @obs_chg.pwr_datum.watts
    @cycdata = []
    2.times do |leg|
      @cycdata.push @obs_chg.cyc_data.select{|c| c.leg == leg}.collect{|d| d.watts}
    end
  end

  def shof1

    @obs_chg = ObsChg.find(params[:id])
    @adat = []
    @vdat = []
    @gdat = []
    @pdat = []
    bda = []
    bda.push Bdcycle.find_by_cyclenum( @obs_chg.precycnum - 1 )
    bda.push Bdcycle.find_by_cyclenum( @obs_chg.postcycnum + 1 )
    bda.each do |bd|
      a,v = bd.get_values 2  # avg min/max
      @adat.push a
      @vdat.push v
      @gdat.push Arr.div( a, v )
      @pdat.push Arr.mul( a, v, 1.0/25000.0 )
    end
    
  end

  def slicendiff

    si = params[:slice][:which].to_i
    cyci = params[:slice][:cyci].to_i
    precyc = ObsChg.find(params[:obs_chg][:id]).precycnum
    samps = 32
    sbins = samps/2 + 1
    bd = Bdcycle.find_by_cyclenum precyc-1
    b = bd.get_fft_slices(samps)[si]
    samplefreq=bd.samplecount*120
    @hertzper=(samplefreq/2)/(b.count - 1)  # up to half sampling frequency
    bhibins = b.slice(1, sbins-1)
    c = Bdcycle.find_by_cyclenum(cyci).get_fft_slices(samps)[si]
    chibins = c.slice(1, sbins-1)
    # data for spectra chart
    @sdataA=[];@snamesA=[];@coptsvarnameA=[]
    @sdataA.push  [bhibins, chibins]
    @snamesA.push  ['Pre1', "#{cyci}:#{si}"]
    @coptsvarnameA.push  'slicechartopts'
    # data for spectra diffs
    @sdataA.push [Arr.diff( bhibins, chibins )] # just one series
    @snamesA.push ["#{cyci}:#{si} diff"]
    @coptsvarnameA.push 'diffslicechartopts'

    render( :layout => false )
  end

  def wattvar
    @allwattvars=ObsChg.limit(400).collect{|o| [o.wattdiff, o.vardiff]}
    @onwattvars=@allwattvars.select{|w,v| w > 0}
    offwattvars=@allwattvars.reject{|w,v| w > 0}
    @invoffwattvars = offwattvars.collect{|w,v| [-w, -v]}
  end
end
