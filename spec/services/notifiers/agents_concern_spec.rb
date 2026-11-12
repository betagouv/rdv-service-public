RSpec.describe Notifiers::AgentsConcern do
  describe ".soon_date?" do
    it "return false" do
      date = Time.zone.parse("2021-12-23 15:30")
      expect(described_class.soon_date?(date)).to be_falsey # rubocop:disable RSpec/PredicateMatcher
    end

    it "return true when date is today" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now
      expect(described_class.soon_date?(date)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    it "return true when date is tomorrow" do
      now = Time.zone.parse("2021-12-23 15:30")
      travel_to(now)
      date = now + 1.day
      expect(described_class.soon_date?(date)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end
  end

  describe ".should_notify_agent?" do
    let(:now) { Time.zone.parse("2021-12-23 15:30") }
    # L'auteur de la modification est implicitement `author` : should_notify? dit si l'agent passé en paramètre doit être notifié.
    let(:author) { build(:agent, rdv_notifications_level: level) }
    let(:colleague) { build(:agent, rdv_notifications_level: level) }
    let(:rdv) { build(:rdv, starts_at: starts_at) }
    let(:starts_at) { now + 10.days }

    before { travel_to(now) }

    def should_notify?(agent_to_notify)
      described_class.should_notify_agent?(rdv, agent_to_notify, author)
    end

    context "avec le niveau all" do
      let(:level) { "all" }

      it "notifie un collègue de l'auteur" do
        expect(should_notify?(colleague)).to be(true)
      end

      it "notifie l'auteur lui-même" do
        expect(should_notify?(author)).to be(true)
      end
    end

    context "avec le niveau none" do
      let(:level) { "none" }

      it "ne notifie jamais" do
        expect(should_notify?(colleague)).to be(false)
        expect(should_notify?(author)).to be(false)
      end
    end

    context "avec le niveau others" do
      let(:level) { "others" }

      it "notifie un collègue de l'auteur, même si le RDV est lointain" do
        expect(should_notify?(colleague)).to be(true)
      end

      it "ne notifie pas l'auteur lui-même" do
        expect(should_notify?(author)).to be(false)
      end
    end

    context "avec le niveau soon" do
      let(:level) { "soon" }

      context "quand le RDV est lointain" do
        it "ne notifie pas" do
          expect(should_notify?(colleague)).to be(false)
        end
      end

      context "quand le RDV a lieu aujourd'hui" do
        let(:starts_at) { now + 1.hour }

        it "notifie un collègue de l'auteur" do
          expect(should_notify?(colleague)).to be(true)
        end

        it "ne notifie pas l'auteur lui-même" do
          expect(should_notify?(author)).to be(false)
        end
      end

      context "quand le RDV a lieu demain" do
        let(:starts_at) { now + 1.day }

        it "notifie un collègue de l'auteur" do
          expect(should_notify?(colleague)).to be(true)
        end

        it "ne notifie pas l'auteur lui-même" do
          expect(should_notify?(author)).to be(false)
        end
      end

      context "quand le RDV vient d'être déplacé d'une date proche vers une date lointaine" do
        let(:rdv) { create(:rdv, starts_at: now + 1.day) }

        before { rdv.update!(starts_at: now + 10.days) }

        it "notifie un collègue de l'auteur" do
          expect(should_notify?(colleague)).to be(true)
        end

        it "ne notifie pas l'auteur lui-même" do
          expect(should_notify?(author)).to be(false)
        end
      end
    end
  end
end
