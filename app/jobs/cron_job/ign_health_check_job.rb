class CronJob::IGNHealthCheckJob < CronJob
  discard_on StandardError # ne jamais retry ce job

  # Ce job vérifie que l’API adresse de l’IGN est accessible.
  # Cette API étant utilisée uniquement en front pour l’auto-complétion des adresses, nous n’avions pas de remontée d’erreur
  # lorsqu’elle était en panne.
  # Si l’API est inaccessible, nous incrémentons un compteur dans Redis. Si ce compteur atteint 3, nous envoyons une alerte Sentry.
  # Le job étant exécuté toutes les minutes, la détection de l’indisponibilité se fera 3 minutes après la première erreur.
  def perform
    begin
      response = Typhoeus.get("https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
    rescue Typhoeus::Errors::TimeoutError
      response = nil
    end

    unless response&.success?
      Redis.with_connection do |redis|
        if redis.incr("ign_api_health_check_failures") > 2
          Sentry.capture_message("L'API adresse de l'IGN est inaccessible (HTTP status: #{response.response_code}). Vérifier l’état du service ici : https://status.uptrends.com/aa35b49e519e4f90866dc6bfc0a797a9/7ec26cae-995d-4974-926a-9130b14f77be?SelectedPeriod=Last30Days")
        end

        redis.expire("ign_api_health_check_failures", 120) # expire après 2 minutes
      end
    end
  end
end
