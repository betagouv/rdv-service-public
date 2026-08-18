RSpec.describe Admin::Planning::PlageOuverturesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) { create(:motif, organisation: organisation, service: service) }
  let!(:lieu1) { create(:lieu, organisation: organisation, name: "MDS Sud", address: "10 rue Belsunce, Paris, 75016") }

  shared_examples "un agent peut créer, consulter, modifier et supprimer une plage d'ouverture" do
    describe "GET #show" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          title: "Permanence",
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      it "affiche la plage d'ouverture" do
        get :show, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(response).to be_successful
        expect(assigns(:plage_ouverture)).to eq(plage_ouverture)
      end
    end

    describe "GET #index" do
      it "renvoie une réponse de succès" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
        expect(assigns(:plage_ouvertures)).to eq([plage_ouverture])
      end

      it "assigne les plages d'ouverture" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(assigns(:plage_ouvertures)).to eq([plage_ouverture])
      end

      it "affiche l'onglet quand une plage est expirée" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now - 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(assigns(:display_tabs)).to be true
      end

      it "assigne les plages d'ouverture expirées quand l'onglet courant est \"expired\"" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)
        expired_plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now - 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id, current_tab: "expired" }
        expect(assigns(:plage_ouvertures)).to eq([expired_plage_ouverture])
      end
    end

    describe "GET #new" do
      it "renvoie une réponse de succès" do
        get :new, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "renvoie une réponse de succès" do
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent)
        get :edit, params: { organisation_id: organisation.id, id: plage_ouverture.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          :weekly_on_monday,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      context "avec des paramètres valides pour une PO exceptionnelle non chevauchante" do
        let(:valid_params) do
          {
            organisation_id: organisation.id,
            plage_ouverture: {
              title: "Permanence ecole",
              motif_ids: [motif.id],
              lieu_id: lieu1.id,
              organisation_id: organisation.id,
              agent_id: agent.id,
              first_day: "17/11/2020",
              start_time: "09:00",
              end_time: "12:00",
              minutes_after_rdvs: 15,
            },
          }
        end

        it "la crée et redirige vers l'index" do
          expect { post(:create, params: valid_params) }.to change { agent.plage_ouvertures.count }.by(1)
          created_plage = PlageOuverture.last
          expect(response).to redirect_to(admin_organisation_planning_plage_ouvertures_path(organisation_id: created_plage.organisation, agent_id: created_plage.agent_id))
        end

        it "utilise les paramètres fournis" do
          expect { post(:create, params: valid_params) }.to change { agent.plage_ouvertures.count }.by(1)
          expected_attrs = {
            title: "Permanence ecole",
            motif_ids: [motif.id],
            lieu_id: lieu1.id,
            organisation_id: organisation.id,
            agent_id: agent.id,
            first_day: Date.new(2020, 11, 17),
            start_time: Tod::TimeOfDay.new(9),
            end_time: Tod::TimeOfDay.new(12),
            minutes_after_rdvs: 15,
          }
          expect(PlageOuverture.last).to have_attributes(expected_attrs)
        end

        it "envoie une notification après la création" do
          perform_enqueued_jobs do
            expect { post(:create, params: valid_params) }.to change { ActionMailer::Base.deliveries.size }.by(1)
          end
          expect(ActionMailer::Base.deliveries.last.subject).to eq("RDV Service Public - Plage d’ouverture créée - Permanence ecole")
        end

        it "n'envoie pas de notification après la création quand l'agent l'a désactivée" do
          agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations
          expect { post(:create, params: valid_params) }.not_to change { ActionMailer::Base.deliveries.size }
        end
      end

      context "avec des paramètres invalides" do
        it "ne crée pas de nouvelle plage d'ouverture" do
          post(
            :create,
            params: {
              organisation_id: organisation.id,
              plage_ouverture: {
                motif_ids: [motif.id],
                lieu_id: lieu1.id,
                organisation_id: organisation.id,
                agent_id: agent.id,
                # champs manquants
              },
            }
          )
          expect(response).to be_successful
          expect(response).to render_template(:new)
          expect(agent.plage_ouvertures.count).to eq 1
        end
      end
    end

    describe "PUT #update" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      context "avec des paramètres valides" do
        it "met à jour la plage d'ouverture demandée" do
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          expect(response).to redirect_to(admin_organisation_planning_plage_ouvertures_path(organisation_id: plage_ouverture.organisation, agent_id: plage_ouverture.agent_id))
        end

        it "envoie une notification après la modification" do
          ActionMailer::Base.deliveries.clear
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          perform_enqueued_jobs
          expect(ActionMailer::Base.deliveries.size).to eq(1)
          expect(ActionMailer::Base.deliveries.last.subject).to eq("RDV Service Public - Plage d’ouverture modifiée - Le nouveau nom")
        end

        it "n'envoie pas de notification après la modification quand l'agent l'a désactivée" do
          ActionMailer::Base.deliveries.clear
          agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          expect(ActionMailer::Base.deliveries.size).to eq(0)
        end
      end

      context "avec des paramètres invalides (end_time avant start_time)" do
        it "renvoie une réponse de succès (pour afficher le template 'edit') et ne met pas à jour" do
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { start_time: "10:00", end_time: "07:00" } }
          expect(response).to be_successful
          plage_ouverture.reload
          expect(plage_ouverture.start_time.to_s).not_to eq("10:00:00")
          expect(plage_ouverture.end_time.to_s).not_to eq("07:00:00")
        end
      end
    end

    describe "DELETE #destroy" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      it "détruit la plage d'ouverture demandée" do
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        end.to change(PlageOuverture, :count).from(1).to(0)
      end

      it "redirige vers l'index des plages d'ouverture" do
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(response).to redirect_to(admin_organisation_planning_plage_ouvertures_path(organisation, agent_id: plage_ouverture.agent_id))
      end

      it "envoie une notification après la suppression" do
        ActionMailer::Base.deliveries.clear
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect { perform_enqueued_jobs }.to change { ActionMailer::Base.deliveries.size }.by(1)
        expect(ActionMailer::Base.deliveries.last.subject).to include("RDV Service Public - Plage d’ouverture supprimée")
      end

      it "n'envoie pas de notification après la suppression quand l'agent l'a désactivée" do
        agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations
        ActionMailer::Base.deliveries.clear
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end

  context "CRUD sur sa propre plage d'ouverture" do
    before { sign_in agent }

    it_behaves_like "un agent peut créer, consulter, modifier et supprimer une plage d'ouverture"

    describe "PUT #update, en réassignant à un autre agent" do
      let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu1, organisation: organisation, agent: agent) }

      it "n'autorise pas la réassignation de la plage d'ouverture à un agent basique hors du périmètre de l'agent connecté" do
        other_service = create(:service)
        other_agent = create(:agent, basic_role_in_organisations: [organisation], service: other_service)

        # `agent` (basic, service `service`) est propriétaire de la plage donc autorisé une première fois,
        # mais `other_agent` n'est pas un confrère (service différent) : la ré-authorisation après
        # assign_attributes doit bloquer la réassignation.
        expect do
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { agent_id: other_agent.id } }
        end.not_to change { plage_ouverture.reload.agent_id }

        expect(flash[:error]).to be_present
      end
    end
  end

  context "CRUD d'un admin sur la plage d'ouverture d'un agent" do
    let(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { sign_in admin }

    it_behaves_like "un agent peut créer, consulter, modifier et supprimer une plage d'ouverture"
  end
end
