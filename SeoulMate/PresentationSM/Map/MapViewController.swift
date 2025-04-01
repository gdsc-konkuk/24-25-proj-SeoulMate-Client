//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import SnapKit
import Combine

final class MapViewController: UIViewController {
  
  // MARK: - Properties
  
  private let locationManager = CLLocationManager()
  private var currentLocation: CLLocation?
  private var mapView: GMSMapView!
  private var markers: [GMSMarker] = []
  private var selectedMarker: GMSMarker?
  private var placesClient: GMSPlacesClient!
  
  // 자동완성 결과를 표시할 테이블 뷰
  private var searchResultsTableView: UITableView!
  private var searchResultsBackgroundView: UIView!
  private var searchResults: [GMSAutocompletePrediction] = []
  private var searchActive: Bool = false
  
  // 서울 좌표 (기본값)
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
  
  private lazy var locationButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "location.circle.fill"), for: .normal)
    button.backgroundColor = .white
    button.tintColor = .systemBlue
    button.layer.cornerRadius = 25
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = 0.1
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowRadius = 4
    button.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private lazy var carouselView: PlaceCardCarouselView = {
    let view = PlaceCardCarouselView()
    view.isHidden = true
    view.onPlaceSelected = { [weak self] place in
      self?.showPlaceDetailPopup(for: place)
    }
    return view
  }()
  
  private var placeDetailPopup: PlaceDetailPopupView?
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Google Places 초기화
    placesClient = GMSPlacesClient.shared()
    
    setupMapView()
    setupSearchBar()
    setupSearchResultsTableView()
    setupLocationButton()
    setupCarouselView()
    setupLocationManager()
    
    // 샘플 마커 추가
    addPlaceMarkers()
    
    // 캐러셀 초기 설정 (빈 카드 5개로 시작)
    updateCarousel(with: [])
  }
  
  // MARK: - Setup Methods
  
  private func setupMapView() {
    // 카메라 위치(초기 위치는 서울)
    let camera = GMSCameraPosition.camera(withTarget: seoulCoordinate, zoom: 14)
    
    // 지도 생성
    mapView = GMSMapView(frame: .zero, camera: camera)
    mapView.delegate = self
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = false // 커스텀 버튼 사용
    
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
  
  private func setupLocationButton() {
    view.addSubview(locationButton)
    
    // SnapKit을 사용한 위치 버튼 제약 조건
    locationButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-16)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-100) // 캐러셀 위에 위치
      make.width.height.equalTo(50)
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
    checkLocationAuthorization()
  }
  
  private func addPlaceMarkers() {
    markers.forEach { $0.map = nil }
    markers.removeAll()
  }
  
  // MARK: - Actions
  
  @objc private func locationButtonTapped() {
    if let location = currentLocation {
      let camera = GMSCameraPosition.camera(
        withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: 15
      )
      mapView.animate(to: camera)
    } else {
      checkLocationAuthorization()
    }
  }
  
  @objc private func searchTextChanged(_ textField: UITextField) {
    guard let searchText = textField.text, !searchText.isEmpty else {
      hideSearchResults()
      return
    }
    
    // 자동완성 검색 수행
    performAutocompleteSearch(searchText)
  }
  
  // MARK: - Google Places Autocomplete
  
  private func performAutocompleteSearch(_ query: String) {
    // 서울 지역으로 제한하는 필터 (선택적)
    let filter = GMSAutocompleteFilter()
    filter.countries = ["KR"]
    
    // 서울 중심으로 검색 반경 설정 (선택적)
    let bounds = GMSCoordinateBounds(
      coordinate: CLLocationCoordinate2D(latitude: 37.4, longitude: 126.8),
      coordinate: CLLocationCoordinate2D(latitude: 37.7, longitude: 127.2)
    )
    
    // 자동완성 검색 요청
    placesClient.findAutocompletePredictions(
      fromQuery: query,
      filter: filter,
      sessionToken: nil
    ) { [weak self] (predictions, error) in
      guard let self = self else { return }
      
      if let error = error {
        print("자동완성 검색 오류: \(error.localizedDescription)")
        return
      }
      
      if let predictions = predictions {
        self.searchResults = predictions
        self.showSearchResults()
      }
    }
  }
  
  private func showSearchResults() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      if self.searchResults.isEmpty {
        self.hideSearchResults()
        return
      }
      
      self.searchActive = true
      self.searchResultsTableView.reloadData()
      self.searchResultsBackgroundView.isHidden = false
      self.searchResultsTableView.isHidden = false
    }
  }
  
  private func hideSearchResults() {
    searchActive = false
    searchResultsBackgroundView.isHidden = true
    searchResultsTableView.isHidden = true
  }
  
  private func fetchPlaceDetails(placeID: String) {
    let fields: GMSPlaceField = [.name, .formattedAddress, .coordinate, .photos]
    
    placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { [weak self] (place, error) in
      guard let self = self else { return }
      
      if let error = error {
        print("장소 상세정보 조회 오류: \(error.localizedDescription)")
        return
      }
      
      if let place = place {
        // 장소 정보 생성
        var newPlace = PlaceInfo(
          id: place.placeID ?? UUID().uuidString,
          name: place.name ?? "알 수 없는 장소",
          address: place.formattedAddress ?? "",
          imageURL: nil, // 초기값은 nil로 설정
          distance: self.calculateDistance(to: place.coordinate),
          coordinate: (place.coordinate.latitude, place.coordinate.longitude)
        )
        
        // 첫 번째 사진이 있는 경우 사진 로드
        if let photoMetadata = place.photos?.first {
          self.loadPlacePhoto(photoMetadata: photoMetadata) { imageURL in
            // 이미지 URL 업데이트
            newPlace.imageURL = imageURL
            // 선택한 장소 처리
            self.handleSelectedPlace(newPlace)
          }
        } else {
          // 사진이 없는 경우 그대로 처리
          self.handleSelectedPlace(newPlace)
        }
      }
    }
  }
  
  private func loadPlacePhoto(photoMetadata: GMSPlacePhotoMetadata, completion: @escaping (String?) -> Void) {
    placesClient.loadPlacePhoto(photoMetadata) { (photo, error) in
      if let error = error {
        print("사진 로드 오류: \(error.localizedDescription)")
        completion(nil)
        return
      }
      
      if let photo = photo {
        // 이미지를 앱 내 임시 디렉토리에 저장하고 URL 생성
        // 실제 앱에서는 이미지 캐싱 라이브러리를 사용하는 것이 좋음
        if let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
          let fileName = "\(UUID().uuidString).jpg"
          let fileURL = documentsDirectory.appendingPathComponent(fileName)
          
          if let data = photo.jpegData(compressionQuality: 0.8) {
            do {
              try data.write(to: fileURL)
              completion(fileURL.absoluteString)
            } catch {
              print("이미지 저장 오류: \(error.localizedDescription)")
              completion(nil)
            }
          } else {
            completion(nil)
          }
        } else {
          completion(nil)
        }
      } else {
        completion(nil)
      }
    }
  }
  
  private func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double {
    guard let currentLocation = self.currentLocation else { return 0.0 }
    
    let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let distance = currentLocation.distance(from: placeLocation) / 1000.0 // km 단위로 변환
    
    return distance
  }
  
  private func handleSelectedPlace(_ place: PlaceInfo) {
    // 검색결과 UI 숨기기
    hideSearchResults()
    searchTextField.resignFirstResponder()
    
    // 해당 위치로 카메라 이동
    let coordinate = CLLocationCoordinate2D(latitude: place.coordinate.0, longitude: place.coordinate.1)
    let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 16)
    mapView.animate(to: camera)
    
    // 마커 추가 (기존 마커가 있으면 재사용)
    let marker = GMSMarker(position: coordinate)
    marker.title = place.name
    marker.snippet = place.address
    marker.userData = place
    marker.map = mapView
    
    // 선택된 마커 저장
    selectedMarker = marker
    
    // 마커를 중앙에 위치시키기
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.mapView.selectedMarker = marker
    }
    
    // 캐러셀에 단일 장소 표시
    updateCarousel(with: [place])
  }
  
  // MARK: - Carousel Methods
  
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
  
  private func scrollCarouselToPlace(_ place: PlaceInfo) {
    carouselView.scrollToPlace(at: 0, animated: true)
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
    
    popup.onDirectionButtonTapped = { [weak self] place in
      self?.getDirections(to: place)
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
  
  private func getDirections(to place: PlaceInfo) {
    // 여기에 경로 안내 로직 구현
    // 예: 네이티브 지도 앱으로 이동하거나, 앱 내에서 경로 표시
    let alert = UIAlertController(
      title: "길 찾기",
      message: "\(place.name)까지의 경로를 안내합니다. (데모 알림)",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    present(alert, animated: true)
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
  
  private func checkLocationAuthorization() {
    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .restricted, .denied:
      showLocationAccessAlert()
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.startUpdatingLocation()
    @unknown default:
      break
    }
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
  
  private func searchLocation(query: String) {
    // 구글 자동완성 API 사용
    performAutocompleteSearch(query)
  }
}

// MARK: - UITextFieldDelegate

extension MapViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if let text = textField.text, !text.isEmpty {
      searchLocation(query: text)
    }
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if let text = textField.text, !text.isEmpty {
      // 텍스트가 있으면 자동완성 결과 표시
      performAutocompleteSearch(text)
    }
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    // 편집 종료 시 딜레이를 두고 검색 결과 숨김 (탭 시간 확보)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.hideSearchResults()
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let prediction = searchResults[indexPath.row]
    fetchPlaceDetails(placeID: prediction.placeID)
  }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    
    // 현재 위치 업데이트
    currentLocation = location
    
    // 최초 1회만 현재 위치로 카메라 이동
    if mapView.camera.target.latitude == seoulCoordinate.latitude &&
        mapView.camera.target.longitude == seoulCoordinate.longitude {
      let camera = GMSCameraPosition.camera(
        withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: 15
      )
      mapView.animate(to: camera)
    }
    
    // 위치를 지속적으로 받을 필요가 없으면 업데이트 중지
    locationManager.stopUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("위치 정보를 가져오는데 실패했습니다: \(error.localizedDescription)")
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    checkLocationAuthorization()
  }
}

// MARK: - GMSMapViewDelegate

extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    // 마커를 탭하면 해당 장소로 카메라 이동
    let camera = GMSCameraPosition.camera(
      withLatitude: marker.position.latitude,
      longitude: marker.position.longitude,
      zoom: mapView.camera.zoom
    )
    mapView.animate(to: camera)
    
    // 선택된 마커 저장
    selectedMarker = marker
    
    // 마커에 연결된 장소 정보 가져오기
    if let place = marker.userData as? PlaceInfo {
      // 선택된 장소를 캐러셀에 표시하고 첫 번째 위치로 스크롤
      updateCarousel(with: [place])
      carouselView.scrollToPlace(at: 0, animated: true)
    }
    
    return true
  }
  
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    // 지도 탭 시 팝업 닫기
    dismissPlaceDetailPopup()
    // 검색 결과 숨기기
    hideSearchResults()
    searchTextField.resignFirstResponder()
  }
  
  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    // 지도 이동 시 수행할 작업 (필요한 경우)
  }
}
