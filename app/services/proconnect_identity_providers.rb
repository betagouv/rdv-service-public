# Ce fichier classe les différents fournisseurs d'identité ProConnect pour indiquer si les agents
# qui s'en servent travaillent pour les collectivités ou pour les services de l'état
#
# On a filtré sur les fournisseurs d'identité en production sur le réseau internet (même si certains des noms indiquent RIE).
# La classification entre collectivités et services de l'état a ensuite été faite manuellement par l'équipe technique.
#
class ProconnectIdentityProviders
  # Ces fournisseurs de service ont vocation à équiper les collectivités, mais il est possible
  # que les agents qui s'en servent soient des employés des opérateurs publics
  # de services numériques.
  COLLECTIVITES = [
    "0b366363-0715-4126-b7ae-55aa81c95fe1", # MEGALIS BRETAGNE
    "b549c763-a35e-49bd-b569-9b58239155ef",	# Vendée
    "747a0046-b570-4db6-8d3f-5f1e78addf05", #	Troyes Champagne Metropole
    "741ddc48-d15d-4bc5-b6f8-a01e4e474437", #	Département de l'Aveyron
    "52fcebf9-be27-40c7-ba1a-af955f59abd0", #	Gironde Numérique
    "f4f4f2d6-3b7a-4e65-9bd7-828f156851d6",	# Citadelle (Département de la Gironde)
    "4d6fb724-20c8-467d-8d06-6de127624fc0", #	Territoire Numérique Ouvert
    "bfa0e843-811f-4465-8119-abc659602568", # Eure Normandie Numérique
    "ee501034-69e8-48a2-b307-4ce20d75570e", # e-Collectivités
    "7d76b30a-5972-4a8e-93d2-4109c1b8f015", # Adico
    "82263f77-fe04-41ca-840d-5c63fe157247", # GIP RECIA
    "c268fac9-3750-47a9-89d8-fb07a5c69078", # RGD Savoie Mont Blanc
    "875ff631-06a8-4452-81bf-fd0ccfd0e097", # CDG47
    "f5154035-c3d6-47ad-8583-197d508269d0", # La Suite territoriale
    "f895c910-121e-4992-8171-1d7e71fe924d", # ARNia
    "852d7b12-5c27-4e0b-9679-97be90986812", # SSO Moselle Fibre
    "dd2578a8-9478-4476-8603-e0fb9718de0e", # SMICA Occitanie
    "9bcbc587-193d-453f-8602-1b1396e05f69", # Centre de gestion de l'Ariege
    "77c8a897-6235-4131-a033-3667d862089c", # SIDEC du Jura
  ].freeze

  ETAT = [
    "431bb83a-db72-4a1a-9ef0-136412b7b133", # Fournisseur d'identités pour les agents de l'Insee
    "200e2f86-fc01-49cf-958f-eb03977f116f", # INRAE - Institut national de recherche pour l'agriculture, l'alimentation et l'environnement
    "3a259af6-8cb5-41ef-9d57-4e489590186a", # SSO DOUANE / DGDDI (Réseau Interministériel de l'État)
    "7e327dfa-d462-4460-9691-2701700072bf", #	Fournisseur d'identités AROBAS pour les agents du MAE
    "e2f397e0-f2a5-4cbb-b19f-8b3b54410c26", #	Agents de l'Administration Centrale des ministères économiques et financiers (Réseau Interministériel de l'État)
    "4dbd03fa-b7a1-426f-b18a-cae70dd26d56", #	Agents de la DGFiP (Réseau Interministériel de l'État)
    "311d582f-0be6-47fb-b9ec-e54a874b8fee", #	CEA - Commissariat à l'énergie atomique et aux énergies Alternatives
    "03f917ba-75e3-4df0-b9f8-7b9b944d8d8d", # INRIA
    "9e139e69-de07-4cbe-987f-d12cb38c0368", #	Ministère de la Justice (Réseau Interministériel de l'État)
    "fe5573f8-df86-4c92-b792-f36161bf677e", #	PEAMA (France Travail)
    "c018aec3-718e-459a-ae83-43f7a2173b25", #	Ministère Chargé des Affaires Sociales
    "e7782e47-8e0f-4b94-8e21-1197cb6e7143", #	Curasso (Gendarmerie Nationale)
    "ee89db94-64de-4e14-b31a-e93ed3ab1168", #	Calypsso (Police Nationale)
    "25d378d8-a2a7-42e5-b1ab-044d086efd10", #	Conseil d'Etat
    "ea0e1dfe-f45e-4075-a5d4-e3a349b0a125", #	Ministère du Travail, de la Santé, des Solidarités et des Familles (MTSSF) - Internet
    "e2f397e0-f2a5-4cbb-b19f-8b3b54410c26", #	Agents de l'Administration Centrale des ministères économiques et financiers (Réseau Interministériel de l'État)
    "4dbd03fa-b7a1-426f-b18a-cae70dd26d56", #	Agents de la DGFiP (Réseau Interministériel de l'État)
    "03f917ba-75e3-4df0-b9f8-7b9b944d8d8d", #	INRIA
    "bcb4b83a-5ee6-4f67-a721-52521b81d910", #	SSO Ministère de la Culture
    "90a0db90-db8a-4fe7-a17e-e97afd3e4a24", #	Sénat (Réseau Interministériel de l'État)
    "9c895aa2-132e-4592-a713-1fa2fe42c39c", #	Passerelle Fédération Éducation Recherche
    "8c39cf91-3f15-43fd-b05b-b9de90d9e9d8", #	Applications de l'Éducation Nationale
    "311d582f-0be6-47fb-b9ec-e54a874b8fee", #	CEA - Commissariat à l'énergie atomique et aux énergies Alternatives
    "bb784654-d8e8-482c-862b-dc8ee08bf575", #	ADEME
    "0ff77adb-e2cf-47ef-bb40-881fa9ef01f4", #	Services du Premier Ministre (Réseau Interministériel de l'État)
    "00044742-92aa-40ba-b678-d21d09912d4c", #	Assurance Maladie (Réseau Interministériel de l'État)
    "50343e7a-a98b-457e-b4f8-124aff74e425", #	Présidence de la République (Réseau Interministériel de l'État)
    "06dbfa27-dead-41ad-ad92-008fc1a77586", #	ANR - Agence Nationale de la Recherche
    "d8cddcd6-4104-4d41-b3a9-705e7d01ccad", #	Cerbère
    "3c69d88b-bf93-4bcd-9f58-714ddff9c343", #	Passage2 (Réseau Interministériel de l'État)
    "4cb81d41-16a4-46d8-a861-06f8d16ab9b9", #	INSERM
    "ee56b416-7caa-446d-bfa7-d06af7ba00bd", #	DGCCRF (Réseau Interministériel de l'État)
    "5b9d24d9-e1af-4bf7-9586-b2adcb45ef79", #	RÉSEAU CANOPÉ
    "8da7b85b-e1f3-4269-b3bf-2d051b86e95f", # MASA
    "217a6877-7ae5-49d3-9d7b-129b48ff57e8", # Meteo-France
    "b4ed3557-6371-46f8-ade4-12a30b4fa205", # Les Crous et Cnous
    "de1cf2ee-f826-41b8-9c17-f05e1833ab68", # FI-INT-DILA
    "e0cd5da1-f15f-4075-9ba0-924f0dc10224", # CDC Connect
    "2f632351-84b6-4028-9317-472db4738728", # IRD - Institut de Recherche pour le Développement (Réseau Interministériel de l'État)
    "9538d850-1ed3-4891-b03b-524d877eb9c3", # IGN Connect
    "bd35acde-2407-4394-b484-9d0227f2412f", # Office français de la biodiversité (OFB)
    "1c0a6255-f52f-44dd-bfb6-2487d8339aaf", # Ineris
    "9080f7d7-7ab3-4965-8aec-34a1a5258c10", # AFDConnect (Réseau Interministériel de l'État)
    "8770f9c0-ba2b-4f41-b46a-e918cf9c162a", # ANJ - EntraID
    "8238dbe1-5b8f-4b46-a5c6-8c3020884261", # Institut de France
    "972344ed-2f17-49a6-84e2-027ad7e90a4e", # SIEEEN - LLNG
    "84b185b6-4d68-4d92-a136-4e94d7add695", # Observatoire Oceanologique de Banyuls-sur-mer
  ].freeze

  # On n'est pas encore sur de comment classifier ces fournisseurs d'identité.
  # "fb401517-ee06-4b78-b86c-b6988f5a71f4", # Open Desk
  #  3f3b319e-3be5-4031-90f7-e79d1b3ecdf2	Authentification Orion du CEREMA
  # "fc2dd106-78a9-4663-915d-834bf67e4c25", # I-MILO
  #
  # On pense qu'il est possible que les fournisseurs d'identité des universités soient utilisés par
  # des étudiants, à qui on ne veut pas permettre d'ouvrir des comptes d'agent.
  # a5ff6211-11fc-4093-8ff8-35ff31efa90c	Sorbonne Université
  # 1f792528-ffaa-41e9-91bb-ff3443a0be1e	Université de Picardie Jules Verne
  #
  # Les SDIS dépendent des conseils départementaux et des préfectures.
  # "7e9d1437-4f09-4409-9023-3a70726f749b", # Service départemental d'incendie et de secours de la Mayenne
  #
  #  ProConnect Identité permet à n'importe qui (y compris le secteur privé et des particuliers de se connecter)
  # "71144ab3-ee1a-4401-b7b3-79b44f7daeeb", # ProConnect Identité
end
