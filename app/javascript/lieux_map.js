window.addEventListener("load", () => {
  fetch("/lieux_map_data.json")
    .then(response => response.json())
    .then(lieux => {
      const mapElt = document.getElementById('map')
      var map = L.map(mapElt).setView([46.603354, 1.888334], 6) // Center of Metropolitan France

      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      }).addTo(map)

      const markers = L.markerClusterGroup()
      lieux.forEach((lieu) => {
        const marker = L.
          marker([lieu.latitude, lieu.longitude]).
          bindPopup(`<b>${lieu.name}</b><br />Organisation ${lieu.organisation_name}`)
        markers.addLayer(marker)
      })
      map.addLayer(markers)
    })
})
