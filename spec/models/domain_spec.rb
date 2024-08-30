RSpec.describe Domain do
  around do |example|
    with_modified_env(
      AGENT_CONNECT_RDVS_CLIENT_SECRET: "un faux secret de test",
      AGENT_CONNECT_RDVS_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa",
      AGENT_CONNECT_RDVAN_CLIENT_SECRET: "un faux secret de test",
      AGENT_CONNECT_RDVAN_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa",
      AGENT_CONNECT_RDVSP_CLIENT_SECRET: "un faux secret de test",
      AGENT_CONNECT_RDVSP_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
    ) do
      reload_domain_file # On charge le fichier pour qu'il prenne en compte les variables d'env settées
      example.run
    end
    reload_domain_file # On charge le fichier à nouveau pour que les domaines soient réinitalisés sans les variables d'env, pour éviter les effets de bord dans d'autres specs
  end

  def reload_domain_file
    # Ce mécanisme permet de recharger le fichier sans avoir le warning "warning: already initialized constant"

    original_verbose = $VERBOSE
    $VERBOSE = nil # suppress warnings
    load Rails.root.join("app/models/domain.rb")
    $VERBOSE = original_verbose
  end

  it "has domains initialized with all the required keys" do
    Domain::ALL.each do |domain|
      expect(domain.to_h.compact.keys).to match_array(described_class.members)
    end
  end
end
