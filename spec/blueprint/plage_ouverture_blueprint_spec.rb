# frozen_string_literal: true

describe PlageOuvertureBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(plage_ouverture, { root: :plage_ouverture }) }
  let(:plage_ouverture) { build(:plage_ouverture) }

  describe "attributes" do
    let(:organisation) { create(:organisation) }
    let(:plage_ouverture) { create(:plage_ouverture, organisation: organisation) }

    it do
      expect(json["plage_ouverture"]["title"]).to eq(plage_ouverture.title)

      expect(json["plage_ouverture"]["lieu"]["id"]).to eq(plage_ouverture.lieu.id)
      expect(json["plage_ouverture"]["motifs"][0]["id"]).to eq(plage_ouverture.motifs.first.id)
      expect(json["plage_ouverture"]["organisation"]["id"]).to eq(plage_ouverture.organisation.id)

      expect(json["plage_ouverture"]["ical_uid"]).to eq("plage_ouverture_#{plage_ouverture.id}@RDV Solidarités")

      expect(json["plage_ouverture"]["web_url"]).to eq("http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/plage_ouvertures/#{plage_ouverture.id}")
    end
  end
end
