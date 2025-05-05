import SwiftUI
import AVKit
import Dependencies

struct AttachmentsView: View {
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.toastManager) private var toastManager
    private let annotation: AnnotationType
    
    init(annotation: AnnotationType) {
        self.annotation = annotation
    }
    
    var body: some View {
        TabView {
            ForEach(Array(annotation.attachments.enumerated()), id: \.element.id) { index, attachment in
                VStack {
                    attachmentView(for: attachment)
                        .tag(index)
                    
                    Button(role: .destructive) {
                        do {
                            switch annotation {
                            case .model(let model):
                                try annotationManager.delete(attachment, from: model)
                            case .working:
                                try annotationManager.deleteAttachmentFromWorkingAnnotation(attachment)
                            }
                        } catch {
                            toastManager.addBreadForToasting(.somethingWentWrong(.error(error)))
                        }
                    } label: {
                        Label("Remove Attachment", systemImage: "trash")
                    }
                }
                .padding(.bottom, 40)
            }
            
            VStack {
                if annotation.attachments.isEmpty {
                    ContentUnavailableView(
                        "No Attachments",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add photos or videos to this marker.")
                    )
                } else {
                    ContentUnavailableView(
                        "Add more attachments",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add more photos or videos to this marker.")
                    )
                }
                
                AttachmentPicker(annotation: annotation)
                    .padding(.top)
            }
            .padding(.bottom, 40)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
    
    @ViewBuilder
    private func attachmentView(for attachment: Attachment) -> some View {
        ZStack {
            Color.clear
            
            switch attachment.type {
            case .image:
                let url: URL? = {
                    do {
                        return try annotationManager.getUrl(for: attachment)
                    } catch {
                        // TODO: - Gracefully handle error (toast?) instead of swallowing
                        print(error)
                        return nil
                    }
                }()
                
                if let url,
                   let uiImage = UIImage(contentsOfFile: url.path()) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Unable to load image")
                }
                
            case .video:
                let url: URL? = {
                    do {
                        return try annotationManager.getUrl(for: attachment)
                    } catch {
                        // TODO: - Gracefully handle error (toast?) instead of swallowing
                        print(error)
                        return nil
                    }
                }()
                
                if let url {
                    VideoPlayerView(url: url)
                } else {
                    Text("Unable to load video")
                }
            }
        }
    }
}

fileprivate struct VideoPlayerView: View {
    @State private var player = AVPlayer()
    
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    var body: some View {
        VideoPlayer(player: player)
            .onChange(of: url, initial: true) {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
    }
}

#Preview {
    AttachmentsView(annotation: .working(.example))
}
