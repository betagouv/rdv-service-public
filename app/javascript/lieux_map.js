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
          paint: {
            'circle-color': [
              'match',
              ['get', 'type_organisation'],
              'RDV Solidarités', '#f28cb1',
              'RDV Service Public', '#3bb2d0',
              'Mairie', '#223b53',
              '#e55e5e',
            ],
            'circle-radius': 4,
            'circle-stroke-width': 1,
            'circle-stroke-color': '#fff'
          }
        });

        map.on('click', 'lieux-markers', (e) => {
          const coordinates = e.features[0].geometry.coordinates.slice();
          const { organisation_name, type_organisation } = e.features[0].properties;
          new maplibregl.Popup()
            .setLngLat(coordinates)
            .setHTML(`${organisation_name} - ${type_organisation}`)
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
