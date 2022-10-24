# frozen_string_literal: true

# Ce check a été ajouté pour éviter d'inexplicables saisies
# accidentelles, par exemple 1922 au lieu de 2022.
# Voir : https://github.com/betagouv/rdv-solidarites.fr/issues/2914
RSpec.describe EnsuresRealisticDate do
  it "is invalid when first day is before 2018" do
    expect(build(:plage_ouverture, first_day: Date.new(2017, 12, 24))).to be_invalid
  end

  it "is invalid when first day is more than 5 years from now" do
    expect(build(:plage_ouverture, first_day: 6.years.from_now.to_date)).to be_invalid
  end

  it "is valid if date is after 2017 and not more than 5 years" do
    expect(build(:plage_ouverture, first_day: Date.new(2020, 12, 24))).to be_valid
  end
end
