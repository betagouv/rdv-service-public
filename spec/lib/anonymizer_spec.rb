# frozen_string_literal: true

RSpec.describe Anonymizer do
  let!(:user) { create(:user) }
  let!(:prescripteur) { create(:prescripteur) }

  it "anonymizes all the data" do
    described_class.anonymize_all_data!

    expect(user.reload.full_name).to eq "asdf"
    expect(prescripteur.reload.full_name).to eq "asdf"
  end
end
