RSpec.describe "health checks" do
  #
  # Cet endpoint a été ajouté lors de la migration de Scalingo vers OVH.
  # En effet, la nouvelle stack a besoin d'un endpoint de health check pour
  # savoir si l'appli tourne, et la redémarrer si nécessaire.
  #
  # La particularité de cette route est qu'elle doit être accessible en
  # production en HTTP plutôt qu'en HTTP, car l'agent qui fait le health
  # check est interne au réseau Kubernetes (le HTTPS en géré à l'extérieur).
  # Nous avons donc défini une config.ssl_options qui exclut cette route.
  #
  describe "/health_check" do
    it "returns HTTP 200" do
      get "/health_check"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "/health/jobs_scheduled" do
    before do
      # Rubocop recommande de définir un allow et un expect
      # https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/StubbedMock
      allow(Rails.configuration.good_job).to receive(:cron)
        .and_return(
          {
            file_attente_job: {
              cron: "0/10 9,10,11,12,13,14,15,16,17,18 * * * Europe/Paris", # Every 10 minutes, from 9:00 to 18:00
              class: "CronJob::FileAttenteJob",
            },
          }
        )
    end

    before { travel_to now }

    context "à 22h, aucun job prévu" do
      let(:now) { Time.zone.parse("2024-10-03 22:00") }

      it "retourne une 200" do
        expect(Rails.configuration.good_job).to receive(:cron)
        get "/health/jobs_scheduled"
        expect(response).to have_http_status(:ok)
      end
    end

    context "à 16h, plusieurs jobs prévus dans la dernière heure mais aucun enqueued car le scheduler ne tourne pas en test" do
      let(:now) { Time.zone.parse("2024-10-03 16:00") }

      it "retourne une erreur" do
        expect(Rails.configuration.good_job).to receive(:cron)
        get "/health/jobs_scheduled"
        expect(response).to have_http_status(503)
        expect(response.parsed_body).to eq("jobs_missed" => ["CronJob::FileAttenteJob"])
      end
    end
  end
end
