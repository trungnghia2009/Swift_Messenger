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

final class LocationPickerViewController: UIViewController {

    // MARK: - Properties
    var completion: ((CLLocationCoordinate2D) -> Void)?
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            guard let coordinates = coordinates else { return }
            navigationItem.rightBarButtonItem?.isEnabled = true
            print("Current selected location: \(coordinates)")
        }
    }
    let isPickable: Bool
    let locationManager = CLLocationManager()
    private let mapView = MKMapView()
    
    // MARK: - Lifecycle
    init(coordinates: CLLocationCoordinate2D? = nil, isPickable: Bool = true) {
        self.coordinates = coordinates
        self.isPickable = isPickable
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        view.backgroundColor = .systemBackground
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        if isPickable {
            navigationItem.title = "Pick Location"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            navigationItem.rightBarButtonItem?.isEnabled = false
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            mapView.addGestureRecognizer(gesture)
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            navigationItem.title = "Show Location"
            guard let coordinates = coordinates else { return }
            let myAnnotation = MKPointAnnotation()
            myAnnotation.coordinate = coordinates
            mapView.addAnnotation(myAnnotation)
            
            let zoomArea = MKCoordinateRegion(center: coordinates,
                                              span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(zoomArea, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.bounds
    }
    
    // MARK: - Helper
    
    
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


// MARK: - MKMapViewDelegate
extension LocationPickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if isPickable {
            let zoomArea = MKCoordinateRegion(center: self.mapView.userLocation.coordinate,
                                              span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.mapView.setRegion(zoomArea, animated: true)
        }
    }
    
    
}
