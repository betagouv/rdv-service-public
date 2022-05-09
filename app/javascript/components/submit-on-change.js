class SubmitOnChange {
  constructor() {
    document.querySelectorAll('.js-submit-on-change').forEach(input => {
      $(input).on('change', input => {
        input.target.form.submit();
      });
    });
  }
}

export { SubmitOnChange };
