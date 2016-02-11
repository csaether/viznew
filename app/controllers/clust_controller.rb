class ClustController < ApplicationController
  def index
    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff > 0' ]
    else
      conditions = [ 'wattdiff > ? and wattdiff < ?',
                     params[:mindiff], params[:maxdiff] ]
    end

    posobschgs = ObsChg.find :all, :conditions => conditions
    posa = posobschgs.collect{|o| [o.wattdiff, o]}
    posminerds = Clu.minertiad posa
    posmins = Clu.peaks posminerds, 1

    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff < 0' ]
    else
      conditions = [ 'wattdiff < ? and wattdiff > ?',
                     -(params[:mindiff].to_i), -(params[:maxdiff].to_i) ]
    end

    negobschgs = ObsChg.find :all, :conditions => conditions
    nega = negobschgs.collect{|o| [o.wattdiff, o]}
    negminerds = Clu.minertiad nega
    negmins = Clu.peaks negminerds, 1

    wmins = (negmins + posmins).sort{|a,b| a[0].abs <=> b[0].abs}
    @wattclusts = []
    wmins.each do |wattc|
      vars = wattc[2].collect{|e| [e[1].vardiff, e[1]]}
      varmis = Clu.minertiad( vars, 12 )  # wider range than wattdiff
      varcs = Clu.peaks( varmis, 1 ) # .collect{|v| [v[0], v[2].count]}
      @wattclusts.push [ wattc[0], wattc[1], wattc[2].count, varcs ]
    end
  end

  def mdchart
    @onwattdens = []
    @offwattdens = []
    return if params[:mindiff].blank? && params[:maxdiff].blank?
    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff > 0' ]
    else
      conditions = [ 'wattdiff > ? and wattdiff < ?',
                     params[:mindiff], params[:maxdiff] ]
    end

    posobschgs = ObsChg.find :all, :conditions => conditions
    posa = posobschgs.collect{|o| [o.wattdiff, o]}
    posminerds = Clu.minertiad posa
    @onwattdens = posminerds.collect{|e| [e[0], e[1]]}

    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff < 0' ]
    else
      conditions = [ 'wattdiff < ? and wattdiff > ?',
                     -(params[:mindiff].to_i), -(params[:maxdiff].to_i) ]
    end

    negobschgs = ObsChg.find :all, :conditions => conditions
    nega = negobschgs.collect{|o| [o.wattdiff, o]}
    negminerds = Clu.minertiad nega
    @invoffwattdens = negminerds.collect{|e| [-e[0], e[1]]}
  end
=begin
  def index
    @wattpeaks = []
    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff > 0' ]
    else
      conditions = [ 'wattdiff > ? and wattdiff < ?',
                     params[:mindiff], params[:maxdiff] ]
    end

    posobschgs = ObsChg.find :all, :conditions => conditions
    posa = posobschgs.collect{|o| [o.wattdiff, o]}
    posgravs = Clu.gravity posa
    pospeaks = Clu.peaks posgravs, 2  # normalized

    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff < 0' ]
    else
      conditions = [ 'wattdiff < ? and wattdiff > ?',
                     -(params[:mindiff].to_i), -(params[:maxdiff].to_i) ]
    end

    negobschgs = ObsChg.find :all, :conditions => conditions
    nega = negobschgs.collect{|o| [o.wattdiff, o]}
    neggravs = Clu.gravity nega
    negpeaks = Clu.peaks neggravs, 2

    wpeaks = (negpeaks + pospeaks).sort{|a,b| a[0].abs <=> b[0].abs}
    @wattpeaks = []
    wpeaks.each do |wattp|
      vars = wattp[3].collect{|e| [e[1].vardiff, e[1]]}
      vargs = Clu.gravity( vars, 12 )  # wider range than wattdiff
      varps = Clu.peaks( vargs, 2 ).collect{|v| [v[0], v[3].count]}
      @wattpeaks.push [ wattp[0], wattp[2], wattp[3].count, varps ]
    end
  end
  def index
    @gravpeaks = []
    return if params[:mindiff].blank? && params[:maxdiff].blank?
    conditions = [ 'wattdiff > ? and wattdiff < ?',
                   params[:mindiff], params[:maxdiff] ]

    posobschgs = ObsChg.find :all, :conditions => conditions
    posgravs = Clu.grav3 posobschgs
    pospeaks = Clu.peaks posgravs, 1

    conditions = [ 'wattdiff < ? and wattdiff > ?',
                   -(params[:mindiff].to_i), -(params[:maxdiff].to_i) ]

    negobschgs = ObsChg.find :all, :conditions => conditions
    neggravs = Clu.grav3 negobschgs
    negpeaks = Clu.peaks neggravs, 1

    @gravpeaks = (negpeaks + pospeaks).sort{|a,b| a[0].abs <=> b[0].abs}
    @gravpeaks.each do |wp|
      vsa = wp[3]
      vpsa = Clu.peaks vsa, 2
      wp[3] = vpsa.sort{|a,b| a[0].abs <=> b[0].abs}
    end
  end
=end
  def mdvar
    @onwattdens = []
    @invoffwattdens = []
    return if params[:mindiff].blank? && params[:maxdiff].blank?
    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff > 0' ]
    else
      conditions = [ 'wattdiff > ? and wattdiff < ?',
                     params[:mindiff], params[:maxdiff] ]
    end

    deltapcnt = 7.0
    deltapcnt = params[:deltapcnt].to_f unless params[:deltapcnt].blank?
    scaling = 7.0
    scaling = params[:scaling].to_f unless params[:scaling].blank?

    posobschgs = ObsChg.find :all, :conditions => conditions
    posa = posobschgs.collect{|o| [o.wattdiff, o]}
    posminerds = Clu.minertiad posa, deltapcnt, scaling
    posminerds.each do |e|
      vai=e[2].collect{|o| [o[1].vardiff, o[1]]}
      vamis = Clu.minertiad vai, deltapcnt, scaling
      vaps = Clu.peaks( vamis, 1 ).collect{|o| [ o[0], o[1], o[2].count ]}
      @onwattdens.push [e[0], e[1], vaps]
    end
#    @onwattdens = posminerds.collect{|e| [e[0], e[1]]}

    if params[:mindiff].blank? && params[:maxdiff].blank?
      conditions = [ 'wattdiff < 0' ]
    else
      conditions = [ 'wattdiff < ? and wattdiff > ?',
                     -(params[:mindiff].to_i), -(params[:maxdiff].to_i) ]
    end

    negobschgs = ObsChg.find :all, :conditions => conditions
    nega = negobschgs.collect{|o| [o.wattdiff, o]}
    negminerds = Clu.minertiad nega
    negminerds.each do |e|
      vai=e[2].collect{|o| [o[1].vardiff, o[1]]}
      vamis = Clu.minertiad vai
      vaps = Clu.peaks( vamis, 1 ).collect{|o| [-o[0], o[1], o[2].count]}
      @invoffwattdens.push [-e[0], e[1], vaps]
    end
#    @invoffwattdens = negminerds.collect{|e| [-e[0], e[1]]}
  end

  def justbins
    params[:wattstep] = 10 if params[:wattstep].blank?
    params[:varstep] = 25 if params[:varstep].blank?
    params[:rampstep] = 25 if params[:rampstep].blank?
    params[:hyperrad] = 1.0 if params[:hyperrad].blank?
    params[:binmin] = 4 if params[:binmin].blank?

    hyperrad = params[:hyperrad].to_f

    @hbins = Clues.new
    @hbins.binsizes=[ params[:wattstep], params[:varstep], params[:rampstep] ]

    tups = ObsChg.find(:all).collect{|o| [o.wattdiff, o.vardiff, o.ramp]}
    @hbins.tups2bins tups
    @hbins.genbinmdiplus hyperrad

    @centers = (@hbins.bintups).sort{|a,b| a[0].abs <=> b[0].abs}
    nil
  end

  def bins

    @hbins = Clues.new
    params[:wattstep] = 20 if params[:wattstep].blank?
    params[:varstep] = 40 if params[:varstep].blank?
    params[:rampstep] = 20 if params[:rampstep].blank?
    params[:hyperrad] = 1.8 if params[:hyperrad].blank?
    params[:binmin] = 4 if params[:binmin].blank?
    binmin = params[:binmin].to_i

    hyperrad = params[:hyperrad].to_f
    @hbins.binsizes=[ params[:wattstep], params[:varstep], params[:rampstep] ]

    tups = ObsChg.find(:all).collect{|o| [o.wattdiff, o.vardiff, o.ramp]}
    @hbins.tups2bins tups
    @hbins.genbinmdiplus hyperrad

    @means = Array.new
    @stdevs = Array.new
    @idmdcnt = Array.new
    centers = (@hbins.bintups).sort{|a,b| a[0].abs <=> b[0].abs}
    centers.each do |ctup|
      ramdis = @hbins.mdihash.find ctup
      next unless ramdis && ramdis[2] >= binmin
      biggy = @hbins.biggest ctup
      next if biggy.nil? || biggy != ctup
=begin
      @idmdcnt.push ramdis[0..2]
      @means.push [ramdis[3][0][0], ramdis[3][1][0], ramdis[3][2][0]]
      @stdevs.push [ramdis[3][0][1], ramdis[3][1][1], ramdis[3][2][1]]
=end
      cdis = @hbins.convergemdi( @hbins.newt(ramdis) )
      next if cdis[2] == 0  # nobody in this set
      @idmdcnt.push cdis[0..2]
      @means.push [cdis[3][0][0], cdis[3][1][0], cdis[3][2][0]]
      @stdevs.push [cdis[3][0][1], cdis[3][1][1], cdis[3][2][1]]
    end
    nil
  end

  def clusig

    chgsig = ChgSig.create :wattchg => params[:wattchg].to_f.round,
      :wattchg_sdev => params[:wattchg_sdev].to_f.round,
      :varchg => params[:varchg].to_f.round,
      :varchg_sdev => params[:varchg_sdev].to_f.round,
      :ramp => params[:ramp].to_f,
      :ramp_sdev => params[:ramp_sdev].to_f
    redirect_to edit_chg_sig_path(chgsig)
  end

  def makesigs

    @hbins = Clues.new
    params[:wattstep] = 20 if params[:wattstep].blank?
    params[:varstep] = 40 if params[:varstep].blank?
    params[:rampstep] = 20 if params[:rampstep].blank?
    params[:hyperrad] = 1.8 if params[:hyperrad].blank?
    params[:binmin] = 4 if params[:binmin].blank?
    binmin = params[:binmin].to_i

    hyperrad = params[:hyperrad].to_f
    @hbins.binsizes = [ params[:wattstep], params[:varstep], params[:rampstep] ]

    tups = ObsChg.find(:all).collect{|o| [o.wattdiff, o.vardiff, o.ramp]}
    @hbins.tups2bins tups
    @hbins.genbinmdiplus hyperrad

    @means = Array.new
    @stdevs = Array.new
    @idmdcnt = Array.new
    centers = (@hbins.bintups).sort{|a,b| a[0].abs <=> b[0].abs}
    centers.each do |ctup|
      ramdis = @hbins.mdihash.find ctup
      next unless ramdis && ramdis[2] >= binmin
      biggy = @hbins.biggest ctup
      next if biggy.nil? || biggy != ctup
=begin
      @idmdcnt.push ramdis[0..2]
      @means.push [ramdis[3][0][0], ramdis[3][1][0], ramdis[3][2][0]]
      @stdevs.push [ramdis[3][0][1], ramdis[3][1][1], ramdis[3][2][1]]
=end
      cdis = @hbins.convergemdi( @hbins.newt(ramdis) )
      next if cdis[2] == 0  # nobody in this set
      @idmdcnt.push cdis[0..2]
      @means.push [cdis[3][0][0], cdis[3][1][0], cdis[3][2][0]]
      @stdevs.push [cdis[3][0][1], cdis[3][1][1], cdis[3][2][1]]
      bdist, bcs = ChgSig.closetup( @means[-1] )
      next if bdist < 1.5

      chgsig = ChgSig.create! :wattchg => @means[-1][0].round,
       :wattchg_sdev => @stdevs[-1][0].round,
       :varchg => @means[-1][1].round,
       :varchg_sdev => @stdevs[-1][1].round,
       :ramp => @means[-1][2],
       :ramp_sdev => @stdevs[-1][2]
    end
    nil

    render :action => :bins
  end
end
