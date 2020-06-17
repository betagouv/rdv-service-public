class ZonesMap {

  constructor() {
    const container = document.querySelector('#zones-map')
    if (!container) { return; }

    this.hoveredCityElt = document.querySelector("#js-hovered-city")

    // lazy way to 'make sure' mapboxgl is loaded
    window.setTimeout(this.initMap, 1000)
  }

  initMap = () => {
    var map = new mapboxgl.Map({
      container: 'zones-map',
      hash: true,
      center: [2.3103, 50.7406], // TODO: 62 hardcoded so far
      zoom: 7,
      style: {
        version: 8,
        sources: {
          'communes-tiles': {
            type: 'vector',
            url: 'https://etalab-tiles.fr/data/decoupage-administratif.json'
          }
        },
        layers: []
      }
    });
    map.addControl(new mapboxgl.NavigationControl());

    map.on('load', () => {
      map.addLayer({
        'id': 'departements-contour',
        'type': 'line',
        'source': 'communes-tiles',
        'source-layer': 'departements',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#ccc',
          'line-width': 1
        }
      });
      map.addLayer({
        'id': 'communes-fill',
        'type': 'fill',
        'source': 'communes-tiles',
        'source-layer': 'communes',
        'paint': {
          'fill-color': [
            'match',
            ['get', 'code'],
          ].concat(this.getMatchingValues()).
            concat('transparent'),
        }
      });
      map.addLayer({
        'id': 'communes-contour',
        'type': 'line',
        'source': 'communes-tiles',
        'source-layer': 'communes',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#ccc',
          'line-width': 1
        }
      });

      // tried but could not get popup to work
      // cf https://docs.mapbox.com/mapbox-gl-js/example/popup-on-hover/
      map.on('mousemove', e => {
        const cityFeature = map.queryRenderedFeatures(e.point).filter(f => f.layer.id == 'communes-fill')[0]
        if (!cityFeature) return;

        const { code, nom } = cityFeature.properties
        this.hoveredCityElt.innerHTML = `${nom}, ${code}`
      })
    })
  }

  getMatchingValues = () => {
    const cases = []
    document.querySelectorAll(".js-legend-organisation").forEach(elt => {
      const cityCodes = JSON.parse(elt.dataset.cityCodesJson).colors
      const color = elt.dataset.color
      cityCodes.forEach(code => {
        cases.push(code)
        cases.push(color)
      })
    })
    return cases;
  }
}

export { ZonesMap }
