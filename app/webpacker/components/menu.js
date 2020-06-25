class Menu {

  constructor() {
    this.body = $('body');    
    this.window = $(window);
  }

  init() {
    this._initMobileMenu();
    this._initSidebarScroll();
    this._initClickBody();
    this._initKeyboardShortcut();
    $(".side-nav").metisMenu();
    this._initMenuItemActive();
    this._initNavbarToggle();
  }

  _initMobileMenu() {
    var $this = this;
    $('.button-menu-mobile, .collapse-menu').on('click', function (event) {
      event.preventDefault();
      $this.body.toggleClass('sidebar-enable');
      if ($this.window.width() >= 768) {
        $this.body.toggleClass('enlarged');
      } else {
        $this.body.removeClass('enlarged');
      }
      $this.resetSidebarScroll();
    });
  }

  _initSidebarScroll() {
    $('.slimscroll-menu').slimscroll({
      height: 'auto',
      position: 'right',
      size: "8px",
      color: '#9ea5ab',
      wheelStep: 5,
      touchScrollStep: 20
    });
  }

  resetSidebarScroll() {
    $('.slimscroll-menu').slimscroll({
      height: 'auto',
      position: 'right',
      size: "8px",
      color: '#9ea5ab',
      wheelStep: 5,
      touchScrollStep: 20
    });
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
      if ($(e.target).closest('.left-side-menu, .side-nav').length > 0 || $(e.target).hasClass('button-menu-mobile') 
        || $(e.target).closest('.button-menu-mobile').length > 0) {
        return;
      }

    $this.body.removeClass('right-bar-enabled');
    $this.body.removeClass('sidebar-enable');
    return;
  });
  }

  _initMenuItemActive = () => {
    document.querySelectorAll(".side-nav a").forEach(elt => {
      if (!this.isCurrentRoute(elt)) return

      const $elt = $(elt)
      $elt.addClass("active");
      $elt.closest("li").addClass("active")
      $elt.closest("ul").addClass("in")
      const $topItemElt = $elt.closest(".side-nav-item")
      $topItemElt.addClass("active");
      $topItemElt.find(">.side-nav-link").addClass("active");
    });
  }

  isCurrentRoute = (elt) => {
    const currentRouteElt = document.getElementById("js-current-route")
    const currentRoute = currentRouteElt && currentRouteElt.value;
    return (!currentRoute || currentRoute === elt.getAttribute("data-route"))
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