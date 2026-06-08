# TODO: supprimer après le 28/06/2026

RSpec.describe PaginationCoherenceMonitor do
  subject(:call) { described_class.new(**params).call }

  describe ".from_paginated_arel" do
    before { create_list(:rdv, 10) }

    context "sans current_page_arel" do
      it "construit le monitor depuis le paginated_arel" do
        paginated_arel = Rdv.page(2).per(3)
        monitor = described_class.from_paginated_arel(paginated_arel)
        expect(monitor).to have_attributes(
          current_page_number: 2,
          current_page_items_count: 3,
          total_pages: 4,
          total_items_count: 10,
          per_page: 3
        )
      end
    end

    context "avec un current_page_arel" do
      let!(:rdv) { create(:rdv) }

      it "utilise le count du current_page_arel pour la page courante" do
        paginated_arel = Rdv.page(2).per(3)
        current_page_arel = Rdv.where(id: paginated_arel.pluck(:id) + [rdv.id]) # we make it wrong on purpose
        monitor = described_class.from_paginated_arel(paginated_arel, current_page_arel:)
        expect(monitor).to have_attributes(
          current_page_number: 2,
          current_page_items_count: 4, # here is the problematic diff
          total_pages: 4,
          total_items_count: 11,
          per_page: 3
        )
      end
    end
  end

  context "page intermédiaire pleine" do
    let(:params) do
      { current_page_number: 1, current_page_items_count: 10, total_pages: 3, per_page: 10, total_items_count: 25 }
    end

    it "ne déclenche pas d'alerte" do
      expect { call }.not_to change(sentry_events, :size)
    end
  end

  context "page intermédiaire non pleine" do
    let(:params) do
      { current_page_number: 1, current_page_items_count: 8, total_pages: 3, per_page: 10, total_items_count: 25 }
    end

    it "déclenche une alerte Sentry" do
      expect { call }.to change(sentry_events, :size).by(1)
    end

    it "ajoute les données de pagination au contexte Sentry" do
      call
      expect(sentry_events.last.contexts["pagination_data"]).to eq(
        current_page_number: 1,
        current_page_items_count: 8,
        total_pages: 3,
        per_page: 10,
        total_items_count: 25
      )
    end
  end

  context "dernière page avec le nombre d'items attendu" do
    let(:params) do
      { current_page_number: 3, current_page_items_count: 5, total_pages: 3, per_page: 10, total_items_count: 25 }
    end

    it "ne déclenche pas d'alerte" do
      expect { call }.not_to change(sentry_events, :size)
    end
  end

  context "dernière page avec un nombre d'items inattendu" do
    let(:params) do
      { current_page_number: 3, current_page_items_count: 7, total_pages: 3, per_page: 10, total_items_count: 25 }
    end

    it "déclenche une alerte Sentry" do
      expect { call }.to change(sentry_events, :size).by(1)
    end
  end

  context "dernière page avec un total d'items multiple de per_page" do
    let(:params) do
      { current_page_number: 2, current_page_items_count: 10, total_pages: 2, per_page: 10, total_items_count: 20 }
    end

    it "ne déclenche pas d'alerte" do
      expect { call }.not_to change(sentry_events, :size)
    end
  end

  context "page unique avec moins d'items que per_page" do
    let(:params) do
      { current_page_number: 1, current_page_items_count: 5, total_pages: 1, per_page: 10, total_items_count: 5 }
    end

    it "ne déclenche pas d'alerte" do
      expect { call }.not_to change(sentry_events, :size)
    end
  end

  context "résultats vides" do
    let(:params) do
      { current_page_number: 1, current_page_items_count: 0, total_pages: 1, per_page: 10, total_items_count: 0 }
    end

    it "ne déclenche pas d'alerte" do
      expect { call }.not_to change(sentry_events, :size)
    end
  end
end
