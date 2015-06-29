//
//  ViewController.swift
//  MaplyTest
//
//  Created by David HM Spector on 6/19/15.
//  Copyright (c) 2015 Zeitgeist. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WhirlyGlobeViewControllerDelegate, MaplyViewControllerDelegate {
    var theViewC    : MaplyBaseViewController?
    var globeViewC  : WhirlyGlobeViewController?
    var mapViewC    : MaplyViewController?
    var layer       : MaplyQuadImageTilesLayer?
    var vectorDict  =  [kMaplyColor: UIColor.whiteColor(), kMaplySelectable: true, kMaplyVecWidth: 4.0]
    
    var doGlobe = false
    var useLocalTiles = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if doGlobe == true {
            globeViewC = WhirlyGlobeViewController()
            theViewC = globeViewC
        } else {
            mapViewC = MaplyViewController()
            theViewC = mapViewC
        }
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(theViewC!.view)
        theViewC!.view.frame = self.view.bounds
        self.addChildViewController(theViewC!)
        theViewC!.clearColor = ( globeViewC != nil ? UIColor.blackColor() : UIColor.whiteColor() )
        
        theViewC!.frameInterval = 2
        if useLocalTiles == true {
            var tileSource = MaplyMBTileSource(MBTiles: "geography-class_medres")
            layer = MaplyQuadImageTilesLayer(coordSystem: tileSource.coordSys, tileSource: tileSource!)
        } else {
            var maxZoom : Int32 = 25
            var baseCacheDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let arialTilesCacheDir = "\(baseCacheDir)/osmtiles/"
            var tileSource = MaplyRemoteTileSource(baseURL: "http://otile1.mqcdn.com/tiles/1.0.0/sat/", ext: "png", minZoom: 0, maxZoom: maxZoom)
            tileSource.cacheDir = arialTilesCacheDir
            layer = MaplyQuadImageTilesLayer(coordSystem: tileSource?.coordSys, tileSource: tileSource)
        }
        layer?.handleEdges = (globeViewC != nil)
        layer?.coverPoles = (globeViewC != nil)
        layer?.requireElev = false
        layer?.waitLoad = false
        layer?.drawPriority = 0
        layer?.singleLevelLoading = false
        theViewC?.addLayer(layer!)
        
        // our starting position - in production, this should be the user's current location, unless they've pre-specified someplace else
        let sf = MaplyCoordinateMakeWithDegrees(-122.4192, 37.7793)
        let nyc = MaplyCoordinateMakeWithDegrees(-73.99,40.75)
        let mapHeight = Float(0.0002)
        
        if globeViewC != nil {
            globeViewC?.delegate = self
            globeViewC?.height = mapHeight
            globeViewC?.animateToPosition(nyc, time: 1.0)
        } else {
            mapViewC?.delegate = self
            mapViewC?.height = mapHeight
            mapViewC?.animateToPosition(nyc, time: 1.0)
        }
        
        self.addCountries()
        self.addBars()
        self.addSpheres()
        
        // comment this and the add building method out to compile w/out the CartoDB tutorial section
        // you will also need to remove eh CartoDBLayer.swift file reference (else it will still compile
        // and generate the errors wrt to the maxZoom/minZoom properties
        self.addBuildings()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addCountries() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            //NSArray *allOutlines = [[NSBundle mainBundle] pathsForResourcesOfType:@"geojson" inDirectory:nil];
            let allOutlines = NSBundle.mainBundle().pathsForResourcesOfType("geojson", inDirectory: nil) as NSArray
            for outlineFile in allOutlines {
                var vecName = ""
                let jsonData = NSData(contentsOfFile: outlineFile as! String)
                if jsonData != nil {
                    let wgVecObj : MaplyVectorObject = MaplyVectorObject(fromGeoJSON: jsonData)
                    // the admin tag from the country outline geojson has the country name ­ save
                    if wgVecObj.attributes != nil { // it is possible for an attribute to be nil.
                        let attributes = wgVecObj.attributes as NSMutableDictionary
                        vecName = attributes.objectForKey("ADMIN") as! String
                        wgVecObj.userObject = vecName
                        
                        // add the outline to our view
                        var compObj : MaplyComponentObject = self.theViewC!.addVectors([wgVecObj], desc: self.vectorDict as Dictionary)
                        // If you ever intend to remove these, keep track of the MaplyComponentObjects above.
                        if count(vecName) > 0 {
                            let label = MaplyScreenLabel()
                            label.layoutImportance = 10.0
                            label.text = vecName
                            label.loc = wgVecObj.center()
                            label.selectable = true
                            let attributes : NSDictionary = [kMaplyFont: UIFont.boldSystemFontOfSize(24.0),
                                kMaplyTextOutlineColor: UIColor.blackColor(),
                                kMaplyTextOutlineSize: 2.0,
                                kMaplyColor: UIColor.whiteColor()]
                            
                            self.theViewC?.addScreenLabels([label], desc: attributes as [NSObject : AnyObject])
                        }
                        
                    }
                }
            }
        })
    }
    
    
    func addBars() {
        // set up some locations
        var capitals = [MaplyCoordinate]()
        capitals.append(MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111))
        capitals.append(MaplyCoordinateMakeWithDegrees(120.966667, 14.583333))
        capitals.append(MaplyCoordinateMakeWithDegrees(55.75, 37.616667))
        capitals.append(MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222))
        capitals.append(MaplyCoordinateMakeWithDegrees(-66.916667, 10.5))
        capitals.append(MaplyCoordinateMakeWithDegrees(139.6917, 35.689506))
        capitals.append(MaplyCoordinateMakeWithDegrees(166.666667, -77.85))
        capitals.append(MaplyCoordinateMakeWithDegrees(-58.383333, -34.6))
        capitals.append(MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056))
        capitals.append(MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333))
        
        // get the image and create the markers
        let icon = UIImage(named:"alcohol-shop-24@2x.png")
        var markers = [MaplyScreenMarker]()
        for (var ii = 0; ii < 10; ii++) {
            let marker = MaplyScreenMarker()
            marker.image = icon;
            marker.loc = capitals[ii];
            marker.size = CGSizeMake(40,40);
            markers.append(marker)
        }
        // add them all at once (for efficency)
        theViewC?.addScreenMarkers(markers as [AnyObject], desc: nil)
    }
    
    func addSpheres() {
        // set up some locations
        var capitals = [MaplyCoordinate]()
        capitals.append(MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111))
        capitals.append(MaplyCoordinateMakeWithDegrees(120.966667, 14.583333))
        capitals.append(MaplyCoordinateMakeWithDegrees(55.75, 37.616667))
        capitals.append(MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222))
        capitals.append(MaplyCoordinateMakeWithDegrees(-66.916667, 10.5))
        capitals.append(MaplyCoordinateMakeWithDegrees(139.6917, 35.689506))
        capitals.append(MaplyCoordinateMakeWithDegrees(166.666667, -77.85))
        capitals.append(MaplyCoordinateMakeWithDegrees(-58.383333, -34.6))
        capitals.append(MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056))
        capitals.append(MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333))
        
        // work through the spheres
        var spheres = [MaplyShapeSphere]()
        for (var ii = 0; ii < 10; ii++) {
            var sphere = MaplyShapeSphere()
            sphere.center = capitals[ii];
            sphere.radius = 0.01;
            spheres.append(sphere)
        }
        self.theViewC?.addShapes(spheres, desc:[ kMaplyColor: UIColor(red: 0.74, green: 0.0, blue: 0.0, alpha: 0.75)])
    }

    
    func addBuildings() {
        let searchString = "SELECT the_geom,address,ownername,numfloors FROM mn_mappluto_13v1 WHERE the_geom && ST_SetSRID(ST_MakeBox2D(ST_Point(%f, %f), ST_Point(%f, %f)), 4326) LIMIT 2000;"
        //var cartoLayer = CartoDBLayer().initWithSearch(searchString)
        var cartoLayer = CartoDBLayer(WithSearch: searchString)
        cartoLayer.minZoom = 15;
        cartoLayer.maxZoom = 15;
        let coordSys = MaplySphericalMercator(webStandard: ())
        let quadLayer = MaplyQuadPagingLayer(coordSystem: coordSys, delegate: cartoLayer)
        self.theViewC?.addLayer(quadLayer)
    }
    
    
    
    // MARK: Add annotation support
    func addAnnotation(title: String, subtitle: String, coord: MaplyCoordinate)  {
        self.theViewC!.clearAnnotations()
        var annotation = MaplyAnnotation()
        annotation.title = title
        annotation.subTitle = subtitle
        theViewC?.addAnnotation(annotation, forPoint: coord, offset: CGPointZero)
    }

    
    // MARK: WhirlyGlobe delegates
    func globeViewController(viewC: WhirlyGlobeViewController!, didTapAt coord: WGCoordinate) {
        let title = "Tap Location:"
        let subtitle = NSString(format:"(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296) as String
        self.addAnnotation(title, subtitle: subtitle, coord: coord)
    }
    
    
    func maplyViewController(viewC: MaplyViewController!, didTapAt coord: MaplyCoordinate) {
        let title = "Tap Location:"
        let subtitle = NSString(format:"(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296) as String
        self.addAnnotation(title, subtitle: subtitle, coord: coord)
    }
    
    
    // MARK: MaplyDelegates

    func hadleSection(viewC : MaplyBaseViewController, selectedObject: NSObject) {
        if selectedObject.isKindOfClass(MaplyVectorObject) {
            let theVector = selectedObject as! MaplyVectorObject
        } else if selectedObject.isKindOfClass(MaplyScreenMarker)  {
            // or it might be a screen marker
            let theMarker = selectedObject as! MaplyScreenMarker
    
            let title = "Selected:"
            let subtitle = "Screen Marker"
            self.addAnnotation(title, subtitle: subtitle, coord:theMarker.loc)
        }
    }

    // This is the version for a globe
    func globeViewController(viewC: WhirlyGlobeViewController!, didSelect selectedObj: NSObject!) {
        self.hadleSection(viewC, selectedObject: selectedObj)
    }


    // This is the version for a map
    func maplyViewController(viewC: MaplyViewController!, didSelect selectedObj: NSObject!) {
        self.hadleSection(viewC, selectedObject: selectedObj)
    }

}

