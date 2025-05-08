//
//  CoreDataStack.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import Foundation
import CoreData

public final class CoreDataStack {
  public static let shared = CoreDataStack()
  
  private let modelName = "ChatDataModel"
  
  public lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: modelName)
    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    return container
  }()
  
  public var mainContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  public func saveContext() {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}
