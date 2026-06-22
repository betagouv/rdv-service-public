RSpec.describe "Lien court vers les créneaux d'un RDV collectif", type: :request do
  let(:rdv) { create(:rdv) }
  let(:token) { rdv.participations.first.restricted_auth_token }

  it "redirige vers la page des créneaux avec le bon token" do
    get "/r/#{rdv.id}/cr?tkn=#{token}"
    expect(response).to redirect_to("/users/rdvs/#{rdv.id}/creneaux?invitation_token=#{token}")
  end
end
