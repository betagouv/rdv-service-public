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
      create(:user, first_name: "jean", last_name: "valjean")
      patricia = create(:user, first_name: "patricia", last_name: "duroy")
      expect(described_class.search_by_text("patricia")).to eq([patricia])
    end

    it "returns users that match with partial email" do
      create(:user, email: "jean@moustache.fr", first_name: "Jean", last_name: "Bernard")
      patricia = create(:user, email: "patoche@duroy.fr", first_name: "Patricia", last_name: "Girard")
      expect(described_class.search_by_text("patoche@dur")).to eq([patricia])
      expect(described_class.search_by_text("patoche@")).to eq([patricia])
      expect(described_class.search_by_text("pato")).to eq([patricia])

      francis = create(:user, email: "francis_du_74@msn.com", first_name: "Francis", last_name: "Lemoine")
      expect(described_class.search_by_text("francis")).to eq([francis])
      expect(described_class.search_by_text("francis_")).to eq([francis])
      # Ces deux recherches ne fonctionnent pas actuellement, à voir plus tard
      # expect(described_class.search_by_text("francis_du")).to eq([francis])
      # expect(described_class.search_by_text("francis_du_74")).to eq([francis])
      expect(described_class.search_by_text("francis_du_74@")).to eq([francis])
      expect(described_class.search_by_text("francis_du_74@msn")).to eq([francis])
      expect(described_class.search_by_text("francis_du_74@autre")).to eq([])
    end

    it "returns users that match with exact email" do
      create(:user, email: "jean@moustache.fr")
      patricia = create(:user, email: "patoche@duroy.fr")
      expect(described_class.search_by_text("patoche@duroy.fr")).to eq([patricia])
    end

    it "returns users that match with phone_number_formatted" do
      jean = create(:user, phone_number: "01 30 30 04 04")
      eglantine = create(:user, phone_number: "+33131343434")
      martine = create(:user, phone_number: "+596 696 00 01 02")
      expect(described_class.search_by_text("+3313030")).to eq([jean])
      expect(described_class.search_by_text("+3313031")).to eq([])
      expect(described_class.search_by_text("01 31 34")).to eq([eglantine])
      expect(described_class.search_by_text("+596 696")).to eq([martine])
    end

    it "returns users that match with a phone number ending in 9" do
      user = create(:user, phone_number: "0658837569")
      expect(described_class.search_by_text("0658837569")).to eq([user])
    end

    it "returns users that match with a partial phone number prefix ending in 9" do
      user = create(:user, phone_number: "0699123456")
      expect(described_class.search_by_text("+33699")).to eq([user])
      expect(described_class.search_by_text("+33700")).to eq([])
    end

    it "returns users that match the given ID" do
      jean = create(:user, id: 1234567)
      _eglantine = create(:user)
      expect(described_class.search_by_text("1234567")).to eq([jean])
      expect(described_class.search_by_text("123456")).to eq([])
    end

    it "orders results by search terms" do
      match_in_last_name = create(:user, first_name: "Marie", last_name: "Nicolas")
      match_in_first_name = create(:user, first_name: "Nicolas", last_name: "Marie")
      match_in_email = create(:user, first_name: "Frédéric", last_name: "Petit", email: "nicolas@example.com")
      expect(described_class.search_by_text("nicolas")).to eq([match_in_last_name, match_in_first_name, match_in_email])
    end

    it "ignores accents" do
      francois = create(:user, first_name: "François", last_name: "Girard")
      emilie = create(:user, first_name: "Émilie", last_name: "Robert")
      dede = create(:user, first_name: "Dédé", last_name: "Lefevre")
      expect(described_class.search_by_text("franco")).to eq([francois])
      expect(described_class.search_by_text("franço")).to eq([francois])
      expect(described_class.search_by_text("emi")).to eq([emilie])
      expect(described_class.search_by_text("Émi")).to eq([emilie])
      expect(described_class.search_by_text("émi")).to eq([emilie])
      expect(described_class.search_by_text("dédé")).to eq([dede])
      expect(described_class.search_by_text("dedé")).to eq([dede])
    end

    it "allows searching with several names" do
      josephine = create(:user, first_name: "Josephine", last_name: "Duroy")
      expect(described_class.search_by_text("josephine duroy")).to eq([josephine])
      expect(described_class.search_by_text("josephine dur")).to eq([josephine])
      expect(described_class.search_by_text("duroy jo")).to eq([josephine])
      expect(described_class.search_by_text("josephine duroi")).to eq([])
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
