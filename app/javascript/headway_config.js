// @see https://docs.headwayapp.co/widget for more configuration options.
config = {
  selector: "#js-headway-anchor", // CSS selector where to inject the badge
  account:  "7643Dy",
  trigger:  "#js-headway-anchor",
  translations: {
    title: "Nouveautés",
    readMore: "Voir plus",
    footer: "Voir tout ↗️"
  },
  callbacks: {
    onWidgetReady: function(widget) {
      // Ne pas afficher le conteneur du badge avant que le widget soit chargé
      // pour éviter le mouvement bref de l'élément au chargement.
      const container = document.querySelector("#HW_badge_cont")
      if(container) {
        container.style.display = "block"
      }
    },
  },
};

Headway.init(config)