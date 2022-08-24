# frozen_string_literal: true

class Users::FileAttenteSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def new_creneau_available(rdv, _user, token)
    @content = "RDV #{rdv.motif&.service&.short_name}: des créneaux se sont libérés.\nPour voir les disponibilités: #{creneaux_users_rdv_short_url(rdv, tkn: token, host: domain_host)}"
  end
end
