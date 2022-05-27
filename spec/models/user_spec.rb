# frozen_string_literal: true

describe User, type: :model do
  describe "new #add_organisation" do
    it "add new organisation to none" do
      organisation = create(:organisation)
      user = create(:user)
      user.add_organisation(organisation)
      expect(user.reload.organisations).to eq([organisation])
    end

    it "add new organisation to existing one" do
      organisation = create(:organisation)
      existing_organisation = create(:organisation)
      user = create(:user, organisations: [existing_organisation])
      user.add_organisation(organisation)
      expect(user.organisations).to match_array([organisation, existing_organisation])
    end

    it "do not change nothing if organisation already set" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      user.add_organisation(organisation)
      expect(user.reload.organisations).to eq([organisation])
    end

    it "set organisation to relatives" do
      organisation = create(:organisation)
      user = create(:user, organisations: [])
      relative = create(:user, organisations: [], responsible: user)
      user.add_organisation(organisation)
      expect(relative.reload.organisations).to eq([organisation])
    end

    it "set organisation to responsible" do
      organisation = create(:organisation)
      user = create(:user, organisations: [])
      relative = create(:user, organisations: [], responsible: user)
      relative.add_organisation(organisation)
      expect(user.reload.organisations).to eq([organisation])
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

  describe "#soft_delete avec des it" do
    it "and has multiple organisations" do
      orga1 = create(:organisation)
      orga2 = create(:organisation)
      responsible = create(:user, organisations: [orga1, orga2])
      relative = create(:user, responsible: responsible)

      expect(relative.organisations.count).to eq(2)

      responsible.soft_delete(orga1)

      expect(relative.reload.organisations).to eq(responsible.reload.organisations)
      expect(relative.reload.deleted_at).to eq(nil)
    end
  end

  describe "#soft_delete" do
    let(:now) { Time.current }

    context "belongs to multiple organisations" do
      let!(:org1) { create(:organisation) }
      let!(:org2) { create(:organisation) }
      let(:user) { create(:user, organisations: [org1, org2], email: "jean@valjean.fr") }

      context "with organisation given" do
        subject { user.soft_delete(org1) }

        it "removes from org1 only" do
          subject
          expect(user.reload.organisations).not_to include(org1)
          expect(user.reload.organisations).to include(org2)
        end

        it "does not mark user as deleted" do
          subject
          expect(user.deleted_at).to be_nil
          expect(user.email).to eq "jean@valjean.fr"
        end
      end

      context "without a given organisation" do
        subject { user.soft_delete }

        it "removes all orgas and mark user as deleted" do
          subject
          expect(user.reload.organisations).to be_empty
          expect(user.deleted_at).not_to be_nil
          expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        end
      end
    end

    context "belongs to one organisation and with organisation given" do
      let!(:org1) { create(:organisation) }
      let(:user) { create(:user, email: "jean@valjean.fr", organisations: [org1]) }

      it "removes from this orga and mark user as deleted" do
        user.soft_delete(org1)
        expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        expect(user.email).to end_with("deleted.rdv-solidarites.fr")
        expect(user.email_original).to eq("jean@valjean.fr")
        expect(user.organisations).to be_empty
      end
    end

    context "when user is a relative" do
      let(:user) { create(:user, responsible_id: create(:user).id) }

      it "deletes user anyhow" do
        user.soft_delete
        expect(user.organisations).to be_empty
        expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end

    context "when user has a relative" do
      let(:org1) { create(:organisation) }
      let(:user) { create(:user, organisations: [org1]) }
      let!(:relative) { create(:user, responsible: user, organisations: [org1]) }

      it "deletes user and relative" do
        user.soft_delete
        expect(user.organisations).to be_empty
        expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        expect(relative.reload.organisations).to be_empty
        expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end

      context "with given orga" do
        it "deletes user and relative" do
          user.soft_delete(org1)
          expect(user.organisations).to be_empty
          expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
          expect(relative.reload.organisations).to be_empty
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

  describe "#notes_for" do
    it "return notes for user and organisation" do
      organisation = create(:organisation)
      user = create(:user)
      _user_profile = create(:user_profile, user: user, organisation: organisation, notes: "blablabla")
      expect(user.notes_for(organisation)).to eq("blablabla")
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
