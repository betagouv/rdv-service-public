describe FindAvailability, type: :service do
  let!(:now) { Date.new(2019, 9, 19) }

  before { travel_to(now) }
  after { travel_back }

  it "without not online motif" do
    motif = create(:motif)
    lieu = create(:lieu)
    expect(FindAvailability.perform_with(motif.name, lieu, now)).to be_nil
  end

  it "with absence" do
    motif = create(:motif)
    agent = create(:agent)
    create(:absence, agent: agent, first_day: Date.new(2019, 9, 19), start_time: Tod::TimeOfDay.new(9, 0), end_day: Date.new(2019, 9, 19), end_time: Tod::TimeOfDay.new(12, 0))
    lieu = create(:lieu)
    expect(FindAvailability.perform_with(motif.name, lieu, now)).to be_nil
  end

  it "return something with a recurrent plage_ouverture" do
    motif = create(:motif, name: "Vaccination", default_duration_in_min: 30)
    lieu = create(:lieu)
    plage_ouverture = create(:plage_ouverture, motifs: [motif], lieu: lieu, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), first_day: now)

    plage_ouverture.update(recurrence: Montrose.monthly.to_json)
    expect(FindAvailability.perform_with(motif.name, lieu, now).starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0))
  end

  it "with a RDV" do
    motif = create(:motif)
    lieu = create(:lieu)
    plage_ouverture = create(:plage_ouverture, motifs: [motif], lieu: lieu, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), first_day: now)
    agent = plage_ouverture.agent
    create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 120, agents: [agent])
    expect(FindAvailability.perform_with(motif.name, lieu, now)).to be_nil
  end

  it "with a cancelled RDV" do
    motif = create(:motif)
    lieu = create(:lieu)
    plage_ouverture = create(:plage_ouverture, motifs: [motif], lieu: lieu, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), first_day: now)
    agent = plage_ouverture.agent
    create(:rdv, starts_at: Time.zone.local(2019, 9, 19, 9, 30), duration_in_min: 30, agents: [agent], cancelled_at: Time.zone.local(2019, 9, 20, 9, 30))
    expect(FindAvailability.perform_with(motif.name, lieu, now).starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0))
  end

  it "with rdv when plage_ouverture is recurrence" do
    motif = create(:motif)
    lieu = create(:lieu)
    plage_ouverture = create(:plage_ouverture, motifs: [motif], lieu: lieu, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), first_day: now)
    plage_ouverture.update(recurrence: Montrose.monthly.to_json)
    expect(FindAvailability.perform_with(motif.name, lieu, now).starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0))
  end
end
