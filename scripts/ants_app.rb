# USAGE : ./bin/bundle exec ruby scripts/ants_app.rb
#
# for livereload :
# gem install rerun && cd scripts && rerun ../bin/bundle exec ruby ants_app.rb

require "sinatra"
require "net/http"
require "json"
require "uri"
require "erb"

class AntsApp < Sinatra::Base
  RDV_HOST = "http://www.rdv-mairie.localhost:3000".freeze
  AUTH_TOKEN = "fake_ants_api_auth_token".freeze

  set :port, ENV.fetch("PORT", 3020)

  get "/" do
    status 200
    render_erb(
      <<-HTML
        <div class="fr-grid-row">
          <div class="fr-col-12 fr-col-md-8">
            <p>
              Cette application est une simulation du moteur de recherche de créneaux ANTS :
              <a href="https://rendezvouspasseport.ants.gouv.fr/" class="fr-link">rendezvouspasseport.ants.gouv.fr</a>
            </p>

            <form action="/search" method="GET" class="fr-form-group">
              <div class="fr-input-group">
                <label class="fr-label" for="zip_code">Code postal commune</label>
                <input class="fr-input" type="text" id="zip_code" name="zip_code" required>
              </div>

              <div class="fr-select-group">
                <label class="fr-label" for="reason">Raison</label>
                <select class="fr-select" name="reason" id="reason" required>
                  <option value="CNI">Carte d'identité</option>
                  <option value="PASSPORT">Passeport</option>
                  <option value="CNI-PASSPORT">Carte d'identité et passeport</option>
                </select>
              </div>

              <div class="fr-input-group">
                <label class="fr-label" for="documents_number">Nombre de documents</label>
                <input class="fr-input" type="number" name="documents_number" id="documents_number" value="1">
              </div>

              <button type="submit" class="fr-btn">Rechercher</button>
            </form>

            <div class="fr-my-4w">
              OU
            </div>


            <a href="/lieux" class="fr-btn fr-btn--secondary fr-mb-4w">Voir les lieux disponibles (getManagedMeetingPoints)</a>
          </div>
        </div>
      HTML
    )
  end

  get "/lieux" do
    lieux = fetch_lieux
    render_erb(
      <<~HTML,
        <nav role="navigation" class="fr-breadcrumb" aria-label="vous êtes ici :">
          <button class="fr-breadcrumb__button" aria-expanded="false" aria-controls="breadcrumb-1">Voir le fil d'Ariane</button>
          <div class="fr-collapse" id="breadcrumb-1">
            <ol class="fr-breadcrumb__list">
              <li>
                <a class="fr-breadcrumb__link" href="/">Accueil</a>
              </li>
              <li>
                <a class="fr-breadcrumb__link" aria-current="page">Liste des lieux</a>
              </li>
            </ol>
          </div>
        </nav>
        <h2>Liste des lieux</h2>
        <ul>
          <% lieux.each do |lieu| %>
            <li><%= lieu["id"] %> : <%= lieu["name"] %> - <%= lieu["public_entry_address"] %>, <%= lieu["city_name"] %> (<%= lieu["zip_code"] %>)</li>
          <% end %>
        </ul>
      HTML
      lieux:
    )
  end

  get "/search" do
    lieux = fetch_lieux
    matching_lieux = lieux.select { |lieu| lieu["zip_code"] == params[:zip_code] }
    meeting_point_ids = matching_lieux.map { _1["id"] }
    creneaux_by_lieux = fetch_creneaux_by_lieu(meeting_point_ids:)

    render_erb(
      <<-HTML,
        <nav role="navigation" class="fr-breadcrumb" aria-label="vous êtes ici :">
          <button class="fr-breadcrumb__button" aria-expanded="false" aria-controls="breadcrumb-1">Voir le fil d'Ariane</button>
          <div class="fr-collapse" id="breadcrumb-1">
            <ol class="fr-breadcrumb__list">
              <li>
                <a class="fr-breadcrumb__link" href="/">Accueil</a>
              </li>
              <li>
                <a class="fr-breadcrumb__link" aria-current="page">Recherche</a>
              </li>
            </ol>
          </div>
        </nav>
        <h2>Recherche</h2>
        Params :
        <pre><%= JSON.pretty_generate(params) %></pre>
        <a class="fr-btn fr-btn--secondary" href="/">Modifier</a>

        <h2 class="fr-mt-4w">Résultats</h2>
        <% if matching_lieux.empty? %>
          Aucun lieu trouvé pour ce code postal
        <% end %>
        <% if creneaux_by_lieux.empty? %>
          Aucun créneau disponible
        <% end %>
        <% creneaux_by_lieux.each do |lieu_id, creneaux| %>
          <div style="border: 1px solid #ccc; padding: 1rem;">
            <% lieu = matching_lieux.find { _1["id"] == lieu_id } %>
            <h3>
              <%= lieu["name"] %> · ID <%= lieu["id"] %>
            </h3>
            <p><%= lieu["public_entry_address"] %></p>
            <div class="fr-grid-row fr-grid-row--gutters">
              <% creneaux.group_by { DateTime.parse(_1["datetime"]).to_date }.each do |date, date_creneaux| %>
                <div class="fr-col-3">
                  <div style="text-align: center; background: #aaa; padding: 1rem; margin-bottom: 1rem;">
                    <h4 style="margin: 0;"><%= date.strftime("%a. %d %B") %></h4>
                  </div>
                  <div class="fr-grid-row fr-grid-row--gutters">
                    <% date_creneaux.each do |creneau| %>
                      <div class="fr-col-6">
                        <a href="<%= creneau['callback_url'].gsub('localhost/', 'localhost:3000/') %>" class="fr-btn fr-btn--secondary" style="width: 100%;">
                          <%= DateTime.parse(creneau["datetime"]).strftime("%H:%M") %>
                        </a>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      HTML
      matching_lieux:, creneaux_by_lieux:, params:
    )
  end

  def fetch_lieux
    fetch_and_parse_uri(URI("#{RDV_HOST}/api/ants/getManagedMeetingPoints"))
  end

  def fetch_creneaux_by_lieu(meeting_point_ids:)
    return {} unless meeting_point_ids.any?

    uri = URI("#{RDV_HOST}/api/ants/availableTimeSlots")
    uri.query = URI.encode_www_form(
      meeting_point_ids:,
      start_date: (Date.today + 1).strftime("%Y-%m-%d"), # rubocop:disable Rails/Date
      end_date: (Date.today + 30).strftime("%Y-%m-%d"), # rubocop:disable Rails/Date
      reason: params[:reason],
      documents_number: params[:documents_number]
    )
    fetch_and_parse_uri(uri)
  end

  def fetch_and_parse_uri(uri)
    request = Net::HTTP::Get.new(uri)
    request["X-HUB-RDV-AUTH-TOKEN"] = AUTH_TOKEN
    response = Net::HTTP.start(uri.hostname, uri.port) { _1.request(request) }
    JSON.parse(response.body)
  end

  TEMPLATE_LAYOUT = Tilt["erb"].new do
    <<-HTML
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
          <meta name="format-detection" content="telephone=no,date=no,address=no,email=no,url=no">
          <link href=" https://cdn.jsdelivr.net/npm/@gouvfr/dsfr@1.13.1/dist/dsfr.min.css " rel="stylesheet">
          <title>ANTS test app</title>
        </head>
        <body>
          <header role="banner" class="fr-header">
            <div class="fr-header__body">
              <div class="fr-container">
                <div class="fr-header__body-row">
                  <div class="fr-header__brand fr-enlarge-link">
                    <div class="fr-header__brand-top">
                      <div class="fr-header__logo">
                        <p class="fr-logo">République<br>Française</p>
                      </div>
                    </div>
                    <div class="fr-header__service">
                      <a href="/">
                        <p class="fr-header__service-title">ANTS App</p>
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </header>

          <main role="main" class="fr-container fr-py-6w">
            <%= yield %>
          </main>
        </body>
      </html>
    HTML
  end.freeze

  def render_erb(erb_raw, **)
    TEMPLATE_LAYOUT.render do
      Tilt["erb"].new { erb_raw }.render(binding, **)
    end
  end
end

AntsApp.run! if __FILE__ == $PROGRAM_NAME
