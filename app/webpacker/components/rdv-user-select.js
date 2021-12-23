// See also AgentsHelper::planning_agent_select
class RdvUserSelect {
  constructor() {
    this.$select = $(".js-rdv-user-select")
    if (!this.$select) return

    this.$select.on("change", this.userSelected)
  }

  userSelected = (event) => {
    let url_template = this.$select[0].dataset.urlTemplate
    let user_id = this.$select.select2("data")[0].element.value;
    let url = url_template.replace("__USER__", user_id)
    Rails.ajax({
      url: url,
      type: "POST",
      data: "first_name=Ricky&last_name=Bobby",
      success: function(data) {
        console.log(data);
      }
    });
  }
}

export { RdvUserSelect }
