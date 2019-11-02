//
//  PhotoAlbumViewController.swift
//  Virtual Tourist 2.0
//
//  Created by Abdullah AlBargi on 01/11/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import Kingfisher

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var fetchButton: UIButton!
    
    // MARK: - UI
    var deleteButton: UIBarButtonItem!
    let noImagesLabel: UILabel = UILabel()
    
    // MARK: - Vars
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Image>!
    var pin: Pin!
    var photos: [Photo] = []
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var isDeleteAll = false

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.addAnnotation(pin)
        mapView.setRegion(.init(center: pin.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000), animated: false)
        noImagesLabel.frame = photosCollectionView.frame
        noImagesLabel.textAlignment = .center
        noImagesLabel.text = "No Images"
        setLoading(true)
        
        setupFetchedResultsController()
        
        if (fetchedResultsController.sections?[0].numberOfObjects ?? 0 == 0) {
            getPhotos()
        } else {
            setLoading(false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Image> = Image.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func getPhotos() {
        setLoading(true)
        let page = Int(arc4random())
        FlickerService.fetchImages(page: page, latitude: pin.latitude, longitude: pin.longitude, completion: handlePhotosResponse(photos:error:))
    }
    
    func handlePhotosResponse(photos: [Photo], error: Error?) {
        guard error == nil else {
            print("Could not load photos: \(error?.localizedDescription ?? "")")
            return
        }
        
        self.setLoading(false)
        
        if photos.count == 0 {
            showNoImages(true)
        } else {
            showNoImages(false)
            photos.forEach {
                addPhoto(url: $0.url)
            }
        }
    }
    
    @IBAction func fetchPressed(_ sender: UIButton) {
        if let images = fetchedResultsController.fetchedObjects {
            images.forEach {
                dataController.viewContext.delete($0)
            }
            try? dataController.viewContext.save()
        }
        getPhotos()
    }
    
    func addPhoto(url: URL?) {
        let image = Image(context: dataController.viewContext)
        image.pin = pin
        image.url = url
        image.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    func deletePhoto(_ photoToDelete: Image) {
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    func setLoading(_ loading: Bool) {
        fetchButton.isEnabled = !loading
        showLoading(loading)
    }
    
    func showNoImages(_ show: Bool) {
        if show {
            photosCollectionView.backgroundView = noImagesLabel
        } else {
            photosCollectionView.backgroundView = nil
        }
    }
    
    func showLoading(_ show: Bool) {
        if show {
            let activity = UIActivityIndicatorView()
            activity.style = .large
            photosCollectionView.backgroundView = activity
            activity.startAnimating()
        } else {
            photosCollectionView.backgroundView = nil
        }
    }
}

// MARK: - Map View Delegatte
extension PhotoAlbumViewController: MKMapViewDelegate {
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
}

// MARK: - Collection View Data Source
extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        if let data = photo.data {
            cell.imageView.image = UIImage(data: data)
        } else if let url = photo.url {
            cell.imageView.kf.setImage(with: url, placeholder: UIImage(named: "placeHolder")) {
                result in
                switch result {
                case .success(let value):
                    photo.data = value.image.pngData()
                    try? self.dataController.viewContext.save()
                    print("Done")
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                }
            }
        }
        return cell
    }
}

// MARK: - Collection View Delegate
extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        deletePhoto(photoToDelete)
    }
}

// MARK: - Collection View Layout

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (collectionView.bounds.width - 10)/3.0
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}

// MARK: - Fetched Result Delegate
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photosCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photosCollectionView.reloadData()
            if photosCollectionView.numberOfItems(inSection: indexPath!.section) == 0 {
                showNoImages(true)
            }
        default:
            ()
        }
    }
    
}

