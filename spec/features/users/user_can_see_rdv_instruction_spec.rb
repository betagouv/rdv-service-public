# frozen_string_literal: true

describe "User can see RDV instructions" do
  it "can see RDV inscrution on RDV page" do
    motif = create(:motif, restriction_for_rdv: "Pensez à prendre votre carnet de santé")
    rdv = create(:rdv, motif: motif)
    user = rdv.users.first
    login_as(user, scope: :user)
    visit users_rdv_path(rdv)
    expect(page).to have_content(motif.restriction_for_rdv)
  end
end
