RSpec.describe UpsertUserForFranceconnectService, type: :service do
  let(:omniauth_info) do
    OpenStruct.new(email: "jeanne@longo.fr",
                   given_name: "jeanne",
                   family_name: "longo",
                   preferred_username: "DUPONT",
                   birthdate: Date.parse("1971-06-20"),
                   sub: "hvdiuds4357")
  end

  def expect_france_connect_fields_to_be_up_to_date(user)
    expect(user.email).to be_nil # Pour un usager qui ne se connecte pas par email/mot de passe
    expect(user.notification_email).to eq("jeanne@longo.fr")

    expect(user.first_name).to eq("jeanne")
    expect(user.birth_name).to eq("longo")
    expect(user.last_name).to eq("DUPONT")
    expect(user.birth_date).to eq(Date.parse("1971-06-20"))
    expect(user.franceconnect_openid_sub).to eq("hvdiuds4357")
  end

  context "no pre-existing user" do
    it "creates a user" do
      service = described_class.new(omniauth_info)
      expect { service.perform }.to change(User, :count).by(1)
      expect(service.new_user?).to be(true)

      expect_france_connect_fields_to_be_up_to_date(service.user.reload)
    end
  end

  context "pre-existing user with same franceconnect sub but different infos" do
    context "not using devise" do
      before do
        create(
          :user,
          email: nil,
          encrypted_password: "",
          franceconnect_openid_sub: "hvdiuds4357",
          logged_once_with_franceconnect: true,
          first_name: "Jeannine",
          birth_name: "LONGINO",
          birth_date: nil
        )
      end

      it "finds the user and updates her info" do
        service = described_class.new(omniauth_info)
        expect { service.perform }.not_to change(User, :count)
        expect(service.new_user?).to be(false)

        expect_france_connect_fields_to_be_up_to_date(service.user.reload)
      end

      context "when the france connect email has capital letters" do
        let(:omniauth_info) do
          OpenStruct.new(email: "JEANNE@longo.fr",
                         given_name: "jeanne",
                         family_name: "longo",
                         preferred_username: "DUPONT",
                         birthdate: Date.parse("1971-06-20"),
                         sub: "hvdiuds4357")
        end

        it "downcases the email" do
          service = described_class.new(omniauth_info)
          expect { service.perform }.not_to change(User, :count)
          expect(service.new_user?).to be(false)
          user = service.user.reload
          expect(user.notification_email).to eq("jeanne@longo.fr")
        end
      end
    end

    context "when the user also users Devise to login with an email and a passowrd" do
      before do
        create(
          :user,
          email: "jeanne@longo.fr",
          password: "coRrect!h0rse",
          franceconnect_openid_sub: "hvdiuds4357",
          logged_once_with_franceconnect: true,
          first_name: "Jeannine",
          birth_name: "LONGINO",
          birth_date: nil
        )
      end

      it "finds the user and updates her info" do
        service = described_class.new(omniauth_info)
        expect { service.perform }.not_to change(User, :count)
        expect(service.new_user?).to be(false)
        user = service.user.reload

        expect(user).to have_attributes(
          {
            email: "jeanne@longo.fr",
            notification_email: nil,
            birth_name: "longo",
          }
        )
      end
    end
  end

  context "pre-existing user with same email but different infos" do
    before do
      create(
        :user,
        email: "jeanne@longo.fr",
        first_name: "Jeannine",
        last_name: "LONGINO",
        birth_name: nil,
        birth_date: Date.parse("1970-02-15")
      )
    end

    it "creates a new user" do
      service = described_class.new(omniauth_info)
      expect { service.perform }.to change(User, :count).by(1)
      expect(service.new_user?).to be(true)

      expect_france_connect_fields_to_be_up_to_date(service.user.reload)
    end
  end
end
