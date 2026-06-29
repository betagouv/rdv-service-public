RSpec.describe DomainRedirectionAfterLogin do
  subject(:controller) do
    Object.new.extend(described_class)
  end

  context "quand l'agent n'a pas encore d'organisation" do
    let(:agent) { create(:agent) }

    context "et qu'il se connecte sur le domaine de l'état" do
      let(:domain) { Domain::RDV_SERVICE_PUBLIC_ETAT }

      it "n'est pas redirigé" do
        expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
        expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
      end
    end

    context "et qu'il se connecte sur le domaine des collectivités" do
      let(:domain) { Domain::RDV_SERVICE_PUBLIC }

      it "n'est pas redirigé" do
        expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
        expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
      end
    end
  end
end
