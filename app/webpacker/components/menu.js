class Menu {

  constructor() {
    this.body = $('body');
    this.window = $(window);
  }

  init() {
    this._initClickBody();
    this._initKeyboardShortcut();
    this._initNavbarToggle();
  }

  _initKeyboardShortcut() {
    var $this = this;
    $(document).keyup(function(e) {
      if (e.key === "Escape") {
        $this.body.removeClass('right-bar-enabled');
      }
    });
  }

  _initClickBody() {
    var $this = this;
    $(document).on('click', 'body', function (e) {
      if ($(e.target).closest('.right-bar-toggle, .right-bar, .daterangepicker').length > 0) {
          return;
      }

    $this.body.removeClass('right-bar-enabled');
    return;
  });
  }

  _initNavbarToggle(){
    $('.navbar-toggle').on('click', function (event) {
      $(this).toggleClass('open');
      $('#navigation').slideToggle(400);
    });

    $('.dropdown-menu a.dropdown-toggle').on('click', function(e) {
      if (!$(this).next().hasClass('show')) {
        $(this).parents('.dropdown-menu').first().find('.show').removeClass("show");
      }
      var $subMenu = $(this).next(".dropdown-menu");
      $subMenu.toggleClass('show');

      return false;
    });
  }
}

export { Menu };
