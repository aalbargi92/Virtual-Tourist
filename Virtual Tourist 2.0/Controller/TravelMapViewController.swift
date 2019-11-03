//
//  TravelMapViewController.swift
//  Virtual Tourist 2.0
//
//  Created by Abdullah AlBargi on 01/11/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation
import SwiftEntryKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class TravelMapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - UI
    var deleteButton: UIBarButtonItem!
    
    // MARK: - Vars
    var resultSearchController:UISearchController!
    let locationManager = CLLocationManager()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pins: [Pin] = []
    var isDelete = false
    var selectedPin:MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        setupLastLocation()
        setupSearchBar()
        setupBar()
        
        setupFetchedResultsController()
        addPinsToMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isDelete = false
        updateDeleteButton()
        
        setupFetchedResultsController()
        addPinsToMap()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            let count = try dataController.viewContext.count(for: fetchRequest)
            if count > 0 {
                updateDeleteButton()
            }
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addPinsToMap() {
        if let pins = fetchedResultsController.fetchedObjects {
            mapView.addAnnotations(pins)
        }
    }
    
    func setupLastLocation() {
        if let center = MapSerivce.getCenter() {
            mapView.setRegion(.init(center: .init(center.center), span: .init(center.zoom)), animated: false)
        } else {
            locationManager.requestLocation()
        }
    }
    
    func setupSearchBar() {
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.delegate = self
        resultSearchController.searchResultsUpdater = locationSearchTable
        resultSearchController.obscuresBackgroundDuringPresentation = false
        resultSearchController.searchBar.placeholder = "Type a location here to search"
        navigationItem.searchController = resultSearchController
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    func setupBar() {
        deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deletePressed(_:)))
        deleteButton.possibleTitles = ["Delete", "Done"]
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PhotoAlbumViewController {
            destination.pin = (sender as! Pin)
            destination.dataController = dataController
        }
    }
    
    // MARK: - Actions
    @IBAction func mapLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended, !isDelete else { return }
        
        let point = sender.location(in: mapView)
        let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
        
        addPin(coordinates: coordinates)
    }
    
    @objc func deletePressed(_ sender: UIBarButtonItem) {
        isDelete = !isDelete
        navigationController?.navigationBar.barTintColor = isDelete ? .red : .systemBackground
        navigationController?.navigationBar.backgroundColor = isDelete ? .red : .systemBackground
        deleteButton.title = isDelete ? "Done" : "Delete"
        updateDeleteButton()
    }
    
    
    private func addPin(coordinates: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinates.latitude.magnitude
        pin.longitude = coordinates.longitude.magnitude
        try? dataController.viewContext.save()
    }
    
    func getPhotos(pin: Pin) {
        let page = Int(arc4random())
        FlickerService.fetchImages(page: page, latitude: pin.latitude, longitude: pin.longitude) { (photos, error) in
            guard error == nil else {
                self.showAlert(title: "Error", message: error!.localizedDescription )
                return
            }
            
            photos.forEach {
                self.addPhoto(pin: pin, url: $0.url)
            }
        }
    }
    
    func addPhoto(pin: Pin, url: URL?) {
        let image = Image(context: dataController.viewContext)
        image.pin = pin
        image.url = url
        image.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    private func deletePin(_ pin: Pin) {
        dataController.viewContext.delete(pin)
        try? dataController.viewContext.save()
        mapView.removeAnnotation(pin)
    }
    
    func updateDeleteButton() {
        guard fetchedResultsController != nil else {
            return
        }
        
        if let pins = fetchedResultsController.fetchedObjects {
            deleteButton.isEnabled = isDelete ? isDelete : pins.count > 0
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Ok", style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - Map View Delegate
extension TravelMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? Pin {
            if isDelete {
                deletePin(pin)
                print("Deleted")
            } else {
                performSegue(withIdentifier: "showImages", sender: pin)
                print("Selected")
            }
        } else {
            print("new")
            addPin(coordinates: view.annotation!.coordinate)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard annotation is Pin else {
            return nil
        }
        
        let pinId = "pinId"
        
        var viewToReturn = mapView.dequeueReusableAnnotationView(withIdentifier: pinId)
        if viewToReturn == nil {
            viewToReturn = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinId)
            viewToReturn?.isDraggable = true
        } else {
            viewToReturn!.annotation = annotation
        }
        
        return viewToReturn
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        switch newState {
        case .starting:
            view.dragState = .dragging
        case .ending:
            view.dragState = .ending
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        MapSerivce.saveCenter(MapLocation(center: Coordinate(mapView.centerCoordinate), zoom: Zoom(mapView.region.span)))
    }
}

// MARK: - Fetched Result Delegate
extension TravelMapViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let pin = fetchedResultsController.object(at: newIndexPath!)
            mapView.addAnnotation(pin)
            updateDeleteButton()
            getPhotos(pin: pin)
            if let selectedPin = selectedPin {
                if selectedPin.coordinate.latitude == pin.coordinate.latitude, selectedPin.coordinate.latitude == pin.coordinate.longitude {
                    mapView.removeAnnotation(selectedPin)
                }
            }
            var attributes = EKAttributes()
            attributes.position = .top
            SwiftEntryKit.display(entry: getNotificationView(text: "Saved Successfully", type: .add), using: attributes)
        case .delete:
            updateDeleteButton()
            var attributes = EKAttributes()
            attributes.position = .top
            SwiftEntryKit.display(entry: getNotificationView(text: "Deleted Successfully", type: .delete), using: attributes)
        default:
            break
        }
    }
    
}

extension TravelMapViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        print(text)
    }
}

extension TravelMapViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        if isDelete {
            deletePressed(deleteButton)
        }
        
    }
}

extension TravelMapViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}

extension TravelMapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        selectedPin = placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
                annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
