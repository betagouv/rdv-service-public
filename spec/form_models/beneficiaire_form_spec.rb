# frozen_string_literal: true

RSpec.describe BeneficiaireForm do
  subject(:form) { described_class.new(params) }

  context "when all params are provided and valid" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "0611223344",
      }
    end

    it { is_expected.to be_valid }
  end

  context "when first name is missing" do
    let(:params) do
      {
        first_name: "",
        last_name: "Rogne",
        phone_number: "0611223344",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Prénom doit être rempli(e)")
    end
  end

  context "when last name is missing" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "",
        phone_number: "0611223344",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Nom d’usage doit être rempli(e)")
    end
  end

  context "when phone number is missing" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.benign_errors.first).to eq("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end

  context "when phone number is invalid" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "1234",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Téléphone n'est pas valide")
    end
  end

  context "when phone number is not mobile" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "0123456789",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Téléphone ne permet pas de recevoir des SMS")
    end
  end
end
