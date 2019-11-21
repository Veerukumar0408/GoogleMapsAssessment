//
//  ViewController.swift
//  JobAssessment
//
//  Created by Mr. Naveen Kumar on 19/11/19.
//  Copyright © 2019 delta. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import MapKit
import Alamofire

struct State {
    
    let long: CLLocationDegrees
    let lat: CLLocationDegrees
    let color:UIColor
}
class ViewController: UIViewController,CLLocationManagerDelegate,UIScrollViewDelegate {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet var googleMaps:GMSMapView!
    var sourcelocation:CLLocationCoordinate2D?
    var states = [
        
        State( long: 80.1709, lat: 12.9941,color: .blue),
        State( long: 72.8656, lat: 19.0896,color: .red)
    ]
    var locationmanager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationmanager.delegate = self
        locationmanager.desiredAccuracy = kCLLocationAccuracyBest
        locationmanager.startUpdatingLocation()
        locationmanager.requestWhenInUseAuthorization()
        self.scrollview.minimumZoomScale = 1.0
        self.scrollview.maximumZoomScale = 7.0
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            self.googlemapsdata()
        }
    }
    
    func googlemapsdata(){
        guard let location = locationmanager.location else {
            print("Location not found")
            return
        }
        guard let coordinat = location.coordinate as? CLLocationCoordinate2D else
        {
            print("error")
            return
        }
        let userlocation = State(long: (coordinat.longitude), lat: (coordinat.latitude), color: .green)
        
        sourcelocation = CLLocationCoordinate2D(latitude: (locationmanager.location?.coordinate.latitude)!, longitude: (locationmanager.location?.coordinate.longitude)!)
        
        states.append(userlocation)
        states.insert(userlocation, at: 2)
        let camera = GMSCameraPosition(latitude: (locationmanager.location?.coordinate.latitude)!, longitude: (locationmanager.location?.coordinate.longitude)!, zoom: 6)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
        self.googleMaps = mapView
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
        for state in states {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: state.lat, longitude: state.long)
            marker.map = mapView
            marker.appearAnimation = GMSMarkerAnimation.pop
            marker.icon = GMSMarker.markerImage(with: state.color)
            
            
            var locate = CLLocation(latitude: state.lat, longitude: state.long)
            CLGeocoder().reverseGeocodeLocation(locate) { (mark, error) in
                if(error != nil){
                    print("error in getting place")
                }
                else{
                    if let userplace = mark?[0]{
                        print(userplace)
                        marker.snippet = userplace.name! + " " + userplace.subLocality! + " " + userplace.locality! + " " + userplace.country!
                        
                    }
                }
            }
            DispatchQueue.main.async {
                self.fetchMapData(source: self.sourcelocation!, destination: CLLocationCoordinate2DMake(12.9961, 80.1709),color:.blue)
                self.fetchMapData(source: self.sourcelocation!, destination: CLLocationCoordinate2DMake(19.0896, 72.8656), color: .red)
            }
            let circle = marker.position
            let circleradius = GMSCircle(position: circle, radius: 100)
            circleradius.map = mapView
            marker.icon = GMSMarker.markerImage(with: state.color)
            marker.map = mapView
            
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.view
    }
    
    func fetchMapData(source:CLLocationCoordinate2D ,destination:CLLocationCoordinate2D,color:UIColor) {
        
        let key = "AIzaSyD_X8WWt6uTvnElkHu0j8H5ivxCf6YlUlE"
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=\(key)")
        
        Alamofire.request(url!).responseJSON
            { response in
                
                if let JSON = response.result.value {
                    print(JSON)
                    let mapResponse: [String: AnyObject] = JSON as! [String : AnyObject]
                    
                    let routesArrayData = (mapResponse["routes"] as? Array) ?? []
                    
                    let routes = (routesArrayData.first as? Dictionary<String, AnyObject>) ?? [:]
                    
                    let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String,AnyObject>) ?? [:]
                    let polypoint = (overviewPolyline["points"] as? String) ?? ""
                    let lines  = polypoint
                    
                    self.addPolyLine(encodedString: lines,color:color)
                }
        }
    }
    
    func addPolyLine(encodedString: String,color:UIColor) {
        
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5
        polyline.strokeColor = color
        polyline.map = googleMaps
    }
}

