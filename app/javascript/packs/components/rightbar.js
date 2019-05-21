class Rightbar {

  constructor() {
    const modal_holder_selector = '#right-bar-holder';
    const modal_selector = '.right-bar';
    const $this = this;

    // right side-bar toggle
    $(document).on('click', '.right-bar-toggle', function (e) {
      e.preventDefault();
      $('body').toggleClass('right-bar-enabled');
    });

    $(document).on('click', 'a[data-rightbar]', function(event) {
      const location = $(this).attr('href');
      $('body').removeClass('right-bar-enabled');
      // Load modal dialog from server
      $.get(
        location,
        data => { 
          $(modal_holder_selector).html(data);
          $this._resetSlimScroll();
          $(modal_selector).trigger('shown.rightbar');
          $('body').addClass('right-bar-enabled');
        }
      );
      return false;
    });

    $(document).on('ajax:success', 'form[data-modal]', function(event){
      const [data, _status, xhr] = event.detail;

      const url = xhr.getResponseHeader('Location');
      if (url) {
        window.location = url;
      } else {
        // Update content
        const modal = $(data).find('body').html();
        $(modal_holder_selector).html(modal);
        $this._resetSlimScroll();
        $(modal_selector).trigger('shown.rightbar');
        $('body').addClass('right-bar-enabled');
      }
      return false;
    });
  }

  _resetSlimScroll() {
    $('.right-bar .slimscroll-menu').slimscroll({
      height: 'auto',
      position: 'right',
      size: "8px",
      color: '#9ea5ab',
      wheelStep: 5,
      touchScrollStep: 20
    });
  }
}

export { Rightbar };