d3.csv('https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/output/measurements.csv', function (measurements) {
    d3.json('https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/output/cities.geojson', function (cities) {
        var map = L.map("map").setView([36.6, 114.5], 6);

        function cities_popup (feature, layer) {
            // filter and prepare data
            var filtered = measurements.filter(d => d.location_id == feature.properties.id); 
            var x = [], y = [];
            filtered.forEach(function (e) {
                x.push(e.date);
                y.push(e.value);
            });
            var toplot = [{x: x, y:y}];

            layer.bindPopup('<div id="plot"></div>', {minWidth: 400, minHeight: 300, autoPan: true});

            layer.on('mouseover', function () {
                layer.openPopup();
                Plotly.newPlot('plot', toplot, {title: 'PM2.5 concentration (mcg/m3)', autosize: false,
                    xaxis: {zeroline: true, showline: true}, yaxis: {zeroline: true, showline: true, range: [0, 200]},
                    width: 400, height: 300, margin: {
                        l: 30,
                        r: 30,
                        b: 30,
                        t: 30,
                        pad: 1
                    }
                });
            });
            layer.on('mouseout', function () {
                layer.closePopup();
            });
        };

        var geojsonMarkerOptions = function (feature) {
            var value = feature.properties.value
            console.log(value);
            var fill_color = "#123456";
            if (value <= 50) {
                fill_color = "green";
            } else if (value <= 100) {
                fill_color = "yellow";
            } else if (value <= 150) {
                fill_color = "orange";
            } else if (value <= 200) {
                fill_color = "red";
            } else if (value <= 300) {
                fill_color = "purple";
            } else {
                fill_color = "maroon";
            }

            return {
                radius: 8,
                fillColor: fill_color,
                color: "#000",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.8
            } 
            
        };

        L.tileLayer("https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}", {
            attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
            maxZoom: 18,
            id: 'mapbox/streets-v11',
            tileSize: 512,
            zoomOffset: -1,
            accessToken: 'pk.eyJ1IjoiZGFubnloYXJ0b25vIiwiYSI6ImNrdnJpbXFzZTdxYzczMm1zbm1lMzhzd2oifQ.xutXbhbN3Zrl99lZGyf3Zg'
        }).addTo(map);

        cities_layer = L.geoJSON(cities, {
            pointToLayer: function (feature, latlng) {
                return L.circleMarker(latlng, geojsonMarkerOptions(feature));
            },
            onEachFeature: cities_popup
        });
        cities_layer.addTo(map);
    })
})

// cities data
// var cities = $.ajax({
//     url: "https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/output/cities.geojson",
//     dataType: "json",
//     success: console.log("Data successfully loaded!"),
//     error: function(xhr) {
//         alert(xhr.statusText)
//     }
// });

// measurement data
// var measurement_csv = $.ajax({
//     url: 'https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/output/measurements.csv',
//     dataType: 'text',
//     succes: console.log('Download successful'),
//     error: function(xhr) {
//         alert(xhr.statusText)
//     }
// })

// $.when(measurement_csv).done(function () {
//     var measurements = $.csv.toObjects(measurement_csv.responseText);

//     $.when(cities).done(function () {
//         var map = L.map("map").setView([35.5, 112.85], 10);

//         function cities_popup (feature, layer) {
//             // filter and prepare data
//             var filtered = measurements.filter(d => d.location_id == feature.properties.id); 
//             var x = [], y = [];
//             filtered.forEach(function (e) {
//                 x.push(e.date);
//                 y.push(e.value);
//             });
//             var toplot = [{x: x, y:y}];

//             layer.bindPopup('<div id="plot"></div>', {minWidth: 400, minHeight: 300, autoPan: true});

//             layer.on('mouseover', function () {
//                 layer.openPopup();
//                 Plotly.newPlot('plot', toplot, {title: 'PM2.5 concentration (mcg/m3)', autosize: false, 
//                     width: 400, height: 300, margin: {
//                         l: 30,
//                         r: 30,
//                         b: 30,
//                         t: 30,
//                         pad: 1
//                     }
//                 });
//             });
//             layer.on('mouseout', function () {
//                 layer.closePopup();
//             });
//         };

//         L.tileLayer("https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}", {
//             attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
//             maxZoom: 18,
//             id: 'mapbox/streets-v11',
//             tileSize: 512,
//             zoomOffset: -1,
//             accessToken: 'pk.eyJ1IjoiZGFubnloYXJ0b25vIiwiYSI6ImNrdnJpbXFzZTdxYzczMm1zbm1lMzhzd2oifQ.xutXbhbN3Zrl99lZGyf3Zg'
//         }).addTo(map);

//         cities_layer = L.geoJSON(cities.responseJSON, {
//             onEachFeature: cities_popup
//         });
//         cities_layer.addTo(map);
//     });
// });