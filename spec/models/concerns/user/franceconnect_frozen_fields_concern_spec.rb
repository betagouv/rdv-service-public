RSpec.describe User::FranceconnectFrozenFieldsConcern do
  context "never logged with FC" do
    let!(:user) { create(:user, first_name: "Jean", birth_name: "DUPONT", logged_once_with_franceconnect: false) }

    it "allows change" do
      res = user.update(birth_name: "MARCO")
      expect(res).to be_truthy
      expect(user.reload.birth_name).to eq("MARCO")
    end
  end

  context "already logged with FC" do
    let!(:user) { create(:user, first_name: "Jean", birth_name: "DUPONT", logged_once_with_franceconnect: true) }

    it "does not allow change to frozen field" do
      res = user.update(birth_name: "MARCO")
      expect(res).to be_falsy
      expect(user.errors).to include(:birth_name)
      expect(user.reload.birth_name).to eq("DUPONT")
    end

    it "allows change to non-frozen field" do
      res = user.update(address: "10 rue du Havre, Paris, 75016")
      expect(res).to be_truthy
      expect(user.reload.address).to eq("10 rue du Havre, Paris, 75016")
    end
  end

  context "new login to FC" do
    let!(:user) { create(:user, first_name: "Jean", birth_name: "DUPONT", logged_once_with_franceconnect: false) }

    it "allows changing frozen fields during the login" do
      res = user.update(birth_name: "MARCO", logged_once_with_franceconnect: true)
      expect(res).to be_truthy
      expect(user.reload.birth_name).to eq("MARCO")
    end
  end
end
