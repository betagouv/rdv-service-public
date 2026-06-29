RSpec.describe DomainRedirectionAfterLogin do
  subject(:controller) do
    Object.new.extend(described_class)
  end

  context "quand l'agent n'a pas encore d'organisation" do
    let(:agent) { create(:agent, pro_connect_openid_sub: "faux_sub_proconnect") }

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

      context "avec un fournisseur d'identité proconnect lié à l'état" do
        let(:agent) do
          create(:agent,
                 pro_connect_openid_sub: "faux_sub_proconnect",
                 pro_connect_idp_id: "9e139e69-de07-4cbe-987f-d12cb38c0368") # Le fournisseur d'identité du ministère de la Justice
        end

        it "est redirigé vers le domaine de l'état" do
          expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
          expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
        end
      end

      context "avec un nom de domaine lié à l'état" do
        let(:agent) do
          create(:agent,
                 pro_connect_openid_sub: "faux_sub_proconnect",
                 email: "francis.factice@justice.fr")
        end

        it "est redirigé vers le domaine de l'état" do
          expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
          expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
        end

        context "mais lié à France Service" do
          let(:agent) do
            create(:agent,
                   pro_connect_openid_sub: "faux_sub_proconnect",
                   email: "francis.factice@france-service.gouv.fr")
          end

          it "n'est pas redirigé" do
            expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
            expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
          end
        end

        context "mais lié à l'ANCT" do
          let(:agent) do
            create(:agent,
                   pro_connect_openid_sub: "faux_sub_proconnect",
                   email: "francis.factice@ext.anct.gouv.fr")
          end

          it "n'est pas redirigé" do
            expect(controller.should_redirect_to_domain_etat?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
            expect(controller.should_redirect_to_domain_anct?(domain, agent)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
          end
        end
      end
    end
  end
end
