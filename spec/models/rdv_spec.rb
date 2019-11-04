describe Rdv, type: :model do
  let(:agent1) { create(:agent) }
  let(:agent2) { create(:agent) }

  describe '#to_ical_for' do
    let(:rdv) { create(:rdv) }
    let(:user_or_agent) { rdv.users.first }

    subject { rdv.to_ical_for(user_or_agent) }

    it { is_expected.to include("SUMMARY:RDV Michel Lapin <> Vaccination") }
    it { is_expected.to match("DTSTART;TZID=Europe/Paris:20190704T150000") }
    it { is_expected.to include("DTEND;TZID=Europe/Paris:20190704T154500") }
    it { is_expected.to include("SEQUENCE:0") }
    it { is_expected.to include("UID:") }
    it { is_expected.to include("ORGANIZER:noreply@lapins.beta.gouv.fr") }
    it { is_expected.to include("ATTENDEE:#{user_or_agent.email}") }
    it { is_expected.to include("CLASS:PRIVATE") }
    it { is_expected.to include("METHOD:REQUEST") }

    context 'when rdv is cancelled' do
      let(:rdv) { create(:rdv, cancelled_at: Time.zone.now) }
      it { is_expected.to include("STATUS:CANCELLED") }
      it { is_expected.to include("METHOD:CANCEL") }
    end

    context 'when ical is for agent' do
      let(:user_or_agent) { rdv.agents.first }

      it { is_expected.to include("ORGANIZER:noreply@lapins.beta.gouv.fr") }
      it { is_expected.to include("CLASS:PUBLIC") }
    end
  end

  describe "#send_ics_to_users_and_agents" do
    let(:rdv) { build(:rdv, agents: [agent1, agent2]) }

    it "should be called after create" do
      expect(rdv).to receive(:send_ics_to_users_and_agents)
      rdv.save!
    end

    context "when rdv already exist" do
      let(:rdv) { create(:rdv) }

      it "should not be called" do
        expect(rdv).not_to receive(:send_ics_to_users_and_agents)
        rdv.save!
      end
    end

    it "calls RdvMailer to send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
      rdv.save!
    end

    it "calls RdvMailer to send email to agents" do
      expect(RdvMailer).to receive(:send_ics_to_agent).with(rdv, agent1).and_return(double(deliver_later: nil))
      expect(RdvMailer).to receive(:send_ics_to_agent).with(rdv, agent2).and_return(double(deliver_later: nil))

      rdv.save!
    end
  end

  describe "#update_ics_to_user_and_agents" do
    let(:rdv) { build(:rdv, agents: [agent1, agent2]) }

    it "should not be called after create" do
      expect(rdv).not_to receive(:update_ics_to_user_and_agents)
      rdv.save!
    end

    context "when rdv already exist" do
      let(:rdv) { create(:rdv) }

      it "should not be called if there is no change" do
        expect(rdv).not_to receive(:update_ics_to_user_and_agents)
        rdv.save!
      end

      context "and starts_at changed" do
        let!(:old_starts_at) { rdv.starts_at }
        before { rdv.starts_at = 2.days.from_now }

        it "should be called if starts_at changed" do
          expect(rdv).to receive(:update_ics_to_user_and_agents)
          rdv.save!
        end

        it "should increment sequence" do
          expect { rdv.save! }.to change { rdv.sequence }.from(0).to(1)
        end

        it "Send email to user" do
          expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, rdv.users.first, old_starts_at.to_s).and_return(double(deliver_later: nil))
          rdv.save!
        end
      end
    end
  end

  describe "#cancel" do
    let(:rdv) { create(:rdv) }
    let(:now) { Time.current }

    subject { rdv.cancel }

    before { freeze_time }
    after { travel_back }

    it "should set cancelled_at" do
      expect { subject }.to change { rdv.cancelled_at }.from(nil).to(now)
    end

    it "should increment sequence" do
      expect { subject }.to change { rdv.sequence }.from(0).to(1)
    end

    it "Send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, rdv.users.first, nil).and_return(double(deliver_later: nil))
      subject
    end
  end

  describe "#associate_users_with_organisation" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }
    let(:rdv) { build(:rdv, users: [user], organisation: create(:organisation)) }

    subject do
      rdv.save
      user.reload
    end

    it "expect .save to trigger #associate_users_with_organisation" do
      expect(rdv).to receive(:associate_users_with_organisation)
      subject
    end

    it "expect .save link user to organisation" do
      expect { subject }.to change(user, :organisation_ids).from([organisation.id]).to([organisation.id, rdv.organisation_id])
    end
  end
end
