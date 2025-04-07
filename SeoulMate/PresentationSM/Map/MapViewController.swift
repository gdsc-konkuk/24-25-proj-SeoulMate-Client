//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import CoreLocation
import GoogleMaps
import GoogleSignIn

class MapViewController: UIViewController {
  
  // MARK: - Properties
  private let mapView = GMSMapView()
  private let locationManager = CLLocationManager()
  
  // 건국대학교 좌표
  private let initialLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
  
  // 로그아웃 버튼
  private lazy var logoutButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("로그아웃", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .systemRed
    button.layer.cornerRadius = 8
    button.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    return button
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 위치 설정
    setupLocationManager()
    
    // 지도 초기 설정
    setupMapView()
    
    // UI
    setupUI()
  }
  
  // MARK: - Setup
  private func setupUI() {
    // 로그아웃 버튼 추가
    view.addSubview(logoutButton)
    
    logoutButton.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
      make.trailing.equalToSuperview().offset(-16)
      make.width.equalTo(80)
      make.height.equalTo(36)
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
    
    
    // UI Setting
    view.addSubview(mapView)
    
    mapView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
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
  
  // MARK: - Actions
  @objc private func logoutButtonTapped() {
    // 로그아웃 확인 알림창
    let alert = UIAlertController(
      title: "로그아웃",
      message: "정말 로그아웃 하시겠습니까?",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
    alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
      // 로그아웃 처리
      UserSessionManager.shared.signOut()
    })
    
    present(alert, animated: true)
  }
}
