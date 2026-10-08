import SwiftUI

/// Phase 2 feature (plan "Build order") — anonymous community + question bank. Placeholder
/// tab so the real navigation shape (spec section 20) is in place from day one.
struct CommunityView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundStyle(AlineColor.electricCobalt)
                Text("Community").font(AlineFont.display(24)).foregroundStyle(AlineColor.inkNavy)
                Text("Anonymous interview experiences and question bank — Phase 2.")
                    .font(AlineFont.body(14))
                    .foregroundStyle(AlineColor.graphite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .background(AlineColor.warmCanvas)
        }
    }
}
