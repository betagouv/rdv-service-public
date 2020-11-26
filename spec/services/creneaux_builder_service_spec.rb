describe CreneauxBuilderService, type: :service do
  let!(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, reservable_online: reservable_online, organisation: organisation, location_type: :public_office) }
  let(:reservable_online) { true }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Date.new(2019, 9, 19) } # a thursday
  let(:tomorrow) { Date.new(2019, 9, 20) }
  let(:six_days_later) { today + 6.days }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, agent: agent, organisation: organisation) }
  let(:now) { today.in_time_zone + 8.hours } # 8 am
  let(:options) { {} }
  let(:motif_name) { motif.name }
  let(:next_7_days_range) { today..six_days_later }

  before { travel_to(now) }
  after { travel_back }

  subject do
    creneaux = CreneauxBuilderService.perform_with(motif_name, lieu, next_7_days_range, **options)
    creneaux.map { |c| creneau_to_hash(c, options[:for_agents]) }
  end

  it "should work" do
    expect(subject.size).to eq(4)

    is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
  end

  context "with motif not bookable reservable_online" do
    let(:reservable_online) { false }

    it "should return 0 creneaux" do
      expect(subject.size).to eq(0)
    end

    context "when the result is for pros" do
      let(:options) { { for_agents: true } }

      it do
        expect(subject.size).to eq(4)

        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
      end
    end
  end

  context "with absences" do
    let!(:absence) { create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 45), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(10, 15), organisation: organisation) }

    it do
      expect(subject.size).to eq(3)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 15), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 45), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "recurring plage ouverture" do
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, recurrence: Montrose.every(:day), agent: agent, organisation: organisation) }

    context "with absence spanning 2 days, ending before start of second day" do
      let!(:absence) { create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 45), end_day: Date.new(2019, 9, 20), end_time: Tod::TimeOfDay.new(6, 30), organisation: organisation) }

      it do
        creneaux_day1 = subject.select { _1[:starts_at].to_date == Date.new(2019, 9, 19) }
        expect(creneaux_day1.size).to eq(1)
        expect(creneaux_day1).to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        creneaux_day2 = subject.select { _1[:starts_at].to_date == Date.new(2019, 9, 20) }
        expect(creneaux_day2.size).to eq(4)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      end
    end

    context "with absence spanning 2 days, ending in middle of second day" do
      let!(:absence) { create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 45), end_day: Date.new(2019, 9, 20), end_time: Tod::TimeOfDay.new(9, 5), organisation: organisation) }

      it do
        creneaux_day1 = subject.select { _1[:starts_at].to_date == Date.new(2019, 9, 19) }
        expect(creneaux_day1.size).to eq(1)
        expect(creneaux_day1).to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        creneaux_day2 = subject.select { _1[:starts_at].to_date == Date.new(2019, 9, 20) }
        # expect(creneaux_day2.size).to eq(4)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 9, 5), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 9, 35), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
        expect(creneaux_day2).to include(starts_at: Time.zone.local(2019, 9, 20, 10, 5), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      end
    end
  end

  context "with recurring absences" do
    let!(:absence) { create(:absence, :weekly, agent: agent, first_day: Date.new(2019, 9, 12), start_time: Tod::TimeOfDay.new(9, 45), end_day: Date.new(2019, 9, 12), end_time: Tod::TimeOfDay.new(10, 15), organisation: organisation) }

    it do
      expect(subject.size).to eq(3)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 15), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 45), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "with a RDV" do
    let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, agents: [agent], organisation: organisation) }

    it do
      expect(subject.size).to eq(3)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "with a RDV shorter than the motif" do
    let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 15, agents: [agent], organisation: organisation) }

    it do
      expect(subject.size).to eq(4)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 45), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 15), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 45), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "with a RDV longer than the motif" do
    let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 45, agents: [agent], organisation: organisation) }

    it do
      expect(subject.size).to eq(3)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 15), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 45), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "with a cancelled RDV" do
    let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, agents: [agent], cancelled_at: Time.zone.local(2019, 9, 20, 9, 30), organisation: organisation) }

    it do
      expect(subject.size).to eq(4)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "with a RDV on the last day of the range" do
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: Date.new(2019, 9, 25), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation) }
    let!(:rdv) { create(:rdv, starts_at: Time.zone.local(2019, 9, 25, 10, 0), duration_in_min: 30, agents: [agent], organisation: organisation) }

    it do
      expect(subject.size).to eq(3)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 25, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 25, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 25, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "when today is jour ferie" do
    let(:today) { Date.new(2020, 1, 1) }

    it do
      expect(subject.size).to eq(0)
    end
  end

  context "when there are two agents" do
    let(:agent2) { create(:agent, organisations: [organisation]) }
    let!(:plage_ouverture2) { create(:plage_ouverture, agent: agent2, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(10), end_time: Tod::TimeOfDay.new(12), organisation: organisation) }

    it do
      expect(subject.size).to eq(6)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end

    context "when the result is for agents" do
      let(:options) { { for_agents: true } }

      it do
        expect(subject.size).to eq(8)

        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent.id, agent_name: agent.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
        is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
      end

      context "when the result is filtered for agent2" do
        let(:options) { { for_agents: true, agent_ids: [agent2.id] } }

        it do
          expect(subject.size).to eq(4)

          is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
          is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
          is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
          is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 11, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id, agent_id: agent2.id, agent_name: agent2.short_name)
        end
      end

      context "when the result is filtered with an empty agents set" do
        let(:options) { { agent_ids: [] } }
        it { should be_empty }
      end

      context "when the result is filtered with an empty agents set, for agents" do
        let(:options) { { for_agents: true, agent_ids: [] } }
        it { should be_empty }
      end

      context "when there is another motif with the same name but a different location_type" do
        let!(:motif_home) { create(:motif, name: "Vaccination", default_duration_in_min: 30, organisation: organisation, location_type: :home) }
        let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif, motif_home], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, agent: agent, organisation: organisation) }
        let(:options) { { for_agents: true, motif_location_type: :home } }

        it "should include only the filtered one" do
          expect(subject.pluck(:motif_id).uniq).to eq([motif_home.id])
        end
      end

      context "when there is another motif with the same name but a different location_type and they are on the same plage ouverture" do
        let!(:motif_home) { create(:motif, name: "Vaccination", default_duration_in_min: 30, organisation: organisation, location_type: :home) }
        let!(:plage_ouverture_home) { create(:plage_ouverture, motifs: [motif_home], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(14) + 35.minutes, agent: agent, organisation: organisation) }

        let(:options) { { for_agents: true, motif_location_type: :home } }

        it "should include only the filtered one" do
          expect(subject.pluck(:motif_id).uniq).to eq([motif_home.id])
        end
      end
    end
  end

  context "when motif has min_booking_delay" do
    let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, min_booking_delay: 30.minutes, reservable_online: true, organisation: organisation) }
    let(:now) { Time.zone.local(2019, 9, 19, 9, 15) }

    it do
      expect(subject.size).to eq(2)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 30), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "when motif has max_booking_delay" do
    let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, max_booking_delay: 45.minutes, reservable_online: true, organisation: organisation) }
    let(:now) { Time.zone.local(2019, 9, 19, 9, 15) }

    it do
      expect(subject.size).to eq(1)

      is_expected.to include(starts_at: Time.zone.local(2019, 9, 19, 10, 0), duration_in_min: 30, lieu_id: lieu.id, motif_id: motif.id)
    end
  end

  context "past creneaux for users" do
    let(:now) { today.in_time_zone + 10.hours } # 10 am

    it "should not appear" do
      expect(subject.first[:starts_at].hour).to eq(10)
    end
  end

  context "past creneaux for agents" do
    let(:now) { today.in_time_zone + 10.hours } # 10 am
    let(:options) { { for_agents: true } }

    it "should not appear" do
      expect(subject.first[:starts_at].hour).to eq(10)
    end
  end

  context "recurring plage ouverture + absence ending late" do
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11) + 20.minutes, recurrence: Montrose.every(:day), agent: agent, organisation: organisation) }
    let!(:absence) { create(:absence, :weekly, agent: agent, first_day: tomorrow, start_time: Tod::TimeOfDay.new(0, 0), end_day: tomorrow, end_time: absence_end_time, organisation: organisation) }

    context "absence end_time leaves enough time for a full creneau after" do
      let(:absence_end_time) { Tod::TimeOfDay.new(23, 0) }

      it do
        tomorrow_creneaux = subject.select { _1[:starts_at].to_date == tomorrow }
        expect(tomorrow_creneaux.count).to eq(0)
        day_after_tomorrow_creneaux = subject.select { _1[:starts_at].to_date == tomorrow + 1.day }
        expect(day_after_tomorrow_creneaux.count).to be > 0
        expect(day_after_tomorrow_creneaux.first[:starts_at].to_time_of_day).to eq(Tod::TimeOfDay.new(9))
      end
    end

    context "absence end_time does not leave enough time for a full creneau" do
      let(:absence_end_time) { Tod::TimeOfDay.new(23, 55) }

      it do
        tomorrow_creneaux = subject.select { _1[:starts_at].to_date == tomorrow }
        expect(tomorrow_creneaux.count).to eq(0)
        day_after_tomorrow_creneaux = subject.select { _1[:starts_at].to_date == tomorrow + 1.day }
        expect(day_after_tomorrow_creneaux.count).to be > 0
        expect(day_after_tomorrow_creneaux.first[:starts_at].to_time_of_day).to eq(Tod::TimeOfDay.new(9))
      end
    end
  end

  def expect_creneau_to_eq(creneau, attr = {})
    expect(creneau.starts_at).to eq(attr[:starts_at])
    expect(creneau.duration_in_min).to eq(attr[:duration_in_min])
    expect(creneau.lieu.id).to eq(attr[:lieu_id])
    expect(creneau.motif.id).to eq(attr[:motif].id)
    expect(creneau.agent_id).to eq(attr[:agent_id]) if attr[:agent_id].present?
    expect(creneau.agent_name).to eq(attr[:agent_name]) if attr[:agent_name].present?
  end

  def creneau_to_hash(creneau, with_agent = false)
    {
      starts_at: creneau.starts_at,
      duration_in_min: creneau.duration_in_min,
      lieu_id: creneau.lieu.id,
      motif_id: creneau.motif.id,
      agent_id: (creneau.agent_id if with_agent),
      agent_name: (creneau.agent_name if with_agent),
    }.compact
  end
end
