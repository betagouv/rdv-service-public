describe Rdv, type: :model do
  it "a une fabrique valide" do
    expect(build(:rdv)).to be_valid
  end

  describe "#notify_rdv_created" do
    let(:rdv) { build(:rdv, starts_at: 3.days.from_now) }

    it "should be called after create" do
      expect(Notifications::Rdv::RdvCreatedService).to receive(:perform_with).with(rdv)
      expect(Notifications::Rdv::RdvDateUpdatedService).not_to receive(:perform_with)
      expect(Notifications::Rdv::RdvCancelledService).not_to receive(:perform_with)
      rdv.save!
    end
  end

  describe "#notify_rdv_date_updated" do
    let!(:rdv) { create(:rdv, starts_at: 3.days.from_now) }

    it "should be called after update starts_at" do
      expect(Notifications::Rdv::RdvCreatedService).not_to receive(:perform_with)
      expect(Notifications::Rdv::RdvDateUpdatedService).to receive(:perform_with).with(rdv)
      expect(Notifications::Rdv::RdvCancelledService).not_to receive(:perform_with)
      rdv.update!(starts_at: 7.days.from_now)
    end
  end

  describe "#notify_rdv_cancelled" do
    let!(:rdv) { create(:rdv, status: :unknown, starts_at: 3.days.from_now) }

    it "should be called after update starts_at" do
      expect(Notifications::Rdv::RdvCreatedService).not_to receive(:perform_with)
      expect(Notifications::Rdv::RdvDateUpdatedService).not_to receive(:perform_with)
      expect(Notifications::Rdv::RdvCancelledService).to receive(:perform_with).with(rdv)
      rdv.update!(status: :excused)
    end
  end

  describe "#cancellable?" do
    let(:now) { Time.current }

    subject { rdv.cancellable? }

    before { travel_to(now) }
    after { travel_back }

    context "when Rdv starts in 5 hours" do
      let(:rdv) { create(:rdv, starts_at: 5.hours.from_now) }

      it { expect(subject).to eq(true) }

      context "but is already cancelled" do
        let(:rdv) { create(:rdv, cancelled_at: DateTime.parse("2020-07-30 10:30").in_time_zone, starts_at: 5.hours.from_now) }

        it { expect(subject).to eq(false) }
      end
    end

    context "when Rdv starts in 4 hours" do
      let(:rdv) { create(:rdv, starts_at: 4.hours.from_now) }

      it { expect(subject).to eq(false) }
    end
  end

  describe "#associate_users_with_organisation" do
    let(:organisation) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }
    let!(:rdv) { build(:rdv, users: [user], organisation: organisation2) }

    subject do
      rdv.save
      user.reload
    end

    it "expect .save to trigger #associate_users_with_organisation" do
      expect(rdv).to receive(:associate_users_with_organisation)
      subject
    end

    it "expect .save link user to organisation" do
      expect { subject }.to change { user.organisation_ids.sort }.from([organisation.id]).to([organisation.id, rdv.organisation_id].sort)
    end

    describe "when user is already associated to organisation" do
      let(:user) { create(:user, organisations: [organisation, organisation2]) }

      it "does not change anything" do
        expect { subject }.not_to raise_error
        expect { subject }.not_to change(user, :organisation_ids)
      end
    end
  end

  describe "valid?" do
    let(:rdv) { build(:rdv, users: users) }
    let(:user_without_email) { create(:user, :with_no_email) }

    subject { rdv.save! }

    context "with a user with no email" do
      let(:users) { [User.find(user_without_email.id)] }

      it do
        rdv.save
        expect(rdv.valid?).to eq(true)
      end
    end
  end

  describe "#address" do
    subject { rdv.address }

    context "when rdv is in public_office" do
      let(:rdv) { create(:rdv) }

      it { should be rdv.lieu.address }
    end

    context "when rdv is at home" do
      let(:responsible) { create(:user) }
      let(:child) { create(:user, responsible: responsible) }
      let(:rdv) { create(:rdv, :at_home, users: [child]) }

      it { should eq responsible.address }
    end

    context "when rdv is by phone" do
      let(:responsible) { create(:user) }
      let(:child) { create(:user, responsible: responsible) }
      let(:rdv) { create(:rdv, :by_phone, users: [child]) }

      it { should be_blank }
    end
  end

  describe "#adress_complete_without_personnal_details" do
    it "return nothing for a phone rdv" do
      rdv = build(:rdv, :by_phone)
      expect(rdv.address_complete_without_personnal_details).to eq("Par téléphone")
    end

    it "return mds address for a public_office rdv" do
      lieu = build(:lieu, address: "16 rue de l'adresse 12345 Ville", name: "PMI centre ville")
      rdv = build(:rdv, motif: build(:motif, :at_public_office), lieu: lieu)
      expect(rdv.address_complete_without_personnal_details).to eq("PMI centre ville (16 rue de l'adresse 12345 Ville)")
    end

    # TODO: retourner la ville quand les adresses seront enregistrees plus proprement
    it "return only city for a at_home rdv"

    it "return nothing for a at_home rdv" do
      user = build(:user, address: "3 rue de l'églie 75020 Paris")
      rdv = build(:rdv, motif: build(:motif, :at_home), users: [user])
      expect(rdv.address_complete_without_personnal_details).to eq("À domicile")
    end
  end

  describe "#destroy" do
    let!(:rdv) { create(:rdv) }
    let!(:rdv_event) { create(:rdv_event, rdv: rdv) }
    it "should work" do
      expect { rdv.destroy }.to change { Rdv.count }.by(-1)
    end
  end

  describe "#with_lieu" do
    it "return lieu's RDV only" do
      organisation = create(:organisation)
      lieu = create(:lieu, organisation: organisation)
      other_lieu = create(:lieu, organisation: organisation)
      rdv = create(:rdv, :future, lieu: lieu, organisation: organisation)
      create(:rdv, :future, lieu: other_lieu, organisation: organisation)

      expect(Rdv.with_lieu(lieu).to_a).to eq([rdv])
    end
  end

  describe "Rdv.with_user_in" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:rdv1) { create(:rdv, users: [user1, user2]) }
    let!(:rdv2) { create(:rdv, users: [user2]) }
    let!(:rdv3) { create(:rdv, users: [user3]) }

    it "should retrieve rdv, contrarily to where(users:)" do
      expect(Rdv.where(users: [user1, user2])).to be_empty
      expect(Rdv.with_user_in([user1, user2])).to include(rdv1)
      expect(Rdv.with_user_in([user1, user2])).to include(rdv2)
      expect(Rdv.with_user_in([user1, user2])).not_to include(rdv3)
    end
  end

  describe "#temporal_status" do
    it "return status when not unknown" do
      rdv = build(:rdv, status: "waiting")
      expect(rdv.temporal_status).to eq("waiting")
      rdv = build(:rdv, status: "seen")
      expect(rdv.temporal_status).to eq("seen")
      rdv = build(:rdv, status: "excused")
      expect(rdv.temporal_status).to eq("excused")
      rdv = build(:rdv, status: "notexcused")
      expect(rdv.temporal_status).to eq("notexcused")
    end

    it "return unknown_future" do
      today = Time.new(2020, 3, 23, 14, 54)
      travel_to(today)
      rdv = build(:rdv, status: "unknown", starts_at: today + 1.hour)
      expect(rdv.temporal_status).to eq("unknown_future")
    end

    it "return unknown_past" do
      today = Time.new(2020, 3, 23, 14, 54)
      travel_to(today)
      rdv = build(:rdv, status: "unknown", starts_at: today - 1.minute)
      expect(rdv.temporal_status).to eq("unknown_past")
    end
  end

  describe "#possible_temporal_statuses" do
    it "returns `unknown_future` and `excused` before rdv's day" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      rdv = build(:rdv, starts_at: (now + 2.days))
      expect(rdv.possible_temporal_statuses).to eq(["unknown_future", "excused"])
    end

    it "returns `unknonw_future`, `waiting` and `excused` at rdv's day before rdv's time" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      expected = %w[unknown_future waiting excused]
      rdv = build(:rdv, starts_at: now + 4.minutes)
      expect(rdv.possible_temporal_statuses).to eq(expected)
    end

    it "returns `unknonw_past`, `seen`, `notexcused` and `excused` at rdv's day after rdv's time" do
      now = DateTime.new(2020, 3, 23, 12, 46)
      travel_to(now)
      expected = %w[unknown_past seen notexcused excused]
      rdv = build(:rdv, starts_at: now - 2.minutes)
      expect(rdv.possible_temporal_statuses).to eq(expected)
    end
  end

  describe "#visible" do
    it "don't return rdv with invisible motif" do
      motif = create(:motif, :invisible)
      create(:rdv, motif: motif)
      expect(Rdv.visible).to contain_exactly
    end

    it "return rdv with visible and notified motif" do
      motif = create(:motif, :visible_and_notified)
      rdv = create(:rdv, motif: motif)
      expect(Rdv.visible).to contain_exactly(rdv)
    end

    it "return rdv with visible and not notified motif" do
      motif = create(:motif, :visible_and_not_notified)
      rdv = create(:rdv, motif: motif)
      expect(Rdv.visible).to contain_exactly(rdv)
    end
  end

  describe "#for_today" do
    it "return empty array when no rdv" do
      expect(Rdv.for_today).to be_empty
    end

    it "return [rdv] when one rdv for today" do
      now = Time.zone.parse("2020/12/23 12:30")
      travel_to(now)
      rdv = create(:rdv, starts_at: now)
      expect(Rdv.for_today).to eq([rdv])
    end

    it "return ONLY the daily rdv" do
      now = Time.zone.parse("2020/12/23 12:30")
      travel_to(now)
      create(:rdv, starts_at: now - 2.days)
      rdv = create(:rdv, starts_at: now)
      create(:rdv, starts_at: now + 1.days)

      expect(Rdv.for_today).to eq([rdv])
    end
  end

  describe "Rdv.ongoing" do
    context "without time_margin" do
      subject { Rdv.ongoing }

      context "rdv ongoing" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now - 30.minutes, duration_in_min: 45) }
        it { should include(rdv) }
      end

      context "rdv finished shortly before" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now - 30.minutes, duration_in_min: 15) }
        it { should_not include(rdv) }
      end

      context "rdv starting shortly after" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now + 30.minutes, duration_in_min: 15) }
        it { should_not include(rdv) }
      end
    end

    context "with 1 hour time_margin" do
      subject { Rdv.ongoing(time_margin: 1.hour) }

      context "rdv ongoing" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now - 30.minutes, duration_in_min: 45) }
        it { should include(rdv) }
      end

      context "rdv finished shortly before" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now - 30.minutes, duration_in_min: 15) }
        it { should include(rdv) }
      end

      context "rdv finished long before" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now - 2.hours, duration_in_min: 15) }
        it { should_not include(rdv) }
      end

      context "rdv starting shortly after" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now + 30.minutes, duration_in_min: 15) }
        it { should include(rdv) }
      end

      context "rdv starting long after" do
        let!(:rdv) { create(:rdv, starts_at: Time.zone.now + 2.hours, duration_in_min: 15) }
        it { should_not include(rdv) }
      end
    end
  end

  describe "#starts_at_in_range" do
    it "return rdv that starts in range" do
      now = Time.zone.parse("2020-10-14 11h30")
      travel_to(now)
      rdv = create(:rdv, starts_at: now + 1.day + 3.hours)
      create(:rdv, starts_at: now + 2.day + 3.hours)
      create(:rdv, starts_at: now - 1.day)
      expect(Rdv.starts_at_in_range((now + 1.day)..(now + 2.day))).to eq([rdv])
      travel_back
    end
  end
end
