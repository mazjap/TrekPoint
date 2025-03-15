import SwiftUI
import PhotosUI
import Photos
import AVKit

struct AttachmentPicker: View {
    @Environment(AttachmentStore.self) private var attachmentStore
    @Binding var attachments: [Attachment]
    @State private var presentPicker = false
    @State private var isLoading = false
    
    var body: some View {
        Button {
            presentPicker = true
        } label: {
            Label("Add Photos or Videos", systemImage: "photo.on.rectangle.angled")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
        .sheet(isPresented: $presentPicker) {
            PHPickerView(attachments: $attachments, isLoading: $isLoading, attachmentStore: attachmentStore)
        }
        
        if isLoading {
            ProgressView("Processing attachments...")
                .padding()
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @Binding private var attachments: [Attachment]
    @Binding private var isLoading: Bool
    private let attachmentStore: AttachmentStore
    
    init(attachments: Binding<[Attachment]>, isLoading: Binding<Bool>, attachmentStore: AttachmentStore) {
        self._attachments = attachments
        self._isLoading = isLoading
        self.attachmentStore = attachmentStore
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0 // No limit
        config.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isLoading = true
            
            picker.dismiss(animated: true)
            
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                
                let itemProvider = result.itemProvider
                
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                        defer { group.leave() }
                        guard let self = self, let image = object as? UIImage else { return }
                        
                        if let attachment = self.parent.attachmentStore.storeImage(image) {
                            DispatchQueue.main.async {
                                self.parent.attachments.append(attachment)
                            }
                        }
                    }
                } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
                        defer { group.leave() }
                        guard let self = self, let url = url, error == nil else { return }
                        
                        // Copy to temporary location
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            
                            if let attachment = self.parent.attachmentStore.storeVideo(thatExistsAtURL: tempURL) {
                                DispatchQueue.main.async {
                                    self.parent.attachments.append(attachment)
                                }
                            }
                        } catch {
                            print("Error copying video: \(error)")
                        }
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.isLoading = false
            }
        }
    }
}
