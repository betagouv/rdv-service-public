RSpec.describe DeletedRdvsBackfill do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let(:starts_at) { 3.months.ago.change(hour: 9) }
  let(:deleted_at) { 2.months.ago.change(usec: 0) }

  def create_version(created_at: deleted_at, **object_overrides)
    PaperTrail::Version.create!(
      item_type: "Rdv", item_id: rand(1_000_000), event: "destroy", whodunnit: "[Agent] Test (id=#{agent.id})", created_at:,
      virtual_attributes: { "user_ids" => [user.id], "agent_ids" => [agent.id], "participations" => [] },
      object: {
        "id" => 1, "status" => "unknown", "starts_at" => starts_at.iso8601, "ends_at" => (starts_at + 30.minutes).iso8601,
        "lieu_id" => 123, "motif_id" => motif.id, "organisation_id" => organisation.id,
        "created_by_id" => agent.id, "created_by_type" => "Agent",
      }.merge(object_overrides)
    )
  end

  it "reconstitue un DeletedRdv à partir de la version de suppression" do
    create_version

    expect { described_class.new(before: Time.zone.now).call }.to change(DeletedRdv, :count).by(1)

    expect(DeletedRdv.last).to have_attributes(
      starts_at: be_within(1.second).of(starts_at),
      ends_at: be_within(1.second).of(starts_at + 30.minutes),
      organisation_id: organisation.id,
      motif_id: motif.id,
      motif_name: motif.name,
      lieu_id: 123, # le lieu n'existe pas : on garde l'id
      status: "unknown",
      created_by_type: "Agent",
      created_by_id: agent.id,
      created_by_name: agent.full_name,
      user_ids: [user.id],
      agent_ids: [agent.id],
      created_at: be_within(1.second).of(deleted_at)
    )
  end

  it "gère les motifs et créateurs qui n'existent plus" do
    create_version("motif_id" => 999_999, "created_by_id" => 999_999)

    described_class.new(before: Time.zone.now).call

    expect(DeletedRdv.last).to have_attributes(motif_id: 999_999, motif_name: nil, created_by_name: nil)
  end

  it "gère une version sans virtual_attributes" do
    create_version.update!(virtual_attributes: nil)

    described_class.new(before: Time.zone.now).call

    expect(DeletedRdv.last).to have_attributes(user_ids: [], agent_ids: [])
  end

  it "ignore les versions postérieures à `before`, les autres types et événements, et les RDV de plus de 2 ans" do
    create_version(created_at: 1.day.ago)
    create_version.update!(item_type: "Motif")
    create_version.update!(event: "update")
    create_version("starts_at" => 25.months.ago.iso8601, "ends_at" => 25.months.ago.iso8601)

    expect { described_class.new(before: 1.week.ago).call }.not_to change(DeletedRdv, :count)
    expect { described_class.new(before: Time.zone.now).call }.to change(DeletedRdv, :count).by(1) # seulement celle du 1.day.ago
  end

  it "peut être relancé sans créer de doublons" do
    create_version

    described_class.new(before: Time.zone.now).call
    expect { described_class.new(before: Time.zone.now).call }.not_to change(DeletedRdv, :count)
  end
end
