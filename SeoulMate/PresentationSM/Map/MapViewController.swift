//
//  MapViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
  
  // MARK: - Properties
  private let mapView = GMSMapView()
  
  // 건국대학교 좌표
  private let initialLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 지도 초기 설정
    setupMapView()
  }
  
  // MARK: - Setup
  private func setupMapView() {
    // 카메라 설정 (건국대학교 중심, 줌 레벨 15)
    let camera = GMSCameraPosition.camera(
      withTarget: initialLocation,
      zoom: 15
    )
    
    // 맵뷰 생성 및 카메라 설정
    mapView.camera = camera
    
    // 내 위치 버튼 표시
    mapView.settings.myLocationButton = true
    
    // 맵뷰 추가
    view.addSubview(mapView)
    
    // SnapKit을 사용한 제약조건 설정
    mapView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

