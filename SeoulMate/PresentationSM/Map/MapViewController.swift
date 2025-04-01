//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleMaps
import CoreLocation
import SnapKit

final class MapViewController: UIViewController {
  
  // MARK: - Properties
  
  private let locationManager = CLLocationManager()
  private var currentLocation: CLLocation?
  private var mapView: GMSMapView!
  private var markers: [GMSMarker] = []
  private var selectedMarker: GMSMarker?
  
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
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMapView()
    setupSearchBar()
    setupLocationButton()
    setupLocationManager()
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
  
  private func setupLocationButton() {
    view.addSubview(locationButton)
    
    // SnapKit을 사용한 위치 버튼 제약 조건
    locationButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-16)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
      make.width.height.equalTo(50)
    }
  }
  
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    checkLocationAuthorization()
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
    // 위치 검색 로직 구현
    // Google Places API 또는 Geocoding API를 활용할 수 있습니다
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
    // 마커 탭 처리 로직
    selectedMarker = marker
    return true
  }
  
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    // 지도 탭 처리 로직 (필요시)
  }
}
