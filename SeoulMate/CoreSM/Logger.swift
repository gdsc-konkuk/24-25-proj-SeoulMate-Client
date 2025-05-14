//
//  Logger.swift
//  SeoulMate
//
//  Created by 박성근 on 5/14/25.
//

import os

enum Logger {
  static func log(_ message: String) {
    os_log("\(message)")
  }
}
