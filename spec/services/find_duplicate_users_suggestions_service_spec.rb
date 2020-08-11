describe FindDuplicateUsersSuggestionsService, type: :service do
  subject { FindDuplicateUsersSuggestionsService.perform_with(organisation).hits }
  let!(:organisation) { create(:organisation) }

  context "a duplicate on the same name" do
    let!(:user1) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUES") }
    let!(:user2) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "PATRICK") }
    let!(:user3) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUS") }

    it "should find the duplicate pair" do
      suggestions = subject
      expect(suggestions.count).to eq 1
      expect(suggestions.first.user_ids).to eq([user1.id, user3.id])
    end
  end

  context "multiple duplicates on the same name" do
    let!(:user1) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUES") }
    let!(:user2) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "PATRICK") }
    let!(:user3) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUE") }
    let!(:user4) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUSS") }

    it "should find multiple duplicate pairs" do
      suggestions = subject
      expect(suggestions.count).to eq 3
      user_ids_pairs = suggestions.map(&:user_ids)
      expect(user_ids_pairs).to include([user1.id, user3.id])
      expect(user_ids_pairs).to include([user1.id, user4.id])
      expect(user_ids_pairs).to include([user3.id, user4.id])
    end
  end

  context "hydrate_users option" do
    let!(:user1) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUES") }
    let!(:user2) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "PATRICK") }
    let!(:user3) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUE") }
    let!(:user4) { create(:user, organisations: [organisation], first_name: "Jean", last_name: "JACQUSS") }

    it "should find multiple duplicate pairs" do
      suggestions = FindDuplicateUsersSuggestionsService.perform_with(organisation, hydrate_users: true).hits
      expect(suggestions.count).to eq 3
      user_ids_pairs = suggestions.map(&:users)
      expect(user_ids_pairs).to include([user1, user3])
      expect(user_ids_pairs).to include([user1, user4])
      expect(user_ids_pairs).to include([user3, user4])
    end
  end

  context "Monsieur or Madame words in names" do
    let!(:user1) { create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JACQUES") }
    let!(:user2) { create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JANY") }
    let!(:user3) { create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JACQUS") }

    it "should ignore monsieur and madame in matches" do
      user_ids_pairs = subject.map(&:user_ids)
      expect(user_ids_pairs).to include([user1.id, user3.id])
      expect(user_ids_pairs).not_to include([user1.id, user2.id])
    end
  end
end
