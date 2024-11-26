RSpec.describe "Visioplainte agents can work on sunday" do
  context "for a visioplainte agent" do
    before do
      load Rails.root.join("db/seeds/visioplainte.rb")
    end

    let(:superviseur) { Agent.find_by(first_name: "Superviseur") }

    describe "plages d'ouverture" do
      it "can be created on sunday" do
        visit plage_ouverture_path
      end
    end

    describe ""
  end

  context "for a normal agent" do
  end
end
