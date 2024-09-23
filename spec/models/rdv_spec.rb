RSpec.describe Rdv, type: :model do
  describe "starts_at realistic validations" do
    context "starts_at before 2018" do
      let(:rdv) { build(:rdv, starts_at: Date.new(2017, 12, 24)) }

      it "should be invalid" do
        expect(rdv).to be_invalid
        expect(rdv.errors.full_messages).to include("L’horaire du RDV ne peut pas être avant 2018")
      end
    end

    context "starts_at more than 5 years from now" do
      let(:rdv) { build(:rdv, starts_at: Date.new(2100, 12, 24)) }

      it "should be invalid" do
        expect(rdv).to be_invalid
        expect(rdv.errors.full_messages).to include("L’horaire du RDV ne peut pas être dans plus de 5 ans")
      end
    end

    context "starts_at is reasonable" do
      let(:rdv) { build(:rdv, starts_at: Date.new(2020, 12, 24)) }

      it "should be valid" do
        expect(rdv).to be_valid
      end
    end
  end

  describe "#duration_is_plausible" do
    let(:now) { Time.zone.parse("2021-05-03 14h00") }

    before { travel_to now }

    it "valid with starts_at < ends_at" do
      rdv = build(:rdv, starts_at: now + 5.hours, ends_at: now + 5.hours + 30.minutes)
      expect(rdv).to be_valid
    end

    it "invalid with starts_at nil" do
      rdv = build(:rdv, starts_at: nil, ends_at: now + 5.hours + 30.minutes)
      expect(rdv).to be_invalid
    end

    it "invalid with ends_at nil" do
      rdv = build(:rdv, starts_at: now + 5.hours, ends_at: nil)
      expect(rdv).to be_invalid
    end

    it "invalid with starts_at == ends_at" do
      rdv = build(:rdv, starts_at: now + 5.hours, ends_at: now + 5.hours)
      expect(rdv).to be_invalid
    end

    it "invalid with starts_at > ends_at" do
      rdv = build(:rdv, starts_at: now + 5.hours, ends_at: now + 4.hours)
      expect(rdv).to be_invalid
    end
  end

  describe "#cancellable_by_user?" do
    let(:now) { Time.zone.parse("2021-05-03 14h00") }
    let(:rdv) { build :rdv, starts_at: starts_at, motif: motif }
    let(:starts_at) { now + 5.hours }
    let(:motif) { build(:motif, rdvs_cancellable_by_user: true) }

    before { travel_to(now) }

    context "when Rdv starts in more than 4 hours" do
      it { expect(rdv.cancellable_by_user?).to be(true) }
    end

    context "when Rdv starts in 4 hours or less" do
      let(:starts_at) { now + 4.hours }

      it { expect(rdv.cancellable_by_user?).to be(false) }
    end

    context "when it is already cancelled" do
      let(:rdv) { build(:rdv, status: "excused", starts_at: starts_at, motif: motif) }

      it { expect(rdv.cancellable_by_user?).to be(false) }
    end

    context "when it is collectif" do
      let(:motif) { build(:motif, collectif: true) }

      it { expect(rdv.cancellable_by_user?).to be(false) }
    end

    context "when the rdvs are set as not cancellable by the user in the motif" do
      let(:motif) { build(:motif, rdvs_cancellable_by_user: false) }

      it { expect(rdv.cancellable_by_user?).to be(false) }
    end
  end

  describe "#editable_by_user?" do
    let(:now) { Time.zone.parse("2021-05-03 14h00") }
    let(:user) { create(:user) }
    let(:rdv) { build :rdv, starts_at: starts_at, motif: motif, created_by: user }
    let(:starts_at) { now + 3.days }
    let(:motif) { build(:motif, rdvs_editable_by_user: true) }

    before { travel_to(now) }

    context "when Rdv starts in more than 2 days" do
      it { expect(rdv.editable_by_user?).to be(true) }
    end

    context "when Rdv starts in 2 days or less" do
      let(:starts_at) { now + 2.days }

      it { expect(rdv.editable_by_user?).to be(false) }
    end

    context "when it is already cancelled" do
      let(:rdv) { build(:rdv, status: "excused", starts_at: starts_at, motif: motif, created_by: user) }

      it { expect(rdv.editable_by_user?).to be(false) }
    end

    context "when it is collectif" do
      let(:motif) { build(:motif, collectif: true) }

      it { expect(rdv.editable_by_user?).to be(false) }
    end

    context "when the rdvs are set as not cancellable by the user in the motif" do
      let(:motif) { build(:motif, rdvs_editable_by_user: false) }

      it { expect(rdv.editable_by_user?).to be(false) }
    end

    context "when the motif is not reservable online" do
      let(:motif) { build(:motif, bookable_by: :agents) }

      it { expect(rdv.editable_by_user?).to be(false) }
    end

    context "when the rdv is created by an agent" do
      let(:agent) { create(:agent) }
      let(:rdv) { build(:rdv, created_by: agent, starts_at: starts_at, motif: motif) }

      it { expect(rdv.editable_by_user?).to be(false) }
    end
  end

  describe "#associate_users_with_organisation" do
    let(:organisation) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }

    it "expect .save to trigger #associate_users_with_organisation" do
      rdv = build(:rdv, users: [user], organisation: organisation2)
      expect(rdv).to receive(:associate_users_with_organisation)
      rdv.save
    end

    it "expect .save link user to organisation" do
      rdv = build(:rdv, users: [user], organisation: organisation2)
      expect do
        rdv.save
      end.to change { user.organisation_ids.sort }.from([organisation.id]).to([organisation.id, rdv.organisation_id].sort)
    end

    describe "when user is already associated to organisation" do
      let(:user) { create(:user, organisations: [organisation, organisation2]) }

      it "does not change anything" do
        rdv = build(:rdv, users: [user], organisation: organisation2)
        expect do
          rdv.save
        end.not_to change(user, :organisation_ids)
      end
    end
  end

  describe "#address" do
    subject { rdv.address }

    context "when rdv is in public_office" do
      let(:rdv) { create(:rdv) }

      it { is_expected.to be rdv.lieu.address }
    end

    context "when rdv is at home" do
      let(:responsible) { create(:user) }
      let(:child) { create(:user, responsible: responsible) }
      let(:rdv) { create(:rdv, :at_home, users: [child]) }

      it { is_expected.to eq responsible.address }
    end

    context "when rdv is by phone" do
      let(:responsible) { create(:user) }
      let(:child) { create(:user, responsible: responsible) }
      let(:rdv) { create(:rdv, :by_phone, users: [child]) }

      it { is_expected.to be_blank }
    end
  end

  describe "#address_without_personal_information" do
    it "return nothing for a phone rdv" do
      rdv = build(:rdv, :by_phone)
      expect(rdv.address_without_personal_information).to eq("Par téléphone")
    end

    it "return mds address for a public_office rdv" do
      lieu = build(:lieu, address: "16 rue de l'adresse, Ville, 12345", name: "PMI centre ville")
      rdv = build(:rdv, motif: build(:motif, :at_public_office), lieu: lieu)
      expect(rdv.address_without_personal_information).to eq("PMI centre ville (16 rue de l'adresse, Ville, 12345)")
    end

    it "indicates a lieu is single_use" do
      lieu = build(:lieu, address: "16 rue de l'adresse, Ville, 12345", name: "Café de la gare", availability: :single_use)
      rdv = build(:rdv, motif: build(:motif, :at_public_office), lieu: lieu)
      expect(rdv.address_without_personal_information).to eq("Café de la gare (16 rue de l'adresse, Ville, 12345) (Ponctuel)")
    end

    it "return only city for a at_home rdv" do
      user = build(:user, address: "3 rue de l'église, Paris, 75020", post_code: "75020", city_name: "Paris")
      rdv = build(:rdv, motif: build(:motif, :at_home), users: [user])
      expect(rdv.address_without_personal_information).to eq("À domicile (75020 Paris)")
    end

    it "return nothing for a at_home rdv if city is blank" do
      user = build(:user, address: "3 rue de l'église, Paris, 75020")
      rdv = build(:rdv, motif: build(:motif, :at_home), users: [user])
      expect(rdv.address_without_personal_information).to eq("À domicile")
    end
  end

  describe "#temporal_status" do
    it "return status when not unknown" do
      rdv = build(:rdv, status: "seen")
      expect(rdv.temporal_status).to eq("seen")
      rdv = build(:rdv, status: "excused")
      expect(rdv.temporal_status).to eq("excused")
      rdv = build(:rdv, status: "noshow")
      expect(rdv.temporal_status).to eq("noshow")
    end

    it "return past/today/future when unknown" do
      today = Time.zone.local(2020, 3, 23, 14, 54)
      travel_to(today)
      rdv = build(:rdv, status: "unknown", starts_at: today + 1.hour)
      expect(rdv.temporal_status).to eq("unknown_today")

      rdv = build(:rdv, status: "unknown", starts_at: today + 1.day)
      expect(rdv.temporal_status).to eq("unknown_future")

      rdv = build(:rdv, status: "unknown", starts_at: today - 1.day)
      expect(rdv.temporal_status).to eq("unknown_past")
    end
  end

  describe "#visible" do
    it "don't return rdv with invisible motif" do
      motif = create(:motif, :invisible)
      create(:rdv, motif: motif)
      expect(described_class.visible).to be_empty
    end

    it "return rdv with visible and notified motif" do
      motif = create(:motif, :visible_and_notified)
      rdv = create(:rdv, motif: motif)
      expect(described_class.visible).to contain_exactly(rdv)
    end

    it "return rdv with visible and not notified motif" do
      motif = create(:motif, :visible_and_not_notified)
      rdv = create(:rdv, motif: motif)
      expect(described_class.visible).to contain_exactly(rdv)
    end
  end

  describe "#for_today" do
    it "return empty array when no rdv" do
      expect(described_class.for_today).to be_empty
    end

    it "return [rdv] when one rdv for today" do
      now = Time.zone.parse("2020/12/23 12:30")
      travel_to(now)
      rdv = create(:rdv, starts_at: now)
      expect(described_class.for_today).to eq([rdv])
    end

    it "return ONLY the daily rdv" do
      now = Time.zone.parse("2020/12/23 12:30")
      travel_to(now - 3.days)
      create(:rdv, starts_at: now - 2.days)
      rdv = create(:rdv, starts_at: now)
      create(:rdv, starts_at: now + 1.day)
      travel_to(now)

      expect(described_class.for_today).to eq([rdv])
    end
  end

  describe "Rdv.ongoing" do
    context "without time_margin" do
      it "returns RDV that ongoing" do
        now = Time.zone.parse("2020-01-13 16:45")
        travel_to(now - 3.days)
        rdv_that_ongoing = create(:rdv, starts_at: now - 30.minutes, duration_in_min: 45)
        create(:rdv, starts_at: now + 30.minutes, duration_in_min: 15) # rdv_starting_shortly_after
        travel_to(now)
        expect(described_class.ongoing).to eq([rdv_that_ongoing])
      end
    end

    context "with 1 hour time_margin" do
      it "returns RDV that ongoing" do
        now = Time.zone.parse("2020-01-13 16:45")
        travel_to(now - 3.days)
        rdv_that_ongoing = create(:rdv, starts_at: now - 30.minutes, duration_in_min: 45)
        rdv_finished_shortly_before = create(:rdv, starts_at: now - 30.minutes, duration_in_min: 15)
        create(:rdv, starts_at: now - 2.hours, duration_in_min: 15) # rdv finished long before
        rdv_starting_shortly_after = create(:rdv, starts_at: now + 30.minutes, duration_in_min: 15)
        create(:rdv, starts_at: now + 2.hours, duration_in_min: 15) # rdv_starting_long_after
        travel_to(now)

        expected_rdvs = [
          rdv_finished_shortly_before,
          rdv_starting_shortly_after,
          rdv_that_ongoing,
        ]

        expect(described_class.ongoing(time_margin: 1.hour)).to match_array(expected_rdvs)
      end
    end
  end

  describe "validations" do
    let(:now) { Time.zone.parse("2020-12-28 14h00") }

    before { travel_to(now) }

    it "a une fabrique valide" do
      expect(build(:rdv)).to be_valid
    end

    it "returns valid with starts_at is less than two days in past" do
      expect(build(:rdv, starts_at: now - 2.days + 1.hour)).to be_valid
    end

    it "returns valid with future starts_at" do
      expect(build(:rdv, starts_at: now + 1.hour)).to be_valid
    end

    it "valid with a user without email" do
      expect(build(:rdv, users: [create(:user, email: nil)])).to be_valid
    end
  end

  describe "lieu_is_not_disabled_if_needed" do
    subject { rdv.errors }

    let(:rdv) { build :rdv, motif: motif, lieu: lieu }
    let(:motif) { build :motif, location_type: location_type }

    before { rdv.validate }

    context "does not require a lieu if location_type is not public_office?" do
      let(:location_type) { :phone }
      let(:lieu) { nil }

      it { is_expected.to be_empty }
    end

    context "requires a lieu if location_type is not public_office" do
      let(:location_type) { :public_office }
      let(:lieu) { nil }

      it { is_expected.to be_of_kind(:lieu, :blank) }
    end

    context "is invalid if lieu is disabled" do
      let(:location_type) { :public_office }
      let(:lieu) { build :lieu, availability: :disabled }

      it { is_expected.to be_of_kind(:lieu, :must_not_be_disabled) }
    end

    context "is valid if lieu is enabled" do
      let(:location_type) { :public_office }
      let(:lieu) { build :lieu, availability: :enabled }

      it { is_expected.to be_empty }
    end

    context "is valid if lieu is single_use" do
      let(:location_type) { :public_office }
      let(:lieu) { build :lieu, availability: :single_use }

      it { is_expected.to be_empty }
    end
  end

  describe "#search_for" do
    it "returns allowed rdvs even with blank option" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      rdv = create(:rdv, organisation: organisation, agents: [admin])
      create(:rdv, organisation: other_organisation, agents: [admin])

      options = { lieu_ids: "" }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns allowed rdvs" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      rdv = create(:rdv, organisation: organisation, agents: [admin])
      create(:rdv, organisation: other_organisation, agents: [admin])

      options = {}
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv for lieu when given" do
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      lieu = create(:lieu, organisation: organisation)
      rdv = create(:rdv, lieu: lieu, organisation: organisation, agents: [admin])
      create(:rdv, lieu: create(:lieu), organisation: organisation, agents: [admin])

      options = { "lieu_ids" => [lieu.id] }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv for motif when given" do
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      motif = create(:motif, organisation: organisation, service: admin.services.first)
      autre_motif = create(:motif, organisation: organisation, service: admin.services.first)
      rdv = create(:rdv, motif: motif, organisation: organisation, agents: [admin])
      create(:rdv, motif: autre_motif, organisation: organisation, agents: [admin])

      options = { "motif_ids" => [motif.id] }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv for given agent" do
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      other_admin = create(:agent, admin_role_in_organisations: [organisation])
      rdv = create(:rdv, organisation: organisation, agents: [admin])
      create(:rdv, organisation: organisation, agents: [other_admin])

      options = { "agent_id" => admin.id }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv for given user" do
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      user = create(:user, organisations: [organisation])
      rdv = create(:rdv, organisation: organisation, agents: [admin], users: [user])
      other_user = create(:user, organisations: [organisation])
      create(:rdv, organisation: organisation, agents: [admin], users: [other_user])

      options = { "user_id" => user.id }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "return rdvs for agent in same organisation and service" do
      organisation = create(:organisation)
      organisation2 = create(:organisation)
      user = create(:user, organisations: [organisation])
      agent1 = create(:agent, basic_role_in_organisations: [organisation])
      agent2 = create(:agent, basic_role_in_organisations: [organisation])
      rdv1 = create(:rdv, organisation: organisation, agents: [agent1], users: [user])
      rdv2 = create(:rdv, organisation: organisation, agents: [agent2], users: [user])
      rdv3 = create(:rdv, organisation: organisation2, agents: [agent2], users: [user])

      options = {}
      expect(described_class.search_for(organisation, options)).to contain_exactly(rdv1, rdv2)
      expect(described_class.search_for(organisation2, options)).to contain_exactly(rdv3)
      expect(described_class.search_for(Organisation.all, options)).to contain_exactly(rdv1, rdv2, rdv3)
    end

    it "returns rdv with given status" do
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      rdv = create(:rdv, :past, organisation: organisation, agents: [admin], status: :seen)
      create(:rdv, :past, organisation: organisation, agents: [admin], status: :excused)

      options = { "status" => "seen" }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv starting after that date" do
      now = Time.zone.parse("20211227 11:00")
      travel_to(now)
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      rdv = create(:rdv, starts_at: now + 3.days, organisation: organisation, agents: [admin])
      create(:rdv, starts_at: now + 1.day, organisation: organisation, agents: [admin])

      options = { "start" => (now + 2.days) }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end

    it "returns rdv starting before that date" do
      now = Time.zone.parse("20211227 11:00")
      travel_to(now)
      organisation = create(:organisation)
      admin = create(:agent, admin_role_in_organisations: [organisation])
      rdv = create(:rdv, starts_at: now + 1.day, organisation: organisation, agents: [admin])
      create(:rdv, starts_at: now + 3.days, organisation: organisation, agents: [admin])

      options = { "end" => (now + 2.days) }
      expect(described_class.search_for(organisation, options)).to eq([rdv])
    end
  end

  describe "#overlapping_plages_ouvertures?" do
    let(:now) { Time.zone.parse("2022-12-27 11:00") }

    before { travel_to(now) }

    it "return false when starts_at blank" do
      rdv = build(:rdv, starts_at: "")
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false when ends_at blank" do
      rdv = build(:rdv, starts_at: now + 1.week, ends_at: nil)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false when lieu blank" do
      rdv = build(:rdv, starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false with past RDV" do
      rdv = build(:rdv, starts_at: now - 1.week, ends_at: now - 1.week + 30.minutes)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false when RDV's error" do
      rdv = build(:rdv, starts_at: now - 1.week, ends_at: now - 1.week)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return true with po overlapping RDV on an other lieu" do
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: agent, first_day: (now + 1.week).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45), lieu: create(:lieu))
      expect(rdv.overlapping_plages_ouvertures?).to be(true)
    end

    it "return false with po overlapping RDV on an same lieu" do
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: agent, first_day: (now + 1.week).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45), lieu: rdv.lieu)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false with po overlapping RDV with an other agent" do
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: create(:agent), first_day: (now + 1.week).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45), lieu: rdv.lieu)
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end

    it "return false with recurring po overlapping RDV" do
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: agent, first_day: (now - 2.weeks).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45), lieu: create(:lieu),
                               recurrence: Montrose.every(:week, on: ["tuesday"], starts: (now - 2.weeks).to_date))
      expect(rdv.overlapping_plages_ouvertures?).to be(true)
    end

    it "return false with recurring po overlapping RDV outside zone" do
      now = Time.zone.parse("2022-12-27 11:00")
      travel_to(now)
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: agent, first_day: (now - 1.week).to_date, start_time: Tod::TimeOfDay.new(10, 45), end_time: Tod::TimeOfDay.new(11, 45), lieu: create(:lieu),
                               recurrence: Montrose.every(:month, day: { Tuesday: [2] }, starts: (now - 1.week).to_date))
      expect(rdv.overlapping_plages_ouvertures?).to be(false)
    end
  end

  describe "#overlapping_plages_ouvertures" do
    let(:now) { Time.zone.parse("2022-12-27 11:00") }

    before { travel_to(now) }

    it "return plage_ouvertures" do
      agent = create(:agent)
      rdv = build(:rdv, agents: [agent], starts_at: now + 1.week, ends_at: now + 1.week + 30.minutes)
      create(:plage_ouverture, agent: agent, first_day: (now + 1.week).to_date, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(14))
      expect(rdv.overlapping_plages_ouvertures.first).to be_a(PlageOuverture)
    end
  end

  describe "#available_to_file_attente?" do
    it "returns true with a 9 days later public office RDV" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      rdv = build(:rdv, :at_public_office, starts_at: now + 9.days)
      expect(rdv.available_to_file_attente?).to be(true)
    end

    it "returns false with a tomorrow RDV" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      rdv = build(:rdv, :at_public_office, starts_at: now + 1.day)
      expect(rdv.available_to_file_attente?).to be(false)
    end

    it "returns false with a home RDV" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      rdv = build(:rdv, :at_home, starts_at: now + 9.days)
      expect(rdv.available_to_file_attente?).to be(false)
    end

    it "returns false with a cancelled RDV" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      rdv = build(:rdv, :at_home, starts_at: now + 9.days, cancelled_at: now - 1.day)
      expect(rdv.available_to_file_attente?).to be(false)
    end

    it "returns false with a not allowed online reservation motif" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      motif = build(:motif, bookable_by: :agents)
      rdv = build(:rdv, :at_home, starts_at: now + 9.days, motif: motif)
      expect(rdv.available_to_file_attente?).to be(false)
    end

    it "returns false with a collective motif" do
      now = Time.zone.parse("20220221 10:34")
      travel_to(now)
      motif = build(:motif, collectif: true)
      rdv = build(:rdv, :at_home, starts_at: now + 9.days, motif: motif)
      expect(rdv.available_to_file_attente?).to be(false)
    end
  end

  describe "#synthesized_receipts_result" do
    it "sets nil if no receipt" do
      rdv = create(:rdv, receipts: [])

      expect(rdv.synthesized_receipts_result).to be_nil
    end

    it "sets failure if failed receipts" do
      rdv = create(:rdv, receipts: build_list(:receipt, 2, result: :failure))

      expect(rdv.synthesized_receipts_result).to eq("failure")
    end

    it "sets processed if receipts are present" do
      rdv = create(:rdv, receipts: build_list(:receipt, 2, result: :sent))

      expect(rdv.synthesized_receipts_result).to eq("processed")
    end
  end

  describe "#destroy" do
    it "dont call update webhook" do
      rdv = create(:rdv)
      expect(rdv).not_to receive(:generate_payload_and_send_webhook)
      rdv.destroy
    end

    it "calls destroy webhook" do
      rdv = create(:rdv)
      expect(rdv).to receive(:generate_payload_and_send_webhook_for_destroy)
      rdv.destroy
    end
  end

  describe "validates collectives rdvs statuses" do
    let(:rdv) { create :rdv, :collectif }

    it "rdv is excused" do
      rdv.status = "excused"
      expect(rdv).not_to be_valid
    end

    it "rdv is noshow" do
      rdv.status = "noshow"
      expect(rdv).not_to be_valid
    end

    Rdv::COLLECTIVE_RDV_STATUSES.each do |status|
      it "rdv is #{status}" do
        rdv.status = status
        expect(rdv).to be_valid
      end
    end
  end

  describe "#update_rdv_status_from_participation for collective rdv" do
    let(:agent) { create :agent }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:user4) { create(:user) }
    let(:rdv) { create :rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent], users: [user1, user2, user3, user4] }

    it "updated as seen if one participation is seen" do
      rdv.participations.first.update(status: "seen")
      rdv.participations.second.update(status: "noshow")
      rdv.participations.third.update(status: "excused")
      rdv.participations.last.update(status: "noshow")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("seen")
    end

    it "updated as revoked if none seen or unknown participation and rdv is in the past" do
      rdv.starts_at = Time.zone.yesterday
      rdv.save
      rdv.participations.first.update(status: "noshow")
      rdv.participations.second.update(status: "noshow")
      rdv.participations.third.update(status: "excused")
      rdv.participations.last.update(status: "excused")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("revoked")
    end

    it "stay unknown if none seen or unknown participation and rdv is in the future" do
      rdv.participations.first.update(status: "noshow")
      rdv.participations.second.update(status: "noshow")
      rdv.participations.third.update(status: "excused")
      rdv.participations.last.update(status: "excused")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("unknown")
    end

    it "stay unknown if one participation is unknown" do
      rdv.participations.first.update(status: "noshow")
      rdv.participations.second.update(status: "excused")
      rdv.participations.third.update(status: "excused")
      rdv.participations.last.update(status: "unknown")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("unknown")
    end
  end

  describe "#update_rdv_status_from_participation for individual rdv (participation can be changed with api)" do
    let(:agent) { create :agent }
    let!(:user1) { create(:user) }
    let(:rdv) { create :rdv, starts_at: Time.zone.tomorrow, agents: [agent], users: [user1] }

    it "updated as seen if one participation is seen" do
      rdv.participations.first.update(status: "seen")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("seen")
    end

    it "updated as excused if one participation is excused" do
      rdv.participations.first.update(status: "excused")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("excused")
    end

    it "updated as revoked if one participation is revoked" do
      rdv.participations.first.update(status: "revoked")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("revoked")
    end

    it "updated as noshow if one participation is noshow" do
      rdv.participations.first.update(status: "noshow")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("noshow")
    end

    it "updated as unknown if one participation is unknown" do
      rdv.participations.first.update(status: "unknown")
      rdv.update_rdv_status_from_participation
      expect(rdv.status).to eq("unknown")
    end
  end

  describe "#overlapping_absences" do
    subject { rdv.overlapping_absences }

    let(:agent) { create(:agent) }
    let(:now) { Time.zone.parse("2021-05-03 09h00") }
    let(:rdv) { create(:rdv, starts_at: now, ends_at: now + 1.hour, agents: [agent]) }
    let!(:absence) do
      create(
        :absence,
        agent: agent,
        first_day: now.to_date,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(10),
        recurrence: Montrose.every(:week, on: ["monday"], starts: Time.zone.parse("20210503 00:00"), until: nil)
      )
    end

    before { travel_to now }

    it "returns absence overlapping rdv" do
      expect(subject).to contain_exactly(absence)
    end

    context "rdv interval is consecutive to absence interval: Absence for 08h-09h and Rdv for 09h-10h" do
      before do
        absence.start_time = Tod::TimeOfDay.new(9)
        absence.start_time = Tod::TimeOfDay.new(10)
        absence.save!
      end

      it "does not find any overlapping absence" do
        expect(subject).to be_empty
      end
    end
  end
end
