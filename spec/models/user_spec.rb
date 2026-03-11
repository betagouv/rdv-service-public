RSpec.describe User, type: :model do
  describe ".fiches_for_email" do
    let!(:user_email)  { create(:user, email: "test@example.fr", notification_email: nil) }
    let!(:user_notif)  { create(:user, email: nil, notification_email: "test@example.fr") }
    let!(:user_other)  { create(:user, email: "other@example.fr", notification_email: nil) }

    it "retourne les fiches dont l'email correspond" do
      expect(described_class.fiches_for_email("test@example.fr")).to contain_exactly(user_email, user_notif)
    end

    it "ne retourne pas les fiches sans lien avec l'email" do
      expect(described_class.fiches_for_email("test@example.fr")).not_to include(user_other)
    end
  end

  describe ".loginable_by_code_for_email" do
    let!(:user_normal) { create(:user, email: "test@example.fr") }
    let!(:user_sso)    { create(:user, email: nil, notification_email: "test@example.fr", franceconnect_openid_sub: "abc123") }

    it "exclut les fiches connectées via SSO" do
      expect(described_class.loginable_by_code_for_email("test@example.fr")).to contain_exactly(user_normal)
    end
  end

  describe ".loginable_by_code_for_email_in_territory_or_without_territory" do
    let!(:territory_1)    { create(:territory) }
    let!(:territory_2)    { create(:territory) }
    let!(:orga_1)         { create(:organisation, territory: territory_1) }
    let!(:orga_2)         { create(:organisation, territory: territory_2) }
    let!(:user_in)        { create(:user, email: "test@example.fr", organisations: [orga_1]) }
    let!(:user_out)       { create(:user, email: nil, notification_email: "test@example.fr", organisations: [orga_2]) }
    let!(:user_no_org)    { create(:user, email: nil, notification_email: "test@example.fr") }
    let!(:user_sso)       { create(:user, email: nil, notification_email: "test@example.fr", franceconnect_openid_sub: "abc123", organisations: [orga_1]) }

    it "retourne les fiches du territoire donné et les fiches sans territoire, en excluant le SSO" do
      expect(described_class.loginable_by_code_for_email_in_territory_or_without_territory("test@example.fr", territory_id: territory_1.id)).to contain_exactly(user_in, user_no_org)
    end
  end

  describe "#names_differ_from?" do
    let(:user) { build(:user, first_name: "Alice", last_name: "Dupont") }

    it "retourne false si les noms correspondent" do
      expect(user.names_differ_from?(first_name: "Alice", last_name: "Dupont")).to be false
    end

    it "retourne true si le prénom diffère" do
      expect(user.names_differ_from?(first_name: "Bob", last_name: "Dupont")).to be true
    end

    it "retourne true si le nom diffère" do
      expect(user.names_differ_from?(first_name: "Alice", last_name: "Martin")).to be true
    end

    it "retourne false si les noms passés sont vides" do
      expect(user.names_differ_from?(first_name: "", last_name: "")).to be false
    end
  end

  describe ".create_from_login_code!" do
    let(:login_code) { build(:login_code, email: "new@example.fr", first_name: "Alice", last_name: "Dupont") }

    it "crée un usager avec les attributs du login code" do
      user = described_class.create_from_login_code!(email: "new@example.fr", login_code:)
      expect(user).to be_persisted
      expect(user.email).to eq("new@example.fr")
      expect(user.first_name).to eq("Alice")
      expect(user.last_name).to eq("Dupont")
      expect(user.created_through).to eq("auto_through_login")
    end
  end

  describe "#email=" do
    it %(automatically fixes ".@" typo) do
      expect(described_class.new(email: "francis.@exemple.fr").email).to eq("francis@exemple.fr")
    end

    it %(automatically fixes ".." typo) do
      expect(described_class.new(email: "francis..factice@exemple.fr").email).to eq("francis.factice@exemple.fr")
    end
  end

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
      expect(relative.organisations).to match_array(responsive.organisations)
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
      expect(loulou.responsible.notify_by_sms).to be(false)
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
    end
  end

  describe "#minor?" do
    it "return true when user birth in 2016 and we are un 2020" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: Date.new(2016, 5, 30))
      expect(user.minor?).to be true
    end

    it "return false when user birth is 2000 and we are in 2020" do
      now = Time.zone.parse("2020-4-3 13:45")
      travel_to(now)
      user = build(:user, birth_date: Date.new(2000, 5, 30))
      expect(user.minor?).to be false
    end

    it "return false when no birthdate" do
      user = build(:user, birth_date: nil)
      expect(user.minor?).to be false
    end
  end

  describe "#responsible" do
    it "can't be a relative to the user" do
      parent = create(:user)
      child = create(:user, responsible: parent)
      expect { parent.update!(responsible: child) }.to raise_error(ActiveRecord::RecordInvalid, /L'usager⋅e ne peut être responsable de son propre responsable/)
    end
  end

  describe "#ants_pre_demande_number" do
    it "accepts lowercase letters, but normalizes them to uppercase" do
      user = create(:user)
      user.ants_pre_demande_number = "abcde12345"
      expect(user).to be_valid
      user.save
      expect(user.reload.ants_pre_demande_number).to eq "ABCDE12345"
    end
  end

  describe "annotations" do
    it "provides the #annotate! helper method" do
      user = create(:user)
      territory = create(:territory)
      expect(Annotation).to receive(:upsert!).with("Ma remarque", user:, territory:)
      user.annotate!("Ma remarque", territory:)
    end

    it "deletes annotations when leaving the last org of a territory" do
      territory_a = create(:territory)
      territory_b = create(:territory)
      organisation_a_1 = create(:organisation, territory: territory_a)
      organisation_a_2 = create(:organisation, territory: territory_a)
      organisation_b_1 = create(:organisation, territory: territory_b)
      organisation_b_2 = create(:organisation, territory: territory_b)

      user = create(:user, organisations: [organisation_a_1, organisation_a_2, organisation_b_1, organisation_b_2])
      user.annotate!("Infos du territoire A", territory: territory_a)
      user.annotate!("Infos du territoire B", territory: territory_b)
      expect(Annotation.where(user: user).count).to eq(2)

      expect { user.organisations.delete(organisation_a_1) }.not_to change(Annotation, :count)
      expect { user.organisations.delete(organisation_a_2) }.to change(Annotation, :count).by(-1)

      expect { user.organisations.delete(organisation_b_1) }.not_to change(Annotation, :count)
      expect { user.organisations.delete(organisation_b_2) }.to change(Annotation, :count).by(-1)
    end

    it "deletes annotations when soft deleting" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      user.annotate!("Ma remarque", territory: organisation.territory)
      expect { user.soft_delete! }.to change { user.annotations.count }.to(0)
    end
  end

  describe "when notification_email is not valid" do
    it "does not allow invalid email with single letter domain name" do
      user = build(:user, :without_devise_email, notification_email: "test@domain.a")
      expect(user).not_to be_valid
      expect(user.errors[:notification_email]).to include("n'est pas valide")
    end

    it "does not allow invalid email that starts with a dot" do
      user = build(:user, :without_devise_email, notification_email: ".test@domain.com")
      expect(user).not_to be_valid
      expect(user.errors[:notification_email]).to include("n'est pas valide")
    end
  end

  describe "#domain" do
    context "when user has no RDV" do
      let(:user) { create(:user) }

      context "on the RDV Solidarités instance" do
        stub_env_with(DEFAULT_DOMAIN_IS_RDV_SOLIDARITES: "true")

        it "uses RDV_SOLIDARITES" do
          expect(user.domain).to eq(Domain::RDV_SOLIDARITES)
        end
      end

      context "on another instance" do
        stub_env_with(DEFAULT_DOMAIN_IS_RDV_SOLIDARITES: nil)

        it "uses RDV Service Public" do
          expect(user.domain).to eq(Domain::RDV_SERVICE_PUBLIC)
        end
      end
    end

    context "when user only has RDV Solidarités rdvs" do
      let!(:organisation) { create(:organisation, verticale: :rdv_solidarites) }
      let!(:user) { create(:user) }
      let!(:rdvs) { create_list(:rdv, 2, organisation: organisation, users: [user]) }

      it "uses RDV_SOLIDARITES" do
        expect(user.domain).to eq(Domain::RDV_SOLIDARITES)
      end
    end

    context "when user has some rdvs" do
      let!(:user) { create(:user) }
      let!(:rdvs) { create_list(:rdv, 2, organisation: organisation, users: [user]) }

      context "in a RDV Insertion organisation" do
        let!(:organisation) { create(:organisation, verticale: :rdv_insertion) }

        it "uses RDV_SOLIDARITES" do
          expect(user.domain).to eq(Domain::RDV_SOLIDARITES)
        end
      end

      context "in a RDV Aide Numerique organisation" do
        let!(:organisation) { create(:organisation, verticale: :rdv_aide_numerique) }

        it "uses RDV_AIDE_NUMERIQUE" do
          expect(user.domain).to eq(Domain::RDV_AIDE_NUMERIQUE)
        end
      end

      context "in a RDV Mairie organisation" do
        let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }

        it "uses RDV_SERVICE_PUBLIC" do
          expect(user.domain).to eq(Domain::RDV_SERVICE_PUBLIC)
        end
      end
    end

    context "when user has mixed RDV domains and most recent is rdv_aide_numerique" do
      let!(:user) { create(:user) }
      let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
      let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_insertion) }
      let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_aide_numerique) }
      let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
      let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
      let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

      it "uses the domain of the most recently created rdv" do
        expect(user.domain).to eq(Domain::RDV_AIDE_NUMERIQUE)
      end
    end

    context "when user has mixed RDV domains and most recent is rdv_solidarites" do
      let!(:user) { create(:user) }
      let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_aide_numerique) }
      let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_insertion) }
      let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
      let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
      let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
      let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

      it "uses the domain of the most recently created rdv" do
        expect(user.domain).to eq(Domain::RDV_SOLIDARITES)
      end
    end

    context "when user has mixed RDV domains and most recent is rdv_insertion" do
      let!(:user) { create(:user) }
      let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
      let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_aide_numerique) }
      let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_insertion) }
      let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
      let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
      let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

      it "uses the domain of the most recently created rdv" do
        expect(user.domain).to eq(Domain::RDV_SOLIDARITES)
      end
    end
  end
end
