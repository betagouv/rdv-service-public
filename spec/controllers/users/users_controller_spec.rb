RSpec.describe Users::UsersController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let!(:child) { create(:user, first_name: "Katia", last_name: "Garcia", birth_date: Date.parse("12/10/1990"), parent_id: user.id) }

  before do
    travel_to(Time.zone.local(2019, 7, 20))
    sign_in user
  end

  after { travel_back }

  describe "GET #edit" do
    subject { get :edit }

    it "Should list children" do
      subject
      expect(response.body).to include("Mes enfants")
      expect(response.body).to include("Katia Garcia (28 ans)")
    end
  end
end
