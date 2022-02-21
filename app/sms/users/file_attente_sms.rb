# frozen_string_literal: true

class Users::FileAttenteSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def new_creneau_available(rdv, _user)
    @content = "Des créneaux se sont libérés plus tot.\nCliquez pour voir les disponibilités : #{creneaux_users_rdv_url(rdv, host: ENV['HOST'])}"
  end
end
