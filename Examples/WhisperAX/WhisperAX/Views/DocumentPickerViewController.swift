import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
struct DocumentPickerViewController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var document: TextFileDocument?
    var contentType: UTType
    var defaultFilename: String
    var onCompletion: (Result<URL, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forExporting: [document!.fileWrapper(configuration: .init())], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerViewController

        init(_ parent: DocumentPickerViewController) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.isPresented = false
            if let url = urls.first {
                parent.onCompletion(.success(url))
            } else {
                parent.onCompletion(.failure(NSError(domain: "DocumentPickerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No document was picked."])))
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
            parent.onCompletion(.failure(NSError(domain: "DocumentPickerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document picker was cancelled."])))
        }
    }
}
#elseif os(macOS)
struct DocumentPickerViewController: NSViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var document: TextFileDocument?
    var contentType: UTType
    var defaultFilename: String
    var onCompletion: (Result<URL, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        DispatchQueue.main.async {
            context.coordinator.presentOpenPanel()
        }
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    class Coordinator: NSObject, NSOpenSavePanelDelegate {
        var parent: DocumentPickerViewController

        init(_ parent: DocumentPickerViewController) {
            self.parent = parent
        }

        func presentOpenPanel() {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            if #available(macOS 12.0, *) {
                panel.allowedContentTypes = [parent.contentType]
            } else {
                panel.allowedFileTypes = [parent.contentType.identifier]
            }
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    self.parent.onCompletion(.success(url))
                } else {
                    self.parent.onCompletion(.failure(NSError(domain: "DocumentPickerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No document was picked."])))
                }
                self.parent.isPresented = false
            }
        }
    }
}
#endif
