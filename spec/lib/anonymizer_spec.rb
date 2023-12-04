# frozen_string_literal: true

RSpec.describe Anonymizer do
  let!(:user) { create(:user) }
  let!(:prescripteur) { create(:prescripteur) }
  let!(:agent) { create(:agent, email: "agent@example.com") }
  let!(:super_admin) { SuperAdmin.create!(email: "admin@example.com") }

  it "anonymizes all the data" do
    described_class.anonymize_all_data!

    expect(user.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
    expect(prescripteur.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
    expect(agent.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
    expect(agent.reload.email).to eq "[valeur unique anonymisée #{agent.id}]"
    expect(super_admin.reload.email).to eq "[valeur anonymisée]"
  end
end
