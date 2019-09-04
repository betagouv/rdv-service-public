class Scroller {

  constructor() {
    $('.link-scroll').on('click', function(e) {
      const anchor = $(this);
      $('html, body').stop().animate({ scrollTop: $(anchor.attr('href')).offset().top }, 1000);
      e.preventDefault();
    });
  }
}

export { Scroller };