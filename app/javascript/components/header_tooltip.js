export const HeaderTooltip = function()  {
  // TODO: A supprimer une semaine après la mise en prod
  const selector = ".js-header-tooltip"

  if(document.querySelector(selector) && localStorage.getItem("header_tooltip_shown") != "true") {
    localStorage.setItem("header_tooltip_shown", "true");
    $(selector).tooltip("show")
    setTimeout(()=> { $(selector).tooltip("hide") }, 5000)
  }
}
