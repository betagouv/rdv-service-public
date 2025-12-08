RSpec.describe CopyPlanningToNewInstanceJob do
  describe CopyPlanningToNewInstanceJob::CopyRdvJob do
    context "for an old rdv taken by a user" do
      let(:user) { create(:user) }
      let(:rdv) do
        create(:rdv, agents: [instance_export.agent], users: [user], starts_at: 2.weeks.ago, created_by: user, organisation: instance_export.source_organisation)
      end
      let(:instance_export) { create(:instance_export) }

      it "sends all the information to the new instance" do
        request_params = nil
        allow_any_instance_of(RdvServicePublicApiClient).to receive(:post) do |_object, _path, params|
          request_params = params
        end

        described_class.new.perform(instance_export.id, rdv.id, Domain::RDV_AIDE_NUMERIQUE.id)
      end
    end
  end
end
