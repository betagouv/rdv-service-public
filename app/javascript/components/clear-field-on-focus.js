document.addEventListener("DOMContentLoaded", function() {
  var secretField = document.getElementById("secret_field");
  if (!secretField) return;

  secretField.addEventListener("focus", function() {
    this.value = "";
  });
});
