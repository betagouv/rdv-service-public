// Used for printing a specific Area of the webpage
class Print {

  print(element) {
    document.body.innerHTML = element.innerHTML;
    window.print();
    this.resetPage();
  }

  resetPage() {
    document.body.innerHTML = this.originalPageHTML; // Ceci permet de rapidement réinitialiser la page au cas où le rechargement prendrait trop de temps
    window.location.reload(); // Recharger la page nous permet de reconnecter tous les events listeners
  }

  constructor() {
    this.originalPageHTML = document.body.innerHTML;

    document.querySelectorAll('.print-btn').forEach(elt =>
      elt.addEventListener("click", evt => {
        this.print(document.querySelector(elt.dataset.target));
        return;
      })
    )
  }

}

export { Print };
