RSpec.describe BenignErrors do
  describe "cas simple, sans association" do
    let(:model) do
      Class.new do
        include ActiveModel::Model
        include BenignErrors
      end.new
    end

    context "sans aucune erreur" do
      it { expect(model.errors_are_all_benign?).to be false }
      it { expect(model.benign_errors).to be_empty }
      it { expect(model.not_benign_errors).to be_empty }
    end

    context "avec une erreur bénigne" do
      before { model.add_benign_error("un message bénin") }

      it { expect(model.errors_are_all_benign?).to be true }
      it { expect(model.benign_errors).to eq(["un message bénin"]) }
      it { expect(model.not_benign_errors).to be_empty }
    end

    context "avec une erreur non bénigne" do
      before { model.errors.add(:name, "ne peut pas être vide") }

      it { expect(model.errors_are_all_benign?).to be false }
      it { expect(model.benign_errors).to be_empty }
      it { expect(model.not_benign_errors.map(&:attribute)).to contain_exactly(:name) }
    end

    context "avec une erreur bénigne et une erreur non bénigne" do
      before do
        model.add_benign_error("un message bénin")
        model.errors.add(:name, "ne peut pas être vide")
      end

      it { expect(model.errors_are_all_benign?).to be false }
      it { expect(model.benign_errors).to eq(["un message bénin"]) }
      it { expect(model.not_benign_errors.map(&:attribute)).to contain_exactly(:name) }
    end
  end

  context "has_many et accepts_nested_attributes_for (User#relatives)" do
    let(:user) { build(:user) }

    # Reproduit ce que fait Users::RdvBookingForm#initialize
    # accepts_nested_attributes_for force autosave: true sur la reflection
    # sans ce autosave, Rails n'importe qu'une erreur générique :relatives sans le détail
    before { user.singleton_class.accepts_nested_attributes_for :relatives }

    context "l'usager n'a aucun proche et aucune erreur" do
      before { user.valid? }

      it { expect(user.errors_are_all_benign?).to be false }
      it { expect(user.benign_errors).to be_empty }
      it { expect(user.not_benign_errors).to be_empty }
    end

    context "l'usager a un proche avec une erreur bénigne" do
      before do
        relative = user.relatives.build(first_name: "Enfant", last_name: "Test", created_through: "user_relative_creation")
        relative.define_singleton_method(:add_benign_error_for_test) { add_benign_error("erreur bénigne sur le proche") }
        relative.singleton_class.validate(:add_benign_error_for_test)
        user.valid?
      end

      it { expect(user.errors_are_all_benign?).to be true }
      it { expect(user.benign_errors).not_to be_empty }
      it { expect(user.not_benign_errors).to be_empty }
    end

    context "l'usager a un proche avec une erreur non bénigne" do
      before do
        user.relatives.build(first_name: "Enfant", created_through: "user_relative_creation") # last_name manquant
        user.valid?
      end

      it { expect(user.errors_are_all_benign?).to be false }
      it { expect(user.benign_errors).to be_empty }
      it { expect(user.not_benign_errors.map(&:attribute)).to contain_exactly(:"relatives.last_name") }
    end

    context "l'usager a un proche avec une erreur bénigne et une non bénigne" do
      before do
        relative = user.relatives.build(first_name: "Enfant", created_through: "user_relative_creation") # last_name manquant
        relative.define_singleton_method(:add_benign_error_for_test) { add_benign_error("erreur bénigne sur le proche") }
        relative.singleton_class.validate(:add_benign_error_for_test)
        user.valid?
      end

      it { expect(user.errors_are_all_benign?).to be false }
      it { expect(user.benign_errors).to eq(["erreur bénigne sur le proche"]) }
      it { expect(user.not_benign_errors.map(&:attribute)).to contain_exactly(:"relatives.last_name") }
    end
  end
end
