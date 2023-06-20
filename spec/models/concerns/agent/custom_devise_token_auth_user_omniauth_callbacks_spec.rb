# frozen_string_literal: true

RSpec.describe Agent::CustomDeviseTokenAuthUserOmniauthCallbacks, type: :concern do
  context "Verifying gem devise_token_auth change in user_omniauth_callbacks file." do
    it "user_omniauth_callbacks.rb digest must not change" do
      gem_name = "devise_token_auth"
      file_path = "app/models/devise_token_auth/concerns/user_omniauth_callbacks.rb"
      original_digest = "abd3ec296adae23ed83e25747d8fd932054f98ddc64ead2488c3944c4b26030c"

      gem_path = Gem::Specification.find_by_name(gem_name).gem_dir

      full_path = File.join(gem_path, file_path)
      current_digest = Digest::SHA256.file(full_path).hexdigest

      # Si ce test fails cela signifie que le fichier Agent::CustomDeviseTokenAuthUserOmniauthCallbacks de la gem devise_token_auth a changé.
      # Hors ce fichier est monkeypatched dans le fichier custom app/models/concerns/agent/custom_devise_token_auth_user_omniauth_callbacks.rb
      # Il faudra donc adapter le code de notre fichier custom avec les nouveautés du fichier de la gem mise à jour et mettre à jour le digest du fichier qui a été update.
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

    context "when agent has a role that is not intervenant" do
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

    context "when agent has no role" do
      let!(:organisation) { create(:organisation) }
      let!(:existing_agent) { create(:agent, admin_role_in_organisations: [organisation], email: "super_agent@gmail.com") }
      let(:agent) { build(:agent, email: nil) }

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
