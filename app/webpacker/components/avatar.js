class Avatar {

  constructor() {
    this.colors = ['#1b85b8', '#5a5255', '#559e83', '#ae5a41', '#c3cb71', '#d11141', '#00b159', '#f37735', '#ffc425', '#e39e54', '#d64d4d', '#4d7358', '#9ed670', '#b62020', '#cb2424', '#fe2e2e', '#fe5757', '#52bf90', '#49ab81', '#419873', '#398564', '#011f4b', '#03396c', '#005b96', '#6497b1', '#d896ff', '#be29ec', '#800080', '#660066', '#8d5524', '#c68642', '#e0ac69'];
    this.avatar = $('.account-user-avatar');
  }

  init() {
    var $this = this;
    this.avatar.each(function () {
      $(this).css('background-color', $this._hexColor($(this).text()));
    });
  }

  _hexColor(s) {
    var index;
    index = this._uniqueNumber(s) % this.colors.length;
    return this.colors[index];
  }

  _uniqueNumber(s) {
    return s.split('').map(function(letter) {
      return letter.charCodeAt(0);
    }).reduce((function(_this) {
      return function(current, previous) {
        return previous + current;
      };
    })(this));
  }

}

export { Avatar };