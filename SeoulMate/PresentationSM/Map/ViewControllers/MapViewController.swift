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
    button.tintColor = .gray400
    
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
    button.tintColor = .red
    
    button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private var currentPlaces: [PlaceCardInfo] = []
  private var currentMarkers: [GMSMarker] = []
  var likedPlaceIds: Set<String> = []  // 좋아요한 장소 ID들을 저장할 Set
  
  // 현재 위치 표시를 위한 커스텀 마커
  private var myLocationCircle: GMSCircle?
  
  // 최초 위치 확인 플래그
  private var isFirstLocationUpdate = true
  
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
    tableView.isUserInteractionEnabled = true // 명시적으로 사용자 상호작용 활성화
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
    setupPlacesAPI()
    setupMapTapGesture()
    fetchLikedPlaces()  // 좋아요 목록 가져오기
    
    // 초기 지도 설정 - 현재 위치가 있으면 현재 위치로, 없으면 건국대학교로
    if let currentLocation = locationManager.location?.coordinate {
      setupMapView(at: currentLocation)
    } else {
      setupMapView()
    }
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
    view.addSubview(placeCardsContainer)
    view.addSubview(myLocationButton)
    view.addSubview(favoriteButton)
    
    // 테이블 뷰를 마지막에 추가하여 z-index가 가장 높게 설정
    view.addSubview(resultsTableView)
    
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
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.distanceFilter = 5 // 5미터 이상 이동했을 때만 업데이트
    locationManager.activityType = .otherNavigation
    
    // 위치 권한 요청
    locationManager.requestWhenInUseAuthorization()
    
    // 위치 업데이트 시작
    locationManager.startUpdatingLocation()
  }
  
  private func setupMapView(at coordinate: CLLocationCoordinate2D? = nil) {
    // 좌표가 없으면 초기 좌표 사용 (건국대학교)
    let targetCoordinate = coordinate ?? initialLocation
    
    Logger.log("지도 초기화 - 위도: \(targetCoordinate.latitude), 경도: \(targetCoordinate.longitude)")
    
    // 카메라 설정
    let camera = GMSCameraPosition.camera(
      withTarget: targetCoordinate,
      zoom: 15
    )
    
    mapView.camera = camera
    mapView.settings.myLocationButton = false  // 기본 내 위치 버튼 제거
    mapView.isMyLocationEnabled = true        // 내 위치 표시 활성화
    mapView.settings.compassButton = true
    mapView.delegate = self
    
    // 현재 위치 원 추가
    updateLocationCircle(at: targetCoordinate)
  }
  
  private func updateLocationCircle(at coordinate: CLLocationCoordinate2D) {
    // 기존 원 제거
    myLocationCircle?.map = nil
    
    // 새로운 원 생성
    myLocationCircle = GMSCircle(position: coordinate, radius: 50)
    myLocationCircle?.fillColor = UIColor.main500.withAlphaComponent(0.2)
    myLocationCircle?.strokeColor = UIColor.main500
    myLocationCircle?.strokeWidth = 2
    myLocationCircle?.map = mapView
  }
  
  private func setupActions() {
    searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    textField.delegate = self
    
    // 텍스트 필드의 editingChanged 이벤트 추가
    textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
  }
  
  private func setupPlacesAPI() {
    placesClient = GMSPlacesClient.shared()
  }
  
  private func setupMapTapGesture() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
    tapGesture.cancelsTouchesInView = false // 다른 터치 이벤트도 전달
    tapGesture.delegate = self
    mapView.addGestureRecognizer(tapGesture) // view 대신 mapView에 제스처 추가
  }
  
  @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: view)
    
    // 검색 결과 테이블이 보이고 있는 상태에서 테이블 뷰 영역을 탭한 경우에는 아무 동작 안 함
    if !resultsTableView.isHidden && resultsTableView.frame.contains(location) {
      return
    }
    
    // 키보드 숨기기
    view.endEditing(true)
    
    // 검색 결과 테이블 숨기기 (테이블 뷰 영역 외부를 탭한 경우)
    if !resultsTableView.isHidden {
      hideResultsTableView()
    }
    
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
        self.resultsTableView.isUserInteractionEnabled = true // 애니메이션 중에도 사용자 상호작용 보장
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
    // 테이블을 즉시 숨기기 위해 애니메이션 시간을 0.1초로 단축
    UIView.animate(withDuration: 0.1) {
      self.resultsTableView.snp.updateConstraints { make in
        make.height.equalTo(0)
      }
      self.view.layoutIfNeeded()
    } completion: { _ in
      self.resultsTableView.isHidden = true
      // 확실하게 검색 결과 초기화
      self.searchResults.removeAll()
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
          Logger.log("즐겨찾기 장소 가져오기 실패: \(error)")
        }
      } receiveValue: { [weak self] response in
        self?.likedPlaceIds = Set(response.placeIds)
        Logger.log("초기 좋아요한 장소들: \(self?.likedPlaceIds ?? [])")
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
    guard let searchText = textField.text, !searchText.isEmpty else { 
      // 검색어가 비어있으면 테이블 숨기기
      hideResultsTableView()
      searchResults.removeAll()
      return 
    }
    
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
      
      // 검색어가 여전히 비어있지 않은 경우에만 결과 표시
      if let currentText = self.textField.text, !currentText.isEmpty {
        // 결과 저장 및 테이블뷰 표시
        self.searchResults = predictions
        self.showResultsTableView()
      } else {
        self.hideResultsTableView()
      }
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
      updateLocationCircle(at: location)
    }
  }
  
  @objc private func favoriteButtonTapped() {
    // 캐러셀이 이미 표시되어 있으면 숨기고 버튼 위치를 원래대로 복원
    if !placeCardsContainer.isHidden {
      placeCardsContainer.hide(animated: true)
      
      // 버튼 위치 업데이트
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
      return
    }
    
    // 캐러셀이 표시되어 있지 않은 경우, 좋아요한 장소들을 가져와서 표시
    getLikedPlacesUseCase.execute()
      .receive(on: DispatchQueue.main)
      .sink { completion in
        switch completion {
        case .finished:
          break
        case .failure(let error):
          Logger.log("즐겨찾기 장소 가져오기 실패: \(error)")
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
        title: "Favorites",
        message: "You haven't added any places to favorites yet.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
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
    Logger.log("위치 권한 상태 변경: \(status.rawValue)")
    
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      Logger.log("위치 권한 획득 - 위치 업데이트 시작")
      mapView.isMyLocationEnabled = true     // 기본 내 위치 표시 활성화
      locationManager.startUpdatingLocation()
    case .denied, .restricted:
      // 권한이 거부된 경우 처리
      let alert = UIAlertController(
        title: "Location Permission Required",
        message: "Location permission is required to show your location. Please allow it in Settings.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      })
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      present(alert, animated: true)
      
      // 위치 권한이 없으면 초기 위치(건국대학교)로 지도 설정
      setupMapView()
    default:
      // 아직 결정되지 않은 경우 초기 위치로 설정
      setupMapView()
      break
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    
    Logger.log("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    
    // 위치 원 업데이트
    updateLocationCircle(at: location.coordinate)
    
    // 첫 위치 업데이트시에만 지도 초기화 (앱 시작할 때)
    if isFirstLocationUpdate {
      Logger.log("첫 위치 업데이트 - 지도 초기화")
      setupMapView(at: location.coordinate)
      isFirstLocationUpdate = false
      
      // 정확한 위치를 얻었으면 연속 업데이트 중지 및 유의미한 변경시에만 업데이트하도록 설정
      locationManager.stopUpdatingLocation()
      locationManager.startMonitoringSignificantLocationChanges()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Logger.log("위치 업데이트 실패: \(error.localizedDescription)")
    
    // 위치 가져오기 실패 시 초기 위치(건국대학교)로 설정
    if isFirstLocationUpdate {
      setupMapView()
      isFirstLocationUpdate = false
    }
  }
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text, !text.isEmpty else {
      textField.resignFirstResponder()
      return true
    }
    
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
    // 텍스트가 비어있으면 결과 테이블 즉시 숨기기
    if let text = textField.text, text.isEmpty {
      hideResultsTableView()
      searchResults.removeAll() // 텍스트가 비어있을 때 검색 결과도 초기화
      return
    }
    
    // 텍스트가 있을 때만 검색 실행
    if let text = textField.text, !text.isEmpty {
      performSearch()
    }
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    // 클리어 버튼 클릭 시 즉시 결과 테이블 숨김 처리
    hideResultsTableView()
    searchResults.removeAll()
    
    // 다음 runloop까지 검색 실행 방지
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
    
    // 명시적으로 셀을 선택 가능하게 설정
    cell.selectionStyle = .default
    cell.isUserInteractionEnabled = true
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 44
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    Logger.log("테이블 셀 선택됨: \(indexPath.row)")
    
    let selectedPlace = searchResults[indexPath.row]
    textField.text = selectedPlace.attributedPrimaryText.string
    
    // Hide keyboard
    textField.resignFirstResponder()
    
    // Fetch place details without hiding results table yet
    fetchPlaceDetails(placeID: selectedPlace.placeID, shouldHideResultsTable: true)
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    Logger.log("테이블 셀 선택 예정: \(indexPath.row)")
    return indexPath
  }
}

// MARK: - Private Methods
extension MapViewController {
  private func fetchPlaceDetails(placeID: String, shouldHideResultsTable: Bool = false) {
    // 카드 컨테이너 초기화
    placeCardsContainer.hide(animated: false)
    
    // 마커 배열 초기화
    currentMarkers = []
    
    placesClient.fetchPlace(
      fromPlaceID: placeID,
      placeFields: [.name, .placeID, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
      sessionToken: nil
    ) { [weak self] (place, error) in
      guard let self = self else { return }
      
      // Hide results table if needed
      if shouldHideResultsTable {
        DispatchQueue.main.async {
          self.hideResultsTableView()
        }
      }
      
      if let error = error {
        Logger.log("장소 상세정보 가져오기 실패: \(error.localizedDescription)")
        return
      }
      
      guard let place = place else {
        Logger.log("장소 정보가 없습니다.")
        return
      }
      
      // 지도 이동
      self.moveMapToLocation(coordinate: place.coordinate)
      
      // 기존 마커 제거
      self.mapView.clear()
      
      // 마커 추가
      let marker = GMSMarker(position: place.coordinate)
      marker.title = place.name
      marker.map = self.mapView
      self.currentMarkers = [marker]
      
      // 현재 위치 가져오기
      let currentLocation = self.locationManager.location?.coordinate ?? self.initialLocation
      
      // 첫 번째 장소 정보 생성
      let firstPlaceInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
      
      Logger.log("첫 번째 장소 정보 생성 완료: \(firstPlaceInfo.name)")
      
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
        Logger.log("추천 장소 요청 실패: \(error)")
      }
    } receiveValue: { [weak self] response in
      self?.handleRecommendedPlaces(response.places, firstPlaceInfo: firstPlaceInfo)
    }
    .store(in: &cancellables)
  }
  
  private func handleRecommendedPlaces(_ places: [RecommendedPlace], firstPlaceInfo: PlaceCardInfo) {
    Logger.log("서버에서 받은 추천 장소 수: \(places.count)")
    Logger.log("첫 번째 장소: \(firstPlaceInfo.name)")
    for (index, place) in places.enumerated() {
      Logger.log("추천 장소 \(index + 1): \(place.placeId)")
    }
    
    // 모든 장소 정보를 한번에 가져오기 위한 그룹
    let group = DispatchGroup()
    var recommendedPlaceInfos: [PlaceCardInfo] = Array(repeating: PlaceCardInfo(placeID: "", name: "", address: "", distance: 0, rating: nil, ratingCount: nil, description: nil), count: places.count)
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
              error == nil else { 
          Logger.log("구글 장소 정보 가져오기 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
          return 
        }
        
        // 현재 위치 가져오기
        let currentLocation = self.locationManager.location?.coordinate ?? self.initialLocation
        
        // PlaceCardInfo 생성
        var placeInfo = PlaceCardInfo.from(place: googlePlace, currentLocation: currentLocation)
        
        // RecommendedPlace의 description으로 업데이트
        placeInfo = PlaceCardInfo(
          placeID: placeInfo.placeID,
          name: placeInfo.name,
          address: placeInfo.address,
          distance: placeInfo.distance,
          rating: placeInfo.rating,
          ratingCount: placeInfo.ratingCount,
          description: place.description
        )
        
        // 마커 생성
        let marker = GMSMarker(position: googlePlace.coordinate)
        marker.title = googlePlace.name
        marker.map = self.mapView
        
        // 배열에 추가
        DispatchQueue.main.async {
          recommendedPlaceInfos[index] = placeInfo
          recommendedMarkers.append(marker)
          Logger.log("Added place at index \(index): \(placeInfo.name)")
        }
      }
    }
    
    // 모든 장소 정보를 가져온 후 UI 업데이트
    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      
      // 유효한 장소 정보만 필터링
      let validPlaceInfos = recommendedPlaceInfos.filter { $0.placeID != "" }
      Logger.log("처리된 추천 장소 수: \(validPlaceInfos.count)")
      
      // 첫 번째 장소와 추천 장소들을 합침
      self.currentPlaces = [firstPlaceInfo] + validPlaceInfos
      Logger.log("최종 장소 수 (첫 번째 장소 + 추천 장소): \(self.currentPlaces.count)")
      
      // 마커 처리
      if let firstMarker = self.currentMarkers.first {
        self.currentMarkers = [firstMarker] + recommendedMarkers
      } else {
        let firstMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        firstMarker.title = firstPlaceInfo.name
        firstMarker.map = self.mapView
        self.currentMarkers = [firstMarker] + recommendedMarkers
      }
      
      // 카드뷰 업데이트 (먼저 hide 했다가 다시 show)
      self.placeCardsContainer.hide(animated: false)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.placeCardsContainer.configure(with: self.currentPlaces)
        self.placeCardsContainer.show(animated: true)
        self.placeCardsContainer.scrollToIndex(0, animated: false)
      }
      
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
    Logger.log("Selected companion: \(filterData.companion ?? "None")")
    Logger.log("Selected purposes: \(filterData.purposes)")
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
    Logger.log("현재 좋아요한 장소들: \(likedPlaceIds)")
  }
}

// MARK: - Google Maps Delegate
extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    // 키보드 숨기기
    view.endEditing(true)
    
    // 검색 결과 테이블 숨기기
    if !resultsTableView.isHidden {
      hideResultsTableView()
    }
    
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
    // 키보드 숨기기
    view.endEditing(true)
    
    // 검색 결과 테이블 숨기기
    if !resultsTableView.isHidden {
      hideResultsTableView()
    }
    
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

// MARK: - UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    // 여러 제스처 인식기가 동시에 동작할 수 있도록 허용
    return true
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    // 터치 위치가 테이블 뷰 안에 있으면 이 제스처 인식기는 무시
    let touchPoint = touch.location(in: view)
    if !resultsTableView.isHidden && resultsTableView.frame.contains(touchPoint) {
      return false
    }
    return true
  }
}

// MARK: - Text Field Change Handling
extension MapViewController {
  @objc private func textFieldDidChange(_ textField: UITextField) {
    if let text = textField.text, text.isEmpty {
      // 텍스트가 비어있으면 즉시 테이블 숨기기
      hideResultsTableView()
      searchResults.removeAll()
    }
  }
}
