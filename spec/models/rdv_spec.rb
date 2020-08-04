describe Rdv, type: :model do
  it "a une fabrique valide" do
    expect(build(:rdv)).to be_valid
  end

  describe "#notify_rdv_created" do
    let(:rdv) { build(:rdv, starts_at: 3.days.from_now) }

    it "should be called after create" do
      expect(rdv).to receive(:notify_rdv_created)
      rdv.save!
    end
  end

  describe "#notify_rdv_updated" do
    let(:rdv) { create(:rdv, starts_at: 3.days.from_now) }

    it "should be called after update starts_at" do
      expect(rdv).to receive(:notify_rdv_updated)
      rdv.update!(starts_at: 7.days.from_now)
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
        let(:rdv) { create(:rdv, cancelled_at: 1.hour.ago, starts_at: 5.hours.from_now) }

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

  describe "#soft_delete_for_user" do
    context "rdv with multiple users" do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:rdv) { create(:rdv, users: [user1, user2]) }

      it "should just remove user, not mark rdv as soft deleted" do
        rdv.soft_delete_for_user(user1)
        expect(rdv.deleted_at).to be_nil
        expect(rdv.users).to eq([user2])
      end
    end

    context "rdv with single user" do
      let(:user1) { create(:user) }
      let(:rdv) { create(:rdv, users: [user1]) }

      it "should mark rdv as soft_deleted but leave user" do
        rdv.soft_delete_for_user(user1)
        expect(rdv.deleted_at).not_to be_nil
        expect(rdv.users).to eq([user1])
      end
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
end
