//
//  MyPageViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit

final class MyPageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  // MARK: - UI Components
  // 프로필 섹션
  private let profileSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let profileContentView: UIView = {
    let v = UIView()
    v.backgroundColor = .clear
    return v
  }()
  
  private let profileImageView: UIImageView = {
    let iv = UIImageView()
    iv.backgroundColor = .gray200
    iv.layer.cornerRadius = 24
    iv.clipsToBounds = true
    return iv
  }()
  
  private let nameLabel: UILabel = {
    let label = UILabel()
    label.text = "user"
    label.font = .boldFont(ofSize: 17)
    return label
  }()
  
  private let emailLabel: UILabel = {
    let label = UILabel()
    label.text = "username@gmail.com"
    label.font = .regularFont(ofSize: 14)
    label.textColor = .gray500
    return label
  }()
  
  // 구분선
  private func makeDivider() -> UIView {
    let v = UIView()
    v.backgroundColor = .gray200
    return v
  }
  
  // 컬렉션 섹션
  private let collectionSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let collectionTitleLabel: UILabel = {
    let label = UILabel()
    label.text = "My collection"
    label.font = .boldFont(ofSize: 18)
    return label
  }()
  
  private lazy var viewAllButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("View all", for: .normal)
    button.titleLabel?.font = .mediumFont(ofSize: 15)
    button.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.showsHorizontalScrollIndicator = false
    cv.backgroundColor = .clear
    return cv
  }()
  
  // 하단 메뉴 섹션
  private let menuSection: UIView = {
    let v = UIView()
    v.backgroundColor = .gray100
    return v
  }()
  
  private let helpButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.setTitle("  Help", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.titleLabel?.font = .regularFont(ofSize: 16)
    btn.setImage(UIImage(systemName: "exclamationmark.circle"), for: .normal)
    btn.contentHorizontalAlignment = .left
    return btn;
  }()
  
  private let logoutButton: UIButton = {
    let btn = UIButton(type: .system)
    btn.setTitle("  Log out", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.titleLabel?.font = .regularFont(ofSize: 16)
    btn.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)
    btn.contentHorizontalAlignment = .left
    return btn;
  }()
  
  private let dummyImages: [String] = Array(repeating: "photo", count: 5)
  
  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .gray100
    setupNavigationBar()
    setupLayout()
    let safeAreaCover = UIView()
    safeAreaCover.backgroundColor = .white
    view.addSubview(safeAreaCover)
    safeAreaCover.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
    }
  }
  
  private func setupNavigationBar() {
    title = "My Page"
    navigationController?.navigationBar.titleTextAttributes = [
      .font: UIFont.mediumFont(ofSize: 20)
    ]
  }
  
  // MARK: - Layout
  private func setupLayout() {
    // 프로필 섹션
    view.addSubview(profileSection)
    profileSection.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.trailing.equalToSuperview()
      // 높이 자동 (내부 패딩 포함)
    }
    profileSection.addSubview(profileContentView)
    profileContentView.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview().inset(24)
      make.leading.trailing.equalToSuperview()
      make.height.greaterThanOrEqualTo(48) // 최소 높이 보장
    }
    profileContentView.addSubview(profileImageView)
    profileImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(48)
    }
    profileContentView.addSubview(nameLabel)
    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(profileImageView.snp.top).offset(4)
      make.left.equalTo(profileImageView.snp.right).offset(12)
    }
    profileContentView.addSubview(emailLabel)
    emailLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(2)
      make.left.equalTo(nameLabel)
    }
    // 구분선1
    let divider1 = makeDivider()
    view.addSubview(divider1)
    divider1.snp.makeConstraints { make in
      make.top.equalTo(profileSection.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(11)
    }
    // 컬렉션 섹션
    view.addSubview(collectionSection)
    collectionSection.snp.makeConstraints { make in
      make.top.equalTo(divider1.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(299)
    }
    collectionSection.addSubview(collectionTitleLabel)
    collectionSection.addSubview(viewAllButton)
    collectionTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.leading.equalToSuperview().offset(16)
      make.height.equalTo(24)
    }
    viewAllButton.snp.makeConstraints { make in
      make.centerY.equalTo(collectionTitleLabel)
      make.trailing.equalToSuperview().inset(16)
    }
    collectionSection.addSubview(collectionView)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(CollectionCell.self, forCellWithReuseIdentifier: "CollectionCell")
    collectionView.snp.makeConstraints { make in
      make.top.equalTo(collectionTitleLabel.snp.bottom).offset(12)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(219)
    }
    // 구분선2
    let divider2 = makeDivider()
    view.addSubview(divider2)
    divider2.snp.makeConstraints { make in
      make.top.equalTo(collectionSection.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(11)
    }
    // 하단 메뉴 섹션
    view.addSubview(menuSection)
    menuSection.snp.makeConstraints { make in
      make.top.equalTo(divider2.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(64+24+24) // Help 위/아래 24씩
    }
    menuSection.addSubview(helpButton)
    menuSection.addSubview(logoutButton)
    helpButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(24)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(24)
      make.trailing.equalToSuperview().inset(20)
    }
    logoutButton.snp.makeConstraints { make in
      make.top.equalTo(helpButton.snp.bottom).offset(24)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(24)
      make.trailing.equalToSuperview().inset(20)
    }
  }
  
  // MARK: - CollectionView DataSource & Delegate
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dummyImages.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
    cell.configure(imageName: dummyImages[indexPath.item])
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 182, height: 219)
  }
  
  // MARK: - Actions
  @objc private func viewAllButtonTapped() {
    let myCollectionVC = MyCollectionViewController()
    navigationController?.pushViewController(myCollectionVC, animated: true)
  }
}
