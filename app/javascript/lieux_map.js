window.addEventListener("load", () => {
  fetch("/lieux_map_data.json")
    .then(response => response.json())
    .then(lieux => {
      const mapElt = document.getElementById('map')
      var map = new maplibregl.Map({
        container: mapElt,
        style: 'https://openmaptiles.data.gouv.fr/styles/positron/style.json',
        center: [0, 20],
        zoom: 2
      })

      map.on('load', () => {
        map.addControl(new maplibregl.NavigationControl());

        map.addSource('lieux', {
          type: "geojson",
          data: {
            "type": "FeatureCollection",
            "features": lieux.map((lieu) => ({
              "type": "Feature",
              "properties": lieu,
              "geometry": {
                "type": "Point",
                "coordinates": [lieu.longitude, lieu.latitude]
              }
            }))
          }
        })

        map.addLayer({
          id: 'lieux-markers',
          type: 'circle',
          source: 'lieux',
          // filter: ['!', ['has', 'point_count']],
          paint: {
            'circle-color': '#11b4da',
            'circle-radius': 4,
            'circle-stroke-width': 1,
            'circle-stroke-color': '#fff'
          }
        });

        map.on('click', 'lieux-markers', (e) => {
          const coordinates = e.features[0].geometry.coordinates.slice();
          const { name, organisation_name } = e.features[0].properties;
          new maplibregl.Popup()
            .setLngLat(coordinates)
            .setHTML(`<b>${name}</b><br />Organisation ${organisation_name}`)
            .addTo(map);
        });

        map.on('mouseenter', 'lieux-markers', () => {
          map.getCanvas().style.cursor = 'pointer';
        });

        map.on('mouseleave', 'lieux-markers', () => {
          map.getCanvas().style.cursor = '';
        });

      })
    })
})
