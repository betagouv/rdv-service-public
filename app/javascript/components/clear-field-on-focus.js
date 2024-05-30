document.addEventListener('turbolinks:load', function() {

  var secretField = document.getElementById("secret_field");
  if (!secretField) return;

  secretField.addEventListener("focus", function() {
    this.value = "";
  });
});
