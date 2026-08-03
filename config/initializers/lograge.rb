Rails.application.configure do
  config.lograge.enabled = true

  # Ajout des infos poussées via `append_info_to_payload` (ex. SearchController) dans la ligne de log.
  config.lograge.custom_options = lambda do |event|
    event.payload.slice(:search_params, :user_agent)
  end
end
