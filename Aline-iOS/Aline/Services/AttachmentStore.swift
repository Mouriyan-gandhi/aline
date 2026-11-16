import Foundation
import UniformTypeIdentifiers

/// Achievement attachment files: uploaded to the backend (`/files/{achievement id}`) and kept
/// in Documents/Attachments so they open instantly and offline on this device.
enum AttachmentStore {
    private struct UploadRequest: Encodable {
        let deviceId: String
        let filename: String
        let contentType: String
        let dataBase64: String
    }

    private static func folder(for id: String) -> URL {
        URL.documentsDirectory.appendingPathComponent("Attachments/\(id)", isDirectory: true)
    }

    /// Copies the picked file (call while its security-scoped access is open) and uploads it.
    static func store(_ pickedURL: URL, forAchievement id: String) {
        guard let data = try? Data(contentsOf: pickedURL) else { return }
        let filename = pickedURL.lastPathComponent
        let contentType = UTType(filenameExtension: pickedURL.pathExtension)?.preferredMIMEType ?? "application/pdf"
        let folder = folder(for: id)
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? data.write(to: folder.appendingPathComponent(filename))

        Task {
            let request = UploadRequest(
                deviceId: DeviceIdentity.deviceID, filename: filename, contentType: contentType,
                dataBase64: data.base64EncodedString()
            )
            _ = try? await APIClient.raw("files/\(id)", method: "PUT", body: request)
        }
    }

    /// The attachment on this device, downloading it from the backend first if needed.
    static func localURL(forAchievement id: String, filename: String) async -> URL? {
        let local = folder(for: id).appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: local.path) { return local }
        guard let data = try? await APIClient.raw(
            "files/\(id)", method: "GET", query: APIClient.deviceQuery(), body: Optional<Int>.none
        ) else { return nil }
        try? FileManager.default.createDirectory(at: folder(for: id), withIntermediateDirectories: true)
        try? data.write(to: local)
        return local
    }

    static func delete(forAchievement id: String) {
        try? FileManager.default.removeItem(at: folder(for: id))
        Task { try? await APIClient.delete("files/\(id)", query: APIClient.deviceQuery()) }
    }
}
