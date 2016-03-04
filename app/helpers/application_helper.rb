module ApplicationHelper
  def onedecimal num
    number_with_precision(num, :precision => 1)
  end

  def twodecimal num
    number_with_precision(num, :precision => 2)
  end

  def threedecimal num
    number_with_precision(num, :precision => 3)
  end

  def hms secs
    return '-' if secs.nil?
    h = (secs/3600).to_i
    m = ((secs/60) % 60).to_i
    s = (secs % 60).to_i
    "#{h}:#{m}:#{s}"
  end

  def ocpageurl pwrdatum

    oc = ObsChg.where('pwr_datum_id = ?', pwrdatum).first
    opage = (oc.id - ObsChg.first.id)/ObsChg.per_page + 1
    url_for :controller => :obs_chgs, :page => opage
  end

  def meandev mda
    "#{mda[0].to_i} / #{mda[1].to_i}"
  end

  def wvrtxt cs
    if cs.wattchg > 0
      "<b>#{onedecimal(cs.wattchg)}, #{onedecimal(cs.varchg)}, #{onedecimal(cs.ramp)}</b>"
    else
      "<i>#{onedecimal(cs.wattchg)}, #{onedecimal(cs.varchg)}, #{onedecimal(cs.ramp)}</i>"
    end
  end
end
