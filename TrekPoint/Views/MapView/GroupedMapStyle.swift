import MapboxMaps

struct GroupedMapStyle: MapContent {
    private let show3DTerrain: Bool
    private let showContor: Bool
    private let usesMetric: Bool
    
    init(show3DTerrain: Bool, showContor: Bool, usesMetric: Bool) {
        self.show3DTerrain = show3DTerrain
        self.showContor = showContor
        self.usesMetric = usesMetric
    }
    
    var body: some MapContent {
        mapTerrain3D
        
        mapContour
    }
    
    @MapContentBuilder
    private var mapTerrain3D: some MapContent {
        if show3DTerrain {
            RasterDemSource(id: "mapbox-dem")
                .url("mapbox://mapbox.mapbox-terrain-dem-v1")
            
            Terrain(sourceId: "mapbox-dem")
                .exaggeration(1.5)
        }
    }
    
    @MapContentBuilder
    private var mapContour: some MapContent {
        if showContor {
            VectorSource(id: "mapbox-terrain")
                .url("mapbox://mapbox.mapbox-terrain-v2")
            
            LineLayer(id: "contour-lines", source: "mapbox-terrain")
                .sourceLayer("contour")
                .lineColor(.black)
                .lineWidth(
                    Exp(.switchCase) {
                        Exp(.eq) {
                            Exp(.get) { "index" }
                            5
                        }
                        1.25 // index contour width
                        0.75 // regular contour width
                    }
                )
                .lineOpacity(
                    Exp(.switchCase) {
                        Exp(.eq) {
                            Exp(.get) { "index" }
                            5
                        }
                        0.9 // index contour opacity
                        0.6 // regular contour opacity
                    }
                )
            
            SymbolLayer(id: "contour-labels", source: "mapbox-terrain")
                .sourceLayer("contour")
                .textField(
                    Exp(.switchCase) {
                        Exp(.eq) {
                            Exp(.get) { "index" }
                            5
                        }
                        Exp(.concat) {
                            if usesMetric {
                                Exp(.get) { "ele" }
                                "m"
                            } else {
                                Exp(.round) {
                                    Exp(.product) {
                                        Exp(.get) { "ele" }
                                        3.2808
                                    }
                                }
                                "ft"
                            }
                        }
                        ""
                    }
                )
                .textColor(.white)
                .textHaloColor(.black)
                .textHaloWidth(1)
                .symbolPlacement(.line)
                .textSize(10)
        }
    }
}
