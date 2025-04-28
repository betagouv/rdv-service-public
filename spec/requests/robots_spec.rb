RSpec.describe "/robots.txt" do
  let(:public_robots) do
    <<~ROBOTS
      # See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      User-agent: *
      Disallow: /
      Allow: /$
      Allow: /mds
      Allow: /accessibility
      Allow: /mentions_legales
      Allow: /cgu
      Allow: /politique_de_confidentialite
      Allow: /domaines
      Allow: /aide
    ROBOTS
  end

  let(:private_robots) do
    <<~ROBOTS
      # See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      User-agent: *
      Disallow: /
    ROBOTS
  end

  it "sert un robots.txt privé pour le domaine rdv.numerique.gouv.fr" do
    # Ces domaines sont officiels et donc crawlables
    get "https://www.rdv-solidarites.fr/robots.txt"
    expect(response.body).to eq(public_robots)
    get "https://www.rdv-aide-numerique.fr/robots.txt"
    expect(response.body).to eq(public_robots)
    get "https://rdv.anct.gouv.fr/robots.txt"
    expect(response.body).to eq(public_robots)

    # Ce domaine n'est pas encore public et donc non crawlables
    get "https://www.rdv.numerique.gouv.fr/robots.txt"
    expect(response.body).to eq(private_robots)

    # La démo n'est pas crawlable
    with_modified_env({ "RDV_SOLIDARITES_INSTANCE_NAME" => "DEMO" }) do
      get "https://demo.rdv-solidarites.fr/robots.txt"
      expect(response.body).to eq(private_robots)
      get "https://demo.rdv-aide-numerique.fr/robots.txt"
      expect(response.body).to eq(private_robots)
      get "https://demo.rdv.anct.gouv.fr/robots.txt"
      expect(response.body).to eq(private_robots)
      get "https://demo.rdv.numerique.gouv.fr/robots.txt"
      expect(response.body).to eq(private_robots)
    end
  end
end
