# frozen_string_literal: true

describe TextSearch, type: :concern do
  # Tester les methods du concerns sans un objet des modles...
  # Peut-être difficile sans activerecord ?

  shared_examples ".search_by_text" do
    it "return findme objects" do
      expect(described_class.search_by_text("findme")).to eq([object])
    end
  end

  shared_examples "#refresh_search_terms" do
    it "update search_terms with combined search terms value" do
      expect do
        object_to_save.refresh_search_terms
      end.to change(object_to_save, :search_terms).from(nil).to("findme")
    end
  end

  shared_examples "#combined_search_terms" do
    it "returns truc truc blabla" do
      expect(object.combined_search_terms).to eq("findme")
    end
  end

  describe(Team) do
    let(:other_object) { create(:team, name: "dont") }
    let(:object) { create(:team, name: "findme") }
    let(:object_to_save) { build(:team, name: "findme") }

    include_examples ".search_by_text"
    include_examples "#refresh_search_terms"
    include_examples "#combined_search_terms"
  end

  # Test sur qui inclue ce concerns
end
