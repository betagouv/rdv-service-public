class SubmitOnChange {
  constructor() {
    document.querySelectorAll('.js-submit-on-change').forEach(input => {
      $(input).on('change', event => {
        if(event.target.classList.contains("js-submit-on-change-cancel")) {
          return;
        }

        event.target.form.submit();
      });
    });
  }
}

export { SubmitOnChange };
