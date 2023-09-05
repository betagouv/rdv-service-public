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

  describe "#remove_from_organisation!" do
    context "belongs to one organisation" do
      it "destroys the user" do
        organisation = create(:organisation)
        user = create(:user, organisations: [organisation])
        user.remove_from_organisation!(organisation)
        expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
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

            responsible.remove_from_organisation!(organisation)
            expect(relative.reload.organisations).to eq([other_organisation])
            expect(responsible.reload.organisations).to eq([other_organisation])
          end

          it "doesnt delete relative" do
            responsible = create(:user, organisations: [organisation, other_organisation])
            relative = create(:user, responsible: responsible)

            responsible.remove_from_organisation!(organisation)
            expect(relative.reload).not_to be_destroyed
          end
        end

        it "removes given organisation only" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.remove_from_organisation!(organisation)
          expect(user.reload.organisations).not_to include(organisation)
          expect(user.reload.organisations).to include(other_organisation)
        end

        it "does not delete the user" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.remove_from_organisation!(organisation)
          expect(user.reload.email).to eq "jean@valjean.fr"
        end
      end
    end

    context "when user is a relative" do
      it "deletes user anyhow" do
        org = create(:organisation)
        user = create(:user, organisations: [org], responsible: create(:user, organisations: [org]))
        user.remove_from_organisation!(user.organisations.first)
        expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user has a relative" do
      it "deletes relative" do
        org = create(:organisation)
        user = create(:user, organisations: [org])
        relative = create(:user, responsible: user, organisations: [org])
        user.remove_from_organisation!(org)
        expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { relative.reload }.to raise_error(ActiveRecord::RecordNotFound)
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
    let(:user) { create(:user, invitation_created_at: invitation_created_at) }

    before { travel_to(Time.zone.parse("2022-04-05 13:45")) }

    it "is valid" do
      expect(subject).to eq(true)
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

  describe "#can_be_removed_from_organisation?" do
    let(:organisation) { create(:organisation) }

    it "return true when no rdv for self and relatives" do
      user = create(:user, organisations: [organisation])
      expect(user.can_be_removed_from_organisation?(organisation)).to be true
    end

    it "return false when rdv for self" do
      rdv = create(:rdv, organisation: organisation)
      user = create(:user, organisations: [organisation])
      create(:rdvs_user, user: user, rdv: rdv)
      expect(user.can_be_removed_from_organisation?(organisation)).to be false
    end

    it "return false when rdv for relatives" do
      rdv = create(:rdv, organisation: organisation)
      responsible = create(:user, organisations: [organisation])
      relative = create(:user, responsible: responsible, organisations: [organisation])
      create(:rdvs_user, user: relative, rdv: rdv)
      expect(relative.can_be_removed_from_organisation?(organisation)).to be false
    end
  end
end
