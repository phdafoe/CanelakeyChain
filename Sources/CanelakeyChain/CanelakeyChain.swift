//
// CanelakeyChain.swift
// CanelakeyChain
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

open class CanelakeyChain {
    
    var lastQueryParameters: [String: Any]?
    open var lastResultCode: OSStatus = noErr
    open var accessGroup: String?
    open var synchronizable: Bool = false
    private let lock = NSLock()
    var keyPrefix = ""
    
    // MARK: - INIT
    public init() {}
    
    public init(keyPrefix: String) {
      self.keyPrefix = keyPrefix
    }
    
    // MARK: - SET
    /**
    Stores the text value in the keychain item under the given key.
    - parameter key: Key under which the text value is stored in the keychain.
    - parameter value: Text string to be written to the keychain.
    - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
     - returns: True if the text was successfully written to the keychain.
    */
    open func setValueString(_ value: String, forKey key: String, withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
        if let valueDes = value.data(using: String.Encoding.utf8) {
            return setValueData(valueDes, forKey: key, withAccess: access)
        }
        return false
    }
    
    /**
    Stores the data in the keychain item under the given key.
    - parameter key: Key under which the data is stored in the keychain.
    - parameter value: Data to be written to the keychain.
    - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
    - returns: True if the text was successfully written to the keychain.
    */
    open func setValueData(_ value: Data, forKey key: String, withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
        
        // The lock prevents the code to be run simultaneously
        // from multiple threads which may result in crashing
        lock.lock()
        defer { lock.unlock() }
        
        deleteNoLock(key) // Delete any existing key before saving it
        
        let accessible = access?.value ?? KeychainSwiftAccessOptions.defaultOption.value
        
        let prefixedKey = keyWithPrefix(key)
        
        var query: [String : Any] = [
            CanelaKeyChainConstants.klass       : kSecClassGenericPassword,
            CanelaKeyChainConstants.attrAccount : prefixedKey,
            CanelaKeyChainConstants.valueData   : value,
            CanelaKeyChainConstants.accessible  : accessible
        ]
        
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: true)
        lastQueryParameters = query
        
        lastResultCode = SecItemAdd(query as CFDictionary, nil)
        
        return lastResultCode == noErr
    }
    
    /**
    Stores the boolean value in the keychain item under the given key.
    - parameter key: Key under which the value is stored in the keychain.
    - parameter value: Boolean to be written to the keychain.
    - parameter withAccess: Value that indicates when your app needs access to the value in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
    - returns: True if the value was successfully written to the keychain.
    */
    open func setValueBool(_ value: Bool, forKey key: String, withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
      let bytes: [UInt8] = value ? [1] : [0]
      let data = Data(bytes)
      return setValueData(data, forKey: key, withAccess: access)
    }
    
    // MARK: - GET
    /**
    Retrieves the text value from the keychain that corresponds to the given key.
    - parameter key: The key that is used to read the keychain item.
    - returns: The text value from the keychain. Returns nil if unable to read the item.
    */
    open func getString(_ key: String) -> String? {
      if let dataDes = getData(key) {
        if let currentStringDes = String(data: dataDes, encoding: .utf8) {
          return currentStringDes
        }
        lastResultCode = -67853 // errSecInvalidEncoding
      }
      return nil
    }
    
    /**
    Retrieves the data from the keychain that corresponds to the given key.
    - parameter key: The key that is used to read the keychain item.
    - parameter asReference: If true, returns the data as reference (needed for things like NEVPNProtocol).
    - returns: The text value from the keychain. Returns nil if unable to read the item.
    
    */
    open func getData(_ key: String, asReference: Bool = false) -> Data? {
      // The lock prevents the code to be run simultaneously
      // from multiple threads which may result in crashing
      lock.lock()
      defer { lock.unlock() }
      
      let prefixedKey = keyWithPrefix(key)
      
      var query: [String: Any] = [
        CanelaKeyChainConstants.klass       : kSecClassGenericPassword,
        CanelaKeyChainConstants.attrAccount : prefixedKey,
        CanelaKeyChainConstants.matchLimit  : kSecMatchLimitOne
      ]
      
      if asReference {
        query[CanelaKeyChainConstants.returnReference] = kCFBooleanTrue
      } else {
        query[CanelaKeyChainConstants.returnData] =  kCFBooleanTrue
      }
      
      query = addAccessGroupWhenPresent(query)
      query = addSynchronizableIfRequired(query, addingItems: false)
      lastQueryParameters = query
      
      var result: AnyObject?
      
      lastResultCode = withUnsafeMutablePointer(to: &result) {
        SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
      }
      
      if lastResultCode == noErr {
        return result as? Data
      }
      
      return nil
    }
    
    /**
    Retrieves the boolean value from the keychain that corresponds to the given key.
    - parameter key: The key that is used to read the keychain item.
    - returns: The boolean value from the keychain. Returns nil if unable to read the item.
    */
    open func getBool(_ key: String) -> Bool? {
      guard let data = getData(key) else { return nil }
      guard let firstBit = data.first else { return nil }
      return firstBit == 1
    }
    
    // MARK: - DELETE
    /**
    Deletes the single keychain item specified by the key.
    - parameter key: The key that is used to delete the keychain item.
    - returns: True if the item was successfully deleted.
    */
    open func delete(_ key: String) -> Bool {
      // The lock prevents the code to be run simultaneously
      // from multiple threads which may result in crashing
      lock.lock()
      defer { lock.unlock() }
      return deleteNoLock(key)
    }
    
    /**
    Return all keys from keychain
    - returns: An string array with all keys from the keychain.
    */
    public var allKeys: [String] {
      var query: [String: Any] = [
        CanelaKeyChainConstants.klass : kSecClassGenericPassword,
        CanelaKeyChainConstants.returnData : true,
        CanelaKeyChainConstants.returnAttributes: true,
        CanelaKeyChainConstants.returnReference: true,
        CanelaKeyChainConstants.matchLimit: CanelaKeyChainConstants.secMatchLimitAll
      ]
    
      query = addAccessGroupWhenPresent(query)
      query = addSynchronizableIfRequired(query, addingItems: false)

      var result: AnyObject?

      let lastResultCode = withUnsafeMutablePointer(to: &result) {
        SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
      }
      
      if lastResultCode == noErr {
        return (result as? [[String: Any]])?.compactMap {
          $0[CanelaKeyChainConstants.attrAccount] as? String } ?? []
      }
      return []
    }
    
    
    func deleteNoLock(_ key: String) -> Bool {
      let prefixedKey = keyWithPrefix(key)
      var query: [String: Any] = [
        CanelaKeyChainConstants.klass       : kSecClassGenericPassword,
        CanelaKeyChainConstants.attrAccount : prefixedKey
      ]
      
      query = addAccessGroupWhenPresent(query)
      query = addSynchronizableIfRequired(query, addingItems: false)
      lastQueryParameters = query
      
      lastResultCode = SecItemDelete(query as CFDictionary)
      
      return lastResultCode == noErr
    }
    
    /**
    Deletes all Keychain items used by the app. Note that this method deletes all items regardless of the prefix settings used for initializing the class.
    - returns: True if the keychain items were successfully deleted.
    */
    open func clear() -> Bool {
      // The lock prevents the code to be run simultaneously
      // from multiple threads which may result in crashing
      lock.lock()
      defer { lock.unlock() }
      var query: [String: Any] = [ kSecClass as String : kSecClassGenericPassword ]
      query = addAccessGroupWhenPresent(query)
      query = addSynchronizableIfRequired(query, addingItems: false)
      lastQueryParameters = query
      lastResultCode = SecItemDelete(query as CFDictionary)
      return lastResultCode == noErr
    }
    
    // MARK: - PRIVATE METHODS
    func addAccessGroupWhenPresent(_ items: [String: Any]) -> [String: Any] {
      guard let accessGroup = accessGroup else { return items }
      var result: [String: Any] = items
      result[CanelaKeyChainConstants.accessGroup] = accessGroup
      return result
    }
    
    func addSynchronizableIfRequired(_ items: [String: Any], addingItems: Bool) -> [String: Any] {
      if !synchronizable { return items }
      var result: [String: Any] = items
      result[CanelaKeyChainConstants.attrSynchronizable] = addingItems == true ? true : kSecAttrSynchronizableAny
      return result
    }
    
    func keyWithPrefix(_ key: String) -> String {
      return "\(keyPrefix)\(key)"
    }
    
}
