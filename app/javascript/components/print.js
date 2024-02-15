// Used for printing a specific Area of the webpage
class Print {

  prepareBeforePrint() {
    let element = document.querySelector("#printable");
    document.body.innerHTML = element.innerHTML;
  }

  resetAfterPrint() {
    document.body.innerHTML = this.originalPageHTML; // Ceci permet de rapidement réinitialiser la page au cas où le rechargement prendrait trop de temps
    window.location.reload(); // Recharger la page nous permet de reconnecter tous les events listeners
  }

  constructor() {
    this.originalPageHTML = document.body.innerHTML;

    window.addEventListener("beforeprint", () => {
      this.prepareBeforePrint();
    })

    window.addEventListener("afterprint", () => {
      this.resetAfterPrint();
    })
  }

}

export { Print };
