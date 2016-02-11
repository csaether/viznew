class RawDataFilesController < ApplicationController
  # GET /raw_data_files
  # GET /raw_data_files.xml
  def index
    @raw_data_files = RawDataFile.all
    @hicycnum = Bdcycle.find :last

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @raw_data_files }
    end
  end

  # GET /raw_data_files/1
  # GET /raw_data_files/1.xml
  def show
    @raw_data_file = RawDataFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @raw_data_file }
    end
  end

  # GET /raw_data_files/new
  # GET /raw_data_files/new.xml
  def new
    @raw_data_file = RawDataFile.new
    @hicycnum = Bdcycle.find :last

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @raw_data_file }
    end
  end

  # GET /raw_data_files/1/edit
  def edit
    @raw_data_file = RawDataFile.find(params[:id])
    @hicycnum = Bdcycle.find :last
  end

  # POST /raw_data_files
  # POST /raw_data_files.xml
  def create

    @raw_data_file = RawDataFile.new(params[:raw_data_file])
    if @raw_data_file.leg_maps.count == 0
      # temp until edit form is fixed
      legmap = LegMap.create! :leg => 0, :voltchan => 0, :ampchan => 1,
               :raw_data_file_id => @raw_data_file
      legmap = LegMap.create! :leg => 1, :voltchan => 0, :ampchan => 2,
               :raw_data_file_id => @raw_data_file
    end

    respond_to do |format|
      if @raw_data_file.save
        flash[:notice] = 'RawDataFile was successfully created.'
        format.html { redirect_to(@raw_data_file) }
        format.xml  { render :xml => @raw_data_file, :status => :created, :location => @raw_data_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @raw_data_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /raw_data_files/1
  # PUT /raw_data_files/1.xml
  def update
    @raw_data_file = RawDataFile.find(params[:id])

    respond_to do |format|
      if @raw_data_file.update_attributes(params[:raw_data_file])
        flash[:notice] = 'RawDataFile was successfully updated.'
        format.html { redirect_to raw_data_files_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @raw_data_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /raw_data_files/1
  # DELETE /raw_data_files/1.xml
  def destroy
    @raw_data_file = RawDataFile.find(params[:id])
    @raw_data_file.destroy

    respond_to do |format|
      format.html { redirect_to(raw_data_files_url) }
      format.xml  { head :ok }
    end
  end

  def process_files

    @raw_data_file = RawDataFile.find(params[:id])
=begin
    lastbd = Bdcycle.find :last
    hicycnum = lastbd.nil? ? 0 : lastbd.cyclenum
    if  hicycnum > @raw_data_file.base_cyclenum
      flash[:error] = 'Already processed higher cyclenumbers'
    else
=end
      @raw_data_file.process_burst_data rescue Exception

      @raw_data_file.process_events
      flash[:notice] = 'Processed data files'
#    end
    redirect_to raw_data_files_path
  end

  def add_cycles
    @raw_data_file = RawDataFile.find(params[:id])

    @raw_data_file.add_cycles_only
    flash[:notice] = 'Checked cycle data'

    redirect_to raw_data_files_path
  end
end
