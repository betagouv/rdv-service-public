module AnnuaireServicePublicStubs
  def self.stub_siret_as_anct(siret, context)
    context.stub_request(:get, "https://api-lannuaire.service-public.fr/api/explore/v2.1/catalog/datasets/api-lannuaire-administration/records?where=siret=%22#{siret}%22")
      .to_return(status: 200, body: context.file_fixture("annuaire_service_public/anct.json"), headers: {})
  end

  def self.stub_siret_as_mairie(_siret, context)
    context.stub_request(:get, "https://api-lannuaire.service-public.fr/api/explore/v2.1/catalog/datasets/api-lannuaire-administration/records?where=siret=%2221600660100019%22")
      .to_return(status: 200, body: context.file_fixture("annuaire_service_public/mairie.json"), headers: {})
  end
end
