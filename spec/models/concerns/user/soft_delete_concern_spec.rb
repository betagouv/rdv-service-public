RSpec.describe User::SoftDeleteConcern do
  describe "#soft_delete!" do
    it "change email to a « deleted.rdv-solidarites.fr » domain and anonymises other attributes" do
      user = create(:user, email: "jean@valjean.fr", first_name: "Jean", last_name: "Valjean")
      other_user = create(:user, email: "other_user@test.com")
      user.soft_delete!
      expect(user.email).to end_with("deleted.rdv-solidarites.fr")
      expect(user).to have_attributes(
        first_name: "Usager supprimé",
        last_name: "Usager supprimé"
      )
      expect(user.address).to match %([valeur unique anonymisée \\d+])
      expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)

      # on n'anonymise pas un autre utilisateur
      expect(other_user.reload.email).to eq("other_user@test.com")
    end

    it "anonymizes past RDVs and receipts and deletes versions" do
      rdv = create(:rdv, :past, context: "des détails sur le rdv")
      user = rdv.users.first

      receipt = create(:receipt, user: user, rdv: rdv, sms_phone_number: "0611111111")
      user.soft_delete!

      expect(receipt.reload.sms_phone_number).to match %([valeur unique anonymisée \\d+])
      expect(rdv.reload.context).to match %([valeur unique anonymisée \\d+])
      expect(user.versions).to be_empty
    end

    it "interdit lorsqu’un RDV à venir existe" do
      user = create(:user)
      rdv = create(:rdv, starts_at: 3.days.from_now, users: [user], context: "des détails sur le RDV")
      expect { user.soft_delete! }.to raise_error(StandardError, /RDV à venir/)
      expect(rdv.reload.context).to eq "des détails sur le RDV"
    end

    it "autorise si le RDV à venir est dans une autre orga" do
      user = create(:user)
      orga1, orga2 = create_list(:organisation, 2)
      rdv = create(:rdv, organisation: orga1, starts_at: 3.days.from_now, users: [user])
      expect { user.soft_delete!(orga2) }.not_to raise_error
      expect(rdv.reload.context).to be_nil
    end

    it "n’anonymise pas les RDV collectifs avec d’autres participants" do
      user1 = create(:user)
      user2 = create(:user)
      rdv = create(:rdv, :past, users: [user1, user2], context: "des détails sur le RDV")
      user1.soft_delete!
      expect(rdv.reload.context).to eq("des détails sur le RDV")
      user2.soft_delete!
      expect(rdv.reload.context).to match %([valeur unique anonymisée \\d+])
    end

    it "is hidden user by default" do
      user = create(:user)
      user.soft_delete!
      expect(User.all).to be_empty
    end

    it "show user with unscoped" do
      user = create(:user)
      user.soft_delete!
      expect(User.unscoped.all).to eq([user])
    end

    context "belongs to one organisation" do
      it "removes this organisation" do
        organisation = create(:organisation)
        user = create(:user, organisations: [organisation])
        user.soft_delete!(organisation)
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

            responsible.soft_delete!(organisation)
            expect(relative.reload.organisations).to eq([other_organisation])
            expect(responsible.reload.organisations).to eq([other_organisation])
          end

          it "doesnt mark relative as deleted" do
            responsible = create(:user, organisations: [organisation, other_organisation])
            relative = create(:user, responsible: responsible)

            responsible.soft_delete!(organisation)
            expect(relative.reload.deleted_at).to be_nil
          end
        end

        it "removes given organisation only" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete!(organisation)
          expect(user.reload.organisations).not_to include(organisation)
          expect(user.reload.organisations).to include(other_organisation)
        end

        it "does not mark user as deleted" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete!(organisation)
          expect(user.deleted_at).to be_nil
          expect(user.email).to eq "jean@valjean.fr"
        end
      end

      context "without a given organisation" do
        it "removes all organisations and mark user as deleted" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete!
          expect(user.reload.organisations).to be_empty
        end

        it "set deleted_at to Time.zone.now" do
          user = create(:user, organisations: [organisation, other_organisation], email: "jean@valjean.fr")
          user.soft_delete!
          expect(user.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        end
      end
    end

    context "when user is a relative" do
      it "deletes user anyhow" do
        user = create(:user, responsible_id: create(:user).id)
        user.soft_delete!
        expect(user.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end

    context "when user has a relative" do
      it "deletes relative" do
        user = create(:user)
        relative = create(:user, responsible: user, organisations: user.organisations)
        user.soft_delete!
        expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
      end

      context "with given organisation" do
        it "deletes relative" do
          organisation = create(:organisation)
          user = create(:user, organisations: [organisation])
          relative = create(:user, responsible: user, organisations: [organisation])
          user.soft_delete!(organisation)

          expect(relative.reload.deleted_at).to be_within(5.seconds).of(Time.zone.now)
        end
      end
    end
  end

  describe "#can_be_soft_deleted_from_organisation?" do
    let(:organisation) { create(:organisation) }

    it "return true when no rdv for self and relatives" do
      user = create(:user, organisations: [organisation])
      expect(user.can_be_soft_deleted_from_organisation?(organisation)).to be true
    end

    it "return false when rdv for self" do
      rdv = create(:rdv, organisation: organisation)
      user = create(:user, organisations: [organisation])
      create(:participation, user: user, rdv: rdv)
      expect(user.can_be_soft_deleted_from_organisation?(organisation)).to be false
    end

    it "return false when rdv for relatives" do
      rdv = create(:rdv, organisation: organisation)
      responsible = create(:user, organisations: [organisation])
      relative = create(:user, responsible: responsible, organisations: [organisation])
      create(:participation, user: relative, rdv: rdv)
      expect(relative.can_be_soft_deleted_from_organisation?(organisation)).to be false
    end
  end
end
