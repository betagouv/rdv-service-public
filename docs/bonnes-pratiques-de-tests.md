# Bonnes pratiques de test

## Pyramide des tests

![https://martinfowler.com/articles/practical-test-pyramid/testPyramid.png](https://martinfowler.com/articles/practical-test-pyramid/testPyramid.png)

La pyramide se lit selon ses deux dimensions : 
- verticalement : plus on est haut, plus nombreuses sont les couches traversées par un test
- horizontalement : plus on est bas, plus nombreux sont les cas testés

Par ailleurs, plus on est haut dans la pyramide, plus c'est couteux à exécuter et à maintenir. Plus c'est bas et moins c'est couteux à exécuter et à maintenir.

Dit autrement, les tests end-to-end vont avoir tendance à se concentrer sur les cas nominaux, pour couvrir une fonctionnalité entière. Les tests unitaires, à l'opposé, couvrent plutôt un bout de code, mais testent exhaustivement toutes ses possibilités.

Pour référence : [pyramide des tests](https://martinfowler.com/articles/practical-test-pyramid.html)

## Quelles couches sont testées par quels test ?

|                                  | JS  | Capybara | Routage et middlewares Rack | Controllers | Code métier |
|----------------------------------|-----|----------|-----------------------------|-------------|-------------|
| Feature spec avec JS             | X   | X        | X                           | X           | X           |
| Feature spec sans JS             |     | X        | X                           | X           | X           |
| Request spec                     |     |          | X                           | X           | X           |
| Controller spec                  |     |          |                             | X           | X           |
| Test unitaire (mailer, model...) |     |          |                             |             | X           |

Des informations sur les performances des tests peuvent être trouvées dans la section ci dessous intitulée : [Les performances](#les-performances).

## End-to-End (E2E) : dans quel cas utiliser des tests de bout en bout (feature specs) ?

Les feature specs sont à utiliser tout en haut de la pyramide, pour les tests end-to-end. Ils sont plus lents que les autres types de test, dans le cas où Javascript est nécessaire, mais aussi parce qu'on traverse la pile entière, le rendu de vue et tous les mécanismes (au travers d'un navigateur). On les reserve à la description de scénarios utilisateurs complets.

Par exemple : la personne arrive sur l'application, s'authentifie, navigue sur plusieurs écrans et formulaires, etc., dans le but de d'utiliser une fonctionnalité entière.

Par ailleurs les feature specs assurent la non régression du système. Puisqu'ils testent une fonctionnalité dans son ensemble, si une brique sous-jacente change et ne permet plus la réalisation de la fonctionnalité, le crash de la feature spec est là pour relever la régression.

## Intégration : dans quel cas utiliser les request specs ?

Les request specs présentent l'avantage de tester simplement (presque) toutes les couches de l'application, comprenant le routage et le rendu des vues par exemple. Ce sont des tests d'intégration (deuxième étage de la pyramide). Ils valident que les différentes parties du système s'intègrent bien les unes avec les autres.

On y teste au minimum tous les cas nominaux. En particulier, on cherche à s'assurer : 
- que le routage fonctionne
- que les bonnes vues sont rendues
- que les redirections sont conformes aux attentes
- que les droits d'accès sont respectés
- que les opérations métier sont réalisées

Il est inutile d'y couvrir dans le détail toutes les opérations métier, qui peuvent être testés par ailleurs de façon unitaire.

En revanche, on peut considérer utile d'y mettre certains cas aux limites. Par exemple : est-ce que la personne est bien redirigée lorsqu'elle n'a pas les droits ? L'application crashe-t-elle lorsque des valeurs inattendues sont saisies dans un formulaire ?

Les cas aux limites sont souvent enrichis avec les couvertures de bug fix réalisés au fil de l'eau.

Comme les request specs sont des tests d'intégration, on peut défendre qu'un test peut contenir plusieurs assertions. Par exemple : 

```rb
describe "creating a rdv" do
  subject(:create_request) { post rdvs_path, params: params }
  let(:params) { ... }
  
  it "works as expected" do
    expect { create_request }.to change { Rdv.count }.by(1)
    expect(response).to be_successful
    expect(response).to render_template(:show)
    expect(response).to include("Le RDV a été créé")
  end
end
```

Toutefois, lorsque la spec plante, on a plutôt envie de savoir ce qui n'a pas fonctionné. Est-ce la création du RDV qui a échoué ? Est-ce le template qui n'a pas été rendu ? Ou le flash a-t-il changé ? Aussi, il semble plus confortable pour la personne qui constate le crash que celui-ci indique immédiatement l'erreur. Pour cela, on recommande plutôt d'avoir, autant que possible, une assertion par test : 

```rb
describe "creating a rdv" do
  subject(:create_request) { post rdvs_path, params: params }
  let(:params) { ... }
  
  it { expect { create_request }.to change { Rdv.count }.by(1) }
  it { expect(create_request).to be_successful }
  it { expect(create_request).to render_template(:show) }
  
  it "flashes about the rdv creation" do
    create_request   
    expect(response.body).to include("Le RDV a bien été créé")
  end
end
```

En outre, ce niveau de détail, couplé à une arborescence de contextes, permet d'écrire plus facilement et plus exhaustivement les tests des cas aux limites. Par exemple : dans le cas où le paramètre `rt_link` est renseigné, on redirige vers `rt_link` après la création plutôt que de rendre le template. Ou encore : si un paramètre est manquant, le RDV n'est pas créé et on affiche un flash d'erreur.

## Intégration : dans quels cas utiliser les controller specs ?

A priori les controller specs ne sont plus utilisés, puisqu'ils ont été dépréciés et qu'ils offrent une couverture moindre que les request specs, pour un coût identique.

Les controller specs du projet peuvent y rester, et sont éventuellement migrés vers des request specs au fil de l'eau par l'équipe de développement.

## Tests unitaires

On s'attend à ce que le reste du code, des modèles aux services en passant par les mailers et les helpers, soient testés de façon unitaire dans des specs dédiées. Tous les cas doivent être couverts, nominaux ou limites.

## Recommandations générales

De nombreuses bonnes pratiques de test sont garanties dans le projet par [rubocop-rspec](https://github.com/rubocop/rubocop-rspec). Néanmoins, dans le détail, nous établissons ici les conventions et bonnes pratiques qui ne peuvent être couvertes par des outils.

### Travailler en mémoire

Lorsque c'est possible, il est préférable d'utiliser `build(:model)` et `build_stubbed(:model)`, au lieu de `create(:model)`, afin de rester en mémoire, sans toucher la BDD, et ainsi augmenter les performances. C'est particulièrement vrai pour les tests unitaires en bas de la pyramide.

Plus d'infos : https://thoughtbot.com/blog/use-factory-bots-build-stubbed-for-a-faster-test

### Minimiser l'utilisation des stubs

Autant que possible, il est préférable d'éviter de stubber des objects ou des classes, en particulier quand elles sont internes au projet. En effet, cela peut fausser complètement la spec : elle continue de fonctionner alors qu'une erreur se produit avec un "vrai" code.

En revanche, on stub quand on utilise des outils tiers ou externes, pour éviter par exemple de d'envoyer des SMS ou de solliciter une API externe.

### Helpers de rspec : `let` et `subject`

Les `let` et `subject`, etc, doivent rester proches de leur lieu d’utilisation, quitte à être répétés dans un autre `context`. On préfère avoir un peu de duplication mais comprendre rapidement l'objet d'un test, que de réduire la duplication à tout prix et de devoir remonter des dizaines de lignes plus haut pour comprendre son contexte.

### Mise en place du contexte de test

Autant que possible, on garde le plus simple possible la mise en place du contexte du test. C'est plutôt désagréable, et surtout difficile à comprendre, lorsque la mise en place consiste en une douzaine de `let` successifs et interdépendants. Grâce aux factories (et peut être à l'avenir aux fixtures), on peut souvent réduire cette mise en place à trois ou quatre `let` successifs.

## Propositions

### Introduction des fixtures

On propose d'introduire des fixtures et de les faire cohabiter avec les factories.

Quand on est en haut de la pyramide, on utilisera préférentiellement des fixtures. La mise en place du test est facile à lire et à comprendre, et le chargement des fixtures est presque instantané, augmentant ainsi la performance de la suite de tests.

En revanche, plus on descend dans la pyramide, plus on a besoin de faire varier les données pour explorer les cas aux limites. On utilisa donc préférentiellement les factories (plutôt que de tweaker les données proposées par les fixtures, car cela crée vite de la complexité).

Il est possible de combiner le sujet des fixtures et des seeds : 
- on écrit les fixtures à partir des seeds
- on supprime les seeds, et on les charge à partir des fixtures

Ainsi, il n'y a qu'un seul jeu de données à plat à maintenir.

### Augmentation de la couverture de test

Le taux de couverture n'est pas l'alpha et l'omega des tests. Toutefois : 
- son évolution est un bon indicateur de santé globale : l'application est-elle de plus en plus couverte, ou de moins en moins ?
- plus le taux est haut, plus le nombre d'erreur 500 en production est bas, et c'est un objectif en soi

Proposition de pratique à discuter en équipe : mettre en place une GitHub action qui, pour une PR donnée, empêche le merge si le taux de couverture globale (mesuré par SimpleCov) est en baisse à cause de cette PR.

## Les performances

À l'heure actuelle (octobre 2022), voici à titre indicatif les performances relatives de différents exemples de specs sur ma machine (Framework 11th Gen Core i5). N'hésitez pas à tester vous-même et compléter ces exemples. 

On y constate les chose suivantes : 
- un test de feature avec JS est 3 fois plus lent qu'un test de feature sans JS
- un test de request a les mêmes perfs qu'un test feature sans JS
- un test de contrôleur est environ 40 % plus rapide qu'un test de request (car il n'exécute pas le routage + middleware)
- un test qui ne fait presque rien prend quand-même 3 ms à s'exécuter, car il exécute les setup et teardown internes à RSpec ainsi que les blocks `before` et `after` définirs dans `rails_helper.rb`
- la création en base de données d'un simple RDV et ses dépendances est 2 fois plus lent que la visite d'une page de feature spec, et donc les différences de perfs entre types de specs sont à mettre en perspective

```ruby
RSpec.describe "performance of typical specs" do
  # ~28 seconds (280ms per test)
  describe "feature spec with JS", type: :feature, js: true do
    100.times do
      it "visit page without DB hit" do
        visit "/accessibility"
        expect(page).to have_content("État de conformité")
      end
    end
  end

  # ~5 seconds (50ms per test)
  describe "feature spec wihtout JS", type: :feature do
    100.times do
      it "visit page without DB hit" do
        visit "/accessibility"
        expect(page).to have_content("État de conformité")
      end
    end
  end

  # ~5 seconds (50ms per test)
  describe "request spec", type: :request do
    100.times do
      it "visit page without DB hit" do
        get "/accessibility"
        expect(response.body).to include("État de conformité")
      end
    end
  end

  # ~3.4 seconds (34ms per test)
  describe StaticPagesController, type: :controller do
    render_views

    100.times do
      it "visit page without DB hit" do
        get :accessibility
        expect(response.body).to include("État de conformité")
      end
    end
  end

  # ~280 ms (3ms per test)
  describe "unit spec" do
    100.times do
      it "does something simple" do
        expect(2 + 2).to eq(4)
      end
    end
  end

  # ~11 seconds (110ms per test)
  describe "creating records in db" do
    100.times do
      it "creates a RDV and its many associations" do
        create(:rdv)
      end
    end
  end

  # ~1500 ms (15ms per test)
  describe "building records" do
    100.times do
      it "creates a RDV and its many associations" do
        build(:rdv)
      end
    end
  end
end
```
