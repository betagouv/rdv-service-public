class Rightbar {

  constructor() {
    const right_bar_holder_selector = '#right-bar-holder';
    const right_bar_selector = '.right-bar';
    const $this = this;

    // right side-bar toggle
    $(document).on('click', '.right-bar-toggle', function (e) {
      e.preventDefault();
      $('body').toggleClass('right-bar-enabled');
    });

    $(document).on('click', 'a[data-rightbar]', function(event) {
      const location = $(this).attr('href');
      $('body').removeClass('right-bar-enabled');
      // Load rightbar dialog from server
      $.get(
        location,
        data => { 
          $(right_bar_holder_selector).html(data);
          $(right_bar_selector).trigger('shown.rightbar');
          $('body').addClass('right-bar-enabled');
        }
      );
      return false;
    });

    $(document).on('ajax:success', 'form[data-rightbar]', function(event){
      const [data, _status, xhr] = event.detail;
      const url = xhr.getResponseHeader('Location');
      if (url) {
        window.location = url;
      } else {
        // Update content
        const rightbar = $(data).find('body').html();
        $(right_bar_holder_selector).html(rightbar);
        $(right_bar_selector).trigger('shown.rightbar');
        $('body').addClass('right-bar-enabled');
      }
      return false;
    });
  }
}

export { Rightbar };