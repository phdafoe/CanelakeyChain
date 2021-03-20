//
// CanelaKeychainQuery.swift
// CanelaKeychainQuery
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

#if CNKEYCHAIN_SYNCHRONIZATION_AVAILABLE
enum CNKeychainQuerySynchronizationMode : Int {
    case any
    case no
    case yes
}
#endif


/**
 Simple interface for querying or modifying keychain items.
 */
open class CanelaKeychainQuery {
    
    /// kSecAttrAccount
    var account: String?
    /// kSecAttrService
    var service: String?
    /// kSecAttrLabel
    var label: String?
    
    #if CNKEYCHAIN_ACCESS_GROUP_AVAILABLE
    /// kSecAttrAccessGroup (only used on iOS)
    var accessGroup: String?
    #endif

    #if CNKEYCHAIN_SYNCHRONIZATION_AVAILABLE
    /// kSecAttrSynchronizable
    var synchronizationMode: SAMKeychainQuerySynchronizationMode?
    #endif
    
    /// Root storage for password information
    var passwordData: Data?
    /// This property automatically transitions between an object and the value of
    /// `passwordData` using NSKeyedArchiver and NSKeyedUnarchiver.
    weak var passwordObject: NSCoding?
    /// Convenience accessor for setting and getting a password string. Passes through
    /// to `passwordData` using UTF-8 string encoding.
    var password: String?
    
    // MARK: - Public
    ///------------------------
    /// @name Saving & Deleting
    ///------------------------

    /// Save the receiver's attributes as a keychain item. Existing items with the
    /// given account, service, and access group will first be deleted.
    /// - Parameter error: Populated should an error occur.
    /// - Returns: `YES` if saving was successful, `NO` otherwise.
    func save(_ error: NSError) -> Bool {
        var status = CNKeychainErrorCode.CNKeychainErrorBadArguments
        if (service == nil) || (account == nil) || (passwordData == nil) {
            if error != nil {
                var customError = error
                customError = self.customError(withCode: status.rawValue)! as NSError
            }
            return false
        }
        
        var query: [AnyHashable : Any]? = nil
        let searchQuery = self.query()
        if let query1 = searchQuery {
            status = CNKeychainErrorCode(rawValue: SecItemCopyMatching(query1 as CFDictionary, nil))!
        }
        if status.rawValue == errSecSuccess { //item already exists, update it!
            query = [AnyHashable : Any]()
            query?[kSecValueData] = passwordData
            #if __IPHONE_4_0 && os(iOS)
            let accessibilityType = SAMKeychain.accessibilityType()
            if let accessibilityType = accessibilityType {
                query[kSecAttrAccessible] = accessibilityType
            }
            #endif
            if let queryDes = searchQuery, let query1 = queryDes as? CFDictionary? {
                status = CNKeychainErrorCode(rawValue: SecItemUpdate(queryDes as CFDictionary, query1!))!
            }
        } else if status.rawValue == errSecItemNotFound { //item not found, create it!
            query = self.query()
            if (self.label != nil) {
                query?[kSecAttrLabel] = label
            }
            query?[kSecValueData] = passwordData
            #if __IPHONE_4_0 && os(iOS)
            let accessibilityType = SAMKeychain.accessibilityType()
            if let accessibilityType = accessibilityType {
                query[kSecAttrAccessible] = accessibilityType
            }
            #endif
            if let queryDes = query {
                status = CNKeychainErrorCode(rawValue: SecItemAdd(queryDes as CFDictionary, nil))!
            }
        }
        if status.rawValue != errSecSuccess && error != nil {
            var customError = error
            customError = self.customError(withCode: status.rawValue)! as NSError
        }
        return (status.rawValue == errSecSuccess)
    }
    
    /// Delete keychain items that match the given account, service, and access group.
    /// - Parameter error: Populated should an error occur.
    /// - Returns: `YES` if saving was successful, `NO` otherwise.
    func deleteItem(_ error: NSError) -> Bool {
        var status = CNKeychainErrorCode.CNKeychainErrorBadArguments
        if (service == nil) || (account == nil) {
            if error != nil {
                var customError = error
                customError = self.customError(withCode: status.rawValue)! as NSError
            }
            return false
        }
        var query = self.query()
        #if os(iOS)
        if let query = query as? CFDictionary {
            status = SecItemDelete(query)
        }
        #else
        // On Mac OS, SecItemDelete will not delete a key created in a different
        // app, nor in a different version of the same app.
        //
        // To replicate the issue, save a password, change to the code and
        // rebuild the app, and then attempt to delete that password.
        //
        // This was true in OS X 10.6 and probably later versions as well.
        //
        // Work around it by using SecItemCopyMatching and SecKeychainItemDelete.
        var result: CFTypeRef? = nil
        query?[kSecReturnRef] = NSNumber(value: true)
        if let query = query {
            status = CNKeychainErrorCode(rawValue: SecItemCopyMatching(query as CFDictionary, &result))!
        }
        if status.rawValue == errSecSuccess {
            if let resultDes = result {
                status = CNKeychainErrorCode(rawValue: SecKeychainItemDelete(resultDes as! SecKeychainItem))!
            }
        }
        #endif
        if status.rawValue != errSecSuccess && error != nil {
            var customError = error
            customError = self.customError(withCode: status.rawValue)! as NSError
        }

        return (status.rawValue == errSecSuccess)
    }
    
    ///---------------
    /// @name Fetching
    ///---------------

    /// Fetch all keychain items that match the given account, service, and access
    /// group. The values of `password` and `passwordData` are ignored when fetching.
    /// - Parameter error: Populated should an error occur.
    /// - Returns: An array of dictionaries that represent all matching keychain items or
    /// `nil` should an error occur.
    /// The order of the items is not determined.
    func fetchAllData(_ error: NSError?) -> [[String : Any?]]? {
        var query = self.query()
        query?[kSecReturnAttributes] = NSNumber(value: true)
        query?[kSecMatchLimit] = kSecMatchLimitAll
        #if __IPHONE_4_0 && os(iOS)
        let accessibilityType = CNKeychain.accessibilityType()
        if let accessibilityType = accessibilityType {
            query[kSecAttrAccessible] = accessibilityType
        }
        #endif
        var result: CFTypeRef? = nil
        var status: OSStatus? = nil
        if let query = query {
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        if status != errSecSuccess && error != nil {
            var customError = error
            customError = self.customError(withCode: status!)! as NSError
            return nil
        }
        return result as? [[String : Any?]]
    }
    
    /// Fetch the keychain item that matches the given account, service, and access
    /// group. The `password` and `passwordData` properties will be populated unless
    /// an error occurs. The values of `password` and `passwordData` are ignored when
    /// fetching.
    /// - Parameter error: Populated should an error occur.
    /// - Returns: `YES` if fetching was successful, `NO` otherwise.
    func fetch(_ error: NSError) -> Bool {
        var status = CNKeychainErrorCode.CNKeychainErrorBadArguments
        if (service == nil) || (account == nil) {
            if error != nil {
                var customError = error
                customError = self.customError(withCode: status.rawValue)! as NSError
            }
            return false
        }
        var result: CFTypeRef? = nil
        var query = self.query()
        query?[kSecReturnData] = NSNumber(value: true)
        query?[kSecMatchLimit] = kSecMatchLimitOne
        if let query = query {
            status = CNKeychainErrorCode(rawValue: SecItemCopyMatching(query as CFDictionary, &result))!
        }
        if status.rawValue != errSecSuccess {
            if error != nil {
                var customError = error
                customError = self.customError(withCode: status.rawValue)! as NSError
            }
            return false
        }

        passwordData = result as? Data
        return true
    }
    
    // MARK: - Accessors
    
    func setPasswordObject(_ object: NSCoding?) {
        if let object = object {
            passwordData = NSKeyedArchiver.archivedData(withRootObject: object)
        }
    }
    
    func passwordObjectMethod() -> NSCoding? {
        if ((passwordData?.count) != nil) {
            return NSKeyedUnarchiver.unarchiveObject(with: passwordData!) as? NSCoding
        }
        return nil
    }
    
    func setPassword(_ password: String?) {
        passwordData = password?.data(using: .utf8)
    }
    
    func passwordMethod() -> String? {
        if ((passwordData?.count) != nil) {
            return String(data: passwordData!, encoding: .utf8)
        }
        return nil
    }
    
    // MARK: - Synchronization Status
    /**
     Returns a boolean indicating if keychain synchronization is available on the device at runtime. The #define
     CNKEYCHAIN_SYNCHRONIZATION_AVAILABLE is only for compile time. If you are checking for the presence of synchronization,
     you should use this method.
     
     @return A value indicating if keychain synchronization is available
     */
    #if CNKEYCHAIN_SYNCHRONIZATION_AVAILABLE
    // Apple suggested way to check for 7.0 at runtime
    // https://developer.apple.com/library/ios/documentation/userexperience/conceptual/transitionguide/SupportingEarlieriOS.html
    func isSynchronizationAvailable() -> Bool {
        #if TARGET_OS_IPHONE
        return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1
        #else
        return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_8_4
        #endif
    }
    #endif
    
    // MARK: - Private
    
    func query() -> [AnyHashable : Any]? {
        var dictionary = [AnyHashable : Any](minimumCapacity: 3)
        dictionary[kSecClass] = kSecClassGenericPassword

        if (self.service != nil) {
            dictionary[kSecAttrService] = self.service
        }
        if (self.account != nil) {
            dictionary[kSecAttrAccount] = self.account
        }
        #if CNKEYCHAIN_ACCESS_GROUP_AVAILABLE
        #if !TARGET_IPHONE_SIMULATOR
        if self.accessGroup {
            dictionary[kSecAttrAccessGroup] = self.accessGroup
        }
        #endif
        #endif
        #if CNKEYCHAIN_SYNCHRONIZATION_AVAILABLE
        if isSynchronizationAvailable() {
            let value: Any? = nil
            switch synchronizationMode {
            case CNKeychainQuerySynchronizationMode.no:
                    value = NSNumber(value: false)
            case CNKeychainQuerySynchronizationMode.yes:
                    value = NSNumber(value: true)
            case CNKeychainQuerySynchronizationMode.any:
                    value = kSecAttrSynchronizableAny
                default:
                    break
            }
            dictionary[kSecAttrSynchronizable] = value
        }
        #endif
        return dictionary
    }
    
    func customError(withCode code: OSStatus) -> Error? {
        var resourcesBundle: Bundle? = nil
        var message: String? = nil
        switch code {
        case errSecSuccess:
            return nil
        case code:
            message = NSLocalizedString("CNKeychainErrorBadArguments", tableName: "CNKeychain", bundle: resourcesBundle!, value: "", comment: "")
            break
        #if TARGET_OS_IPHONE
        case errSecUnimplemented:
            message = NSLocalizedString("errSecUnimplemented", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecParam:
            message = NSLocalizedString("errSecParam", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecAllocate:
            message = NSLocalizedString("errSecAllocate", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecNotAvailable:
            message = NSLocalizedString("errSecNotAvailable", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecDuplicateItem:
            message = NSLocalizedString("errSecDuplicateItem", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecItemNotFound:
            message = NSLocalizedString("errSecItemNotFound", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecInteractionNotAllowed:
            message = NSLocalizedString("errSecInteractionNotAllowed", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecDecode:
            message = NSLocalizedString("errSecDecode", "CNKeychain", resourcesBundle, nil);
            break;
        case errSecAuthFailed:
            message = NSLocalizedString("errSecAuthFailed", "CNKeychain", resourcesBundle, nil);
            break;
        default:
            message = NSLocalizedString("errSecDefault", "CNKeychain", resourcesBundle, nil);
        #else
        default:
            message = SecCopyErrorMessageString(code, nil) as String?
        #endif
        }
        
        var userInfo: [AnyHashable : Any]? = nil
        if (message != nil) {
            userInfo = [
                NSLocalizedDescriptionKey: message as Any
            ]
        }
        return NSError(domain: kCNKeychainErrorDomain, code: Int(code), userInfo: userInfo as? [String : Any])

    }
    
}
