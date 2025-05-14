//
//  AIChatViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit

final class AIChatViewController: UIViewController {
  // MARK: - Properties
  private let useCase: ChatUseCaseProtocol
  private var placeInfo: PlaceCardInfo?
  private var messages: [ChatMessage] = []
  private var isBotTyping: Bool = false
  private var inputContainerBottomConstraint: Constraint?
  private var tableViewBottomConstraint: Constraint?
  private var loadingIndicator: UIActivityIndicatorView?
  
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
    
    // 시스템의 자동 컨텐츠 인셋 조정 비활성화
    tableView.contentInsetAdjustmentBehavior = .never
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // 레이아웃이 완료된 후 다시 한번 여백 확인 및 조정
    if tableView.contentInset.top != 0 {
      tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      tableView.contentOffset = CGPoint(x: 0, y: 0)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // 뷰가 나타날 때마다 여백 재설정
    tableView.contentInset = UIEdgeInsets.zero
    tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    
    // 첫 번째 셀이 상단에 붙도록 contentOffset 재설정
    if tableView.numberOfRows(inSection: 0) > 0 {
      tableView.setContentOffset(.zero, animated: false)
    }
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.backgroundColor = .white
    
    view.addSubview(navBar)
    view.addSubview(tableView)
    view.addSubview(inputContainer)
    view.addSubview(bottomBackgroundView)
    
    setupNavBar()
    setupInputBar()
    setupTableView()
    setupBottomBackground()
    setupLoadingIndicator()
    setupTapGestureRecognizer()
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
    
    tableView.contentInset = UIEdgeInsets.zero
    tableView.automaticallyAdjustsScrollIndicatorInsets = false
    tableView.sectionHeaderHeight = 0
    
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
    
    inputTextField.placeholder = "Ask me anything.."
    inputTextField.backgroundColor = UIColor(white: 0.15, alpha: 1)
    inputTextField.textColor = .lightGray
    inputTextField.attributedPlaceholder = NSAttributedString(string: "Ask me anything..", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    inputTextField.layer.cornerRadius = 24
    inputTextField.font = .mediumFont(ofSize: 16)
    inputTextField.returnKeyType = .send
    inputTextField.delegate = self
    inputTextField.borderStyle = .none
    
    let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    let paperplane = UIImageView(image: UIImage(systemName: "paperplane"))
    paperplane.tintColor = .gray
    paperplane.contentMode = .scaleAspectFit
    paperplane.frame = CGRect(x: -4, y: 8, width: 24, height: 24)
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
  
  private func setupTapGestureRecognizer() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    tableView.addGestureRecognizer(tapGesture)
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    let keyboardHeight = keyboardFrame.height
    
    inputContainerBottomConstraint?.deactivate()
    inputContainer.snp.makeConstraints { make in
      inputContainerBottomConstraint = make.bottom.equalToSuperview().offset(-keyboardHeight).constraint
    }
    
    tableViewBottomConstraint?.update(offset: 0)
    bottomBackgroundView.isHidden = true
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
    
    if !self.messages.isEmpty {
      self.scrollToBottom()
    }
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
    
    inputContainerBottomConstraint?.deactivate()
    inputContainer.snp.makeConstraints { make in
      inputContainerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }
    
    tableViewBottomConstraint?.update(offset: 0)
    bottomBackgroundView.isHidden = false
    
    UIView.animate(withDuration: duration) {
      self.view.layoutIfNeeded()
    }
  }
  
  @objc private func closeTapped() {
    if let tabBarController = parent as? TabBarController {
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
  
  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }
  
  private func sendMessage(_ text: String, chatType: ChatType = .FREE_CHAT) {
    let userMessage = ChatMessage(
      text: text,
      sender: "user",
      timestamp: Date(),
      chatType: chatType
    )
    messages.append(userMessage)
    tableView.reloadData()
    
    // 키보드 내리기
    view.endEditing(true)
    
    // 타이핑 셀 표시 및 스크롤
    isBotTyping = true
    tableView.reloadData()
    
    // 키보드가 내려간 후에 스크롤 실행
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.scrollToBottom()
    }
    
    Task {
      do {
        let response = try await useCase.sendMessage(
          placeId: placeInfo?.placeID ?? "",
          chatType: chatType,
          text: text
        )
        await MainActor.run {
          let botMessage: ChatMessage
          if chatType == .FITNESS_SCORE {
            let scoreText = "점수: \(response.score ?? "N/A")\n\n설명: \(response.explanation ?? "설명이 없습니다.")"
            botMessage = ChatMessage(
              text: scoreText,
              sender: "bot",
              timestamp: Date(),
              chatType: .REPLY
            )
          } else {
            botMessage = ChatMessage(
              text: response.reply ?? "응답이 없습니다.",
              sender: "bot",
              timestamp: Date(),
              chatType: .REPLY
            )
          }
          self.messages.append(botMessage)
          self.isBotTyping = false
          self.tableView.reloadData()
          self.scrollToBottom()
        }
      } catch {
        await MainActor.run {
          let errorMessage = ChatMessage(
            text: "죄송합니다. 메시지를 처리하는 중에 오류가 발생했습니다.",
            sender: "bot",
            timestamp: Date(),
            chatType: .REPLY
          )
          self.messages.append(errorMessage)
          self.isBotTyping = false
          self.tableView.reloadData()
          self.scrollToBottom()
        }
      }
    }
  }
  
  private func loadInitialMessages() {
    loadingIndicator?.startAnimating()
    
    // 상단에 약간의 여백 추가
    tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    tableView.verticalScrollIndicatorInsets = UIEdgeInsets.zero
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self = self else { return }
      
      let welcomeMessage = ChatMessage(
        text: "Hi there! Nice to see you. I am Seoulmate Bot. How can I help you?",
        sender: "bot",
        timestamp: Date(),
        chatType: .REPLY
      )
      self.messages = [welcomeMessage]
      self.tableView.reloadData()
      
      // 명시적으로 contentOffset 설정
      self.tableView.contentOffset = CGPoint(x: 0, y: 0)
      
      if !self.messages.isEmpty {
        self.scrollToBottom()
      }
      
      self.loadingIndicator?.stopAnimating()
    }
  }
  
  private func scrollToBottom() {
    let lastRow = tableView.numberOfRows(inSection: 0) - 1
    if lastRow >= 0 {
      let indexPath = IndexPath(row: lastRow, section: 0)
      tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
  }
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo) {
    self.placeInfo = placeInfo
    loadInitialMessages()
  }
  
  // MARK: - Fitness Score
  func requestFitnessScore() {
    guard let placeInfo = placeInfo else { return }
    
    let fitnessScoreText = "\(placeInfo.name)\nFitness Score"
    inputTextField.text = fitnessScoreText
    
    sendMessage(fitnessScoreText, chatType: .FITNESS_SCORE)
    inputTextField.text = ""
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
        
        // 첫 번째 셀 여백 확인
        if indexPath.row == 0 {
          cell.contentView.layoutMargins = UIEdgeInsets.zero
        }
        
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: BotMessageCell.identifier, for: indexPath) as! BotMessageCell
        cell.configure(with: message)
        cell.delegate = self
        
        // 첫 번째 셀 여백 확인
        if indexPath.row == 0 {
          cell.contentView.layoutMargins = UIEdgeInsets.zero
        }
        
        return cell
      }
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: AIChatTypingCell.identifier, for: indexPath) as! AIChatTypingCell
      
      // 첫 번째 셀 여백 확인
      if indexPath.row == 0 {
        cell.contentView.layoutMargins = UIEdgeInsets.zero
      }
      
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return nil
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
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
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    view.endEditing(true)
  }
}

extension AIChatViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    sendMessage()
    textField.resignFirstResponder()
    return true
  }
}

// MARK: - BotMessageCellDelegate
extension AIChatViewController: BotMessageCellDelegate {
  func didTapFitnessScore() {
    requestFitnessScore()
  }
  
  func didTapFreeChat() {
    // 키보드 표시
    inputTextField.becomeFirstResponder()
  }
}
