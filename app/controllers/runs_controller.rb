class RunsController < ApplicationController
  # GET /runs
  # GET /runs.xml
  def index

    @which = 'All'
    @conditions = nil
    unless params[:load_desc_id].blank?
      @conditions = ['load_desc_id = ?', params[:load_desc_id] ]
      @which = LoadDesc.find(params[:load_desc_id]).name
    end
    @runs = Run.where(@conditions).order(:start_time).paginate :page => params[:page]

    unless @conditions.nil?
      onwattvals=[]
      offwattvals=[]
      onrampvals=[]
      ontrans=[]
      offtrans=[]
      durvals=[]
      @runs.each do |r|
        onwattvals.push(r.load_desc.wattdiff_part( r.on_chg )) if r.on_chg
        onrampvals.push( r.on_chg.ramp )
        ontrans.push( r.on_chg.trancycs )
        if r.off_chg
          offwattvals.push(r.load_desc.wattdiff_part( r.off_chg ))
          offtrans.push( r.off_chg.trancycs )
          durvals.push( r.duration )
        end
      end

      @onwattmd = Ma.stdev onwattvals
      @offwattmd = Ma.stdev offwattvals
      @onrampmd = Ma.stdev onrampvals
      @ontranmd = Ma.stdev ontrans
      @offtranmd = Ma.stdev offtrans
      @durmd = Ma.stdev durvals
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @runs }
    end
  end

  # GET /runs/1
  # GET /runs/1.xml
  def show
    @run = Run.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @run }
    end
  end

  # GET /runs/1/fwdmatch


  def fwdmatch

    @run = Run.find(params[:id])
#    @run.bestoffs
    offcans = @run.arr_ag.arr

    @candidatesA = Array.new( offcans.count )
    offcans.count.times do |i|
      oc = ObsChg.find offcans[i][1]
      cs = ChgSig.find offcans[i][2]
      @candidatesA[i] = [ offcans[i][0], oc, cs ]
    end

    unless params[:ocid].nil?

      @aoc = ObsChg.find params[:ocid]
      @atime = @aoc.pwr_datum.dtime  # around this time
      @pwrdata = PwrDatum.where('dtime > ? and dtime < ?', @atime - 300, @atime + 300)
    end
  end

  def fwdmatch_v0

    @run = Run.find(params[:id])
    oc = @run.on_chg

    pd = oc.pwr_datum
    ontime = pd.dtime
    loadruns = @run.load_desc.runs.sort{|a,b| a.start_time <=> b.start_time }
    @nxtrun = loadruns.detect{|r| r.start_time > ontime }
    if @nxtrun
      @hipd = @nxtrun.on_chg.pwr_datum
    else
      @hipd = PwrDatum.where('dtime > ?', ontime + 5*60*60).first # 5 hrs
      @hipd = PwrDatum.last unless @hipd
    end

    csa = @run.load_desc.chg_sigs
    doca = []
    csa.each do |cs|

      cslow = cs.off_watts - 2*cs.off_watts_sdev
      cshi = cs.off_watts + 2*cs.off_watts_sdev
      low = params[:low]
      high = params[:high]
      low = cslow if low.blank?
      high = cshi if high.blank?
      low = cslow if low.nil?
      high = cshi if high.nil?


      ocac = ObsChg.where('pwr_datum_id > ? AND pwr_datum_id < ? AND wattdiff <= ? AND wattdiff >= ?',
         pd, @hipd, high, low).limit(20)
      ocac.each do |oc|
        doca.push [cs.distance(oc), oc, cs]
      end
    end
    @candidatesA = doca.sort{|a,b| a[0] <=> b[0]}

    unless params[:ocid].nil?

      @aoc = ObsChg.find params[:ocid]
      @atime = @aoc.pwr_datum.dtime  # around this time
      @pwrdata = PwrDatum.where('dtime > ? and dtime < ?', @atime - 300, @atime + 300)
    end
  end

  def close
    Run.endruns params[:load_desc_id]

    redirect_to :action => 'index', :load_desc_id => params[:load_desc_id]
  end

  def range

    redirect_to :action => :fwdmatch, :low => params[:low],
       :high => params[:high], :id => params[:id]
  end

  # GET /runs/new
  # GET /runs/new.xml
  def new
    @run = Run.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @run }
    end
  end

  # GET /runs/1/edit
  def edit
    @run = Run.find(params[:id])
  end

  def add_chg

    run = Run.find( params[:id] )
    obs_chg = ObsChg.find( params[:offocid] ) unless params[:offocid].nil?
    unless obs_chg.nil?
      run.off_chg = obs_chg
      run.duration = obs_chg.pwr_datum.dtime - run.start_time
      run.save!
      run.on_chg.update_attribute :training, true
      obs_chg.chg_sig = ChgSig.find params[:offcsid]
      obs_chg.training = true
      obs_chg.save!
    end
    
    redirect_to( url_for :action => :index, :controller => 'obs_chgs',
         :page => (obs_chg.id - ObsChg.first.id)/ObsChg.per_page + 1)
  end

  # POST /runs
  # POST /runs.xml
  def create
    @run = Run.new(params[:run])

    respond_to do |format|
      if @run.save
        flash[:notice] = 'Run was successfully created.'
        format.html { redirect_to(@run) }
        format.xml  { render :xml => @run, :status => :created, :location => @run }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /runs/1
  # PUT /runs/1.xml
  def update
    @run = Run.find(params[:id])
byebug
    respond_to do |format|
      if @run.update_attributes(params[:run])
        flash[:notice] = 'Run was successfully updated.'
        format.html { redirect_to(@run) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /runs/1
  # DELETE /runs/1.xml
  def destroy
    @run = Run.find(params[:id])
    @run.destroy

    respond_to do |format|
      format.html { redirect_to(runs_url) }
      format.xml  { head :ok }
    end
  end
end
