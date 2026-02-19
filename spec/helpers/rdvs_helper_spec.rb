RSpec.describe RdvsHelper do
  include ActionView::Helpers::DateHelper

  let(:organisation) { create(:organisation) }
  let(:motif) { build(:motif, name: "Consultation normale", organisation:) }
  let(:user) { build(:user, first_name: "Marie", last_name: "DENIS") }
  let(:rdv) { build(:rdv, users: [user], motif: motif, organisation:) }

  describe "#rdv_title_for_agent" do
    subject { helper.rdv_title_for_agent(rdv) }

    it { is_expected.to eq "Marie DENIS" }

    context "multiple users" do
      let(:user2) { build(:user, first_name: "Lea", last_name: "CAVE") }
      let(:rdv) { build(:rdv, users: [user, user2], motif: motif) }

      it { is_expected.to eq "Marie DENIS et Lea CAVE" }

      context "for a rdv collectif" do
        let(:motif) { build(:motif, :collectif, name: "Atelier collectif") }

        it "shows the motif of the rdv rather than the list of users" do
          expect(subject).to eq "Atelier collectif"
        end

        context "with a rdv name" do
          before { rdv.name = "Traitement de texte" }

          it "shows the rdv name as well, since the motif only would be too vague" do
            expect(subject).to eq "Atelier collectif : Traitement de texte"
          end
        end
      end
    end

    context "created by user (bookabled by everyone (default))" do
      let(:rdv) { build(:rdv, users: [user], motif: motif, created_by: user) }

      it { is_expected.to eq "@ Marie DENIS" }
    end

    context "phone RDV" do
      let(:rdv) { build(:rdv, :by_phone, users: [user]) }

      it { is_expected.to eq "Marie DENIS ☎️" }
    end

    context "at home RDV" do
      let(:rdv) { build(:rdv, :at_home, users: [user]) }

      it { is_expected.to eq "Marie DENIS 🏠" }
    end
  end

  describe "#rdv_title" do
    it "show date, time and duration in minutes" do
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-10-23 12h54"), duration_in_min: 30)
      expect(rdv_title(rdv)).to eq("Le vendredi 23 octobre 2020 à 12h54 (durée : 30 minutes)")
    end

    it "when rdv starts_at today, show only time and duration in minutes" do
      now = Time.zone.parse("2020-10-23 12h54")
      travel_to(now)
      rdv = build(:rdv, starts_at: now + 3.hours, duration_in_min: 30)
      expect(rdv_title(rdv)).to eq("Aujourd’hui à 15h54 (durée : 30 minutes)")
    end
  end

  describe "#rdv_starts_at_and_duration" do
    context "with :human format" do
      it "return starts_at hour, minutes and duration" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-03-23 13:46"), duration_in_min: 4)
        expect(rdv_starts_at_and_duration(rdv, :human)).to eq("lundi 23 mars 2020 à 13h46 (4 minutes)")
      end

      it "return only starts_at hour, minutes when no duration_in_min" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-03-23 13:46"), duration_in_min: nil)
        expect(rdv_starts_at_and_duration(rdv, :human)).to eq("lundi 23 mars 2020 à 13h46")
      end
    end

    context "with :time_only format" do
      it "return starts_at hour, minutes and duration" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-03-23 13:46"), duration_in_min: 4)
        expect(rdv_starts_at_and_duration(rdv, :time_only)).to eq("13h46 (4 minutes)")
      end

      it "return only starts_at hour, minutes when no duration_in_min" do
        rdv = build(:rdv, starts_at: Time.zone.parse("2020-03-23 13:46"), duration_in_min: nil)
        expect(rdv_starts_at_and_duration(rdv, :time_only)).to eq("13h46")
      end
    end
  end

  describe "#change_status_confirmation_message" do
    let(:now) { Time.zone.parse("2022-01-10 10:00") }

    before do
      travel_to(now)
    end

    %i[seen excused revoked noshow].each do |rdv_status|
      context "with a today's RDV" do
        let(:rdv) { build(:rdv, starts_at: now) }

        it "returns empty string message for #{rdv_status}" do
          expect(change_status_confirmation_message(rdv, rdv_status)).to eq("")
        end
      end

      context "with a past's RDV" do
        let(:now) { Time.zone.parse("2022-01-10 10:00") }
        let(:rdv) { build(:rdv, starts_at: now - 2.days) }

        before do
          travel_to(now)
        end

        it "returns empty string message for #{rdv_status}" do
          expect(change_status_confirmation_message(rdv, rdv_status)).to eq("")
        end
      end
    end

    context "with a today's RDV" do
      it "returns reinit confirm message for unknown" do
        rdv = build(:rdv, starts_at: now)
        expect(change_status_confirmation_message(rdv, :unknown)).to eq("")
      end
    end

    context "with a past's RDV" do
      it "returns empty confirm message for unknown" do
        rdv = build(:rdv, starts_at: now - 2.days)
        expect(change_status_confirmation_message(rdv, :unknown)).to eq("")
      end
    end

    it "return reinit status message for a futur unknown RDV" do
      rdv = build(:rdv, :future)
      expected = I18n.t("admin.rdvs.message.confirm.reinit_status")
      expect(change_status_confirmation_message(rdv, "unknown")).to eq(expected)
    end

    it "return simple confirm message for a revoked future RDV with invisible motif" do
      motif = create(:motif, visibility_type: Motif::INVISIBLE, organisation:)
      rdv = create(:rdv, motif: motif, organisation:)
      expected = I18n.t("admin.rdvs.message.confirm.simple_cancel")
      expect(change_status_confirmation_message(rdv, "revoked")).to eq(expected)
    end

    it "return simple confirm message for a revoked future RDV with visible and notified motif" do
      motif = create(:motif, visibility_type: Motif::VISIBLE_AND_NOTIFIED, organisation:)
      rdv = create(:rdv, motif: motif, organisation:)
      expected = I18n.t("admin.rdvs.message.confirm.cancel_with_notification")
      expect(change_status_confirmation_message(rdv, "revoked")).to eq(expected)
    end
  end

  describe "show participants count" do
    context "for an individual rdv" do
      it "returns empty string" do
        rdv = build(:rdv, motif: build(:motif, collectif: false), users: [build(:user)])
        expect(show_participants_count(rdv)).to eq("")
      end
    end

    context "for a collectif rdv" do
      it "returns only users count without limitation" do
        rdv = build(:rdv, motif: build(:motif, collectif: true), users: [build(:user)], users_count: 1, max_participants_count: nil)
        expect(show_participants_count(rdv)).to eq("1")
      end

      it "returns users count and max participants" do
        rdv = build(:rdv, motif: build(:motif, collectif: true), users: [build(:user)], users_count: 1, max_participants_count: 3)
        expect(show_participants_count(rdv)).to eq("1 / 3")
      end
    end
  end

  describe "#dates_interval" do
    context "when start and end are both valid" do
      let(:params) { { start: "01/01/2024", end: "01/02/2024" } }

      it "displays date interval" do
        expect(dates_interval).to eq("Lundi 1 janvier 2024 - Jeudi 1 février 2024")
      end
    end

    context "when only start is valid and end is invalid" do
      let(:params) { { start: "01/01/2024", end: "invalid_date" } }

      it "displays only one date" do
        expect(dates_interval).to eq("A partir du Lundi 1 janvier 2024")
      end
    end

    context "when only end is valid and start is invalid" do
      let(:params) { { start: "invalid_date", end: "01/02/2024" } }

      it "displays only one date" do
        expect(dates_interval).to eq("Jusqu'au Jeudi 1 février 2024")
      end
    end

    context "when start and end are both invalid" do
      let(:params) { { start: "invalid_date", end: "invalid_date" } }

      it "displays nothing" do
        expect(dates_interval).to be_nil
      end
    end
  end

  describe "#display_user_phone_number_for_rdv" do
    subject { strip_tags(display_user_phone_number_for_rdv(rdv, current_agent)) }

    let(:current_agent) { build(:agent) }
    let(:rdv) { build(:rdv, :by_phone, users: [user], agents: [current_agent]) }
    let(:user) do
      build(:user, :francis_factice, phone_number: "0611223344")
    end

    context "when the current_agent participates in the rdv" do
      it "displays the user's phone number so that the agent can call them" do
        expect(subject).to eq "RDV téléphonique : vous pouvez appeler Francis FACTICE au 06 11 22 33 44."
      end

      context "with multiple users" do
        let(:other_user_with_phone) { build(:user, first_name: "Camille", last_name: "Avec téléphone", phone_number: "0122334455") }
        let(:user_without_phone) { build(:user, first_name: "Dominique", last_name: "Sans téléphone", phone_number: nil) }
        let(:rdv) { build(:rdv, :by_phone, users: [user, other_user_with_phone, user_without_phone], agents: [current_agent]) }

        it "displays all the available phone numbers" do
          expect(subject).to eq "RDV téléphonique : vous pouvez appeler Francis FACTICE au 06 11 22 33 44 ou Camille AVEC TÉLÉPHONE au 01 22 33 44 55."
        end
      end
    end

    context "when the current_agent doesn't participate in the rdv" do
      it "displays the proper text" do
        expect(strip_tags(display_user_phone_number_for_rdv(rdv, build(:agent)))).to eq "RDV téléphonique : l'agent peut appeler Francis FACTICE au 06 11 22 33 44."
      end
    end
  end
end
