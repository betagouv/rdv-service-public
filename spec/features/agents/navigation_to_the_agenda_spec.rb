RSpec.describe "Route vers l'agenda" do
  context "when the agent is not signed i" do
    it "redirects to the sign in page" do
      visit "/agents/agenda"
      raise "TODO: continuer ici"
    end
  end

  context "when the agent is signed in" do
    context "and they don't have any organisation" do
      it "redirects to the page to create a new organisation"
    end

    context "and they have one organisation" do
      it "shows the agenda for this organisation"
    end

    context "and they have multiple organisations" do
      it "redirections to the list of organisations"
    end
  end
end
