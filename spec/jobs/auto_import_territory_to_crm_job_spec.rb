RSpec.describe AutoImportTerritoryToCrmJob, type: :job do
  context "quand la clef NOTION_API_SECRET est définie" do
    stub_env_with(NOTION_API_SECRET: "secret")

    it "catégorise l'espace État pour les domaines en abc.gouv.fr et enqueue la création de la page CRM" do
      agent = create(:agent, email: "jean@interieur.gouv.fr")
      PaperTrail.request.whodunnit = agent.name_for_paper_trail
      territory = create(:territory)
      expect { described_class.new.perform(territory.id) }.to have_enqueued_job(CreateCrmPageJob).with(territory.id)
      expect(territory.reload.category).to eq "État"
    end

    it "ne fait rien quand l'auteur de la création a une adresse france services" do
      agent = create(:agent, email: "jean@france-services.gouv.fr")
      PaperTrail.request.whodunnit = agent.name_for_paper_trail
      territory = create(:territory)
      expect { described_class.new.perform(territory.id) }.not_to have_enqueued_job(CreateCrmPageJob)
      expect(territory.reload.category).to be_nil
    end

    it "ne fait rien quand l'auteur de la création n'a pas d'adresse en .gouv.fr" do
      agent = create(:agent, email: "jean@mairie-marseille.com")
      PaperTrail.request.whodunnit = agent.name_for_paper_trail
      territory = create(:territory)
      expect { described_class.new.perform(territory.id) }.not_to have_enqueued_job(CreateCrmPageJob)
      expect(territory.reload.category).to be_nil
    end

    it "ne fait rien quand l'espace a déjà une catégorie" do
      agent = create(:agent, email: "jean@interieur.gouv.fr")
      PaperTrail.request.whodunnit = agent.name_for_paper_trail
      territory = create(:territory, category: "Commune")
      expect { described_class.new.perform(territory.id) }.not_to have_enqueued_job(CreateCrmPageJob)
      expect(territory.reload.category).to eq "Commune"
    end

    it "ne fait rien quand la création de l'espace n'a pas été faite par un agent" do
      territory = create(:territory)
      expect { described_class.new.perform(territory.id) }.not_to have_enqueued_job(CreateCrmPageJob)
      expect(territory.reload.category).to be_nil
    end
  end

  context "quand la clef NOTION_API_SECRET n'est pas définie" do
    stub_env_with(NOTION_API_SECRET: nil)

    it "ne fait rien" do
      agent = create(:agent, email: "jean@interieur.gouv.fr")
      PaperTrail.request.whodunnit = agent.name_for_paper_trail
      territory = create(:territory)
      expect { described_class.new.perform(territory.id) }.not_to have_enqueued_job(CreateCrmPageJob)
      expect(territory.reload.category).to be_nil
    end
  end
end
