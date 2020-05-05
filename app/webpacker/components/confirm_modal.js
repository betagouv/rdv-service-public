class ConfirmModal {

  constructor() {
    $(document).on('confirm', '[data-confirm]', function(e){
      var $el = $(this);

      showConfirmBox($el.data('confirm'), $el, (confirmed) => {
        if (confirmed) {
          $el[0].removeAttribute('data-confirm')
          $el[0].click()
        }
      });
      // prevent the default behaviour of showing the standard window.confirm dialog
      return false;
    });
  }
}

function showConfirmBox(message, element, callback) {
  var trueMessage = element.data('true') || "Ok"
  var falseMessage = element.data('false') || "Annuler"

  var html = `
  <div class='modal' tabindex='-1' role='dialog'>
    <div class='modal-dialog' role='document'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h5 class='modal-title'>Confirmation</h5>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
        </div>
        <div class='modal-body'>
          <p>${message}</p>
        </div>
        <div class='modal-footer'>
          <button type='button' class='btn btn-light' data-dismiss='modal'>${falseMessage}</button>
          <button type='button' class='btn btn-danger js-yes'>${trueMessage}</button>
        </div>
      </div>
    </div>
  </div>`

  $(html).modal();

  $('.js-yes').one('click', () => {
    callback(true);
  });
}

export { ConfirmModal };
