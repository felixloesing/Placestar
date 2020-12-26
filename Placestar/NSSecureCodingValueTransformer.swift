//
//  NSSecureCodingValueTransformer.swift
//  Placestar
//
//  Created by Felix Loesing on 12/26/20.
//  Copyright © 2020 Felix Lösing. All rights reserved.
//

import Foundation

public protocol ValueTransforming: NSSecureCoding {
  static var valueTransformerName: NSValueTransformerName { get }
}

public class NSSecureCodingValueTransformer<T: NSObject & ValueTransforming>: ValueTransformer {
  public override class func transformedValueClass() -> AnyClass { T.self }
  public override class func allowsReverseTransformation() -> Bool { true }

  public override func transformedValue(_ value: Any?) -> Any? {
    guard let value = value as? T else { return nil }
    return try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
  }

  public override func reverseTransformedValue(_ value: Any?) -> Any? {
    guard let data = value as? NSData else { return nil }
    let result = try? NSKeyedUnarchiver.unarchivedObject(
      ofClass: T.self,
      from: data as Data
    )
    return result
  }

  /// Registers the transformer by calling `ValueTransformer.setValueTransformer(_:forName:)`.
  public static func registerTransformer() {
    let transformer = NSSecureCodingValueTransformer<T>()
    ValueTransformer.setValueTransformer(transformer, forName: T.valueTransformerName)
  }
}
