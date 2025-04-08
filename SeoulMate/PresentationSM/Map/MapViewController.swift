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
import GooglePlaces

class MapViewController: UIViewController {
  
  // MARK: - Properties
  private let mapView = GMSMapView()
  private let locationManager = CLLocationManager()
  private var placesClient: GMSPlacesClient!
  private var searchResults: [GMSAutocompletePrediction] = []
  
  // 건국대학교 좌표
  private let initialLocation = CLLocationCoordinate2D(latitude: 37.540693, longitude: 127.079361)
  
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
    button.backgroundColor = .black
    button.layer.cornerRadius = 24
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let sliderImage = UIImage(systemName: "slider.horizontal.3", withConfiguration: config)
    button.setImage(sliderImage, for: .normal)
    button.tintColor = .white
    
    return button
  }()
  
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
    
    setupUI()
    setupActions()
    setupLocationManager()
    setupMapView()
    setupPlacesAPI()
    setupMapTapGesture()
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.addSubview(mapView)
    
    view.addSubview(searchContainerView)
    searchContainerView.addSubview(searchButton)
    searchContainerView.addSubview(textField)
    view.addSubview(filterButton)
    
    view.addSubview(logoutButton)
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
    
    // TODO: 삭제
    logoutButton.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(150)
      make.trailing.equalToSuperview().offset(-16)
      make.width.equalTo(80)
      make.height.equalTo(36)
    }
    
    resultsTableView.snp.makeConstraints { make in
      make.top.equalTo(searchContainerView.snp.bottom).offset(8)
      make.leading.equalTo(searchContainerView)
      make.trailing.equalTo(filterButton)
      make.height.equalTo(0) // 처음에는 높이 0
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
      
      if let error = error {
        print("장소 검색 오류: \(error.localizedDescription)")
        return
      }
      
      guard let predictions = predictions, !predictions.isEmpty else {
        print("검색 결과가 없습니다.")
        self.hideResultsTableView()
        return
      }
      
      // 결과 저장 및 테이블뷰 표시
      self.searchResults = predictions
      self.showResultsTableView()
    }
  }
  
  @objc private func filterButtonTapped() {
    // 필터 기능 실행
    // TODO: 필터 기능 구현
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

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    performSearch()
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
    
    // 테이블 숨기기 및 키보드 내리기
    hideResultsTableView()
    textField.resignFirstResponder()
  }
}
