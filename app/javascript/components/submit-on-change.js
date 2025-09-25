class SubmitOnChange {
  constructor() {
    document.querySelectorAll('.js-submit-on-change').forEach(input => {
      $(input).on('change', input => {
        // Pour l'instant ce comportement n'est utile que sur des select simples.
        // On veut éviter que l'auto-submit ait lieu sur un select multiple, notamment le select d'agent.
        if(input.target.multiple) {
          return;
        }

        input.target.form.submit();
      });
    });
  }
}

export { SubmitOnChange };
