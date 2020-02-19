class InviteUserOnCreate {

  constructor() {
      var $email = $("#user_email")
      if ($email.length) {
        $email.change(function() {
          if ($(this).val()) {
            $('#invite-user').show()
          } else {
            $("#user_send_invite_on_create").prop("checked", false);
            $('#invite-user').hide()
          }
        })
      }
  }
}

export { InviteUserOnCreate };
