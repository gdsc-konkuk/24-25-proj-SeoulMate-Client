//
//  FilterRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Combine

protocol FilterRepositoryProtocol {
  func getFilterData() -> AnyPublisher<FilterData?, NetworkError>
  func saveFilterData(_ data: FilterData) -> AnyPublisher<Void, NetworkError>
  func createFilterData(_ data: FilterData) -> AnyPublisher<FilterData, NetworkError>
}
