# frozen_string_literal: true

# RSpec.describe "Adding a user to a collective RDV" do
#   context "with a signed in user" do
#     it "works" do
#       territory = create(:territory, departement_number: "75")
#       organisation = create(:organisation, territory: territory)
#       agent = create(:agent, organisations: [organisation])
#       motif = create(:motif, :collectif, reservable_online: true, organisation: organisation, name: "Atelier")
#       rdv = create(:rdv, :without_users, motif: motif, agents: [agent], organisation: organisation)
#       user = create(:user, phone_number: "+33601010101", email: "frederique@example.com")
#       login_as(user, scope: :user)

#       params = {
#         address: "Paris 75001",
#         city_code: "75056",
#         date: "2022-09-23+17%3A00%3A00+%2B0200",
#         departement: "75",
#         latitude: "48.859",
#         lieu_id: rdv.lieu.id,
#         longitude: "2.347",
#         motif_name_with_location_type: motif.name_with_location_type,
#         service_id: motif.service.id,
#       }
#       visit root_path(params)

#       expect(page).to have_content("Atelier")
#       expect(page).to have_content("S'inscrire")

#       expect do
#         click_link("S'inscrire")
#       end.to change { rdv.reload.users.count }.from(0).to(1)
# # TODO : Continuer le parcours A REVOIR entiérement
#       expect(page).to have_content("Inscription confirmée")
#     end
#   end

#   context "with a not signed in user" do
#     it "redirect to login page before subscription" do
#       territory = create(:territory, departement_number: "75")
#       organisation = create(:organisation, territory: territory)
#       agent = create(:agent, organisations: [organisation])
#       motif = create(:motif, :collectif, reservable_online: true, organisation: organisation, name: "Atelier")
#       rdv = create(:rdv, :without_users, motif: motif, agents: [agent], organisation: organisation)
#       user = create(:user, phone_number: "+33601010101", email: "frederique@example.com")

#       params = {
#         address: "Paris 75001",
#         city_code: "75056",
#         date: "2022-09-23+17%3A00%3A00+%2B0200",
#         departement: "75",
#         latitude: "48.859",
#         lieu_id: rdv.lieu.id,
#         longitude: "2.347",
#         motif_name_with_location_type: motif.name_with_location_type,
#         service_id: motif.service.id,
#       }
#       visit root_path(params)

#       expect(page).to have_content("Atelier")
#       expect(page).to have_content("S'inscrire")

#       click_link("S'inscrire")

#       expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer.")

#       fill_in("user_email", with: user.email)
#       fill_in("password", with: user.password)
#       click_button("Se connecter")

#       expect(page).to have_content("Inscription confirmée")
#       expect(rdv.reload.users.count).to eq(1)
#     end
#   end
# end
