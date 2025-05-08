//
//  AIChatViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit
import CoreData

final class AIChatViewController: UIViewController {
  // MARK: - Properties
  private let useCase: ChatUseCaseProtocol
  private var placeInfo: PlaceCardInfo?
  private var messages: [ChatMessage] = []
  private var lastLoadedConversationStartedAt: Date?
  private var isLoadingPreviousConversation = false
  private var isBotTyping: Bool = false
  private var inputContainerBottomConstraint: Constraint?
  private var tableViewBottomConstraint: Constraint?
  private var loadingIndicator: UIActivityIndicatorView?
  private var refreshControl: UIRefreshControl?
  
  // MARK: - UI Components
  private let navBar: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Seoulmate Bot"
    label.font = .boldSystemFont(ofSize: 18)
    label.textColor = .black
    return label
  }()
  
  private let closeButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark"), for: .normal)
    button.tintColor = .black
    return button
  }()
  
  private let tableView = UITableView()
  private let inputContainer = UIView()
  private let inputTextField = PaddedTextField()
  private let sendButton = UIButton(type: .system)
  private var inputContainerHeightConstraint: Constraint?
  
  private let bottomBackgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }()
  
  // MARK: - Initialization
  init(useCase: ChatUseCaseProtocol) {
    self.useCase = useCase
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupKeyboardObservers()
    loadInitialMessages()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    useCase.endCurrentConversation()
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.backgroundColor = .white
    
    // 먼저 모든 view를 hierarchy에 추가
    view.addSubview(navBar)
    view.addSubview(tableView)
    view.addSubview(inputContainer)
    view.addSubview(bottomBackgroundView)
    
    // 그 다음 제약조건 설정
    setupNavBar()
    setupInputBar()
    setupTableView()
    setupBottomBackground()
    setupLoadingIndicator()
  }
  
  private func setupNavBar() {
    navBar.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.left.right.equalToSuperview()
      make.height.equalTo(56)
    }
    
    navBar.addSubview(titleLabel)
    titleLabel.snp.makeConstraints { make in
      make.centerX.centerY.equalToSuperview()
    }
    
    navBar.addSubview(closeButton)
    closeButton.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().inset(16)
      make.width.height.equalTo(24)
    }
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
  }
  
  private func setupTableView() {
    tableView.backgroundColor = .clear
    tableView.separatorStyle = .none
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UserMessageCell.self, forCellReuseIdentifier: UserMessageCell.identifier)
    tableView.register(BotMessageCell.self, forCellReuseIdentifier: BotMessageCell.identifier)
    tableView.register(AIChatTypingCell.self, forCellReuseIdentifier: AIChatTypingCell.identifier)
    
    // Add refresh control
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
    refreshControl?.attributedTitle = NSAttributedString(string: "이전 대화 불러오는 중...")
    tableView.refreshControl = refreshControl
    
    tableView.snp.makeConstraints { make in
      make.top.equalTo(navBar.snp.bottom)
      make.left.right.equalToSuperview()
      tableViewBottomConstraint = make.bottom.equalTo(inputContainer.snp.top).constraint
    }
  }
  
  private func setupInputBar() {
    inputContainer.backgroundColor = .black
    inputContainer.layer.cornerRadius = 24
    inputContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    inputContainer.clipsToBounds = true
    
    inputContainer.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      inputContainerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
      make.height.equalTo(64)
    }
    
    // TextField
    inputTextField.placeholder = "Ask me anything.."
    inputTextField.backgroundColor = UIColor(white: 0.15, alpha: 1)
    inputTextField.textColor = .lightGray
    inputTextField.attributedPlaceholder = NSAttributedString(string: "Ask me anything..", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    inputTextField.layer.cornerRadius = 24
    inputTextField.font = .systemFont(ofSize: 16)
    inputTextField.returnKeyType = .send
    inputTextField.delegate = self
    inputTextField.borderStyle = .none
    
    // 오른쪽에 paperplane 아이콘 추가 (padding 포함)
    let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    let paperplane = UIImageView(image: UIImage(systemName: "paperplane"))
    paperplane.tintColor = .gray
    paperplane.contentMode = .scaleAspectFit
    paperplane.frame = CGRect(x: 8, y: 8, width: 24, height: 24)
    rightContainer.addSubview(paperplane)
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(paperplaneTapped))
    rightContainer.isUserInteractionEnabled = true
    rightContainer.addGestureRecognizer(tap)
    
    inputTextField.rightView = rightContainer
    inputTextField.rightViewMode = .always
    inputContainer.addSubview(inputTextField)
    
    inputTextField.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().inset(16)
      make.top.equalToSuperview().offset(12)
      make.height.equalTo(40)
    }
    
    sendButton.isHidden = true
  }
  
  private func setupBottomBackground() {
    bottomBackgroundView.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.equalTo(inputContainer.snp.bottom)
      make.bottom.equalToSuperview()
    }
  }
  
  private func setupLoadingIndicator() {
    loadingIndicator = UIActivityIndicatorView(style: .medium)
    loadingIndicator?.hidesWhenStopped = true
    loadingIndicator?.color = .black
    if let loadingIndicator = loadingIndicator {
      view.addSubview(loadingIndicator)
      loadingIndicator.snp.makeConstraints { make in
        make.center.equalToSuperview()
      }
    }
  }
  
  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }
  
  // MARK: - Actions
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    let keyboardHeight = keyboardFrame.height
    
    // InputContainer를 SafeArea 무시하고 키보드 위에 배치
    inputContainerBottomConstraint?.deactivate()
    inputContainer.snp.makeConstraints { make in
      inputContainerBottomConstraint = make.bottom.equalToSuperview().offset(-keyboardHeight).constraint
    }
    
    // 테이블뷰의 bottom constraint 업데이트
    tableViewBottomConstraint?.update(offset: 0)
    
    // 배경뷰 숨기기
    bottomBackgroundView.isHidden = true
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
    
    // 메시지 있을 경우 스크롤
    if !self.messages.isEmpty {
      self.scrollToBottom()
    }
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    // InputContainer를 다시 SafeArea 위에 배치
    inputContainerBottomConstraint?.deactivate()
    inputContainer.snp.makeConstraints { make in
      inputContainerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }
    
    tableViewBottomConstraint?.update(offset: 0)
    
    // 배경뷰 다시 표시
    bottomBackgroundView.isHidden = false
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
  }
  
  @objc private func closeTapped() {
    // 현재 대화 저장
    useCase.endCurrentConversation()
    
    // TabBarController에서 온 경우 이전 탭으로 돌아가기
    if let tabBarController = parent as? TabBarController {
      // TODO: 추후에 이전 탭 기억하도록 수정 가능
      tabBarController.switchToTab(.map)
    } else {
      dismiss(animated: true)
    }
  }
  
  @objc private func paperplaneTapped() {
    guard let text = inputTextField.text, !text.isEmpty else { return }
    sendMessage(text)
    inputTextField.text = ""
  }
  
  @objc private func sendMessage() {
    guard let text = inputTextField.text, !text.isEmpty else { return }
    sendMessage(text)
    inputTextField.text = ""
  }
  
  private func sendMessage(_ text: String) {
    // 사용자 메시지 추가
    useCase.addMessage(text: text, sender: "user")
    loadCurrentMessages()
    
    // 봇 응답 시뮬레이션
    isBotTyping = true
    tableView.reloadData()
    
    // 실제 API 호출로 대체 필요
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self = self else { return }
      self.useCase.addMessage(text: "응답: \(text)", sender: "bot")
      self.isBotTyping = false
      self.loadCurrentMessages()
    }
  }
  
  private func loadInitialMessages() {
    // 로딩 인디케이터 표시
    loadingIndicator?.startAnimating()
    
    // 새 대화 시작 - CoreData에 새 대화 생성
    useCase.startNewConversation()
    
    // 이전 대화 로드 시점 초기화
    lastLoadedConversationStartedAt = Date()
    
    // 메시지 배열 초기화
    messages.removeAll()
    
    // 잠시 지연 후 초기 인삿말 메시지만 추가 (UI가 준비된 후)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self else { return }
      
      // 현재 대화에 봇의 인삿말 메시지 추가
      self.useCase.addMessage(text: "안녕하세요! 서울메이트입니다. 서울 여행에 관해 무엇이든 물어보세요.", sender: "bot")
      
      // 현재 대화의 메시지 로드 (인삿말만 있는 상태)
      self.messages = self.useCase.fetchMessages()
      self.tableView.reloadData()
      
      // 메시지가 있으면 스크롤
      if !self.messages.isEmpty {
        self.scrollToBottom()
      }
      
      // 로딩 인디케이터 숨김
      self.loadingIndicator?.stopAnimating()
    }
  }
  
  private func loadCurrentMessages() {
    // 현재 대화의 메시지만 가져오기 (이전 대화 제외)
    let newMessages = useCase.fetchMessages()
    
    // 기존 메시지와 병합
    if messages.isEmpty {
      messages = newMessages
    } else {
      // 새 메시지만 추가
      let existingIds = Set(messages.compactMap { $0.id })
      let messagesToAdd = newMessages.filter { message in
        guard let id = message.id else { return false }
        return !existingIds.contains(id)
      }
      
      if !messagesToAdd.isEmpty {
        messages.append(contentsOf: messagesToAdd)
      }
    }
    
    tableView.reloadData()
    scrollToBottom()
  }
  
  private func scrollToBottom() {
    let lastRow = tableView.numberOfRows(inSection: 0) - 1
    if lastRow >= 0 {
      let indexPath = IndexPath(row: lastRow, section: 0)
      tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
  }
  
  @objc private func refreshTriggered() {
    loadPreviousConversation()
  }
  
  private func loadPreviousConversation() {
    guard !isLoadingPreviousConversation else {
      refreshControl?.endRefreshing()
      return
    }
    
    isLoadingPreviousConversation = true
    
    // 이전 대화 로드
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      
      // 이전 대화 가져오기 (현재 시간 이전의 대화)
      if let previousConversation = self.useCase.fetchPreviousConversation(after: self.lastLoadedConversationStartedAt) {
        let previousMessages = self.useCase.fetchMessages(from: previousConversation)
        
        // UI 업데이트는 메인 스레드에서
        DispatchQueue.main.async {
          if !previousMessages.isEmpty {
            // 기존 메시지와 중복되지 않는 메시지만 추가
            let existingIds = Set(self.messages.compactMap { $0.id })
            let messagesToAdd = previousMessages.filter { message in
              guard let id = message.id else { return false }
              return !existingIds.contains(id)
            }
            
            if !messagesToAdd.isEmpty {
              // 현재 콘텐츠 높이와 오프셋 저장
              let oldContentHeight = self.tableView.contentSize.height
              let oldContentOffset = self.tableView.contentOffset.y
              
              // 메시지 추가 및 테이블 업데이트
              self.messages.insert(contentsOf: messagesToAdd, at: 0)
              self.tableView.reloadData()
              
              // 스크롤 위치 조정 (현재 보고 있던 위치 유지)
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let newContentHeight = self.tableView.contentSize.height
                let heightDifference = newContentHeight - oldContentHeight
                if heightDifference > 0 {
                  self.tableView.setContentOffset(CGPoint(x: 0, y: oldContentOffset + heightDifference), animated: false)
                }
              }
            }
            
            // 마지막으로 로드된 대화 날짜 업데이트
            self.lastLoadedConversationStartedAt = previousConversation.startedAt
          }
          
          // 리프레시 컨트롤 종료 및 로딩 상태 업데이트
          self.refreshControl?.endRefreshing()
          self.isLoadingPreviousConversation = false
        }
      } else {
        // 더 이상 로드할 대화가 없을 때
        DispatchQueue.main.async {
          self.refreshControl?.endRefreshing()
          self.isLoadingPreviousConversation = false
        }
      }
    }
  }
  
  private func startNewConversation() {
    // 새로운 대화 시작
    useCase.startNewConversation()
    lastLoadedConversationStartedAt = nil
    
    // 메시지 배열 초기화
    messages.removeAll()
    
    // 테이블뷰 업데이트
    tableView.reloadData()
    scrollToBottom()
  }
  
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo) {
    self.placeInfo = placeInfo
    // 새로운 대화 시작 (이전 대화와 무관하게)
    loadInitialMessages()
  }
}

// MARK: - UITableViewDataSource
extension AIChatViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count + (isBotTyping ? 1 : 0)
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row < messages.count {
      let message = messages[indexPath.row]
      if message.sender == "user" {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserMessageCell.identifier, for: indexPath) as! UserMessageCell
        cell.configure(with: message)
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: BotMessageCell.identifier, for: indexPath) as! BotMessageCell
        cell.configure(with: message)
        return cell
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: AIChatTypingCell.identifier, for: indexPath) as! AIChatTypingCell
      return cell
    }
  }
}

// MARK: - UITableViewDelegate
extension AIChatViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  // 스크롤이 맨 위에 도달했을 때 이전 대화 로드
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // 스크롤이 맨 위에 가까워지면
    if scrollView.contentOffset.y < 50 && !isLoadingPreviousConversation {
      // 스크롤뷰에 리프레시 컨트롤이 있는 경우 리프레시 컨트롤이 작동하므로
      // 여기서는 별도 처리가 필요 없음
    }
  }
  
  // 리프레시 컨트롤이 작동하지 않을 때에도 스크롤로 이전 메시지 로드 지원
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    // 스크롤이 맨 위에 있고, 리프레시 컨트롤이 작동하지 않는 경우에도 이전 대화 로드
    if scrollView.contentOffset.y < 0 && !refreshControl!.isRefreshing && !isLoadingPreviousConversation {
      refreshControl?.beginRefreshing()
      loadPreviousConversation()
    }
  }
}

// MARK: - Custom PaddedTextField
class PaddedTextField: UITextField {
  let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
}

extension AIChatViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    sendMessage()
    textField.resignFirstResponder()
    return true
  }
}
