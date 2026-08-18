RSpec.describe Caldav::BaseJob do
  let(:agent) { create(:agent, :with_caldav_config) }

  let(:job_class) do
    stub_const "MyCaldavJob", Class.new(described_class)
    MyCaldavJob.class_eval do
      def perform(agent_id)
        agent = Agent.find(agent_id)
        agent.caldav_config.caldav_client.calendars.find(agent.caldav_config.caldav_agenda_url, sync: true)
      end
    end
    MyCaldavJob
  end

  describe "gestion des réponses en erreur" do
    it "enregistre requête et réponse dans Sentry si la récupération du token retourne une erreur" do
      cal_url = agent.caldav_config.caldav_agenda_url
      stub_request(:propfind, cal_url)
        .and_return({ status: 500, body: "ceci est mon corps", headers: { "Set-Cookie" => "secret" } })

      job_class.perform_now(agent.id)

      expect(sentry_events.last.exception.values.last.value).to eq("500 Internal Server Error (Calendav::RequestError)")

      request_breadcrumb = sentry_events.last.breadcrumbs.compact[0]
      expect(request_breadcrumb.data[:method]).to eq(:propfind)
      expect(request_breadcrumb.data[:url]).to eq(cal_url)
      expect(request_breadcrumb.data[:headers]["Authorization"]).to eq("[FILTERED]")

      response_breadcrumb = sentry_events.last.breadcrumbs.compact[1]
      expect(response_breadcrumb.data[:status_code]).to eq(500)
      expect(response_breadcrumb.data[:body]).to eq("ceci est mon corps")
      expect(response_breadcrumb.data[:duration_ms]).to be_between(0, 100)
      expect(response_breadcrumb.data[:headers]["Set-Cookie"]).to eq("[FILTERED]")
    end

    it "utilise un fingerprint différent pour chaque statut HTTP de réponse d'erreur" do
      cal_url = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id"

      stub_request(:propfind, cal_url).and_return({ status: 403 })
      job_class.perform_now(agent.id)
      expect(sentry_events.last.fingerprint).to eq(["{{default}}", "Calendav::RequestError", "403"])

      stub_request(:propfind, cal_url).and_return({ status: 500 })
      job_class.perform_now(agent.id)
      expect(sentry_events.last.fingerprint).to eq(["{{default}}", "Calendav::RequestError", "500"])
    end

    # Cette spec a été ajoutée pour vérifier que le job ne part pas en retry infini.
    # Un déploiement précédent avait cassé la prod à cause d'un usage de retry_job causant une boucle inifnie de retries.
    it "retry le job 13 fois, envoie des warning les 4 premières tentatives et un erreur à la dernière" do
      cal_url = "https://ox8-oidc.ox8-oidc.osprod.dimail1.numerique.gouv.fr/dav/caldav/1234_calendar_id"
      stub_request(:propfind, cal_url).and_return({ status: 500 })

      expect(enqueued_jobs).to be_empty
      job_class.perform_later(agent.id)

      # Les 12 premiers retries ne déclenchent pas d'exception
      12.times do |index|
        expect(enqueued_jobs.sole["executions"]).to eq(index)
        perform_enqueued_jobs
        expect(enqueued_jobs.sole["executions"]).to eq(index + 1)
      end

      # Après 13 retries l'exception est levée et non catchée par retry_on, elle sera alors nativement gérée par sentry-rails.
      expect { perform_enqueued_jobs }.to raise_error(Calendav::RequestError)

      # On a bien exécuté le job 13 fois
      expect(a_request(:propfind, cal_url)).to have_been_made.times(13)

      # On ne re-enqueue rien
      expect(enqueued_jobs).to be_empty

      # On envoie des warnings à Sentry pour les 4 premiers retries, puis une erreur au retry final
      expect(sentry_events.map { [_1.tags[:executions], _1.level] }).to eq([[1, :warning], [2, :warning], [3, :warning], [4, :warning], [13, :error]])
    end
  end
end
