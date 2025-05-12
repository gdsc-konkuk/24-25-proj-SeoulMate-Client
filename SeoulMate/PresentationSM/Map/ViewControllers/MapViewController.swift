//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import Combine
import CoreLocation
import GoogleMaps
import GoogleSignIn
import GooglePlaces

final class MapViewController: UIViewController {
  
  // MARK: - Properties
  private let appDIContainer: AppDIContainer
  private let getRecommendedPlacesUseCase: GetRecommendedPlacesUseCaseProtocol
  private let getUserProfileUseCase: GetUserProfileUseCaseProtocol
  private let getLikedPlacesUseCase: GetLikedPlacesUseCaseProtocol
  private var cancellables = Set<AnyCancellable>()
  
  private let slideTransitioningDelegate = SlideTransitioningDelegate()
  private let mapView = GMSMapView()
  private let locationManager = CLLocationManager()
  private var placesClient: GMSPlacesClient!
  private var searchResults: [GMSAutocompletePrediction] = []
  
  // 건국대학교 좌표
  private let initialLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
  
  private lazy var placeCardsContainer: PlaceCardsContainerView = {
    let view = PlaceCardsContainerView()
    view.delegate = self
    view.isHidden = true
    return view
  }()
  
  private lazy var myLocationButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = .white
    button.layer.cornerRadius = 24
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowOpacity = 0.1
    button.layer.shadowRadius = 4
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let locationImage = UIImage(systemName: "location.fill", withConfiguration: config)
    button.setImage(locationImage, for: .normal)
    button.tintColor = .main500
    
    button.addTarget(self, action: #selector(myLocationButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private lazy var favoriteButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = .white
    button.layer.cornerRadius = 24
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowOpacity = 0.1
    button.layer.shadowRadius = 4
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let heartImage = UIImage(systemName: "heart.fill", withConfiguration: config)
    button.setImage(heartImage, for: .normal)
    button.tintColor = .main500
    
    button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private var currentPlaces: [PlaceCardInfo] = []
  private var currentMarkers: [GMSMarker] = []
  var likedPlaceIds: Set<String> = []  // 좋아요한 장소 ID들을 저장할 Set
  
  // MARK: - UI Properties
  private let searchContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 30
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOffset = CGSize(width: 0, height: 2)
    view.layer.shadowOpacity = 0.1
    view.layer.shadowRadius = 4
    return view
  }()
  
  private lazy var resultsTableView: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = .white
    tableView.register(PlaceCell.self, forCellReuseIdentifier: PlaceCell.identifier)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.isHidden = true
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    return tableView
  }()
  
  private let searchButton: UIButton = {
    let button = UIButton(type: .system)
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let searchIcon = UIImage(systemName: "magnifyingglass", withConfiguration: config)
    button.setImage(searchIcon, for: .normal)
    button.tintColor = .gray
    button.contentMode = .scaleAspectFit
    return button
  }()
  
  private let textField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "Gyeongbokgung"
    textField.font = .regularFont(ofSize: 16)
    textField.borderStyle = .none
    textField.backgroundColor = .clear
    textField.clearButtonMode = .whileEditing
    textField.autocorrectionType = .no
    textField.returnKeyType = .search
    return textField
  }()
  
  private let filterButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .main500
    button.layer.cornerRadius = 24
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let sliderImage = UIImage(systemName: "slider.horizontal.3", withConfiguration: config)
    button.setImage(sliderImage, for: .normal)
    button.tintColor = .white
    
    return button
  }()
  
  // MARK: - Initializer
  init(
    appDIContainer: AppDIContainer,
    getRecommendedPlacesUseCase: GetRecommendedPlacesUseCaseProtocol,
    getUserProfileUseCase: GetUserProfileUseCaseProtocol,
    getLikedPlacesUseCase: GetLikedPlacesUseCaseProtocol
  ) {
    self.appDIContainer = appDIContainer
    self.getRecommendedPlacesUseCase = getRecommendedPlacesUseCase
    self.getUserProfileUseCase = getUserProfileUseCase
    self.getLikedPlacesUseCase = getLikedPlacesUseCase
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupActions()
    setupLocationManager()
    setupMapView()
    setupPlacesAPI()
    setupMapTapGesture()
    fetchLikedPlaces()  // 좋아요 목록 가져오기
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.addSubview(mapView)
    
    view.addSubview(searchContainerView)
    searchContainerView.addSubview(searchButton)
    searchContainerView.addSubview(textField)
    view.addSubview(filterButton)
    view.addSubview(resultsTableView)
    view.addSubview(placeCardsContainer)
    view.addSubview(myLocationButton)
    view.addSubview(favoriteButton)
    
    mapView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    searchContainerView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalTo(filterButton.snp.leading).offset(-12)
      make.height.equalTo(48)
    }
    
    searchButton.snp.makeConstraints { make in
      make.leading.equalTo(searchContainerView).offset(16)
      make.centerY.equalTo(searchContainerView)
      make.width.height.equalTo(24)
    }
    
    textField.snp.makeConstraints { make in
      make.leading.equalTo(searchButton.snp.trailing).offset(8)
      make.trailing.equalTo(searchContainerView).offset(-16)
      make.centerY.equalTo(searchContainerView)
      make.height.equalTo(30)
    }
    
    filterButton.snp.makeConstraints { make in
      make.centerY.equalTo(searchContainerView)
      make.trailing.equalToSuperview().offset(-16)
      make.width.height.equalTo(48)
    }
    
    resultsTableView.snp.makeConstraints { make in
      make.top.equalTo(searchContainerView.snp.bottom).offset(8)
      make.leading.equalTo(searchContainerView)
      make.trailing.equalTo(filterButton)
      make.height.equalTo(0) // 처음에는 높이 0
    }
    
    placeCardsContainer.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-29)
      make.height.equalTo(220)
    }
    
    myLocationButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-24)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.width.height.equalTo(48)
    }
    
    favoriteButton.snp.makeConstraints { make in
      make.trailing.equalTo(myLocationButton)
      make.bottom.equalTo(myLocationButton.snp.top).offset(-12)
      make.width.height.equalTo(48)
    }
  }
  
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    // 위치 권한 요청
    locationManager.requestWhenInUseAuthorization()
  }
  
  private func setupMapView() {
    // 카메라 설정 (건국대학교 중심, 줌 레벨 15)
    let camera = GMSCameraPosition.camera(
      withTarget: initialLocation,
      zoom: 15
    )
    
    mapView.camera = camera
    mapView.settings.myLocationButton = false  // 기본 내 위치 버튼 제거
    mapView.settings.compassButton = true
    mapView.delegate = self
  }
  
  private func setupActions() {
    searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    textField.delegate = self
  }
  
  private func setupPlacesAPI() {
    placesClient = GMSPlacesClient.shared()
  }
  
  private func setupMapTapGesture() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
    tapGesture.cancelsTouchesInView = false // 다른 터치 이벤트도 전달
    view.addGestureRecognizer(tapGesture)
  }
  
  @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: view)
    // 카드뷰가 보이고, 카드뷰 영역 밖을 탭한 경우에만 숨김
    if !placeCardsContainer.isHidden && !placeCardsContainer.frame.contains(location) {
      placeCardsContainer.hide(animated: true)
    }
  }
  
  private func showResultsTableView() {
    DispatchQueue.main.async {
      self.resultsTableView.reloadData()
      
      UIView.animate(withDuration: 0.3) {
        self.resultsTableView.isHidden = false
        self.resultsTableView.snp.updateConstraints { make in
          // 최대 5개 결과만 표시 (또는 결과 개수에 따라 조정)
          let height = min(self.searchResults.count, 5) * 44
          make.height.equalTo(height)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
  
  private func hideResultsTableView() {
    UIView.animate(withDuration: 0.3) {
      self.resultsTableView.snp.updateConstraints { make in
        make.height.equalTo(0)
      }
      self.view.layoutIfNeeded()
    } completion: { _ in
      self.resultsTableView.isHidden = true
    }
  }
  
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
        self?.likedPlaceIds = Set(response.placeIds)
        print("초기 좋아요한 장소들: \(self?.likedPlaceIds ?? [])")
      }
      .store(in: &cancellables)
  }
}

// MARK: - Action methods
extension MapViewController {
  @objc private func searchButtonTapped() {
    // 검색 실행
    performSearch()
  }
  
  private func performSearch() {
    guard let searchText = textField.text, !searchText.isEmpty else { return }
    
    // Places API를 사용하여 자동 완성 요청
    let filter = GMSAutocompleteFilter()
    filter.countries = ["KR"]    // 한국으로 제한
    
    placesClient.findAutocompletePredictions(
      fromQuery: searchText,
      filter: filter,
      sessionToken: nil
    ) { [weak self] (predictions, error) in
      guard let self = self else { return }
      
      if error != nil {
        return
      }
      
      guard let predictions = predictions, !predictions.isEmpty else {
        self.hideResultsTableView()
        return
      }
      
      // 결과 저장 및 테이블뷰 표시
      self.searchResults = predictions
      self.showResultsTableView()
    }
  }
  
  @objc private func filterButtonTapped() {
    // 캐러셀이 보이는 상태라면 숨기고 버튼 위치 업데이트
    if !placeCardsContainer.isHidden {
      placeCardsContainer.hide(animated: true)
      
      UIView.animate(withDuration: 0.3) {
        self.myLocationButton.snp.remakeConstraints { make in
          make.trailing.equalToSuperview().offset(-24)
          make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
          make.width.height.equalTo(48)
        }
        self.favoriteButton.snp.remakeConstraints { make in
          make.trailing.equalTo(self.myLocationButton)
          make.bottom.equalTo(self.myLocationButton.snp.top).offset(-12)
          make.width.height.equalTo(48)
        }
        self.view.layoutIfNeeded()
      }
    }
    
    let mapSceneDIContainer = appDIContainer.makeMapSceneDIContainer()
    let filterVC = mapSceneDIContainer.makeFilterViewController()
    filterVC.delegate = self
    
    filterVC.modalPresentationStyle = .fullScreen
    filterVC.transitioningDelegate = slideTransitioningDelegate
    
    present(filterVC, animated: true)
  }
  
  @objc private func myLocationButtonTapped() {
    if let location = locationManager.location?.coordinate {
      let camera = GMSCameraPosition.camera(withTarget: location, zoom: 15)
      mapView.animate(to: camera)
    }
  }
  
  @objc private func favoriteButtonTapped() {
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
        self?.handleLikedPlaces(response)
      }
      .store(in: &cancellables)
  }
  
  private func handleLikedPlaces(_ response: LikedPlacesResponse) {
    guard !response.placeIds.isEmpty else {
      // 즐겨찾기한 장소가 없는 경우 알림 표시
      let alert = UIAlertController(
        title: "즐겨찾기",
        message: "아직 즐겨찾기한 장소가 없습니다.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "확인", style: .default))
      present(alert, animated: true)
      return
    }
    
    // 기존 마커와 장소 정보 초기화
    mapView.clear()
    currentMarkers.removeAll()
    currentPlaces.removeAll()
    
    // 여러 비동기 작업을 처리하기 위한 그룹 생성
    let group = DispatchGroup()
    var placeInfos: [PlaceCardInfo] = []
    var markers: [GMSMarker] = []
    
    // 거리 계산을 위한 현재 위치 가져오기
    let currentLocation = locationManager.location?.coordinate ?? initialLocation
    
    // 각 즐겨찾기 장소의 상세 정보 가져오기
    for (index, placeId) in response.placeIds.enumerated() {
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
        
        // 장소 정보 생성
        var placeInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
        // 서버에서 받은 description으로 업데이트
        placeInfo = PlaceCardInfo(
          placeID: placeInfo.placeID,
          name: placeInfo.name,
          address: placeInfo.address,
          distance: placeInfo.distance,
          rating: placeInfo.rating,
          ratingCount: placeInfo.ratingCount,
          description: "TODO"
        )
        
        // 마커 생성
        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        marker.map = self.mapView
        
        // 배열에 추가 (순서 유지)
        DispatchQueue.main.async {
          while placeInfos.count <= index {
            placeInfos.append(placeInfo)
          }
          while markers.count <= index {
            markers.append(marker)
          }
          placeInfos[index] = placeInfo
          markers[index] = marker
        }
      }
    }
    
    // 모든 장소 정보를 가져온 후 UI 업데이트
    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      
      self.currentPlaces = placeInfos
      self.currentMarkers = markers
      
      // 카드뷰 업데이트
      self.placeCardsContainer.configure(with: self.currentPlaces)
      self.placeCardsContainer.show(animated: true)
      self.placeCardsContainer.scrollToIndex(0, animated: false)
      
      // 첫 번째 장소로 지도 이동
      if let firstPlace = placeInfos.first,
         let firstMarker = markers.first {
        self.moveMapToLocation(coordinate: firstMarker.position)
        self.mapView.selectedMarker = firstMarker
      }
      
      // 버튼 위치 업데이트
      UIView.animate(withDuration: 0.3) {
        self.myLocationButton.snp.remakeConstraints { make in
          make.trailing.equalToSuperview().offset(-24)
          make.bottom.equalTo(self.placeCardsContainer.snp.top).offset(-16)
          make.width.height.equalTo(48)
        }
        self.favoriteButton.snp.remakeConstraints { make in
          make.trailing.equalTo(self.myLocationButton)
          make.bottom.equalTo(self.myLocationButton.snp.top).offset(-12)
          make.width.height.equalTo(48)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.startUpdatingLocation()
      mapView.isMyLocationEnabled = true
      mapView.settings.myLocationButton = true
    case .denied, .restricted:
      // 권한이 거부된 경우 처리
      let alert = UIAlertController(
        title: "위치 권한 필요",
        message: "내 위치를 표시하려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      })
      alert.addAction(UIAlertAction(title: "취소", style: .cancel))
      present(alert, animated: true)
    default:
      break
    }
  }
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    performSearch()
    
    // 검색 결과가 있으면 첫 번째 결과로 자동 이동
    if !searchResults.isEmpty {
      fetchPlaceDetails(placeID: searchResults[0].placeID)
      textField.text = searchResults[0].attributedPrimaryText.string
      hideResultsTableView()
    }
    
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidChangeSelection(_ textField: UITextField) {
    // 텍스트가 비어있으면 결과 테이블 숨기기
    if let text = textField.text, text.isEmpty {
      hideResultsTableView()
    }
    performSearch()
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    DispatchQueue.main.async {
      self.hideResultsTableView()
    }
    return true
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceCell.identifier, for: indexPath) as? PlaceCell else {
      return UITableViewCell()
    }
    
    let prediction = searchResults[indexPath.row]
    let placeName = prediction.attributedPrimaryText.string
    
    cell.configure(with: placeName)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 44
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedPlace = searchResults[indexPath.row]
    textField.text = selectedPlace.attributedPrimaryText.string
    
    // TODO: 상세 정보 가져오기
    fetchPlaceDetails(placeID: selectedPlace.placeID)
    
    // 테이블 숨기기 및 키보드 내리기
    hideResultsTableView()
    textField.resignFirstResponder()
  }
}

// MARK: - Private Methods
extension MapViewController {
  private func fetchPlaceDetails(placeID: String) {
    placesClient.fetchPlace(
      fromPlaceID: placeID,
      placeFields: [.name, .placeID, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
      sessionToken: nil
    ) { [weak self] (place, error) in
      guard let self = self else { return }
      
      if error != nil {
        return
      }
      
      guard let place = place else {
        return
      }
      
      // 지도 이동
      self.moveMapToLocation(coordinate: place.coordinate)
      
      // 마커 추가
      self.mapView.clear()
      self.addMarker(at: place.coordinate, title: place.name)
      
      // 현재 위치 가져오기
      let currentLocation = self.locationManager.location?.coordinate ?? self.initialLocation
      
      // 첫 번째 장소 정보 생성
      let firstPlaceInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
      
      // 추천 장소 가져오기
      self.fetchRecommendedPlaces(coordinate: place.coordinate, firstPlaceInfo: firstPlaceInfo)
    }
  }
  
  private func fetchRecommendedPlaces(coordinate: CLLocationCoordinate2D, firstPlaceInfo: PlaceCardInfo) {
    getRecommendedPlacesUseCase.execute(
      x: coordinate.longitude,
      y: coordinate.latitude
    )
    .receive(on: DispatchQueue.main)
    .sink { completion in
      switch completion {
      case .finished:
        break
      case .failure(let error):
        print("추천 장소 요청 실패: \(error)")
      }
    } receiveValue: { [weak self] response in
      self?.handleRecommendedPlaces(response.places, firstPlaceInfo: firstPlaceInfo)
    }
    .store(in: &cancellables)
  }
  
  private func handleRecommendedPlaces(_ places: [RecommendedPlace], firstPlaceInfo: PlaceCardInfo) {
    print("서버에서 받은 추천 장소 수: \(places.count)")
    print("첫 번째 장소: \(firstPlaceInfo.name)")
    for (index, place) in places.enumerated() {
      print("추천 장소 \(index + 1): \(place.placeId)")
    }
    
    // 모든 장소 정보를 한번에 가져오기 위한 그룹
    let group = DispatchGroup()
    var recommendedPlaceInfos: [PlaceCardInfo] = []
    var recommendedMarkers: [GMSMarker] = []
    
    // 각 추천 장소에 대해 구글 Places API로 상세 정보를 가져옵니다
    for (index, place) in places.enumerated() {
      group.enter()
      
      placesClient.fetchPlace(
        fromPlaceID: place.placeId,
        placeFields: [.name, .placeID, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
        sessionToken: nil
      ) { [weak self] (googlePlace, error) in
        defer { group.leave() }
        
        guard let self = self,
              let googlePlace = googlePlace,
              error == nil else { return }
        
        // 현재 위치 가져오기
        let currentLocation = self.locationManager.location?.coordinate ?? self.initialLocation
        
        // PlaceCardInfo 생성
        var description = place.description
        var placeInfo = PlaceCardInfo.from(place: googlePlace, currentLocation: currentLocation)
        // RecommendedPlace의 description으로 업데이트
        placeInfo = PlaceCardInfo(
          placeID: placeInfo.placeID,
          name: placeInfo.name,
          address: placeInfo.address,
          distance: placeInfo.distance,
          rating: placeInfo.rating,
          ratingCount: placeInfo.ratingCount,
          description: description
        )
        
        // 마커 생성
        let marker = GMSMarker(position: googlePlace.coordinate)
        marker.title = googlePlace.name
        marker.map = self.mapView
        
        // 배열에 추가 (순서 보장)
        DispatchQueue.main.async {
          // 배열의 크기가 index보다 작으면 nil로 채움
          while recommendedPlaceInfos.count <= index {
            recommendedPlaceInfos.append(placeInfo)
          }
          while recommendedMarkers.count <= index {
            recommendedMarkers.append(marker)
          }
          
          // 해당 인덱스에 정보 저장
          recommendedPlaceInfos[index] = placeInfo
          recommendedMarkers[index] = marker
        }
      }
    }
    
    // 모든 장소 정보를 가져온 후 UI 업데이트
    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      
      print("처리된 추천 장소 수: \(recommendedPlaceInfos.count)")
      
      // 첫 번째 장소와 추천 장소들을 합침
      self.currentPlaces = [firstPlaceInfo] + recommendedPlaceInfos
      print("최종 장소 수 (첫 번째 장소 + 추천 장소): \(self.currentPlaces.count)")
      
      // 첫 번째 마커가 있는 경우에만 추가
      if let firstMarker = self.currentMarkers.first {
        self.currentMarkers = [firstMarker] + recommendedMarkers
      } else {
        self.currentMarkers = recommendedMarkers
      }
      
      // 카드뷰 업데이트
      self.placeCardsContainer.configure(with: self.currentPlaces)
      self.placeCardsContainer.show(animated: true)
      self.placeCardsContainer.scrollToIndex(0, animated: false)
      
      // 내 위치 버튼 위치 업데이트
      UIView.animate(withDuration: 0.3) {
        self.myLocationButton.snp.remakeConstraints { make in
          make.trailing.equalToSuperview().offset(-24)
          make.bottom.equalTo(self.placeCardsContainer.snp.top).offset(-16)
          make.width.height.equalTo(48)
        }
        self.favoriteButton.snp.remakeConstraints { make in
          make.trailing.equalTo(self.myLocationButton)
          make.bottom.equalTo(self.myLocationButton.snp.top).offset(-12)
          make.width.height.equalTo(48)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
  
  // 3. UI 업데이트
  private func updateUIWithRecommendedPlaces(_ places: [RecommendedPlace]) {
    // 첫 번째 장소는 이미 표시되어 있으므로 건너뜁니다
    handleRecommendedPlaces(places, firstPlaceInfo: currentPlaces[0])
  }
  
  private func moveMapToLocation(coordinate: CLLocationCoordinate2D) {
    let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 17)
    mapView.animate(to: camera)
  }
  
  private func addMarker(at coordinate: CLLocationCoordinate2D, title: String?) {
    // 기존 마커 제거
    mapView.clear()
    
    // 새 마커 추가
    let marker = GMSMarker(position: coordinate)
    marker.title = title
    marker.map = mapView
    
    // 마커의 정보창 표시
    mapView.selectedMarker = marker
  }
}

extension MapViewController: FilterDelegate {
  func didApplyFilter(_ filterData: FilterData) {
    print("Selected companion: \(filterData.companion ?? "None")")
    print("Selected purposes: \(filterData.purposes)")
    
    // TODO: 필터에 따른 지도 업데이트
  }
}

extension MapViewController: PlaceCardsContainerDelegate {
  func didSelectPlace(at index: Int, placeInfo: PlaceCardInfo) {
    // 장소 상세정보 팝업 표시
    showPlaceDetailPopup(placeInfo)
  }
  
  func didScrollToPlace(at index: Int, placeInfo: PlaceCardInfo) {
    // 스크롤 시 해당 장소로 지도 이동
    if index < currentMarkers.count {
      let marker = currentMarkers[index]
      mapView.selectedMarker = marker
      
      // 카메라 이동
      let camera = GMSCameraPosition.camera(
        withTarget: marker.position,
        zoom: 16
      )
      mapView.animate(to: camera)
    }
  }
  
  func showPlaceDetailPopup(_ placeInfo: PlaceCardInfo) {
    getUserProfileUseCase.execute()
      .receive(on: DispatchQueue.main)
      .sink { completion in
        // 에러 처리 등
      } receiveValue: { [weak self] profile in
        guard let self = self else { return }
        let purposes = profile.purpose ?? []
        let isLiked = self.likedPlaceIds.contains(placeInfo.placeID ?? "")
        let vc = PlaceDetailViewController(
          placeId: placeInfo.placeID ?? "",
          updateLikeStatusUseCase: appDIContainer.updateLikeStatusUseCase,
          isLiked: isLiked
        )
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.configure(with: placeInfo, purposes: purposes)
        self.present(vc, animated: false)
      }
      .store(in: &cancellables)
  }
}

extension MapViewController: PlaceDetailViewControllerDelegate {
  func placeDetailViewController(_ controller: PlaceDetailViewController, didDismissWith placeInfo: PlaceCardInfo?) {
    guard let placeInfo = placeInfo else { return }
    
    // PlaceDetailViewController dismiss
    controller.dismiss(animated: false) { [weak self] in
      // Only show AIChatViewController if placeInfo is not nil (meaning it was dismissed via Ask to Bot)
      let aiChatVC = self?.appDIContainer.makeAIChatSceneDIContainer().makeAIChatViewController()
      aiChatVC?.configure(with: placeInfo)
      aiChatVC?.modalPresentationStyle = .fullScreen
      aiChatVC?.modalTransitionStyle = .coverVertical
      if let aiChatVC = aiChatVC {
        self?.present(aiChatVC, animated: true)
      }
    }
  }
  
  func placeDetailViewController(_ controller: PlaceDetailViewController, didChangeLikeStatus placeId: String, isLiked: Bool) {
    if isLiked {
      likedPlaceIds.insert(placeId)
    } else {
      likedPlaceIds.remove(placeId)
    }
    print("현재 좋아요한 장소들: \(likedPlaceIds)")
  }
}

// MARK: - Google Maps Delegate
extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    if !placeCardsContainer.isHidden {
      placeCardsContainer.hide(animated: true)
      
      // 내 위치 버튼 위치 업데이트
      UIView.animate(withDuration: 0.3) {
        self.myLocationButton.snp.remakeConstraints { make in
          make.trailing.equalToSuperview().offset(-24)
          make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
          make.width.height.equalTo(48)
        }
        self.favoriteButton.snp.remakeConstraints { make in
          make.trailing.equalTo(self.myLocationButton)
          make.bottom.equalTo(self.myLocationButton.snp.top).offset(-12)
          make.width.height.equalTo(48)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
  
  // ★ POI(장소) 클릭 시 카드뷰 띄우기
  func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
    // POI의 상세 정보를 가져와서 카드뷰를 띄움
    placesClient.fetchPlace(
      fromPlaceID: placeID,
      placeFields: [.name, .placeID, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
      sessionToken: nil
    ) { [weak self] (place, error) in
      guard let self = self, let place = place, error == nil else { return }
      
      // 지도 이동
      self.moveMapToLocation(coordinate: place.coordinate)
      
      // 기존 마커 제거
      self.mapView.clear()
      
      // 현재 위치 가져오기
      let currentLocation = self.locationManager.location?.coordinate ?? self.initialLocation
      
      // 첫 번째 장소 정보 생성
      let firstPlaceInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
      
      // 첫 번째 마커 생성 및 추가
      let firstMarker = GMSMarker(position: place.coordinate)
      firstMarker.title = place.name
      firstMarker.map = self.mapView
      
      // 현재 마커와 장소 정보 초기화
      self.currentMarkers = [firstMarker]
      self.currentPlaces = [firstPlaceInfo]
      
      // 추천 장소 가져오기
      self.fetchRecommendedPlaces(coordinate: place.coordinate, firstPlaceInfo: firstPlaceInfo)
    }
  }
}
