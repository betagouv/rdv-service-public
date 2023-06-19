# frozen_string_literal: true

RSpec.describe Agent::CustomDeviseTokenAuthUserOmniauthCallbacks, type: :concern do
  context "Verifying gem devise_token_auth change in user_omniauth_callbacks file." do
    let(:gem_name) { "devise_token_auth" }
    let(:file_path) { "app/models/devise_token_auth/concerns/user_omniauth_callbacks.rb" }
    let(:original_digest) { "abd3ec296adae23ed83e25747d8fd932054f98ddc64ead2488c3944c4b26030c" }

    def gem_path(gem_name)
      Gem::Specification.find_by_name(gem_name).gem_dir
    end

    def calculate_digest(gem_name, file_path)
      full_path = File.join(gem_path(gem_name), file_path)
      Digest::SHA256.file(full_path).hexdigest
    end

    it "user_omniauth_callbacks.rb digest must not change" do
      # If this test fails, adapt Agent::CustomDeviseTokenAuthUserOmniauthCallbacks with new changes and fix original_digest
      current_digest = calculate_digest(gem_name, file_path)
      expect(current_digest).to eq(original_digest)
    end
  end

  describe "included validations" do
    context "when agent has all roles intervenant" do
      let!(:organisation) { create(:organisation) }
      let(:agent) { build(:agent, email: nil) }
      let(:existing_agent) { build(:agent, email: nil) }

      before do
        existing_agent.roles = [create(:agent_role, :intervenant)]
        existing_agent.save
        agent.roles = [create(:agent_role, :intervenant)]
        agent.valid?
      end

      it "does not validate presence or nil uniqueness of the email" do
        expect(agent.errors[:email]).to be_empty
      end
    end

    context "when agent has not all roles intervenant" do
      let!(:organisation) { create(:organisation) }
      let!(:existing_agent) { create(:agent, admin_role_in_organisations: [organisation], email: "super_agent@gmail.com") }
      let(:agent) { build(:agent, admin_role_in_organisations: [organisation], email: nil) }

      it "validates presence of email" do
        agent.valid?
        expect(agent.errors[:email]).to include("doit être rempli(e)")
      end

      it "validates uniqueness of email" do
        agent.email = "super_agent@gmail.com"
        agent.valid?
        expect(agent.errors[:email]).to include("est déjà utilisé")
      end
    end
  end
end
