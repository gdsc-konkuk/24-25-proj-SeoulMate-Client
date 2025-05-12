//
//  MyPageViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit
import GooglePlaces
import Combine
import GoogleSignIn

final class MyPageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  // MARK: - Properties
  private let appDIContainer: AppDIContainer
  private let getLikedPlacesUseCase: GetLikedPlacesUseCaseProtocol
  private var cancellables = Set<AnyCancellable>()
  private var likedPlaces: [PlaceCardInfo] = []
  private var placesClient = GMSPlacesClient.shared()
  
  // MARK: - UI Components
  // 프로필 섹션
  private let profileSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let profileContentView: UIView = {
    let v = UIView()
    v.backgroundColor = .clear
    return v
  }()
  
  private let profileImageView: UIImageView = {
    let iv = UIImageView()
    iv.backgroundColor = .gray200
    iv.layer.cornerRadius = 24
    iv.clipsToBounds = true
    return iv
  }()
  
  private let nameLabel: UILabel = {
    let label = UILabel()
    label.text = "user"
    label.font = .boldFont(ofSize: 17)
    return label
  }()
  
  private let emailLabel: UILabel = {
    let label = UILabel()
    label.text = "username@gmail.com"
    label.font = .regularFont(ofSize: 14)
    label.textColor = .gray500
    return label
  }()
  
  // 구분선
  private func makeDivider() -> UIView {
    let v = UIView()
    v.backgroundColor = .gray200
    return v
  }
  
  // 컬렉션 섹션
  private let collectionSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let collectionTitleLabel: UILabel = {
    let label = UILabel()
    label.text = "My collection"
    label.font = .boldFont(ofSize: 18)
    return label
  }()
  
  private lazy var viewAllButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("View all", for: .normal)
    button.titleLabel?.font = .mediumFont(ofSize: 15)
    button.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.showsHorizontalScrollIndicator = false
    cv.backgroundColor = .clear
    return cv
  }()
  
  // 하단 메뉴 섹션
  private let menuSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let helpButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.setTitle("  Help", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.titleLabel?.font = .regularFont(ofSize: 16)
    btn.setImage(UIImage(systemName: "exclamationmark.circle"), for: .normal)
    btn.contentHorizontalAlignment = .left
    return btn;
  }()
  
  private let logoutButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.setTitle("  Log out", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.titleLabel?.font = .regularFont(ofSize: 16)
    btn.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)
    btn.contentHorizontalAlignment = .left
    return btn;
  }()
  
  private let dummyImages: [String] = Array(repeating: "photo", count: 5)
  
  // MARK: - Initializer
  init(appDIContainer: AppDIContainer, getLikedPlacesUseCase: GetLikedPlacesUseCaseProtocol) {
    self.appDIContainer = appDIContainer
    self.getLikedPlacesUseCase = getLikedPlacesUseCase
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .gray100
    setupNavigationBar()
    setupLayout()
    fetchLikedPlaces()
    updateUserProfile()
    
    let safeAreaCover = UIView()
    safeAreaCover.backgroundColor = .white
    view.addSubview(safeAreaCover)
    safeAreaCover.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
    }
  }
  
  private func setupNavigationBar() {
    title = "My Page"
    navigationController?.navigationBar.titleTextAttributes = [
      .font: UIFont.mediumFont(ofSize: 20)
    ]
  }
  
  // MARK: - Layout
  private func setupLayout() {
    // 프로필 섹션
    view.addSubview(profileSection)
    profileSection.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.trailing.equalToSuperview()
      // 높이 자동 (내부 패딩 포함)
    }
    profileSection.addSubview(profileContentView)
    profileContentView.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview().inset(24)
      make.leading.trailing.equalToSuperview()
      make.height.greaterThanOrEqualTo(48) // 최소 높이 보장
    }
    profileContentView.addSubview(profileImageView)
    profileImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(48)
    }
    profileContentView.addSubview(nameLabel)
    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(profileImageView.snp.top).offset(4)
      make.left.equalTo(profileImageView.snp.right).offset(12)
    }
    profileContentView.addSubview(emailLabel)
    emailLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(2)
      make.left.equalTo(nameLabel)
    }
    // 구분선1
    let divider1 = makeDivider()
    view.addSubview(divider1)
    divider1.snp.makeConstraints { make in
      make.top.equalTo(profileSection.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(11)
    }
    // 컬렉션 섹션
    view.addSubview(collectionSection)
    collectionSection.snp.makeConstraints { make in
      make.top.equalTo(divider1.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(299)
    }
    collectionSection.addSubview(collectionTitleLabel)
    collectionSection.addSubview(viewAllButton)
    collectionTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.leading.equalToSuperview().offset(16)
      make.height.equalTo(24)
    }
    viewAllButton.snp.makeConstraints { make in
      make.centerY.equalTo(collectionTitleLabel)
      make.trailing.equalToSuperview().inset(16)
    }
    collectionSection.addSubview(collectionView)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(CollectionCell.self, forCellWithReuseIdentifier: "CollectionCell")
    collectionView.snp.makeConstraints { make in
      make.top.equalTo(collectionTitleLabel.snp.bottom).offset(12)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(219)
    }
    // 구분선2
    let divider2 = makeDivider()
    view.addSubview(divider2)
    divider2.snp.makeConstraints { make in
      make.top.equalTo(collectionSection.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(11)
    }
    // 하단 메뉴 섹션
    view.addSubview(menuSection)
    menuSection.snp.makeConstraints { make in
      make.top.equalTo(divider2.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(64+24+24) // Help 위/아래 24씩
    }
    menuSection.addSubview(helpButton)
    menuSection.addSubview(logoutButton)
    helpButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(24)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(24)
      make.trailing.equalToSuperview().inset(20)
    }
    logoutButton.snp.makeConstraints { make in
      make.top.equalTo(helpButton.snp.bottom).offset(24)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(24)
      make.trailing.equalToSuperview().inset(20)
    }
    
    // 로그아웃 버튼 액션 추가
    logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
  }
  
  // MARK: - Data Fetching
  private func fetchLikedPlaces() {
    getLikedPlacesUseCase.execute()
      .receive(on: DispatchQueue.main)
      .sink { completion in
        switch completion {
        case .finished:
          break
        case .failure(let error):
          print("즐겨찾기 장소 가져오기 실패: \(error)")
        }
      } receiveValue: { [weak self] response in
        self?.fetchPlaceDetails(for: response.placeIds)
      }
      .store(in: &cancellables)
  }
  
  private func fetchPlaceDetails(for placeIds: [String]) {
    let group = DispatchGroup()
    var placeInfos: [PlaceCardInfo] = []
    
    for placeId in placeIds {
      group.enter()
      
      placesClient.fetchPlace(
        fromPlaceID: placeId,
        placeFields: [.name, .placeID, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
        sessionToken: nil
      ) { [weak self] (place, error) in
        defer { group.leave() }
        
        guard let self = self,
              let place = place,
              error == nil else { return }
        
        // 현재 위치 가져오기 (여기서는 임의의 위치 사용)
        let currentLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
        
        // PlaceCardInfo 생성
        let placeInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
        placeInfos.append(placeInfo)
      }
    }
    
    group.notify(queue: .main) { [weak self] in
      self?.likedPlaces = placeInfos
      self?.collectionView.reloadData()
    }
  }
  
  // MARK: - User Profile
  private func updateUserProfile() {
    if let user = GIDSignIn.sharedInstance.currentUser {
      // 이름 업데이트
      nameLabel.text = user.profile?.name ?? "User"
      
      // 이메일 업데이트
      emailLabel.text = user.profile?.email ?? "No email"
      
      // 프로필 이미지 업데이트
      if let profileImageURL = user.profile?.imageURL(withDimension: 96) {
        URLSession.shared.dataTask(with: profileImageURL) { [weak self] data, response, error in
          guard let self = self,
                let data = data,
                let image = UIImage(data: data) else { return }
          
          DispatchQueue.main.async {
            self.profileImageView.image = image
          }
        }.resume()
      }
    }
  }
  
  // MARK: - CollectionView DataSource & Delegate
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return likedPlaces.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
    let place = likedPlaces[indexPath.item]
    
    // 장소의 첫 번째 사진을 가져와서 표시
    if let placeId = place.placeID {
      placesClient.lookUpPhotos(forPlaceID: placeId) { [weak self] (photos, error) in
        guard let self = self,
              let photoMetadata = photos?.results.first else { return }
        
        self.placesClient.loadPlacePhoto(photoMetadata) { (photo, error) in
          if let photo = photo {
            DispatchQueue.main.async {
              cell.configure(image: photo)
            }
          }
        }
      }
    }
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 182, height: 219)
  }
  
  // MARK: - Actions
  @objc private func viewAllButtonTapped() {
    let myCollectionVC = MyCollectionViewController(likedPlaces: likedPlaces)
    navigationController?.pushViewController(myCollectionVC, animated: true)
  }
  
  @objc private func logoutButtonTapped() {
    let alert = UIAlertController(
      title: "로그아웃",
      message: "정말 로그아웃 하시겠습니까?",
      preferredStyle: .alert
    )
    
    let cancelAction = UIAlertAction(title: "취소", style: .cancel)
    let logoutAction = UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
      self?.performLogout()
    }
    
    alert.addAction(cancelAction)
    alert.addAction(logoutAction)
    
    present(alert, animated: true)
  }
  
  private func performLogout() {
    GIDSignIn.sharedInstance.signOut()
    
    // 로그인 화면으로 이동
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
      let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
      let loginVC = loginSceneDIContainer.makeSocialLoginViewController()
      let navController = UINavigationController(rootViewController: loginVC)
      window.rootViewController = navController
      window.makeKeyAndVisible()
    }
  }
}
