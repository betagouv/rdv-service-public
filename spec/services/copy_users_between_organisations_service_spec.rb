RSpec.describe CopyUsersBetweenOrganisationsService, type: :service do
  describe "#perform" do
    subject { described_class.new(sources_organisations_ids, target_organisation_id).perform }

    let(:source_organisation1) { create(:organisation) }
    let(:source_organisation2) { create(:organisation) }
    let(:sources_organisations_ids) { [source_organisation1, source_organisation2] }
    let(:target_organisation) { create(:organisation) }
    let(:target_organisation_id) { target_organisation.id }
    let!(:user1_org1) { create(:user, organisations: [source_organisation1]) }
    let!(:user2_org1) { create(:user, organisations: [source_organisation1]) }
    let!(:user_org2) { create(:user, organisations: [source_organisation2]) }
    let!(:user_in_org_target) { create(:user, organisations: [target_organisation]) }
    let!(:user_without_org) { create(:user) }
    let!(:webhook_endpoint) do
      create(
        :webhook_endpoint,
        organisation: target_organisation,
        subscriptions: %w[user_profile]
      )
    end

    it "ajoute les utilisateurs des organisations sources à l'organisation cible et déclenche les webhook" do
      expect do
        subject
      end.to change { target_organisation.users.count }.by(3)
        .and have_enqueued_job(WebhookJob).with(json_payload_with_meta("model", "UserProfile"), webhook_endpoint.id).exactly(3).times

      expect(target_organisation.users).to include(user1_org1, user2_org1, user_org2, user_in_org_target)
    end

    context "avec des utilisateurs déjà présents dans l'organisation cible" do
      let(:target_organisation_id) { 999 }

      it "ne copie pas les utilisateurs si l'organisation cible est invalide" do
        expect(Rails.logger).to receive(:error).with("Organisation cible introuvable avec l'ID #{target_organisation_id}")

        expect do
          subject
        end.not_to change(UserProfile, :count)
      end
    end

    context "avec des organisations sources invalides" do
      let(:sources_organisations_ids) { [8888, 9999] }

      it "ne copie pas les utilisateurs si les organisations sources sont invalides" do
        expect(Rails.logger).to receive(:error).with("Aucune organisation source valide trouvée.")

        expect do
          subject
        end.not_to change(UserProfile, :count)
      end
    end
  end
end
