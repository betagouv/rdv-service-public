class CronJob::IGNHealthCheckJob < CronJob
  # Ce job vérifie que l’API adresse de l’IGN est accessible.
  # Cette API étant utilisée uniquement en front pour l’auto-complétion des adresses, nous n’avions pas de remontée d’erreur
  # lorsqu’elle était en panne.
  def perform
    response = Faraday.get("https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")

    if response.status != 200
      Sentry.capture_message("L'API adresse de l'IGN est inaccessible (HTTP status: #{response.status}). Vérifier l’état du service ici : https://status.uptrends.com/aa35b49e519e4f90866dc6bfc0a797a9/7ec26cae-995d-4974-926a-9130b14f77be?SelectedPeriod=Last30Days")
    end
  end
end
