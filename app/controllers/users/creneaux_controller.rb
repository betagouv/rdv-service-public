class Users::CreneauxController < UserAuthController
  def new
    @rdv = policy_scope(Rdv).find(params[:rdv_id])
    authorize(@rdv)
    @starts_at = params[:starts_at].to_time
    @state = nil
    return if params[:confirmed] == 'true' && @starts_at.present? && @rdv.update(starts_at: @starts_at)

    lieu = Lieu.find_by(address: @rdv.location)
    @creneau = Creneau.new(starts_at: @starts_at, motif: @rdv.motif, lieu_id: lieu.id)
    if @creneau.available?
      @state = true
    else
      @state = false
      flash.now[:error] = "Malheureusement, ce créneau n'est plus disponible."
    end
  end
end
