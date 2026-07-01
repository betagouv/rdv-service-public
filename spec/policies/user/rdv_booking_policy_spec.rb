RSpec.describe User::RdvBookingPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:pundit_context) { user }
  let(:domain) { Domain::RDV_SERVICE_PUBLIC }

  # ─── RDV individuel ───────────────────────────────────────────────────────────

  context "RDV individuel : l'usager réserve pour lui-même" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV individuel : tentative de réserver pour un autre usager via user_ids param" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [create(:user).id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :new? # le create? est contrôlé via les selected_users plus bas
  end

  context "RDV individuel : motif non réservable par les usagers" do
    let(:rdv_booking_form) do
      motif = create(:motif, bookable_by: :agents_and_prescripteurs)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV individuel : l'usager sélectionne un proche existant" do
    let(:rdv_booking_form) do
      relative = create(:user, :relative, responsible: user)
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["existing_relative_#{relative.id}"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end

  context "RDV individuel : l'usager tente de sélectionner le proche d'un autre usager" do
    let(:rdv_booking_form) do
      other_relative = create(:user, :relative, responsible: create(:user))
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["existing_relative_#{other_relative.id}"])
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :create?
  end

  context "RDV individuel : l'usager sélectionne un nouveau proche (non persisté)" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["new_relative_0"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end

  context "RDV individuel : selected_users avec une valeur inconnue" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["unknown_value"])
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :create?
  end

  # ─── RDV collectif ────────────────────────────────────────────────────────────

  context "RDV collectif : réservation pour l'usager lui-même" do
    let(:rdv_booking_form) do
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV collectif : réservation pour un proche existant" do
    let(:rdv_booking_form) do
      relative = create(:user, :relative, responsible: user)
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["existing_relative_#{relative.id}"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV collectif : réservation pour un nouveau proche (non persisté)" do
    let(:rdv_booking_form) do
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["new_relative_0"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV collectif : tentative de réservation pour le proche d'un autre usager" do
    let(:rdv_booking_form) do
      other_relative = create(:user, :relative, responsible: create(:user))
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["existing_relative_#{other_relative.id}"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :new?
    it_behaves_like "not permit actions", :rdv_booking_form, :create?
  end

  context "RDV collectif révoqué" do
    let(:rdv_booking_form) do
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_collectif.revoked!
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :new?, :create?
  end

  context "RDV collectif : motif non réservable par les usagers" do
    let(:rdv_booking_form) do
      rdv_collectif = create(:rdv, :collectif, :without_users)
      rdv_collectif.motif.update!(bookable_by: :agents_and_prescripteurs)
      rdv_builder = Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:)
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :new?, :create?
  end

  # ─── Cas ANTS multi-participants ──────────────────────────────────────────────
  # Pour les démarches ANTS, plusieurs proches peuvent être sélectionnés simultanément.
  # La policy doit vérifier TOUS les selected_users avec .all?
  context "ANTS : juste le current_user sélectionné" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["current_user"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end

  context "ANTS : current_user + plusieurs proches sélectionnés" do
    let(:rdv_booking_form) do
      relative1 = create(:user, :relative, responsible: user)
      relative2 = create(:user, :relative, responsible: user)
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["current_user", "existing_relative_#{relative1.id}", "existing_relative_#{relative2.id}"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end

  context "ANTS : current_user + un proches existant + une erreur" do
    let(:rdv_booking_form) do
      relative1 = create(:user, :relative, responsible: user)
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["current_user", "existing_relative_#{relative1.id}", "unrecognized_value"])
    end

    it_behaves_like "not permit actions", :rdv_booking_form, :create?
  end

  context "ANTS : mix proche valide + proche d'un autre usager" do
    let(:rdv_booking_form) do
      relative = create(:user, :relative, responsible: user)
      other_relative = create(:user, :relative, responsible: create(:user))
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["existing_relative_#{relative.id}", "existing_relative_#{other_relative.id}"])
    end

    # Un seul participant non autorisé suffit à bloquer
    it_behaves_like "not permit actions", :rdv_booking_form, :create?
  end

  context "ANTS : plusieurs nouveaux proches (non persistés)" do
    let(:rdv_booking_form) do
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: %w[new_relative_0 new_relative_1])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end

  context "ANTS : mix nouveau proche + proche existant valide" do
    let(:rdv_booking_form) do
      relative = create(:user, :relative, responsible: user)
      motif = create(:motif)
      rdv_builder = Users::RdvBuilder.new(user, { motif_id: motif.id, user_ids: [user.id] })
      Users::RdvBookingForm.new(user:, rdv_builder:, domain:, selected_users: ["new_relative_0", "existing_relative_#{relative.id}"])
    end

    it_behaves_like "permit actions", :rdv_booking_form, :create?
  end
end
