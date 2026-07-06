RSpec.describe Users::UsersController, type: :controller do
  render_views

  before do
    travel_to(Time.zone.local(2019, 7, 20))
    sign_in user
  end

  describe "GET #edit" do
    subject { get :edit }

    let(:user) { create(:user) }
    let!(:relative) { create(:user, first_name: "Katia", last_name: "Garcia", birth_date: Date.parse("12/10/1990"), responsible_id: user.id) }

    it "lists relatives" do
      subject
      expect(response.body).to include("Mes proches")
      expect(response.body).to include("Katia GARCIA (28 ans)")
    end
  end

  describe "PATCH #update qui force l'envoi d'un email en contournant le disabled HTML" do
    let(:user) { create(:user, email: "test@blah.fr") }

    it do
      patch :update, params: { user: { email: "hacked@exemple.fr" } }

      expect(user.reload.email).to eq("test@blah.fr")
    end
  end
end
