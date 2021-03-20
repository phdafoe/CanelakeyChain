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

public enum CNKeychainErrorCode: OSStatus {
    /// Some of the arguments were invalid.
    case CNKeychainErrorBadArguments = -1001
}

let kCNKeychainErrorDomain = "com.csoffes.ckeychain"
let kCNKeychainAccountKey = "acct"
let kCNKeychainCreatedAtKey = "cdat"
let kCNKeychainClassKey = "labl"
let kCNKeychainDescriptionKey = "desc"
let kCNKeychainLabelKey = "labl"
let kCNKeychainLastModifiedKey = "mdat"
let kCNKeychainWhereKey = "svce"


open class CanelakeyChain {
    
    
    
    #if __IPHONE_4_0 && os(iOS)
    private let CNKeychainAccessibilityType: CFTypeRef? = nil
    #endif
    
    open func password(forService serviceName: String?, account: String?) -> String? {
        return try? self.password(forService: serviceName, account: account)
    }
    
    open func password(forService serviceName: String?, account: String?, error: NSError) -> String? {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        query.account = account
        query.fetch(error)
        
        return query.passwordMethod()
    }
    
    open func passwordData(forService serviceName: String?, account: String?) -> Data? {
        return self.passwordData(forService: serviceName, account: account)
    }
    
    open func passwordData(forService serviceName: String?, account: String?, error: NSError) -> Data? {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        query.account = account
        query.fetch(error)

        return query.passwordData
    }
    
    open func deletePassword(forService serviceName: String?, account: String?) -> Bool {
        return self.deletePassword(forService: serviceName, account: account)
    }
    
    open func deletePassword(forService serviceName: String?, account: String?, error: NSError) -> Bool {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        query.account = account
        return query.deleteItem(error)
    }
    
    open func setPassword(_ password: String?, forService serviceName: String?, account: String?) -> Bool {
        return self.setPassword(password, forService: serviceName, account: account)
    }
    
    open func setPassword(_ password: String?, forService serviceName: String?, account: String?, error: NSError) -> Bool {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        query.account = account
        query.password = password
        return query.save(error)
    }
    
    open func setPasswordData(_ password: Data?, forService serviceName: String?, account: String?) -> Bool {
        return self.setPasswordData(password, forService: serviceName, account: account)
    }
    
    open func setPasswordData(_ password: Data?, forService serviceName: String?, account: String?, error: NSError) -> Bool {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        query.account = account
        query.passwordData = password
        return query.save(error)
    }
    
    open func allAccounts() -> [[String : Any?]]? {
        return self.allAccounts(nil)
    }
    
    open func allAccounts(_ error: NSError?) -> [[String : Any?]]? {
        return self.accounts(forService: nil, error: error)
    }
    
    open func accounts(forService serviceName: String?) -> [[String : Any?]]? {
        return self.accounts(forService: serviceName)
    }
    
    open func accounts(forService serviceName: String?, error: NSError?) -> [[String : Any?]]? {
        let query = CanelaKeychainQuery()
        query.service = serviceName
        return query.fetchAllData(error)
    }
    
    #if __IPHONE_4_0 && os(iOS)
    open func accessibilityType() -> CFTypeRef? {
        return CNKeychainAccessibilityType
    }
    
    open func setAccessibilityType(_ accessibilityType: CFTypeRef?) {
        CFRetain(accessibilityType)
        if CNKeychainAccessibilityType != nil {
        }
        if let accessibilityType = accessibilityType {
            CNKeychainAccessibilityType = accessibilityType
        }
    }
    #endif
    
}
