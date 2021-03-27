//
// CanelaKeyChainConstants.swift
// CanelaKeyChainConstants
//
// Copyright (c) 2021 Andrés Ocampo (http://icologic.co)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import Security

public enum KeychainSwiftAccessOptions {
  case accessibleWhenUnlocked
  case accessibleWhenUnlockedThisDeviceOnly
  case accessibleAfterFirstUnlock
  case accessibleAfterFirstUnlockThisDeviceOnly
  case accessibleWhenPasscodeSetThisDeviceOnly
  
  static var defaultOption: KeychainSwiftAccessOptions {
    return .accessibleWhenUnlocked
  }
  
  var value: String {
    switch self {
    case .accessibleWhenUnlocked:
      return toString(kSecAttrAccessibleWhenUnlocked)
      
    case .accessibleWhenUnlockedThisDeviceOnly:
      return toString(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
      
    case .accessibleAfterFirstUnlock:
      return toString(kSecAttrAccessibleAfterFirstUnlock)
      
    case .accessibleAfterFirstUnlockThisDeviceOnly:
      return toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
      
    case .accessibleWhenPasscodeSetThisDeviceOnly:
      return toString(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
    }
  }
  
  func toString(_ value: CFString) -> String {
    return CanelaKeyChainConstants.toString(value)
  }
}

public struct CanelaKeyChainConstants {
    public static var accessGroup: String { return toString(kSecAttrAccessGroup) }
    public static var accessible: String { return toString(kSecAttrAccessible) }
    public static var attrAccount: String { return toString(kSecAttrAccount) }
    public static var attrSynchronizable: String { return toString(kSecAttrSynchronizable) }
    public static var klass: String { return toString(kSecClass) }
    public static var matchLimit: String { return toString(kSecMatchLimit) }
    public static var returnData: String { return toString(kSecReturnData) }
    public static var valueData: String { return toString(kSecValueData) }
    public static var returnReference: String { return toString(kSecReturnPersistentRef) }
    public static var returnAttributes : String { return toString(kSecReturnAttributes) }
    public static var secMatchLimitAll : String { return toString(kSecMatchLimitAll) }
    static func toString(_ value: CFString) -> String {
      return value as String
    }
    
}
