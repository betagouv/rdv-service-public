RSpec.describe WebhookEndpoint, type: :model do
  stub_env_with(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS")

  describe "target_url validation" do
    subject { webhook_endpoint.valid? }

    let(:organisation) { create(:organisation) }
    let(:webhook_endpoint) { build(:webhook_endpoint, organisation_id: organisation.id, target_url: target_url) }
    let!(:other_webhook_endpoint) { create(:webhook_endpoint, organisation_id: organisation.id, target_url: "https://www.taken_url.com") }

    context "when the target_url is unique in the organisation_id scope" do
      let(:target_url) { "https://www.rdv-insertion.fr/rdv_solidarites_webhooks" }

      it "is valid" do
        expect(subject).to be(true)
      end
    end

    context "when the target_url is already taken in the organisation_id scope" do
      let(:target_url) { "https://www.taken_url.com" }

      it "is not valid" do
        expect(subject).to be(false)
      end
    end
  end

  describe "format de target_url" do
    it "est valide si target_url est une URL https valide" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "https://cd92.fr/webhooks?source=rdv")
      expect(webhook_endpoint).to be_valid
    end

    it "est valide si target_url est une URL http avec un port" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "http://localhost:3000/webhooks")
      expect(webhook_endpoint).to be_valid
    end

    it "est invalide si target_url n'a pas de schéma" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "evil.fr/webhooks")
      expect(webhook_endpoint).not_to be_valid
      expect(webhook_endpoint.errors[:target_url]).to eq(["n’est pas une URL valide, elle doit commencer par http(s)://"])
    end

    it "est invalide si target_url n'a qu'un slash après le schéma http:/" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "http:/evil.fr/webhooks")
      expect(webhook_endpoint).not_to be_valid
    end

    it "est invalide pour un autre schéma que http(s)" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "ftp://cd92.fr/webhooks")
      expect(webhook_endpoint).not_to be_valid
    end

    it "est invalide si target_url contient des espaces" do
      webhook_endpoint = build(:webhook_endpoint, target_url: "pas une url")
      expect(webhook_endpoint).not_to be_valid
    end
  end

  describe "restriction des domaines autorisés pour target_url" do
    it "est valide si ALLOWED_WEBHOOK_HOSTS contient deux domaines et target_url utilise un des deux" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "rdvi.gouv.fr; cd92.fr") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://cd92.fr/webhooks")
        expect(webhook_endpoint).to be_valid
      end
    end

    it "est invalide si ALLOWED_WEBHOOK_HOSTS contient deux domaines et target_url en utilise un autre" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "rdvi.gouv.fr; cd92.fr") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://evil92.fr/webhooks")
        expect(webhook_endpoint).not_to be_valid
      end
    end

    it "est invalide si ALLOWED_WEBHOOK_HOSTS contient cd92.fr et target_url utilise le sous-domaine api.cd92.fr" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "cd92.fr") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://api.cd92.fr/webhooks")
        expect(webhook_endpoint).not_to be_valid
      end
    end

    it "est invalide et invite à nous écrire si ALLOWED_WEBHOOK_HOSTS contient cd92.fr et target_url utilise evilcd92.fr qui se termine pareil" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "cd92.fr") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://evilcd92.fr/webhooks")
        expect(webhook_endpoint).not_to be_valid
        expect(webhook_endpoint.errors[:target_url]).to eq(["« evilcd92.fr » ne fait pas partie des domaines autorisés pour les webhooks. Contactez-nous pour ajouter votre domaine."])
      end
    end

    it "est invalide quel que soit le domaine si ALLOWED_WEBHOOK_HOSTS est absente" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: nil) do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://cd92.fr/webhooks")
        expect(webhook_endpoint).not_to be_valid
      end
    end

    it "est valide quel que soit le domaine si ALLOWED_WEBHOOK_HOSTS vaut ALLOW_ALL_HOSTS" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "https://exemple.fr/webhooks")
        expect(webhook_endpoint).to be_valid
      end
    end

    it "ne renvoie que l'erreur de format si target_url est mal formée et que son domaine n'est pas autorisé" do
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "cd92.fr") do
        webhook_endpoint = build(:webhook_endpoint, target_url: "evil.fr/webhooks")
        expect(webhook_endpoint).not_to be_valid
        expect(webhook_endpoint.errors[:target_url]).to eq(["n’est pas une URL valide, elle doit commencer par http(s)://"])
      end
    end

    it "permet de modifier les abonnements d'un webhook vers exemple.fr créé avant que ALLOWED_WEBHOOK_HOSTS ne soit restreinte à cd92.fr" do
      webhook_endpoint = with_modified_env(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS") do
        create(:webhook_endpoint, target_url: "https://exemple.fr/webhooks")
      end
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "cd92.fr") do
        expect(webhook_endpoint.update(subscriptions: ["rdv"])).to be(true)
      end
    end

    it "refuse de changer l'URL d'un webhook créé avant que ALLOWED_WEBHOOK_HOSTS ne soit restreinte à cd92.fr vers un autre domaine non autorisé" do
      webhook_endpoint = with_modified_env(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS") do
        create(:webhook_endpoint, target_url: "https://exemple.fr/webhooks")
      end
      with_modified_env(ALLOWED_WEBHOOK_HOSTS: "cd92.fr") do
        expect(webhook_endpoint.update(target_url: "https://autre-exemple.fr/webhooks")).to be(false)
      end
    end
  end

  describe "#subscriptions_validity" do
    subject { webhook_endpoint.valid? }

    let(:organisation) { create(:organisation) }
    let(:webhook_endpoint) { build(:webhook_endpoint, organisation_id: organisation.id, subscriptions: subscriptions) }

    context "when the subscriptions array is valid" do
      let(:subscriptions) { %w[rdv absence plage_ouverture user motif lieu agent agent_role referent_assignation] }

      it "is valid" do
        expect(subject).to be(true)
      end
    end

    context "when the target_url is already taken in the organisation_id scope" do
      let(:subscriptions) { %w[user organisation wrong_value] }

      it "is not valid" do
        expect(subject).to be(false)
      end
    end
  end

  describe "sending notifications for a new URL" do
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:territory_admins) { create_list(:agent, 2, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    context "when creating a webhook" do
      context "when the URL is new to all webhooks in the territory" do
        it "warns all territory admins" do
          expect do
            create(:webhook_endpoint, organisation:, target_url: "https://example.com")
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
          expect(ActionMailer::Base.deliveries.last(2).map(&:subject).uniq).to eq(["Une nouvelle URL de webhook vient d'être ajoutée"])
        end
      end

      context "when the URL is already present in another webhook in the territory" do
        before do
          create(:webhook_endpoint, target_url: "https://example.com", organisation: create(:organisation, territory:))
        end

        it "does not send notifications" do
          expect do
            create(:webhook_endpoint, organisation:, target_url: "https://example.com")
          end.not_to change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "when the URL is already present in another webhook in another territory" do
        before do
          create(:webhook_endpoint, target_url: "https://example.com", organisation: create(:organisation, territory: create(:territory)))
        end

        it "sends notifications" do
          expect do
            create(:webhook_endpoint, organisation:, target_url: "https://example.com")
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
          expect(ActionMailer::Base.deliveries.last(2).map(&:subject).uniq).to eq(["Une nouvelle URL de webhook vient d'être ajoutée"])
        end
      end
    end

    context "when updating a webhook" do
      let!(:webhook) { create(:webhook_endpoint, organisation:, target_url: "https://example.com") }

      context "when the URL is new to all webhooks in the territory" do
        it "warns all territory admins" do
          expect do
            webhook.update!(target_url: "https://new-url.biz")
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
          expect(ActionMailer::Base.deliveries.last(2).map(&:subject).uniq).to eq(["Une nouvelle URL de webhook vient d'être ajoutée"])
        end
      end

      context "when the URL is already present in another webhook in the territory" do
        before do
          create(:webhook_endpoint, target_url: "https://new-url.biz", organisation: create(:organisation, territory:))
        end

        it "does not send notifications" do
          expect do
            webhook.update!(target_url: "https://new-url.biz")
          end.not_to change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "when the URL is already present in another webhook in another territory" do
        before do
          create(:webhook_endpoint, target_url: "https://new-url.biz", organisation: create(:organisation, territory: create(:territory)))
        end

        it "sends notifications" do
          expect do
            webhook.update!(target_url: "https://new-url.biz")
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
          expect(ActionMailer::Base.deliveries.last(2).map(&:subject).uniq).to eq(["Une nouvelle URL de webhook vient d'être ajoutée"])
        end
      end
    end
  end
end
