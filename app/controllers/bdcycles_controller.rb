class BdcyclesController < ApplicationController

  # using default map.connect for now

  def index
    @bdcycles = Bdcycle.paginate :page => params[:page], :per_page => 5
  end

  def slice
  end
end
