class SubmitOnChange {
  constructor() {
    document.addEventListener('change', event => {
      if (event.target.matches('.js-submit-on-change')) {
        event.target.form.requestSubmit();
      }
    });
  }
}

export { SubmitOnChange };
