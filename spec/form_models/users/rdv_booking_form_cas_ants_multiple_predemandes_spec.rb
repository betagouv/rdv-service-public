RSpec.describe Users::RdvBookingForm do
  let(:domain) { Domain::RDV_SERVICE_PUBLIC }
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
  let!(:motif_category) { create(:motif_category, :passeport) }
  let!(:motif) { create(:motif, organisation:, motif_category:) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }

  include_context "rdv_mairie_api_authentication"

  before do
    allow(rdv_builder).to receive(:creneau).and_return(creneau)
    stub_ants_status_ok("VALID00001", status: "validated", meeting_point_id: lieu.id, appointments: [])
    stub_ants_status_ok("VALID00002", status: "validated", meeting_point_id: lieu.id, appointments: [])
    stub_ants_status_ok("VALID00003", status: "validated", meeting_point_id: lieu.id, appointments: [])
    stub_ants_status_ok("UNKNOW0001", status: "unknown", meeting_point_id: lieu.id, appointments: [])
    stub_ants_status_ok(
      "WITHAPPOI1", status: "validated", meeting_point_id: lieu.id,
                    appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
    )
  end

  context "3 pré-demandes + 3 proches préexistants" do
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id, ants_pre_demandes_count: 3 }) }
    let!(:proche1) { create(:user, :relative, responsible: user) }
    let!(:proche2) { create(:user, :relative, responsible: user) }
    let!(:proche3) { create(:user, :relative, responsible: user) }

    context "sélectionnés : current_user + 2 nouveaux proches" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        julie = User.find_by!(first_name: "Julie", last_name: "Martin")
        expect(form.rdv.users).to contain_exactly(user, marc, julie)
        expect(marc.created_through).to eq("user_relative_creation")
        expect(julie.created_through).to eq("user_relative_creation")
        expect(user.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(marc.ants_pre_demande_number).to eq("VALID00002")
        expect(julie.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : current_user + 2 nouveaux proches, mais les proches existants sont soumis avec des numéros de pré-demandes" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "IGNORED0001" },
              "r#{proche2.id}" => { id: proche2.id.to_s, ants_pre_demande_number: "IGNORED0002" },
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        julie = User.find_by!(first_name: "Julie", last_name: "Martin")
        expect(form.rdv.users).to contain_exactly(user, marc, julie)
        expect(user.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(marc.ants_pre_demande_number).to eq("VALID00002")
        expect(julie.ants_pre_demande_number).to eq("VALID00003")
        expect(proche1.reload.ants_pre_demande_number).to be_nil
        expect(proche2.reload.ants_pre_demande_number).to be_nil
      end
    end

    context "sélectionnés : current_user + 2 proches existants" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "VALID00002" },
              "r#{proche2.id}" => { id: proche2.id.to_s, ants_pre_demande_number: "VALID00003" },
              "r#{proche3.id}" => { id: proche3.id.to_s },
            },
          },
          selected_users: ["current_user", "existing_relative_#{proche1.id}", "existing_relative_#{proche2.id}"]
        )
        expect { form.save }.to change(Rdv, :count).by(1)
        expect(form.rdv.users).to contain_exactly(user, proche1, proche2)
        expect(user.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(proche1.reload.ants_pre_demande_number).to eq("VALID00002")
        expect(proche2.reload.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : current_user + 1 proche existant + 1 nouveau proche" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "VALID00002" },
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: ["current_user", "existing_relative_#{proche1.id}", "new_relative_0"]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(1)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        expect(form.rdv.users).to contain_exactly(user, proche1, marc)
        expect(user.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(proche1.reload.ants_pre_demande_number).to eq("VALID00002")
        expect(marc.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : 3 proches existants (mais pas le current_user)" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "VALID00001" },
              "r#{proche2.id}" => { id: proche2.id.to_s, ants_pre_demande_number: "VALID00002" },
              "r#{proche3.id}" => { id: proche3.id.to_s, ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: ["existing_relative_#{proche1.id}", "existing_relative_#{proche2.id}", "existing_relative_#{proche3.id}"]
        )
        expect { form.save }.to change(Rdv, :count).by(1)
        expect(form.rdv.users).to contain_exactly(proche1, proche2, proche3)
        expect(proche1.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(proche2.reload.ants_pre_demande_number).to eq("VALID00002")
        expect(proche3.reload.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : 3 nouveaux proches (mais pas le current_user)" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00001" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
              "2" => { first_name: "Paul", last_name: "Blanc", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: %w[new_relative_0 new_relative_1 new_relative_2]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(3)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        julie = User.find_by!(first_name: "Julie", last_name: "Martin")
        paul = User.find_by!(first_name: "Paul", last_name: "Blanc")
        expect(form.rdv.users).to contain_exactly(marc, julie, paul)
        expect(marc.ants_pre_demande_number).to eq("VALID00001")
        expect(julie.ants_pre_demande_number).to eq("VALID00002")
        expect(paul.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : current_user avec un numéro invalide + 2 nouveaux proches avec des numéros valides" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "UNKNOW0001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00001" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors[:ants_pre_demande_number]).to be_present
      end
    end

    context "sélectionnés : current_user avec un numéro invalide + 2 proches existants avec des numéros valides" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "UNKNOW0001",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "VALID00001" },
              "r#{proche2.id}" => { id: proche2.id.to_s, ants_pre_demande_number: "VALID00002" },
              "r#{proche3.id}" => { id: proche3.id.to_s },
            },
          },
          selected_users: ["current_user", "existing_relative_#{proche1.id}", "existing_relative_#{proche2.id}"]
        )
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors[:ants_pre_demande_number]).to be_present
      end
    end

    context "sélectionnés : current_user avec un numéro valide + 1 nouveau proche avec un numéro invalide + 1 nouveau proche avec un numéro valide" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "UNKNOW0001" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors.full_messages).to contain_exactly("Numéro de pré-demande ANTS n'est pas reconnu par l'ANTS")
      end
    end

    context "sélectionnés : current_user avec un numéro valide + 1 proche existant avec un numéro invalide + 1 proche existant avec un numéro valide" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "UNKNOW0001" },
              "r#{proche2.id}" => { id: proche2.id.to_s, ants_pre_demande_number: "VALID00002" },
              "r#{proche3.id}" => { id: proche3.id.to_s },
            },
          },
          selected_users: ["current_user", "existing_relative_#{proche1.id}", "existing_relative_#{proche2.id}"]
        )
        expect { form.save }.not_to change(Rdv, :count)
      end
    end

    context "sélectionnés : 1 proche existant + 2 nouveaux proches (mais pas le current_user)" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            relatives_attributes: {
              "r#{proche1.id}" => { id: proche1.id.to_s, ants_pre_demande_number: "VALID00001" },
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: ["existing_relative_#{proche1.id}", "new_relative_0", "new_relative_1"]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        julie = User.find_by!(first_name: "Julie", last_name: "Martin")
        expect(form.rdv.users).to contain_exactly(proche1, marc, julie)
        expect(proche1.reload.ants_pre_demande_number).to eq("VALID00001")
        expect(marc.ants_pre_demande_number).to eq("VALID00002")
        expect(julie.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "sélectionnés : current_user + 2 nouveaux proches, dont un a déjà un appointment" do
      it "empêche la création et affiche un avertissement bénin" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "WITHAPPOI1" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors_are_all_benign?).to be true
        expect(form.benign_errors).to eq(
          [
            <<-TXT.squish,
                  Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Montrouge.
                  Veuillez <a href="http://rdvsympa.fr/123" target="_blank">annuler ce RDV</a> avant d'en prendre un nouveau.
            TXT
          ]
        )
      end
    end

    context "sélectionnés : current_user avec un numéro mal formatté + 1 nouveau proche avec un numéro déjà utilisé + 1 nouveau proche valide" do
      it "affiche uniquement l'erreur bloquante, sans mélanger le message bénin (HTML) au milieu" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "abhs",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "WITHAPPOI1" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors_are_all_benign?).to be false
        expect(form.not_benign_errors.map(&:message)).to contain_exactly("doit comporter 10 chiffres et lettres")
        expect(form.benign_errors.join).to include("<a href=")
      end
    end

    context "sélectionnés : current_user + 2 nouveaux proches, dont un a déjà un appointment, en ignorant les avertissements" do
      it "n'empêche pas la création" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678",
            ants_pre_demande_number: "VALID00001", ignore_benign_errors: "true",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "WITHAPPOI1" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00002" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
      end
    end
  end

  context "3 pré-demandes + aucun proche pré-existant" do
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id, ants_pre_demandes_count: 3 }) }

    context "sélectionnés : le current_user + 2 nouveaux proches" do
      it do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678", ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "VALID00003" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
        marc = User.find_by!(first_name: "Marc", last_name: "Durant")
        julie = User.find_by!(first_name: "Julie", last_name: "Martin")
        expect(form.rdv.users).to contain_exactly(user, marc, julie)
        expect(user.ants_pre_demande_number).to eq("VALID00001")
        expect(marc.ants_pre_demande_number).to eq("VALID00002")
        expect(julie.ants_pre_demande_number).to eq("VALID00003")
      end
    end

    context "avec un proche dont le numéro de pré-demande est manquant" do
      it "ne crée pas le RDV" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678", ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
      end
    end

    context "avec un proche dont le numéro de pré-demande a un mauvais format" do
      it "ne crée pas le RDV" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678", ants_pre_demande_number: "VALID00001",
            relatives_attributes: {
              "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "VALID00002" },
              "1" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "TROP_COURT" },
            },
          },
          selected_users: %w[current_user new_relative_0 new_relative_1]
        )
        expect { form.save }.not_to change(Rdv, :count)
      end
    end

    context "quand seul le 3e nouveau proche est sélectionné et que ses informations sont en erreur" do
      it "réindexe la sélection et garde les informations saisies sur le proche réaffiché en position 0" do
        form = described_class.new(
          user:, rdv_builder:, domain:,
          user_attributes: {
            relatives_attributes: {
              "0" => {},
              "1" => {},
              "2" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "UNKNOW0001" },
            },
          },
          selected_users: ["new_relative_2"]
        )
        expect(form.valid?).to be false
        expect(form.selected_users).to eq(["new_relative_0"])
        expect(form.new_proches.first.first_name).to eq("Marc")
        expect(form.new_proches.first.ants_pre_demande_number).to eq("UNKNOW0001")
      end
    end
  end
end
