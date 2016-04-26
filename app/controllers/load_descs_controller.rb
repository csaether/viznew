class LoadDescsController < ApplicationController
  # GET /load_descs
  # GET /load_descs.xml
  def index

    @load_descs = LoadDesc.all
    unless params[:load_desc_ids].blank?
      ldids=params[:load_desc_ids].map{|i| i.to_i}
      @load_descs=@load_descs.select{|ld| ldids.include?(ld.id)}
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @load_descs }
    end
  end

  # GET /load_descs/1
  # GET /load_descs/1.xml
  def show
    @load_desc = LoadDesc.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @load_desc }
    end
  end

  # GET /load_descs/new
  # GET /load_descs/new.xml
  def new
    @load_desc = LoadDesc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @load_desc }
    end
=begin
byebug
    echgsig = params[:editchgsig]
    if echgsig.nil?
      @load_desc[:editchgsig] = nil  # send along for the ride
    else
      @load_desc[:editchgsig] = echgsig
    end
=end
  end

  # GET /load_descs/1/edit
  def edit
    @load_desc = LoadDesc.find(params[:id])
  end

  # POST /load_descs
  # POST /load_descs.xml
  def create

    echgsig = params[:load_desc][:editchgsig]
    params[:load_desc].delete :editchgsig
    @load_desc = LoadDesc.new(ldc_parms)
    respond_to do |format|
      if @load_desc.save
        if echgsig.blank?  # hidden field returned blank for nil
          format.html { redirect_to(new_chg_sig_path, :notice => 'LoadDesc was successfully created.') }
          format.xml  { render :xml => @load_desc, :status => :created, :location => @load_desc }
        else
          chgsig = ChgSig.find echgsig
          format.html { redirect_to edit_chg_sig_path( chgsig ) }
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @load_desc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /load_descs/1
  # PUT /load_descs/1.xml
  def update
    @load_desc = LoadDesc.find(params[:id])

    params[:load_desc][:short_duty]=X.parsecs params[:load_desc][:short_duty]
    params[:load_desc][:long_duty]=X.parsecs params[:load_desc][:long_duty]
    respond_to do |format|
      if @load_desc.update_attributes(ldc_parms)
        format.html { redirect_to(load_descs_path, :notice => 'LoadDesc was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @load_desc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /load_descs/1
  # DELETE /load_descs/1.xml
  def destroy
    @load_desc = LoadDesc.find(params[:id])
    @load_desc.destroy

    respond_to do |format|
      format.html { redirect_to(load_descs_url) }
      format.xml  { head :ok }
    end
  end
  private
  def ldc_parms
    params.require(:load_desc).permit(:avg_on, :avg_off, :name, :short_duty, :long_duty)
  end
end
