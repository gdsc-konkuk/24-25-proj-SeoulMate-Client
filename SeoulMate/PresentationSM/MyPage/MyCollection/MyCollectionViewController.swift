import UIKit
import SnapKit
import GooglePlaces

final class MyCollectionViewController: UIViewController {
  // MARK: - Properties
  private var likedPlaces: [PlaceCardInfo] = []
  private var placesClient = GMSPlacesClient.shared()
  
  // MARK: - UI Components
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 11
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = .zero
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .gray100
    collectionView.showsVerticalScrollIndicator = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(MyCollectionCell.self, forCellWithReuseIdentifier: MyCollectionCell.identifier)
    return collectionView
  }()
  
  // MARK: - Initializer
  init(likedPlaces: [PlaceCardInfo]) {
    self.likedPlaces = likedPlaces
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  // MARK: - Setup
  private func setupUI() {
    title = "My Collection"
    view.backgroundColor = .white
    
    // Navigation bar background color
    navigationController?.navigationBar.backgroundColor = .white
    
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}

// MARK: - UICollectionViewDataSource
extension MyCollectionViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return likedPlaces.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionCell.identifier, for: indexPath) as? MyCollectionCell else {
      return UICollectionViewCell()
    }
    
    let place = likedPlaces[indexPath.item]
    cell.configure(with: place)
    
    // Fetch and load images for the place
    if let placeId = place.placeID {
      placesClient.lookUpPhotos(forPlaceID: placeId) { [weak self] (photos, error) in
        guard let self = self,
              let photoMetadata = photos?.results else { return }
        
        // Load up to 5 photos
        let photosToLoad = Array(photoMetadata.prefix(5))
        var loadedPhotos: [UIImage] = []
        
        let group = DispatchGroup()
        
        for photo in photosToLoad {
          group.enter()
          self.placesClient.loadPlacePhoto(photo) { (photo, error) in
            defer { group.leave() }
            if let photo = photo {
              loadedPhotos.append(photo)
            }
          }
        }
        
        group.notify(queue: .main) {
          cell.updatePhotos(loadedPhotos)
        }
      }
    }
    
    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MyCollectionViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.width
    return CGSize(width: width, height: 269)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 11
  }
} 
