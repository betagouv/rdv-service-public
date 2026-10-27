RSpec.describe PrescripteurMailer, type: :mailer do
  describe "#rdv_created" do
    let(:organisation) { create(:organisation) }
    let(:rdv) { create(:rdv, organisation:, motif: create(:motif, organisation:, location_type: :visio)) }
    let(:participation) { rdv.participations.first }
    let(:mail) { described_class.rdv_created(participation, rdv.domain.id) }

    before { participation.update!(created_by: create(:prescripteur)) }

    it "indique au prescripteur que le lien de visio sera communiqué à l'usager" do
      expect(mail.body.decoded).to include("Le lien de visioconférence sera communiqué à l’usager.")
    end
  end
end
