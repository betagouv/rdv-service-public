# frozen_string_literal: true

describe User, type: :model do
  describe "#add_organisation" do
    subject do
      user.add_organisation(organisation)
      user.reload
      relative.reload if defined?(relative)
      responsible.reload if defined?(responsible)
    end

    let(:user) { create(:user, organisations: organisations) }
    let(:organisation) { create(:organisation) }

    describe "when organisation is not associated" do
      let(:organisations) { [] }

      it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
    end

    describe "when organisation is associated" do
      let(:organisations) { [organisation] }

      it { expect { subject }.not_to change(user, :organisation_ids) }

      describe "with many organisations" do
        let(:organisations) { [organisation, create(:organisation)] }

        it "does not change organisations" do
          subject
          expect(organisations).to match_array(user.organisations)
        end
      end
    end

    describe "when responsible has relative" do
      let(:organisations) { [organisation] }

      describe "add organisation to responsible" do
        let!(:user) { create(:user, organisations: []) }
        let!(:relative) { create(:user, organisations: [], responsible_id: user.id) }

        it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
        it { expect { subject }.to change(relative, :organisation_ids).from([]).to([organisation.id]) }
      end

      describe "add organisation to relative" do
        let!(:responsible) { create(:user, organisations: []) }
        let!(:user) { create(:user, organisations: [], responsible_id: responsible.id) }

        it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
        it { expect { subject }.to change(responsible, :organisation_ids).from([]).to([organisation.id]) }
      end
    end
  end

  describe "#set_organisations_from_responsible" do
    it "no changes without responsible" do
      responsive = create(:user, organisations: [create(:organisation), create(:organisation)])
      relative = create(:user, responsible_id: nil)
      expect(relative.organisations).not_to eq(responsive.organisations)
    end

    it "when user is responsible" do
      responsive = create(:user, organisations: [create(:organisation), create(:organisation)])
      relative = create(:user, responsible: responsive)
      expect(relative.organisations.sort).to eq(responsive.organisations.sort)
    end
  end

  describe "#soft_delete" do
    it "change email to a « deleted.rdv-solidarites.fr » domain" do
      user = create(:user, email: "jean@valjean.fr")
      user.soft_delete
      expect(user.email).to end_with("deleted.rdv-solidarites.fr")
    end

    it "keep original email in an other attribute" do
      user = create(:user, email: "jean@valjean.fr")
      user.soft_delete
      expect(user.email_original).to eq("jean@valjean.fr")
    end

    it "set deleted_at to now" do
      user = create(:user)
      user.soft_delete
      expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
    end

    it "hidden user by default" do
      user = create(:user)
      user.soft_delete
      expect(described_class.all).to be_empty
    end

    it "show user with unscoped" do
      user = create(:user)
      user.soft_delete
      expect(described_class.unscoped.all).to eq([user])
    end

    context "belongs to one organisation" do
      it "removes this organisation" do
        organisation = create(:organisation)
        user = create(:user, organisations: [organisation])
        user.soft_delete(organisation)
        expect(user.reload.organisations).to be_empty
      end
    end

    context "belongs to 2 organisations" do
      let(:organisation) { create(:organisation) }
      let(:other_organisation) { create(:organisation) }

      context "with organisation given" do
        context "applied to responsible" do
          it "removes organisation to relative and responsible" do
            responsible = create(:user, organisations: [organisation, other_organisation])
            relative = create(:user, responsible: responsible)

            responsible.soft_delete(organisation)
            expect(relative.reload.organisations).to eq([other_organisation])
            expect(responsible.reload.organisations).to eq([other_organisation])
          end

          it "doesnt mark relative as deleted" do
            responsible = create(:user, organisations: [organisation, other_organisation])
            relative = create(:user, responsible: responsible)

            responsible.soft_delete(organisation)
            expect(relative.reload.deleted_at).to eq(nil)
          end
        end

        it "removes given organisation only" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete(organisation)
          expect(user.reload.organisations).not_to include(organisation)
          expect(user.reload.organisations).to include(other_organisation)
        end

        it "does not mark user as deleted" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete(organisation)
          expect(user.deleted_at).to be_nil
          expect(user.email).to eq "jean@valjean.fr"
        end
      end

      context "without a given organisation" do
        it "removes all organisations and mark user as deleted" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete
          expect(user.reload.organisations).to be_empty
        end

        it "set deleted_at to Time.zone.now" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete
          expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        end
      end
    end

    context "when user is a relative" do
      it "deletes user anyhow" do
        user = create(:user, responsible_id: create(:user).id)
        user.soft_delete
        expect(user.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end

    context "when user has a relative" do
      it "deletes relative" do
        user = create(:user)
        relative = create(:user, responsible: user, organisations: user.organisations)
        user.soft_delete
        expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end

      context "with given organisation" do
        it "deletes relative" do
          organisation = create(:organisation)
          user = create(:user, organisations: [organisation])
          relative = create(:user, responsible: user, organisations: [organisation])
          user.soft_delete(organisation)

          expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        end
      end
    end
  end

  describe "#profile_for" do
    it "renvoie le profile de l'organisation passée en paramètre" do
      profile = create(:user_profile)
      organisation = profile.organisation
      user = profile.user
      expect(user.profile_for(organisation)).to eq(profile)
    end

    it "avec plusieurs organisation, renvoie le profile de l'organisation passé en paramètre" do
      profile = create(:user_profile)
      organisation = profile.organisation
      user = profile.user
      create(:user_profile, user: user)
      expect(user.profile_for(organisation)).to eq(profile)
    end
  end

  describe "responsible_attributes" do
    it "allows saving nested responsible" do
      expect(described_class.count).to eq(0)
      loulou = build(:user, responsible_attributes: attributes_for(:user, first_name: "Jean", notify_by_sms: false))
      loulou.save!
      expect(described_class.count).to eq(2)
      expect(loulou.responsible).not_to be_nil
      expect(loulou.responsible.first_name).to eq("Jean")
      expect(loulou.responsible.notify_by_sms).to eq(false)
    end
  end

  describe "#rdvs_future_without_ongoing" do
    it "return empty array without next rdv" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      create(:rdv, users: [user])
      expect(user.rdvs_future_without_ongoing(organisation)).to eq([])
    end

    it "return rdv for same user and organisation" do
      today = Time.zone.local(2020, 5, 23, 15, 56)

      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])

      travel_to(today - 4.days)
      create(:rdv, users: [user], starts_at: today - 1.day)
      create(:rdv, starts_at: today - 1.day)
      create(:rdv, users: [user], starts_at: today - 2.days)
      next_rdv = create(:rdv, starts_at: today + 1.day, organisation: organisation, users: [user])

      travel_to(today)
      expect(user.rdvs_future_without_ongoing(organisation)).to eq([next_rdv])
      travel_back
    end

    it "returns only future rdv" do
      now = Time.zone.local(2020, 5, 23, 15, 56)

      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])

      travel_to(now - 5.days)
      create(:rdv, users: [user], starts_at: now - 1.day)
      create(:rdv, starts_at: now - 4.days, organisation: organisation, users: [user])
      future_rdv = create(:rdv, starts_at: now + 4.days, organisation: organisation, users: [user])
      travel_to(now)

      expect(user.rdvs_future_without_ongoing(organisation)).to eq([future_rdv])
      travel_back
    end
  end

  # cf https://github.com/heartcombo/devise/wiki/How-To:-Email-only-sign-up
  describe "#set_reset_password_token" do
    it "returns the plaintext token" do
      potential_token = subject.send(:set_reset_password_token)
      potential_token_digest = Devise.token_generator.digest(subject, :reset_password_token, potential_token)
      actual_token_digest = subject.reset_password_token
      expect(potential_token_digest).to eql(actual_token_digest)
    end
  end

  describe "#invitation_period_valid?" do
    subject { user.send(:invitation_period_valid?) }

    let(:invitation_created_at) { Time.zone.parse("2022-04-05 13:00") }
    let(:user) { create(:user, invitation_created_at: invitation_created_at, invite_for: invite_for) }

    before { travel_to(Time.zone.parse("2022-04-05 13:45")) }

    context "when no invitation period is precised" do
      let(:invite_for) { nil }

      it "is valid" do
        expect(subject).to eq(true)
      end
    end

    context "when invitation was created less than invitation period ago" do
      let(:invite_for) { 1.hour.to_i }

      it "is valid" do
        expect(subject).to eq(true)
      end
    end

    context "when invitation was created more than invitation period ago" do
      let(:invite_for) { 30.minutes.to_i }

      it "is not valid" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#minor?" do
    it "return true when user birth in 2016 and we are un 2020" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: Date.new(2016, 5, 30))
      expect(user.minor?).to be true
      travel_back
    end

    it "return false when user birth is 2000 and we are in 2020" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: Date.new(2000, 5, 30))
      expect(user.minor?).to be false
      travel_back
    end

    it "return false when no birthdate" do
      user = build(:user, birth_date: nil)
      expect(user.minor?).to be false
    end
  end

  describe "#can_be_soft_deleted_from_organisation?" do
    let(:organisation) { create(:organisation) }

    it "return true when no rdv for self and relatives" do
      user = create(:user, rdvs: [], organisations: [organisation])
      expect(user.can_be_soft_deleted_from_organisation?(organisation)).to be true
    end

    it "return false when rdv for self" do
      rdv = create(:rdv, organisation: organisation)
      user = create(:user, rdvs: [rdv], organisations: [organisation])
      expect(user.can_be_soft_deleted_from_organisation?(organisation)).to be false
    end

    it "return false when rdv for relatives" do
      rdv = create(:rdv, organisation: organisation)
      responsible = create(:user, rdvs: [], organisations: [organisation])
      relative = create(:user, responsible: responsible, rdvs: [rdv], organisations: [organisation])
      expect(relative.can_be_soft_deleted_from_organisation?(organisation)).to be false
    end
  end
end
