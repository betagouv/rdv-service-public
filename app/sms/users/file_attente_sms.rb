# frozen_string_literal: true

class Users::FileAttenteSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def new_creneau_available(rdv_payload, _user)
    @content = "Des créneaux se sont libérés plus tot.\nCliquez pour voir les disponibilités : #{users_creneaux_index_url(rdv_id: rdv_payload.id, host: ENV["HOST"])}"
  end
end
