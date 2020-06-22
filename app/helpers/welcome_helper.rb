module WelcomeHelper
  include SectorisationUtils

  def root_path?
    root_path == request.path
  end

  def sign_up_agent_button
    link_to 'Je m\'inscris', new_agent_registration_path, class: 'btn btn-primary'
  end

  def sign_in_agent_button
    link_to "Se connecter en tant qu'agent", new_agent_session_path, class: 'btn btn-outline-white'
  end

  def sign_in_user_button
    link_to 'Se connecter', new_user_session_path, class: 'btn btn-white'
  end

  def contact_us_button
    mail_to "contact@rdv-solidarites.fr", "Contactez-nous", class: 'btn btn-tertiary'
  end

  def urgency_quote
    "En cas de besoin, vous pouvez contacter le <b>#{urgency_number}</b>.".html_safe if urgency_number
  end

  def urgency_number
    case departement_params
    when '77'
      '01.64.14.77.77'
    when '92'
      '01.55.48.03.30'
    when '64'
      '05.59.69.34.11'
    when '62'
      '03 21 216 216'
    when '22'
      '02.96.60.86.86'
    when '80'
      '06.47.46.19.86'
    when '55'
      '03.29.80.32.34'
    end
  end

  def departement_params
    (controller_name == 'welcome' && params[:departement]) || (params[:search] && params[:search][:departement])
  end

  def sectorisation_hint(zone, organisations, departement)
    return nil if !sectorisation_enabled?(departement) || zone.nil?

    "Sectorisation : Commune #{@zone.city_name} → #{organisations.pluck(:name).join(', ')}"
  end
end
