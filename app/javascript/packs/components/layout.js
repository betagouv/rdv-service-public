class Layout {

  constructor() {
    this.body = $('body');    
    this.window = $(window);
  }

  init() {
    if (this.window.width() >= 768 && this.window.width() <= 1028) {
      this.body.addClass('enlarged');
    } else {
      if (this.body.data('keep-enlarged') != true) {
        this.body.removeClass('enlarged');
      }
    }
  }
}

export { Layout };