# Spec volontairement en échec pour vérifier que la CI affiche bien
# quel exemple a échoué (cf. #6678 et le fix --format progress).
# À supprimer une fois la vérification faite.
require "rails_helper"

RSpec.describe "Canari de sortie CI" do
  it "échoue exprès pour rendre visible le nom du spec dans les logs CI" do
    expect(1).to eq(2)
  end
end
