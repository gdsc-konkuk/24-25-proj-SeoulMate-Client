import UIKit
import SnapKit

final class MyCollectionViewController: UIViewController {
  // MARK: - Properties
  private var savedPlaces: [PlaceCardInfo] = [
    PlaceCardInfo(
      placeID: "ChIJa4QRyMZQAGARiQ5BMMFjJm8",
      name: "경복궁",
      address: "161, Sajik-ro, Jongno-gu, Seoul",
      distance: 1200,
      rating: 4.8,
      ratingCount: 1250,
      description: "조선왕조 제일의 법궁"
    ),
    PlaceCardInfo(
      placeID: "ChIJa4QRyMZQAGARiQ5BMMFjJm8",
      name: "창덕궁",
      address: "99, Yulgok-ro, Jongno-gu, Seoul",
      distance: 2500,
      rating: 4.7,
      ratingCount: 980,
      description: "조선왕조의 이궁"
    ),
    PlaceCardInfo(
      placeID: "ChIJa4QRyMZQAGARiQ5BMMFjJm8",
      name: "덕수궁",
      address: "99, Sejong-daero, Jung-gu, Seoul",
      distance: 3100,
      rating: 4.6,
      ratingCount: 750,
      description: "조선왕조의 별궁"
    )
  ]
  
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
    return savedPlaces.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionCell.identifier, for: indexPath) as? MyCollectionCell else {
      return UICollectionViewCell()
    }
    
    let place = savedPlaces[indexPath.item]
    cell.configure(with: place)
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
