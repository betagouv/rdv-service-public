describe Notifications::Rdv::RdvCreatedService, type: :service do
  subject { Notifications::Rdv::RdvCreatedService.perform_with(rdv) }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:agent1) { build(:agent) }
  let(:agent2) { build(:agent) }

  context "starts in more than 2 days" do
    let(:rdv) { create_rdv_skip_notify(starts_at: 3.days.from_now, users: [user1, user2], agents: [agent1, agent2]) }
    # create is necessary for serialization reasons (?)

    it "triggers sending mail to users but not to agents" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1).and_return(double(deliver_later: nil))
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2).and_return(double(deliver_later: nil))
      expect(Agents::RdvMailer).not_to receive(:rdv_starting_soon_created)
      subject
      expect(rdv.events.where(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: "created").count).to eq 2
    end
  end

  context "starts today or tomorrow" do
    let(:rdv) { create_rdv_skip_notify(starts_at: 2.hours.from_now, users: [user1, user2], agents: [agent1, agent2]) }

    it "triggers sending mails to both user and agents" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user1).and_return(double(deliver_later: nil))
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, user2).and_return(double(deliver_later: nil))
      expect(Agents::RdvMailer).to receive(:rdv_starting_soon_created).with(rdv, agent1).and_return(double(deliver_later: nil))
      expect(Agents::RdvMailer).to receive(:rdv_starting_soon_created).with(rdv, agent2).and_return(double(deliver_later: nil))
      subject
    end
  end

  context "motif with users notifications disabled" do
    let(:motif) { build(:motif, :no_notification) }
    let(:rdv) { create_rdv_skip_notify(motif: motif, starts_at: 3.days.from_now, users: [user1, user2]) }

    it "should not be called" do
      expect(Users::RdvMailer).not_to receive(:rdv_created)
      subject
    end
  end

  context "when rdv is for a relative" do
    # TODO: this is actually testing the users#user_to_notify method, move it
    let(:responsible) { create(:user) }
    let(:relative) { create(:user, responsible_id: responsible.id) }
    let(:rdv) { create_rdv_skip_notify(users: [relative], starts_at: 3.days.from_now) }

    it "calls RdvMailer to send email to responsible" do
      expect(Users::RdvMailer).to receive(:rdv_created).with(rdv, responsible).and_return(double(deliver_later: nil))
      subject
    end
  end
end
