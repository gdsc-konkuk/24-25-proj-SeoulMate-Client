//
//  Logger.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//

import os

public enum Logger {
  public static func log(message: String) {
    os_log("\(message)")
  }
}
