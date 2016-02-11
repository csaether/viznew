class ChgSigsController < ApplicationController
  # GET /chg_sigs
  # GET /chg_sigs.xml
  def index
    @chg_sigs = (ChgSig.all).sort{|a,b| a.wattchg.abs <=> b.wattchg.abs}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @chg_sigs }
    end
  end

  # GET /chg_sigs/1
  # GET /chg_sigs/1.xml
  def show
    @chg_sig = ChgSig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @chg_sig }
    end
  end

  # GET /chg_sigs/new
  # GET /chg_sigs/new.xml
  def new
    @chg_sig = ChgSig.new
    @loads = LoadDesc.find :all

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @chg_sig }
    end
  end

  # GET /chg_sigs/1/edit
  def edit
    @chg_sig = ChgSig.find(params[:id])
    @loads = LoadDesc.find :all
=begin
    onwattvals=[]
    offwattvals=[]
    onrampvals=[]
    ontranvals=[]
    offtranvals=[]
    oca = @chg_sig.obs_chgs.find_all_by_training true
    oca = @chg_sig.obs_chgs.find(:all) if oca.empty?
    oca.each do |oc|
      if oc.wattdiff > 0
        onwattvals.push oc.wattdiff
        onrampvals.push oc.ramp
        ontranvals.push oc.trancycs
      else
        offwattvals.push oc.wattdiff
        offtranvals.push oc.trancycs
      end
    end
    @onwattmd = Ma.stdev onwattvals
    @offwattmd = Ma.stdev offwattvals
    @onrampmd = Ma.stdev onrampvals
    @ontranmd = Ma.stdev ontranvals
    @offtranmd = Ma.stdev offtranvals
=end
  end

  # POST /chg_sigs
  # POST /chg_sigs.xml
  def create

    @chg_sig = ChgSig.new(params[:chg_sig])
    @loads = LoadDesc.find :all

    respond_to do |format|
      if @chg_sig.save
        flash[:notice] = 'ChgSig was successfully created.'
        format.html { redirect_to(@chg_sig) }
        format.xml  { render :xml => @chg_sig, :status => :created, :location => @chg_sig }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @chg_sig.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /chg_sigs/1
  # PUT /chg_sigs/1.xml
  def update
    @chg_sig = ChgSig.find(params[:id])

    respond_to do |format|
      if @chg_sig.update_attributes(params[:chg_sig])
        flash[:notice] = 'ChgSig was successfully updated.'
        format.html { redirect_to chg_sigs_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @chg_sig.errors, :status => :unprocessable_entity }
      end
    end
  end

  def resetruns
    chg_sig = ChgSig.find(params[:id])
    chg_sig.resetRuns

    redirect_to chg_sigs_path
  end

  # DELETE /chg_sigs/1
  # DELETE /chg_sigs/1.xml
  def destroy
    @chg_sig = ChgSig.find(params[:id])
    @chg_sig.destroy

    respond_to do |format|
      format.html { redirect_to(chg_sigs_url) }
      format.xml  { head :ok }
    end
  end
end
