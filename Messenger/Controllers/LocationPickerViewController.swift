//
//  LocationViewController.swift
//  Messenger
//
//  Created by trungnghia on 8/7/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {

    // MARK: - Properties
    var completion: ((CLLocationCoordinate2D) -> Void)?
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            guard let coordinates = coordinates else { return }
            print("Current selected location: \(coordinates)")
        }
    }
    let locationManager = CLLocationManager()
    private let mapView = MKMapView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        view.addSubview(mapView)
        view.backgroundColor = .systemBackground
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(gesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.bounds
    }
    
    // MARK: - Helper
    private func configureNavigationBar() {
        navigationItem.title = "Pick Location"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
    }
    
    
    // MARK: - Selectors
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendButtonTapped() {
        guard let coordinates = coordinates else { return }
        dismiss(animated: true) { [weak self] in
            self?.completion?(coordinates)
        }
    }
    
    @objc private func didTapMap(_ gesture: UITapGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        
        let touchPoint = gesture.location(in: mapView)
        let touchLocation = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        coordinates = touchLocation // assign touchLocation to coordinates
        
        let myAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = touchLocation
        myAnnotation.title = "\(touchLocation.latitude) \(touchLocation.longitude)"
        mapView.addAnnotation(myAnnotation)
    }
    

}

// MARK: - CLLocationManagerDelegate
extension LocationPickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            let latitudeString = "\(newLocation.coordinate.latitude)"
            let longitudeString = "\(newLocation.coordinate.longitude)"
            print("latitude: \(latitudeString) | longitude: \(longitudeString)")
        }
    }
}

// MARK: - MKMapViewDelegate
extension LocationPickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        coordinates = userLocation.coordinate
        let zoomArea = MKCoordinateRegion(center: self.mapView.userLocation.coordinate,
                                          span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.mapView.setRegion(zoomArea, animated: true)
    }
}
