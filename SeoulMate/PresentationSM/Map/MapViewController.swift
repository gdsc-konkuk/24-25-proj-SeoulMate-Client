//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//  Updated on 4/3/25.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import SnapKit
import Combine

final class MapViewController: UIViewController {
  
  // MARK: - Dependencies
  private let placeSearchUseCase: PlaceSearchUseCaseProtocol
  private let placeImageUseCase: FetchPlaceImagesUseCaseProtocol
  
  // MARK: - Properties
  private let locationManager = CLLocationManager()
  private var mapView: GMSMapView!
  private var selectedMarker: GMSMarker?
  private var cancellables = Set<AnyCancellable>()
  private var userLocation: CLLocation?
  private let seoulCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
  
  // MARK: - UI Components
  private lazy var searchContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 8
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.1
    view.layer.shadowOffset = CGSize(width: 0, height: 2)
    view.layer.shadowRadius = 4
    return view
  }()
  
  private lazy var searchTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "장소, 주소 검색"
    textField.font = UIFont.systemFont(ofSize: 16)
    textField.returnKeyType = .search
    textField.clearButtonMode = .whileEditing
    textField.delegate = self
    textField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
    return textField
  }()
  
  private lazy var searchIconImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "magnifyingglass")
    imageView.tintColor = .gray
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  // 자동완성 결과를 표시할 테이블 뷰
  private var searchResultsTableView: UITableView!
  private var searchResultsBackgroundView: UIView!
  private var searchResults: [GMSAutocompletePrediction] = []
  private var searchActive: Bool = false
  
  private lazy var carouselView: PlaceCardCarouselView = {
    let view = PlaceCardCarouselView()
    view.isHidden = true
    view.onPlaceSelected = { [weak self] place in
      self?.showPlaceDetailPopup(for: place)
    }
    return view
  }()
  
  private var placeDetailPopup: PlaceDetailPopupView?
  private var loadingIndicator: UIActivityIndicatorView?
  
  // MARK: - Initialization
  init() {
    // DIContainer에서 필요한 UseCase 가져오기
    self.placeSearchUseCase = DIContainer.shared.resolve(type: PlaceSearchUseCaseProtocol.self)!
    self.placeImageUseCase = DIContainer.shared.resolve(type: FetchPlaceImagesUseCaseProtocol.self)!
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMapView()
    setupSearchBar()
    setupSearchResultsTableView()
    setupCarouselView()
    setupLocationManager()
    setupLoadingIndicator()
    
    // 초기 캐러셀 설정 (빈 카드)
    updateCarousel(with: [])
  }
  
  // MARK: - Setup Methods
  
  private func setupMapView() {
    // 카메라 위치(초기 위치는 서울)
    let camera = GMSCameraPosition.camera(withTarget: seoulCoordinate, zoom: 14)
    
    // 지도 생성
    mapView = GMSMapView()
    mapView.delegate = self
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = true
    
    view.addSubview(mapView)
    
    // SnapKit을 사용한 지도 제약 조건
    mapView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  private func setupSearchBar() {
    view.addSubview(searchContainerView)
    searchContainerView.addSubview(searchIconImageView)
    searchContainerView.addSubview(searchTextField)
    
    // SnapKit을 사용한 검색바 제약 조건
    searchContainerView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
      make.height.equalTo(50)
    }
    
    searchIconImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(20)
    }
    
    searchTextField.snp.makeConstraints { make in
      make.leading.equalTo(searchIconImageView.snp.trailing).offset(8)
      make.trailing.equalToSuperview().offset(-12)
      make.top.bottom.equalToSuperview()
    }
  }
  
  private func setupSearchResultsTableView() {
    // 테이블뷰 배경 뷰
    searchResultsBackgroundView = UIView()
    searchResultsBackgroundView.backgroundColor = .white
    searchResultsBackgroundView.layer.cornerRadius = 12
    searchResultsBackgroundView.layer.shadowColor = UIColor.black.cgColor
    searchResultsBackgroundView.layer.shadowOpacity = 0.2
    searchResultsBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
    searchResultsBackgroundView.layer.shadowRadius = 6
    searchResultsBackgroundView.isHidden = true
    view.addSubview(searchResultsBackgroundView)
    
    // 테이블뷰 설정
    searchResultsTableView = UITableView()
    searchResultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaceCell")
    searchResultsTableView.delegate = self
    searchResultsTableView.dataSource = self
    searchResultsTableView.backgroundColor = .clear
    searchResultsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    searchResultsTableView.keyboardDismissMode = .onDrag
    searchResultsTableView.isHidden = true
    searchResultsBackgroundView.addSubview(searchResultsTableView)
    
    // 제약 조건 설정
    searchResultsBackgroundView.snp.makeConstraints { make in
      make.top.equalTo(searchContainerView.snp.bottom).offset(8)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
      make.height.equalTo(300) // 최대 높이 설정
    }
    
    searchResultsTableView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    }
  }
  
  private func setupCarouselView() {
    view.addSubview(carouselView)
    
    // SnapKit을 사용한 캐러셀 뷰 제약 조건
    carouselView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      make.height.equalTo(200)
    }
  }
  
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    
    let authorizationStatus = locationManager.authorizationStatus
    checkLocationAuthorization(status: authorizationStatus)
    
    switch authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.startUpdatingLocation()
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    default:
      break
    }
  }
  
  private func setupLoadingIndicator() {
    loadingIndicator = UIActivityIndicatorView(style: .large)
    loadingIndicator?.color = .systemBlue
    loadingIndicator?.hidesWhenStopped = true
    
    guard let loadingIndicator = loadingIndicator else { return }
    
    view.addSubview(loadingIndicator)
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
  
  // MARK: - Search Functions
  
  func searchPlaces(query: String) {
    guard !query.isEmpty else {
      self.searchResults = []
      self.updateSearchResultsUI(isEmpty: true)
      return
    }
    
    showLoading(true)
    
    // 현재 위치 정보
    let userCoordinate = locationManager.location?.coordinate
    
    placeSearchUseCase.searchPlaces(query: query, region: userCoordinate)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          self?.showLoading(false)
          
          if case .failure(let error) = completion {
            self?.showErrorAlert(message: "검색 오류: \(error.localizedDescription)")
          }
        },
        receiveValue: { [weak self] predictions in
          self?.searchResults = predictions
          self?.updateSearchResultsUI(isEmpty: predictions.isEmpty)
        }
      )
      .store(in: &cancellables)
  }
  
  func getPlaceDetails(placeID: String) {
    guard !placeID.isEmpty else {
      showErrorAlert(message: "유효하지 않은 장소 ID입니다.")
      return
    }
    
    Logger.log(message: "장소 상세 정보 요청 시작: \(placeID)")
    showLoading(true)
    
    // 사용자 위치 정보
    let userLocation = locationManager.location
    
    placeSearchUseCase.getPlaceDetails(placeID: placeID, userLocation: userLocation)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          self?.showLoading(false)
          
          if case .failure(let error) = completion {
            Logger.log(message: "장소 정보 조회 실패: \(error.localizedDescription)")
            
            if let nserror = error as NSError? {
              // 상세 오류 로깅
              Logger.log(message: "도메인: \(nserror.domain), 코드: \(nserror.code)")
              
              if nserror.domain.contains("GooglePlaces") {
                self?.showErrorAlert(message: "Google Places API 오류: \(nserror.localizedDescription)")
              } else {
                self?.showErrorAlert(message: "장소 정보 조회 오류")
              }
            } else {
              self?.showErrorAlert(message: "장소 정보 조회 오류")
            }
          }
        },
        receiveValue: { [weak self] placeInfo in
          guard let self = self else { return }
          
          Logger.log(message: "장소 정보 조회 성공: \(placeInfo.name)")
          
          // 검색결과 UI 숨기기
          self.hideSearchResults()
          
          // 지도 업데이트
          self.updateMapWithSelectedPlace(placeInfo)
          
          // 장소 위치로 카메라 이동
          let coordinate = CLLocationCoordinate2D(
            latitude: placeInfo.coordinate.0,
            longitude: placeInfo.coordinate.1
          )
          let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 16)
          self.mapView.animate(to: camera)
        }
      )
      .store(in: &cancellables)
  }
  
  // MARK: - Location 관련 함수
  
  func checkLocationAuthorization(status: CLAuthorizationStatus) {
    switch status {
    case .denied, .restricted:
      showLocationAccessAlert()
      let camera = GMSCameraPosition.camera(withTarget: seoulCoordinate, zoom: 14)
      mapView.animate(to: camera)
    case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
      break
    @unknown default:
      let camera = GMSCameraPosition.camera(withTarget: seoulCoordinate, zoom: 14)
      mapView.animate(to: camera)
    }
  }
  
  // MARK: - UI Update Methods
  
  private func updateMapWithSelectedPlace(_ place: PlaceInfo) {
    // 기존 마커 제거
    mapView.clear()
    
    // 해당 위치에 마커 생성
    let coordinate = CLLocationCoordinate2D(
      latitude: place.coordinate.0,
      longitude: place.coordinate.1
    )
    
    let marker = GMSMarker(position: coordinate)
    marker.title = place.name
    marker.snippet = place.address
    marker.userData = place
    marker.map = mapView
    selectedMarker = marker
    
    // 캐러셀에 선택된 장소 표시
    updateCarousel(with: [place])
  }
  
  private func updateSearchResultsUI(isEmpty: Bool) {
    if isEmpty {
      searchResultsBackgroundView.isHidden = true
      searchResultsTableView.isHidden = true
      searchActive = false
    } else {
      searchResultsTableView.reloadData()
      searchResultsBackgroundView.isHidden = false
      searchResultsTableView.isHidden = false
      searchActive = true
    }
  }
  
  private func updateCarousel(with places: [PlaceInfo]) {
    // 장소 목록 설정 (빈 목록이라도 캐러셀은 표시됨)
    carouselView.setPlaces(places)
    
    // 항상 캐러셀 표시 (빈 카드가 자동으로 추가됨)
    if carouselView.isHidden {
      carouselView.isHidden = false
      carouselView.alpha = 0
      
      // 애니메이션으로 캐러셀 표시
      UIView.animate(withDuration: 0.3) {
        self.carouselView.alpha = 1.0
      }
    }
  }
  
  private func showLoading(_ isLoading: Bool) {
    if isLoading {
      loadingIndicator?.startAnimating()
    } else {
      loadingIndicator?.stopAnimating()
    }
  }
  
  // MARK: - Actions
  
  @objc private func locationButtonTapped() {
    if let location = locationManager.location {
      let camera = GMSCameraPosition.camera(
        withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: 15
      )
      mapView.animate(to: camera)
    } else {
      checkLocationAuthorization(status: locationManager.authorizationStatus)
    }
  }
  
  @objc private func searchTextChanged(_ textField: UITextField) {
    guard let searchText = textField.text else { return }
    searchPlaces(query: searchText)
  }
  
  // MARK: - Place Detail Popup
  
  private func showPlaceDetailPopup(for place: PlaceInfo) {
    // 기존 팝업 제거
    dismissPlaceDetailPopup()
    
    // 새 팝업 생성
    let popup = PlaceDetailPopupView(frame: view.bounds)
    popup.configure(with: place)
    popup.alpha = 0
    
    // 팝업 액션 설정
    popup.onDismiss = { [weak self] in
      self?.dismissPlaceDetailPopup()
    }
    
    popup.onShareButtonTapped = { [weak self] place in
      self?.sharePlaceInfo(place)
    }
    
    view.addSubview(popup)
    placeDetailPopup = popup
    
    // 애니메이션으로 팝업 표시
    UIView.animate(withDuration: 0.3) {
      popup.alpha = 1.0
    }
  }
  
  private func dismissPlaceDetailPopup() {
    guard let popup = placeDetailPopup else { return }
    
    UIView.animate(withDuration: 0.3, animations: {
      popup.alpha = 0
    }) { _ in
      popup.removeFromSuperview()
      self.placeDetailPopup = nil
    }
  }
  
  private func sharePlaceInfo(_ place: PlaceInfo) {
    // 장소 정보 공유 로직 구현
    let activityItems = [
      "\(place.name)",
      "\(place.address)",
      "SeoulMate 앱에서 확인해보세요!"
    ]
    
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    
    // iPad 대응
    if let popoverController = activityViewController.popoverPresentationController {
      popoverController.sourceView = view
      popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }
    
    present(activityViewController, animated: true)
  }
  
  // MARK: - Helper Methods
  
  private func hideSearchResults() {
    searchResults = []
    updateSearchResultsUI(isEmpty: true)
    searchTextField.resignFirstResponder()
  }
  
  private func showLocationAccessAlert() {
    let alert = UIAlertController(
      title: "위치 접근 권한이 필요합니다",
      message: "더 나은 경험을 위해 위치 접근을 허용해주세요.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    })
    
    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    
    present(alert, animated: true)
  }
  
  private func showErrorAlert(message: String) {
    let alert = UIAlertController(
      title: "오류",
      message: message,
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    
    present(alert, animated: true)
  }
}

// MARK: - UITextFieldDelegate

extension MapViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if let text = textField.text, !text.isEmpty {
      // 자동완성 결과가 있고 비어있지 않으면 첫 번째 항목 선택
      if !searchResults.isEmpty {
        let firstPrediction = searchResults[0]
        // 텍스트 필드의 내용을 선택한 항목의 텍스트로 업데이트
        textField.text = firstPrediction.attributedPrimaryText.string
        getPlaceDetails(placeID: firstPrediction.placeID)
      } else {
        // 자동완성 결과가 없으면 기존처럼 검색어로 검색
        searchPlaces(query: text)
      }
    }
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if let text = textField.text, !text.isEmpty {
      // 텍스트가 있으면 자동완성 결과 표시
      searchPlaces(query: text)
    }
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.hideSearchResults()
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    return searchResults.count
  }
  
  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
    
    let prediction = searchResults[indexPath.row]
    
    // 셀 스타일 설정
    cell.textLabel?.text = prediction.attributedPrimaryText.string
    cell.detailTextLabel?.text = prediction.attributedSecondaryText?.string
    cell.imageView?.image = UIImage(systemName: "mappin.circle.fill")
    cell.imageView?.tintColor = .systemBlue
    cell.accessoryType = .disclosureIndicator
    
    return cell
  }
  
  func tableView(
    _ tableView: UITableView,
    didSelectRowAt indexPath: IndexPath
  ) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let prediction = searchResults[indexPath.row]
    getPlaceDetails(placeID: prediction.placeID)
    
    searchTextField.text = prediction.attributedPrimaryText.string
  }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.first else { return }
    userLocation = location
    
    // 최초 위치 설정 시 카메라 이동
    if userLocation == nil {
      let camera = GMSCameraPosition.camera(
        withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: 15
      )
      mapView.animate(to: camera)
    }
  }
  
  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    Logger.log(message: "위치 정보를 가져오는데 실패했습니다: \(error.localizedDescription)")
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    checkLocationAuthorization(status: manager.authorizationStatus)
    
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      // 권한이 허용되면 즉시 위치 업데이트 시작
      locationManager.startUpdatingLocation()
    case .denied, .restricted, .notDetermined:
      // 권한 없을 때 처리
      break
    @unknown default:
      break
    }
  }
}

// MARK: - GMSMapViewDelegate
extension MapViewController: GMSMapViewDelegate {
  func mapView(
    _ mapView: GMSMapView,
    didTapAt coordinate: CLLocationCoordinate2D
  ) {
    // 지도 탭 시 팝업 닫기
    dismissPlaceDetailPopup()
    
    // 검색 결과 숨기기
    hideSearchResults()
    searchTextField.resignFirstResponder()
  }
  
  func mapView(
    _ mapView: GMSMapView,
    didTapPOIWithPlaceID placeID: String,
    name: String,
    location: CLLocationCoordinate2D
  ) {
    getPlaceDetails(placeID: placeID)
  }
}
