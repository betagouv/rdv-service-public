class SubmitOnChange {
  constructor() {
    document.querySelectorAll(".js-submit-on-change").forEach(input => {
      $(input).on('change', event => {
        // Si la classe a été retirée de l'élément, c'est pour désactiver l'auto-submit.
        if(event.target.classList.contains("js-submit-on-change")) {
          event.target.form.submit();
        }
      });
    });
  }
}

export { SubmitOnChange };
