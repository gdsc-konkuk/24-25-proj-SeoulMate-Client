//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import CoreLocation
import GoogleMaps

class MapViewController: UIViewController {
  
  // MARK: - Properties
  private let mapView = GMSMapView()
  private let locationManager = CLLocationManager()
  
  // 건국대학교 좌표
  private let initialLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 위치 설정
    setupLocationManager()
    
    // 지도 초기 설정
    setupMapView()
  }
  
  // MARK: - Setup
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
}
