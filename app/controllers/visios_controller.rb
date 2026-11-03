class VisiosController < ApplicationController
  layout "application_narrow"

  def show
    @rdv = Rdv.find_signed(params[:token], purpose: :visio) or raise ActiveRecord::RecordNotFound

    if @rdv.cancelled? || !@rdv.motif.visio?
      @message = "Ce rendez-vous n’a pas de visioconférence associée."
    elsif @rdv.visio_url.present?
      redirect_to @rdv.visio_url, allow_other_host: true
    else
      @message = I18n.t("rdvs.visio_link_not_yet_available")
    end
  end
end
