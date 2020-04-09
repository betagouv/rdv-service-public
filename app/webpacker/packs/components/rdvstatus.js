class Rdvstatus {

  constructor() {
    $("input[type=radio][name='rdv[status]']").on('change', function() {
      Rails.fire(this.form, 'submit');
    });
  }
}

export { Rdvstatus };