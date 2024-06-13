require "fileutils"
# require "slim"

# rubocop:disable Metrics/BlockLength

class Group
  attr_reader :screenshots, :name

  def initialize(name:)
    @name = name
    @screenshots = []
  end
end

RSpec.describe "public pages", type: :feature, js: true do
  before(:all) do
    @timestamp = Time.zone.now.strftime("%Y-%m-%d_%H-%M-%S").to_s
    @dirpath = File.join(__dir__, @timestamp)
    FileUtils.mkdir_p(@dirpath)
  end

  before(:each) do
    Capybara.register_driver :mobile do |capybara_app|
      Capybara::Selenium::Driver.new(
        capybara_app,
        browser: :firefox,
        options: Selenium::WebDriver::Firefox::Options.new(args: %w[--headless --width=390 --height=844])
      )
    end
    Capybara.register_driver :desktop do |capybara_app|
      Capybara::Selenium::Driver.new(
        capybara_app,
        browser: :firefox,
        options: Selenium::WebDriver::Firefox::Options.new(args: %w[--headless --width=1280 --height=1024])
      )
    end
  end

  context "default" do
    let(:now) { Time.zone.now }
    # from spec/features/users/online_booking/default_spec.rb
    let!(:territory92) { create(:territory, departement_number: "92") }
    let!(:organisation) { create(:organisation, :with_contact, territory: territory92) }
    let!(:service_medical) { create(:service, name: "Service Médical") }
    let!(:service_social) { create(:service, name: "Service Social") }
    let!(:motif_vaccination) { create(:motif, name: "Vaccination", organisation: organisation, restriction_for_rdv: nil, service: service_medical) }
    let!(:motif_tel) { create(:motif, :by_phone, name: "Télé consultation", organisation: organisation, restriction_for_rdv: nil, service: service_medical) }
    let!(:motif_collectif) { create(:motif, :collectif, name: "Atelier collectif", organisation: organisation, restriction_for_rdv: nil, service: service_social) }
    let!(:motif_rsa) { create(:motif, name: "poursuite RSA", organisation: organisation, restriction_for_rdv: nil, service: service_social) }
    let!(:lieu_centre) { create(:lieu, name: "MDS Centre", organisation: organisation) }
    let!(:lieu_est) { create(:lieu, name: "MJD Est", organisation: organisation) }
    let!(:plage_ouverture_vaccination) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_vaccination], lieu: lieu_centre, organisation: organisation) }
    let!(:plage_ouverture_motif_tel) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_tel], lieu: lieu_centre, organisation: organisation) }
    let!(:plage_ouverture_rsa) { create(:plage_ouverture, :daily, first_day: now + 1.month, motifs: [motif_rsa], lieu: lieu_est, organisation: organisation) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let!(:rdv_collectifs) do
      3.times do |i|
        create(
          :rdv,
          starts_at: now + 1.month + i.days + 10.hours,
          motif: motif_collectif,
          lieu: lieu_est,
          organisation: organisation,
          agents: [agent]
        )
      end
    end

    let!(:user) { create(:user, first_name: "Jean", last_name: "Dupont", email: "jean.dupont@lycos.fr", password: "Rdvservicepublictest1!") }

    it "screenshots" do
      @viewports = { mobile: {}, desktop: {} }
      @viewports.each_key do |viewport|
        puts "--- running for #{viewport} ---"
        @current_viewport = viewport
        run_screenshots
      end

      page.driver.browser.close

      puts "stitching screenshots..."
      system "pngquant --ext .png --force #{File.join(@dirpath, '**/*.png')}"

      html = Slim::Template.new(File.join(__dir__, "template.slim")).render(OpenStruct.new(timestamp: @timestamp, viewports: @viewports))
      File.write(File.join(@dirpath, "index.html"), html)
      system "cp #{File.join(__dir__, 'style.css')} #{@dirpath}"
      system "open #{@dirpath}/index.html"
      puts "run `cd #{@dirpath} && python -m http.server && open http://localhost:8000` to see the screenshots"
    end

    def enter_group(name)
      @current_group_name = name
      puts "  group #{@current_group_name}"
    end

    def run_screenshots # rubocop:disable Metrics/MethodLength
      Capybara.current_driver = @current_viewport

      enter_group "static-pages"
      [
        "/contact",
        "/mds",
        "/accessibility",
        "/mentions_legales",
        "/cgu",
        "/politique_de_confidentialite",
        "/domaines",
        "/stats/",
        "/stats/notifications",
        "/connexion_super_admins",
      ].each do |path|
        visit path
        screenshot path.parameterize
      end

      enter_group "prise-rdv"
      visit root_path
      screenshot "home"
      # from spec/features/users/online_booking/default_spec.rb
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
      find("#search_departement", visible: :all) # permet d'attendre que l'élément soit dans le DOM
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")
      click_button("Rechercher")
      screenshot "selection-service"
      click_on "Service Médical"
      screenshot "selection-motif"
      click_on "Vaccination"
      screenshot "selection-lieu"
      find(".card-title", text: /MDS Centre/).ancestor(".card").find("a.stretched-link").click
      screenshot "selection-creneau"
      click_on "sem. prochaine"
      first(:link, "11:00").click
      screenshot "connexion"
      fill_in "user_email", with: "jean.dupont@lycos.fr"
      fill_in "user[password]", with: "Rdvservicepublictest1!"
      click_button "Se connecter"
      screenshot "etape-informations-usager"
      click_on "Continuer"
      screenshot "etape-choix-usager"
      click_on "Continuer"
      screenshot "etape-confirmation"
      click_on "Confirmer mon RDV"

      enter_group "user-account"
      visit "/users/informations"
      screenshot "mes-informations"
      click_on "Ajouter un proche"
      screenshot "modale-ajouter-un-proche"
      first_name = { mobile: "Bryony", desktop: "Karim" }[@current_viewport]
      within "#modal-holder" do
        fill_in "user_first_name", with: first_name
        fill_in "user_last_name", with: "Dupont"
        click_on "Enregistrer"
      end
      screenshot "DEBUG"
      find("div.col", text: /#{first_name}/).ancestor("li").click_on "Modifier"
      screenshot "modifier-un-proche"
      visit "/users/edit"
      screenshot "mon-compte"
      visit "/users/rdvs"
      screenshot "mes-rdvs"
      first(".btn", text: "Déplacer le RDV").click
      screenshot "deplacer-rdv"
      first(:link, "08:00").click
      screenshot "deplacer-rdv-confirmation"
      click_on "Confirmer le nouveau créneau"
      click_on "Annuler le RDV"
      screenshot "annuler-rdv"

      enter_group "invitation"
      visit "/invitation"
      screenshot "invitation-manuelle"
      visit "/users/user_name_initials_verification/new"
      screenshot "verification-initiales"
      # user = User.create!(first_name: "Claudia", last_name: "La Pobla", organisations: [organisation])
      # user.invite!(domain: Domain::RDV_SOLIDARITES, invited_by: agent)
      # fill_in "invitation_token", with: user.invitation_token
      # click_on "Créer son compte"
      # user.assign_rdv_invitation_token
      # user.save!
      # visit "/prendre_rdv?address=Garennecolombes&city_code=92035&departement=92&latitude=48.904582&longitude=2.25391&service_id=1&street_ban_id=92035_7145&invitation_token=#{user.rdv_invitation_token}"
      # exit

      enter_group "prise-rdv-collectif"
      visit root_path
      # from spec/features/users/online_booking/default_spec.rb
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")
      find("#search_departement", visible: :all)
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")
      click_button("Rechercher")
      click_on "Service Social"
      screenshot "selection-motif"
      click_on "Atelier collectif"
      find(".card-title", text: /MJD Est/).ancestor(".card").find("a.stretched-link").click
      screenshot "selection-creneau"
      first(:link, "S'inscrire").click
      click_on "Continuer"
      click_on "Continuer"
      screenshot "etape-confirmation"
      click_on "Confirmer ma participation"
      screenshot "rdv"
      click_on "modifier"
      screenshot "modifier-participants"
      find('button[aria-controls="modal-header-menu"]').click if @current_viewport == :mobile
      screenshot "menu-user-logged-in"
      click_on "Déconnexion"

      enter_group "inscription"
      visit "/users/sign_up"
      screenshot "inscription"
      fill_in "user_first_name", with: "Zineb"
      fill_in "user_last_name", with: "Moussaoui"
      fill_in "user_email", with: "zmous@wanadoo.fr"
      click_on "Je m'inscris"
      visit "/users/confirmation?confirmation_token=#{User.find_by(email: 'zmous@wanadoo.fr').confirmation_token}"
      screenshot "definir-mot-de-passe"
      visit "/users/password/new"
      screenshot "mot-de-passe-oublie"
    end

    def screenshot(name)
      @viewports[@current_viewport][@current_group_name] ||= Group.new(name: @current_group_name)
      sleep 0.2
      index = (@viewports[@current_viewport][@current_group_name].screenshots.count + 1).to_s.rjust(2, "0")
      filename = "screenshot-#{index}-#{name.parameterize}.png"
      filepath_rel = File.join @current_viewport.to_s, @current_group_name, filename
      filepath_abs = File.join @dirpath, filepath_rel
      FileUtils.mkdir_p File.dirname(filepath_abs)
      page.driver.browser.save_full_page_screenshot filepath_abs
      @viewports[@current_viewport][@current_group_name].screenshots << OpenStruct.new(path: filepath_rel, name:)
    end
  end
end

# rubocop:enable Metrics/BlockLength
