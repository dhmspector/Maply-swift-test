//
//  CartoDBLayer.swift
//  MaplyTest
//
//  Created by David HM Spector on 6/21/15.
//  Copyright (c) 2015 Zeitgeist. All rights reserved.
//

import UIKit

class CartoDBLayer: NSObject, MaplyPagingDelegate {
    var search  : String?
    var opQueue : NSOperationQueue
    var minZoom : Int
                // tried Int32 as that is the explicit type Swift is inferring. tried NSInteger too.  Same result
    
    
// overriding the setters and getters here has no effect
//    {
//        set { self.minZoom = newValue }
//        get { return self.minZoom }
//    }

    var maxZoom : Int
// ditto
//    {
//        set { self.maxZoom = newValue }
//        get { return self.maxZoom }
//    }
    
    init(WithSearch inSearch: String) {
        search = inSearch
        opQueue = NSOperationQueue()
        super.init()
    }

// trying to make them top-level functions generates a comiler error about trying to duplcate 
// the built-in accessors.
//    func minZoom() -> Int32 {
//        return self.minZoom
//    }
//
//    func maxZoom() -> Int32 {
//        return self.maxZoom
//
//    }
    
    
     func startFetchForTile(tileID: MaplyTileID, forLayer layer: MaplyQuadPagingLayer!) {
        var bbox = MaplyBoundingBox()
        layer.geoBoundsforTile(tileID, ll: &bbox.ll, ur: &bbox.ur)
        let urlReq : NSURLRequest = self.constructRequest(search!, bbox: bbox)
        NSURLConnection.sendAsynchronousRequest(urlReq, queue: opQueue) { (response, data, connectionError) -> Void in
            if let vecObj :MaplyVectorObject = MaplyVectorObject(fromGeoJSON: data) {
                
                var filledObjDesc  = [kMaplyColor: UIColor(red: 0.25, green: 0.0, blue: 0.0, alpha: 0.25), kMaplyFilled: true, kMaplyEnable: false]
                let filledObj = layer.viewC.addVectors([vecObj], desc: filledObjDesc, mode:MaplyThreadCurrent)
                
                var outlineObjDesc  = [kMaplyColor: UIColor.redColor(), kMaplyFilled: false, kMaplyEnable: false]
                let outlineObj = layer.viewC.addVectors([vecObj], desc: outlineObjDesc, mode:MaplyThreadCurrent)
                
                layer.addData([filledObj, outlineObj], forTile: tileID)
            }
            layer.tileDidLoad(tileID)
        }
    }
    
    



    func constructRequest(search: String, bbox:MaplyBoundingBox) -> NSURLRequest {
        var toDeg = Float(180/M_PI)

        let query = NSString(format:search, bbox.ll.x * toDeg, bbox.ll.y * toDeg,bbox.ur.x * toDeg,bbox.ur.y * toDeg)
        var encodedQuery = query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        encodedQuery = encodedQuery!.stringByReplacingOccurrencesOfString("&", withString: "%26", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        var fullURL = NSString(format: "https://pluto.cartodb.com/api/v2/sql?format=GeoJSON&q=%@", encodedQuery!) as String
        return NSURLRequest(URL: NSURL(string: fullURL)!)
    }


}
