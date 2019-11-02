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

class TravelMapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - UI
    var deleteButton: UIBarButtonItem!
    
    // MARK: - Vars
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var pins: [Pin] = []
    var isDelete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLastLocation()
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
        }
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
        guard sender.state == .ended else { return }
        
        let point = sender.location(in: mapView)
        let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
        
        addPin(coordinates: coordinates)
    }
    
    @objc func deletePressed(_ sender: UIBarButtonItem) {
        isDelete = !isDelete
        navigationController?.navigationBar.barTintColor = isDelete ? .red : .white
        deleteButton.title = isDelete ? "Done" : "Delete"
        updateDeleteButton()
    }
    
    
    private func addPin(coordinates: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinates.latitude.magnitude
        pin.longitude = coordinates.longitude.magnitude
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

}

// MARK: - Map View Delegate
extension TravelMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation as? Pin else {
            return
        }
        if isDelete {
            
            deletePin(pin)
            print("Deleted")
        } else {
            performSegue(withIdentifier: "showImages", sender: pin)
            print("Selected")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinId = "pinId"
        
        var viewToReturn = mapView.dequeueReusableAnnotationView(withIdentifier: pinId)
        if viewToReturn == nil {
            viewToReturn = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinId)
            viewToReturn?.canShowCallout = false
        } else {
            viewToReturn!.annotation = annotation
        }
        
        return viewToReturn
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
        case .delete:
            updateDeleteButton()
        default:
            break
        }
    }
    
}
