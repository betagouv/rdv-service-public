class InviteUserOnCreate {

  constructor() {
      var $email = $("#user_email")
      if ($email.length) {
        if ($email.val()) { $('#invite-user').show() }
        $email.change(function() {
          if ($(this).val()) {
            $("#user_invite_on_create").prop("checked", true);
            $('#invite-user').hide().show("slow")
          } else {
            $("#user_invite_on_create").prop("checked", false);
            $('#invite-user').hide("slow")
          }
        })
      }
  }
}

export { InviteUserOnCreate };
