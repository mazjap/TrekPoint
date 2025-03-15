import SwiftUI
import AVKit

struct AttachmentsView: View {
    @Binding private var attachments: [Attachment]
    @Environment(AttachmentStore.self) private var attachmentStore
    
    init(attachments: Binding<[Attachment]>) {
        self._attachments = attachments
    }
    
    var body: some View {
        TabView {
            ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                VStack {
                    attachmentView(for: attachment)
                        .tag(index)
                    
                    Button(role: .destructive) {
                        attachmentStore.deleteAttachment(attachment)
                        attachments.remove(at: index)
                    } label: {
                        Label("Remove Attachment", systemImage: "trash")
                    }
                }
                .padding(.bottom, 40)
            }
            
            VStack {
                if attachments.isEmpty {
                    ContentUnavailableView(
                        "No Attachments",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add photos or videos to this annotation.")
                    )
                } else {
                    ContentUnavailableView(
                        "Add more attachments",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add more photos or videos to this annotation.")
                    )
                }
                
                AttachmentPicker(attachments: $attachments)
                    .padding(.top)
            }
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func attachmentView(for attachment: Attachment) -> some View {
        ZStack {
            Color.clear
            
            switch attachment.type {
            case .image:
                if let url = attachmentStore.resolveURL(for: attachment),
                   let uiImage = UIImage(contentsOfFile: url.path()) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Unable to load image")
                }
                
            case .video:
                if let url = attachmentStore.resolveURL(for: attachment) {
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
    @Previewable @State var attachments = [Attachment]()
    
    AttachmentsView(attachments: $attachments)
}
