class PwrDataController < ApplicationController
  # GET /pwr_data
  # GET /pwr_data.xml
  def index
    @pwr_data = PwrDatum.paginate :page => params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pwr_data }
    end
  end

  # GET /pwr_data/1
  # GET /pwr_data/1.xml
  def show
    @pwr_datum = PwrDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pwr_datum }
    end
  end

  # GET /pwr_data/new
  # GET /pwr_data/new.xml
  def new
    @pwr_datum = PwrDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pwr_datum }
    end
  end

  # GET /pwr_data/1/edit
  def edit
    @pwr_datum = PwrDatum.find(params[:id])
  end

  # POST /pwr_data
  # POST /pwr_data.xml
  def create
    @pwr_datum = PwrDatum.new(params[:pwr_datum])

    respond_to do |format|
      if @pwr_datum.save
        flash[:notice] = 'PwrDatum was successfully created.'
        format.html { redirect_to(@pwr_datum) }
        format.xml  { render :xml => @pwr_datum, :status => :created, :location => @pwr_datum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pwr_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pwr_data/1
  # PUT /pwr_data/1.xml
  def update
    @pwr_datum = PwrDatum.find(params[:id])

    respond_to do |format|
      if @pwr_datum.update_attributes(params[:pwr_datum])
        flash[:notice] = 'PwrDatum was successfully updated.'
        format.html { redirect_to(@pwr_datum) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pwr_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pwr_data/1
  # DELETE /pwr_data/1.xml
  def destroy
    @pwr_datum = PwrDatum.find(params[:id])
    @pwr_datum.destroy

    respond_to do |format|
      format.html { redirect_to(pwr_data_url) }
      format.xml  { head :ok }
    end
  end
end
