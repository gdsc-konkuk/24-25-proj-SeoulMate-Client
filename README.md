# 🏙️ SeoulMate

<div align="center">

  <br>
  
  <img src="https://github.com/user-attachments/assets/a361977f-a40f-45f4-ae28-66e190d45b7d" alt="Icon" width="200" height="200">  

  <br>
  
  **Experience Seoul Easier and More Enjoyably**
  
  [![iOS](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)](https://www.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
  [![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue.svg)](https://developer.apple.com/xcode/)  
  <br>
  
</div>

## 📋 Table of Contents
- [Introduction](#-introduction)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Main Features](#-main-features)
- [Requirements](#-requirements)
- [Architecture Overview](#-architecture-overview)

<br>

## 🌟 Introduction
SeoulMate is a mobile application designed to enhance the experience of tourists and residents in Seoul by providing personalized recommendations, interactive maps, and AI-powered conversational assistance.
<br>

## 🛠️ Tech Stack

### Architecture
- **Clean Architecture + MVVM-C pattern**
- **Clear separation of layers**: Presentation, Domain, Data, Network, etc.
- **Dependency injection** using DIContainer

### Core Technologies
- **UI Framework**: UIKit
- **Authentication**: Google Sign-In
- **Maps & Places**: Google Maps SDK
- **Networking**: Custom implementation with interceptors and monitoring
- **Reactive Programming**: Combine for data binding
- **Asynchronous Operations**: Swift Concurrency (async/await)

### Dependencies
- **Layout**: SnapKit for programmatic UI constraints
- **Linting**: SwiftLint for code convention enforcement
- **Maps**: Google Maps, Google Places
- **Authentication**: Google Sign-In

<br>

## 🏗️ Project Structure
```
SeoulMate/
├── ApplicationSM/
│   ├── Resource/
│   └── Source/
├── CoreSM/
│   └── Logger.swift
├── DataSM/
│   └── Repository/
├── DataStorageSM/
├── DomainSM/
│   └── UseCase/
├── NetworkSM/
└── PresentationSM/
```

<br>

## 🌟 Main Features
- **Interactive Map**: Browse and discover Seoul's attractions, restaurants, and points of interest
- **Personalized Recommendations**: Get recommendations tailored to your preferences
- **User Authentication**: Secure login options including Google Sign-In
- **Favorites Management**: Save and organize places you want to visit
- **AI Chat Assistant**: Get instant help and information about Seoul
- **User Profile**: Manage your preferences and history

<br>

## 📱 Requirements
- **iOS**: 16.0+
- **Xcode**: 16+
- **Swift**: 5.9
- **Dependency Management**: Swift Package Manager

<br>

## 🧩 Architecture Overview
The project follows Clean Architecture principles with a clear separation of concerns:

- **Presentation Layer**: Handles UI logic, uses ViewModels to interact with UseCases
- **Domain Layer**: Contains business logic and Use Cases, independent of UI or external dependencies
- **Data Layer**: Manages data access through Repositories and communicates with external services
- **Application Layer**: Coordinates app components and manages dependencies

## Demonstration video

| Title | Login Flow + Main Screen | Search | Place Recommendations | My Page |
|-------|--------------------------|--------|------------------------|---------|
| Video | <video src="https://github.com/user-attachments/assets/da77c505-965b-488d-af23-6bc91f7b8bbd" width="300" controls></video> | <video src="https://github.com/user-attachments/assets/f01055db-0cbc-49d2-846c-119e640df7a7" width="300" controls></video> | <video src="https://github.com/user-attachments/assets/4aebae42-ce65-46bf-8163-679a11e86c68" width="300" controls></video> | <video src="https://github.com/user-attachments/assets/508c57d8-7e13-432f-b332-832c994bc7f5" width="300" controls></video> |


