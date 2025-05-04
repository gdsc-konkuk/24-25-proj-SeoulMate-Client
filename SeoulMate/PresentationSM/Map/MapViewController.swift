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
  private let generatePlacePromptUseCase: GeneratePlacePromptUseCaseProtocol
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
  
  private var currentPlaces: [PlaceCardInfo] = []
  private var currentMarkers: [GMSMarker] = []
  
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
    generatePlacePromptUseCase: GeneratePlacePromptUseCaseProtocol
  ) {
    self.appDIContainer = appDIContainer
    self.getRecommendedPlacesUseCase = getRecommendedPlacesUseCase
    self.generatePlacePromptUseCase = generatePlacePromptUseCase
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
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.height.equalTo(220)
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
    mapView.settings.myLocationButton = true
    mapView.settings.compassButton = true
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
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
    mapView.addGestureRecognizer(tapGesture)
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
    let mapSceneDIContainer = appDIContainer.makeMapSceneDIContainer()
    let filterVC = mapSceneDIContainer.makeFilterViewController()
    filterVC.delegate = self
    
    filterVC.modalPresentationStyle = .fullScreen
    filterVC.transitioningDelegate = slideTransitioningDelegate
    
    present(filterVC, animated: true)
  }
  
  @objc private func mapTapped() {
    if !resultsTableView.isHidden {
      hideResultsTableView()
      textField.resignFirstResponder()
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
      placeFields: [.name, .coordinate, .formattedAddress, .rating, .userRatingsTotal, .photos],
      sessionToken: GMSAutocompleteSessionToken.init()
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
      
      // 단일 카드 표시
      self.showPlaceCard(for: place)
      
      // 서버에서 추천 장소 가져오기
      self.fetchRecommendedPlaces(coordinate: place.coordinate)
    }
  }
  
  private func showPlaceCard(for place: GMSPlace) {
    // 현재 위치 가져오기
    let currentLocation = locationManager.location?.coordinate ?? initialLocation
    
    // PlaceCardInfo 생성
    let placeInfo = PlaceCardInfo.from(place: place, currentLocation: currentLocation)
    
    // 단일 장소 표시
    currentPlaces = [placeInfo]
    placeCardsContainer.configure(with: currentPlaces)
    placeCardsContainer.show(animated: true)
  }
  
  // 2. 서버에서 추천 장소 가져오기
  private func fetchRecommendedPlaces(coordinate: CLLocationCoordinate2D) {
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
          self?.updateUIWithRecommendedPlaces(response.places)
      }
      .store(in: &cancellables)
  }
  
  // 3. UI 업데이트
  private func updateUIWithRecommendedPlaces(_ places: [PlaceResponse]) {
      guard let firstPlace = currentPlaces.first else { return }
      
      // 현재 위치
      let currentLocation = locationManager.location?.coordinate ?? initialLocation
      
      // 추천 장소들을 PlaceCardInfo로 변환
      let recommendedPlaces = places.map { place -> PlaceCardInfo in
          let coordinate = CLLocationCoordinate2D(
              latitude: place.coordinate.latitude,
              longitude: place.coordinate.longitude
          )
          
          // 거리 계산
          let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
          let distance = userLocation.distance(from: placeLocation) / 1000
          
          return PlaceCardInfo(
              name: place.address, // 또는 적절한 이름 필드
              address: place.address,
              distance: distance,
              rating: nil, // 서버 응답에 없으면 nil
              reviewCount: nil,
              imageUrl: place.image,
              placeId: place.id
          )
      }
      
      // 첫 번째 장소(사용자가 선택한 것) + 추천 장소들
      var allPlaces = [firstPlace]
      allPlaces.append(contentsOf: recommendedPlaces)
      
      // 카드뷰 업데이트
      currentPlaces = allPlaces
      placeCardsContainer.configure(with: allPlaces)
      
      // TODO: 추천 장소 마커 추가
      // addRecommendedMarkers(places)
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
    
    private func showPlaceDetailPopup(_ placeInfo: PlaceCardInfo) {
        // TODO: 장소 상세정보 팝업 구현
        print("Show detail for: \(placeInfo.name)")
    }
}

// MARK: - Google Maps Delegate
extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
      if placeCardsContainer.isHidden {
          placeCardsContainer.show(animated: true)
      } else {
          placeCardsContainer.hide(animated: true)
      }
  }
}
