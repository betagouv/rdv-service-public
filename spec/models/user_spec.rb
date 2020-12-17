describe User, type: :model do
  describe "#add_organisation" do
    let(:user) { create(:user, organisations: organisations) }
    let(:organisation) { create(:organisation) }

    subject do
      user.add_organisation(organisation)
      user.reload
      relative.reload if defined?(relative)
      responsible.reload if defined?(responsible)
    end

    describe "when organisation is not associated" do
      let(:organisations) { [] }
      it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
    end

    describe "when organisation is associated" do
      let(:organisations) { [organisation] }
      it { expect { subject }.not_to change(user, :organisation_ids) }

      describe "with many organisations" do
        let(:organisations) { [organisation, create(:organisation)] }
        it "should not change organisations" do
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

        it "should remove from org1 only" do
          subject
          expect(user.reload.organisations).not_to include(org1)
          expect(user.reload.organisations).to include(org2)
        end

        it "should not mark user as deleted" do
          subject
          expect(user.deleted_at).to be_nil
          expect(user.email).to eq "jean@valjean.fr"
        end
      end

      context "without a given organisation" do
        subject { user.soft_delete }

        it "should remove all orgas and mark user as deleted" do
          subject
          expect(user.reload.organisations).to be_empty
          expect(user.deleted_at).not_to be_nil
          expect(user.deleted_at).to be_within(5.seconds).of(Time.now)
        end
      end
    end

    context "belongs to one organisation and with organisation given" do
      let!(:org1) { create(:organisation) }
      let(:user) { create(:user, email: "jean@valjean.fr", organisations: [org1]) }

      it "should remove from this orga and mark user as deleted" do
        user.soft_delete(org1)
        expect(user.deleted_at).to be_within(5.seconds).of(Time.now)
        expect(user.email).to end_with("deleted.rdv-solidarites.fr")
        expect(user.email_original).to eq("jean@valjean.fr")
        expect(user.organisations).to be_empty
      end
    end

    context "when user is a relative" do
      let(:user) { create(:user, responsible_id: create(:user).id) }

      it "should delete user anyhow" do
        user.soft_delete
        expect(user.organisations).to be_empty
        expect(user.deleted_at).to be_within(5.seconds).of(Time.now)
      end
    end

    context "when user has a relative" do
      let(:org1) { create(:organisation) }
      let(:user) { create(:user, organisations: [org1]) }
      let!(:relative) { create(:user, responsible: user, organisations: [org1]) }

      it "should delete user and relative" do
        user.soft_delete
        expect(user.organisations).to be_empty
        expect(user.deleted_at).to be_within(5.seconds).of(Time.now)
        expect(relative.reload.organisations).to be_empty
        expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.now)
      end

      context "with given orga" do
        it "should delete user and relative" do
          user.soft_delete(org1)
          expect(user.organisations).to be_empty
          expect(user.deleted_at).to be_within(5.seconds).of(Time.now)
          expect(relative.reload.organisations).to be_empty
          expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.now)
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
    it "should allow saving nested responsible" do
      expect(User.count).to eq(0)
      loulou = User.new(
        first_name: "loulou",
        last_name: "durand",
        responsible_attributes: {
          first_name: "Jean",
          last_name: "durand",
          email: "jean@durand.fr",
          notify_by_sms: false
        }
      )
      loulou.save!
      expect(User.count).to eq(2)
      expect(loulou.responsible).not_to be_nil
      expect(loulou.responsible.first_name).to eq("Jean")
      expect(loulou.responsible.notify_by_sms).to eq(false)
    end
  end

  describe "phone_number formatted normalization" do
    subject { user.phone_number_formatted }
    context "on create" do
      context "no phone number" do
        let!(:user) { create(:user, phone_number: nil) }
        it { should eq(nil) }
      end
      context "blank phone number" do
        let!(:user) { create(:user, phone_number: "") }
        it { should eq(nil) }
      end
      context "valid phone number" do
        let!(:user) { create(:user, phone_number: "01 30 30 40 40") }
        it { should eq("+33130304040") }
      end
      context "invalid phone number" do
        it "should not save" do
          user = build(:user, phone_number: "01 30 20")
          expect(user.save).to be false
        end
      end
    end

    context "on update" do
      context "previous phone number" do
        it "should update it" do
          user = create(:user, phone_number: "01 30 30 40 40")
          expect(user.phone_number_formatted).to eq("+33130304040")
          user.update!(phone_number: "04 300 32020")
          expect(user.phone_number_formatted).to eq("+33430032020")
          user.update!(phone_number: "")
          expect(user.phone_number_formatted).to eq(nil)
        end
      end
    end
  end

  describe "#search_by_text" do
    let!(:user_jean) { create(:user, first_name: "jean", last_name: "moustache", email: "jean@moustache.fr", phone_number: "01 30 30 04 04") }
    let!(:user_patricia) { create(:user, first_name: "patricia", last_name: "duroy", email: "patoche@duroy.fr", phone_number: nil) }
    let!(:user_maurice) { create(:user, first_name: "maurice", last_name: "rhey", email: "mo@mo.lo", phone_number: "0152424242") }
    subject { User.search_by_text(query) }

    context "name query" do
      let(:query) { "patricia" }
      it { should include(user_patricia) }
      it { should_not include(user_jean) }
    end

    context "email query" do
      let(:query) { "patoche@duro" }
      it { should include(user_patricia) }
      it { should_not include(user_jean) }
    end

    context "phone number query" do
      let(:query) { "013030" }
      it { should include(user_jean) }
      it { should_not include(user_patricia) }
      it { should_not include(user_maurice) }
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

  describe "#previous_rdvs" do
    it "return empty array without previous rdv" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      create(:rdv, users: [user])
      expect(user.previous_rdvs(organisation)).to eq([])
    end

    it "return rdv for same user and organisation" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      rdv = create(:rdv, users: [user])
      create(:rdv)
      create(:rdv, users: [user])
      previous_rdv = create(:rdv, starts_at: rdv.starts_at - 1.day, organisation: organisation, users: [user])

      expect(user.previous_rdvs(organisation)).to eq([previous_rdv])
    end

    it "return only 5 last previous rdv order by starts_at desc" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      rdv = create(:rdv, users: [user])

      p4 = create(:rdv, starts_at: rdv.starts_at - 7.day, organisation: organisation, users: [user])
      p5 = create(:rdv, starts_at: rdv.starts_at - 13.day, organisation: organisation, users: [user])
      p1 = create(:rdv, starts_at: rdv.starts_at - 1.day, organisation: organisation, users: [user])
      create(:rdv, starts_at: rdv.starts_at - 16.day, organisation: organisation, users: [user])
      p2 = create(:rdv, starts_at: rdv.starts_at - 2.day, organisation: organisation, users: [user])
      p3 = create(:rdv, starts_at: rdv.starts_at - 4.day, organisation: organisation, users: [user])

      expect(user.previous_rdvs(organisation)).to eq([p1, p2, p3, p4, p5])
    end

    it "returns only past rdv" do
      today = Time.new(2020, 5, 23, 15, 56)
      travel_to(today)
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      rdv = create(:rdv, users: [user], starts_at: today - 2.days)
      past_rdv = create(:rdv, starts_at: rdv.starts_at - 4.days, organisation: organisation, users: [user])
      create(:rdv, starts_at: rdv.starts_at + 4.days, organisation: organisation, users: [user])
      expect(user.previous_rdvs(organisation)).to eq([past_rdv])
    end
  end

  describe "#next_rdvs" do
    it "return empty array without next rdv" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      create(:rdv, users: [user])
      expect(user.next_rdvs(organisation)).to eq([])
    end

    it "return rdv for same user and organisation" do
      today = Time.new(2020, 5, 23, 15, 56)
      travel_to(today)

      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      create(:rdv, users: [user], starts_at: today - 1.day)
      create(:rdv, starts_at: today - 1.day)
      create(:rdv, users: [user], starts_at: today - 2.days)
      next_rdv = create(:rdv, starts_at: today + 1.day, organisation: organisation, users: [user])

      expect(user.next_rdvs(organisation)).to eq([next_rdv])
    end

    it "returns only future rdv including current RDV (from 2 hours)" do
      now = Time.new(2020, 5, 23, 15, 56)
      travel_to(now)

      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      create(:rdv, users: [user], starts_at: now - 1.day)
      create(:rdv, starts_at: now - 4.days, organisation: organisation, users: [user])
      future_rdv = create(:rdv, starts_at: now + 4.days, organisation: organisation, users: [user])
      current_rdv = create(:rdv, starts_at: now - 2.minutes, organisation: organisation, users: [user])

      expect(user.next_rdvs(organisation).sort).to eq([current_rdv, future_rdv].sort)
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
end
