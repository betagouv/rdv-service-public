class RdvUpdater

  def initialize(rdv)
    @rdv = rdv
  end

  def update(rdv_params)
    @rdv.update(rdv_params)
  end
end
