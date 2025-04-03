import SwiftUI
import PhotosUI
import Photos
import AVKit

struct AttachmentPicker: View {
    @Environment(AnnotationPersistenceManager.self) private var attachmentManager
    @State private var presentPicker = false
    @State private var isLoading = false
    
    private let annotation: AnnotationType
    
    init(annotation: AnnotationType) {
        self.annotation = annotation
    }
    
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
            PHPickerView(isLoading: $isLoading) { attachmentType in
                do {
                    switch (annotation, attachmentType) {
                    case let (.model(annotationData), .addImage(image)):
                        try attachmentManager.addImage(image, to: annotationData)
                    case let (.working, .addImage(image)):
                        try attachmentManager.addImageToWorkingAnnotation(image)
                    case let (.model(annotationData), .addVideo(url)):
                        try attachmentManager.addVideo(thatExistsAtURL: url, to: annotationData)
                    case let (.working, .addVideo(url)):
                        try attachmentManager.addVideoToWorkingAnnotation(thatExistsAtURL: url)
                    }
                } catch {
                    // TODO: - Gracefully handle error (toast?) instead of swallowing
                    print(error)
                }
            }
        }
        
        if isLoading {
            ProgressView("Processing attachments...")
                .padding()
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    enum AttachmentType {
        case addImage(UIImage)
        case addVideo(at: URL)
    }
    
    @Binding private var isLoading: Bool
    private let addAttachment: (AttachmentType) -> Void
    
    init(isLoading: Binding<Bool>, addAttachment: @escaping (AttachmentType) -> Void) {
        self._isLoading = isLoading
        self.addAttachment = addAttachment
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
                        guard let image = object as? UIImage else { return }
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.parent.addAttachment(.addImage(image))
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
                            
                            DispatchQueue.main.async { [weak self] in
                                self?.parent.addAttachment(.addVideo(at: tempURL))
                            }
                        } catch {
                            // TODO: - Gracefully handle error (toast?) instead of swallowing
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
