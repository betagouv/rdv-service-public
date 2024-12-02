RSpec.describe Admin::CreateMotifs do
  let(:service) { create(:service) }
  let!(:organisations) { create_list(:organisation, 2) }
  let(:valid_motif) { build(:motif, organisation: nil, service:) }

  context "when all params are valid" do
    it "is valid and creates a motif for each organisation" do
      form = described_class.new(motif_params: valid_motif.attributes, organisations:)
      expect(form).to be_valid
      expect { form.save }.to change(Motif, :count).by(2)
      expect(Motif.last(2).map(&:organisation)).to match_array(organisations)
    end
  end

  context "when one attribute is invalid" do
    let(:invalid_motif) { valid_motif.tap { _1.assign_attributes(default_duration_in_min: nil) } }

    it "is invalid, provides unique errors and prevents from saving" do
      form = described_class.new(motif_params: invalid_motif.attributes, organisations:)
      expect(form).to be_invalid
      expect(form.errors.to_a).to eq(["Default duration in min doit être rempli(e)"])
      expect(form.save).to be_falsey
    end
  end

  context "when the motif already exists in one of the orgs" do
    let!(:organisations) do
      [
        create(:organisation, name: "Ma première orga").tap { |org| valid_motif.dup.tap { |motif| motif.assign_attributes(organisation: org) }.save! },
        create(:organisation, name: "Ma seconde orga").tap { |org| valid_motif.dup.tap { |motif| motif.assign_attributes(organisation: org) }.save! },
        create(:organisation, name: "Ma troisième orga"),
      ]
    end

    let(:invalid_motif) { valid_motif.dup.tap { _1.assign_attributes(default_duration_in_min: nil) } }

    it "is invalid, provides unique errors and prevents from saving" do
      form = described_class.new(motif_params: invalid_motif.attributes, organisations:)
      expect(form).to be_invalid
      expected_errors = [
        "Default duration in min doit être rempli(e)",
        "Un motif du même nom, même service et même type existe déjà dans Ma première orga",
        "Un motif du même nom, même service et même type existe déjà dans Ma seconde orga",
      ]
      expect(form.errors.to_a).to match_array(expected_errors)
      expect(form.save).to be_falsey
    end
  end
end
