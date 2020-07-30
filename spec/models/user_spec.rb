describe User, type: :model do
  describe "#age" do
    let(:user) { build(:user, birth_date: birth_date) }

    context "born 4 years ago" do
      let(:birth_date) { 4.years.ago }

      it { expect(user.age).to eq("4 ans") }
    end

    context "born 4 years + 1 day ago" do
      let(:birth_date) { 4.years.ago + 1.day }

      it { expect(user.age).to eq("3 ans") }
    end

    context "born 2 months ago" do
      let(:birth_date) { 2.months.ago }

      it { expect(user.age).to eq("2 mois") }
    end

    context "born 23 months ago" do
      let(:birth_date) { 23.months.ago }

      it { expect(user.age).to eq("23 mois") }
    end

    context "born 24 months ago" do
      let(:birth_date) { 24.months.ago }

      it { expect(user.age).to eq("2 ans") }
    end

    context "born 20 days ago" do
      let(:birth_date) { 20.days.ago }

      it { expect(user.age).to eq("20 jours") }
    end
  end

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

    before do
      freeze_time
      relative.reload if defined?(relative)
      subject
    end

    subject do
      user.soft_delete(deleted_org)
      user.reload
    end

    context "belongs to multiple organisations and with organisation given" do
      let(:user) { create(:user, :with_multiple_organisations, email: "jean@valjean.fr") }
      let(:deleted_org) { user.organisations.first }
      it { expect(user.organisations).not_to include(deleted_org) }

      it "remove the correct organisation" do
        left_orgs_ids = Organisation.where.not(id: deleted_org.id).pluck(:id)
        expect(user.organisations.pluck(:id)).to match_array(left_orgs_ids)
      end
      it { expect(user.deleted_at).to be_nil }
      it { expect(user.email).to eq "jean@valjean.fr" }
    end

    context "belongs to one organisation and with organisation given" do
      let(:user) { create(:user, email: "jean@valjean.fr", organisations: [create(:organisation)]) }
      let(:deleted_org) { user.organisations.first }
      it { expect(user.deleted_at).to eq(now) }
      it { expect(user.email).to end_with("deleted.rdv-solidarites.fr") }
      it { expect(user.email_original).to eq("jean@valjean.fr") }
      it { expect(user.organisations).to be_empty }
    end

    context "with no organisation given" do
      let(:user) { create(:user, :with_multiple_organisations) }
      let(:deleted_org) { nil }
      it { expect(user.organisations).to be_empty }
      it { expect(user.deleted_at).not_to be_nil }
      it { expect(user.deleted_at).to eq(now) }
    end

    context "when user is a relative" do
      let(:user) { create(:user, responsible_id: create(:user).id) }
      let(:deleted_org) { nil }

      it { expect(user.organisations).to be_empty }
      it { expect(user.deleted_at).to eq(now) }
    end

    context "when user has a relative" do
      let(:user) { create(:user, organisations: [create(:organisation)]) }
      let!(:relative) { create(:user, responsible: user, organisations: user.organisations) }

      let(:deleted_org) { nil }

      it { expect(user.organisations).to be_empty }
      it { expect(user.deleted_at).to eq(now) }
      it { expect(relative.reload.organisations).to be_empty }
      it { expect(relative.reload.deleted_at).to eq(now) }

      context "and belong to an organisation" do
        let(:deleted_org) { user.organisations.first }

        it { expect(user.organisations).to be_empty }
        it { expect(user.reload.deleted_at).to eq(now) }
        it { expect(relative.reload.organisations).to be_empty }
        it { expect(relative.reload.deleted_at).to eq(now) }
      end
    end
  end

  describe "#available_rdvs(organisation_id)" do
    let!(:organisation1) { create(:organisation) }
    let!(:organisation2) { create(:organisation) }
    let!(:responsible1) { create(:user) }
    let!(:relative1) { create(:user, responsible_id: responsible1.id) }
    let!(:responsible2) { create(:user) }

    before do
      [responsible1, relative1, responsible2].each do |user|
        create(:rdv, users: [user], organisation: organisation1)
        create(:rdv, :excused, users: [user], organisation: organisation1)
      end
      create(:rdv, users: [responsible1, relative1], organisation: organisation1)
    end

    it { expect(responsible1.available_rdvs(organisation1.id).size).to eq(5) }
    it { expect(responsible1.available_rdvs(organisation1.id)).to match_array((responsible1.rdvs + relative1.rdvs).uniq) }
    it { expect(relative1.available_rdvs(organisation1.id)).to match_array relative1.rdvs }
    it { expect(responsible2.available_rdvs(organisation1.id)).to match_array responsible2.rdvs }
    it { expect(responsible1.available_rdvs(organisation2.id)).to be_empty }
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
          email: "jean@durand.fr"
        }
      )
      loulou.save!
      expect(User.count).to eq(2)
      expect(loulou.responsible).not_to be_nil
      expect(loulou.responsible.first_name).to eq("Jean")
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
end
