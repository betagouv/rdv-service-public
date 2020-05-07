describe Notifications::Rdv::RdvCreatedService, type: :service do
  subject { Notifications::Rdv::RdvCreatedService.perform_with(rdv) }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:rdv) { create(:rdv, starts_at: 3.days.from_now, users: [user1, user2]) }
  # create is necessary for serialization reasons (?)

  it "calls RdvMailer to send email to user" do
    expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1).and_return(double(deliver_later: nil))
    expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2).and_return(double(deliver_later: nil))
    subject
  end

  context "motif with users notifications disabled" do
    let(:motif) { build(:motif, :no_notification) }
    let(:rdv) { create(:rdv, motif: motif, starts_at: 3.days.from_now, users: [user1, user2]) }

    it "should not be called" do
      expect(Users::RdvMailer).not_to receive(:rdv_created)
      subject
    end
  end

  context "when rdv is for a relative" do
    # TODO: this is actually testing the users#user_to_notify method, move it
    let(:responsible) { create(:user) }
    let(:relative) { create(:user, responsible_id: responsible.id) }
    let(:rdv) { create(:rdv, users: [relative], starts_at: 3.days.from_now) }

    it "calls RdvMailer to send email to responsible" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, responsible).and_return(double(deliver_later: nil))
      subject
    end
  end
end
