RSpec.describe TextSearch, type: :concern do
  describe(Team) do
    let(:other_object) { create(:team, name: "dont") }
    let(:object) { create(:team, name: "findme") }
    let(:object_to_save) { build(:team, name: "findme") }

    it "return findme objects" do
      expect(described_class.search_by_text("findme")).to eq([object])
    end
  end

  describe(User) do
    it "returns users that match with first name" do
      create(:user, first_name: "jean")
      patricia = create(:user, first_name: "patricia")
      expect(described_class.search_by_text("patricia")).to eq([patricia])
    end

    it "returns users that match with partial email" do
      create(:user, email: "jean@moustache.fr")
      patricia = create(:user, email: "patoche@duroy.fr")
      expect(described_class.search_by_text("patoche@dur")).to eq([patricia])
    end

    it "returns users that match with exact email" do
      create(:user, email: "jean@moustache.fr")
      patricia = create(:user, email: "patoche@duroy.fr")
      expect(described_class.search_by_text("patoche@duroy.fr")).to eq([patricia])
    end

    it "returns users that match with partial notification_email" do
      create(:user, :without_devise_email, notification_email: "jean@moustache.fr")
      patricia = create(:user, :without_devise_email, notification_email: "patoche@duroy.fr")
      expect(described_class.search_by_text("patoche@dur")).to eq([patricia])
    end

    it "returns users that match with notification_email" do
      create(:user, :without_devise_email, notification_email: "jean@moustache.fr")
      patricia = create(:user, :without_devise_email, notification_email: "patoche@duroy.fr")
      expect(described_class.search_by_text("patoche@duroy.fr")).to eq([patricia])
    end

    it "returns users that match with phone_number_formatted" do
      jean = create(:user, phone_number: "01 30 30 04 04")
      create(:user, phone_number: "01 31 34 34 34")
      expect(described_class.search_by_text("+3313030")).to eq([jean])
    end

    it "orders results by search terms" do
      match_in_last_name = create(:user, first_name: "Marie", last_name: "Nicolas")
      match_in_first_name = create(:user, first_name: "Nicolas", last_name: "Marie")
      match_in_email = create(:user, first_name: "Frédéric", last_name: "Petit", email: "nicolas@example.com")
      expect(described_class.search_by_text("nicolas")).to eq([match_in_last_name, match_in_first_name, match_in_email])
    end
  end

  describe(Agent) do
    it "returns agents that match with first name" do
      create(:agent, first_name: "jean", last_name: "valjean")
      martine = create(:agent, first_name: "martine")
      expect(described_class.search_by_text("martine")).to eq([martine])
    end

    it "returns agent that match with partial email" do
      create(:agent, email: "jean@moustache.fr")
      martine = create(:agent, email: "martine@validay.fr")
      expect(described_class.search_by_text("martine@val")).to eq([martine])
    end

    it "returns agent that match with exact email" do
      create(:agent, email: "jean@moustache.fr")
      martine = create(:agent, email: "martine@validay.fr")
      expect(described_class.search_by_text("martine@validay.fr")).to eq([martine])
    end
  end
end
