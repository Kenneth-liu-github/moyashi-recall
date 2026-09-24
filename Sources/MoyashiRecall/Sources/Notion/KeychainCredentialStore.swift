import Foundation
import Security

public enum CredentialStoreError: Error, Equatable {
    case invalidData
    case unexpectedStatus(OSStatus)
}

public struct KeychainCredentialStore {
    public static let notionTokenAccount = "notion-api-token"

    private let service: String

    public init(service: String = "com.moyashi.recall") {
        self.service = service
    }

    public func save(_ secret: String, account: String) throws {
        guard let data = secret.data(using: .utf8) else {
            throw CredentialStoreError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            update as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw CredentialStoreError.unexpectedStatus(updateStatus)
        }

        var insert = query
        insert[kSecValueData as String] = data

        let addStatus = SecItemAdd(
            insert as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw CredentialStoreError.unexpectedStatus(addStatus)
        }
    }

    public func read(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw CredentialStoreError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            throw CredentialStoreError.invalidData
        }

        return value
    }

    public func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.unexpectedStatus(status)
        }
    }
}
