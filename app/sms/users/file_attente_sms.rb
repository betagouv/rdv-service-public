class Users::FileAttenteSms < Users::BaseSms
  include Rails.application.routes.url_helpers

  def new_creneau_available(rdv, _user, token)
    @content = if rdv.service_short_name
                 "RDV #{rdv.motif&.service&.short_name}: des créneaux se sont libérés."
               else
                 "Des créneaux se sont libérés pour votre RDV."
               end

    @content += "\nPour voir les disponibilités: #{creneaux_users_rdv_short_url(rdv, tkn: token, host: domain_host)}"
  end
end
