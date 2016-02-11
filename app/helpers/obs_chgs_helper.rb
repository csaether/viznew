module ObsChgsHelper

  def chgname oc
    return h(oc.chg_sig.name) if oc.chg_sig
    h( ChgSig.closest oc )
  end

  def runmatchlink oc
    return unless oc.run_offs.empty?
    if oc.run_ons.empty? && (oc.wattdiff < 0)
      return link_to "CheckBack", backmatch_obs_chg_path(oc)
    end

    another = false
    ret = ''
    oc.run_ons.each do |r|
      next if r.off_chg
      ret += ' | ' if another
      ret += link_to "#{h r.load_desc.name}", fwdmatch_run_path(r)
      another = true
    end
    ret
  end

  def cycname oc, cyci
    if cyci <= oc.precycnum
      "Pre#{oc.precycnum - cyci}"
    elsif cyci < oc.postcycnum
      "Tran#{cyci - oc.precycnum}"
    else
      "Post#{cyci - oc.postcycnum}"
    end
  end

  def cycsym oc, cyci
    if cyci <= oc.precycnum
      'circle'
    elsif cyci < oc.postcycnum
      'diamond'
    else
      'square'
    end
  end
end
