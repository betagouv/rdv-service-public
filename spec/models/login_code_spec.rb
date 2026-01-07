RSpec.describe LoginCode, type: :model do
  describe ".most_recent_usable_for scope" do
    before do
      create(:login_code, email: "test@usager1.fr", code: "112233", created_at: 10.minutes.ago, used_at: 8.minutes.ago)
      create(:login_code, email: "test@usager1.fr", code: "223344", created_at: 2.hours.ago)
      create(:login_code, email: "test@usager1.fr", code: "556677", created_at: 1.minute.ago)
      create(:login_code, email: "test@usager1.fr", code: "667788", created_at: 2.minutes.ago)
      create(:login_code, email: "autre@personne.fr", code: "990099", created_at: 30.seconds.ago)
    end

    specify do
      expect(described_class.most_recent_usable_for(email: "test@usager1.fr").code).to eq("556677")
    end
  end

  describe "#set_random_code before_save callback" do
    let(:login_code) { described_class.new(email: "test@usager.fr", domain_id: "RDV_SERVICE_PUBLIC") }

    specify do
      login_code.save
      expect(login_code.reload.code).not_to be_blank
    end
  end
end
