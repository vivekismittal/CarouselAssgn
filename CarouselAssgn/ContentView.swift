//
//  ContentView.swift
//  CarouselAssgn
//
//  Created by VM on 12/12/25.
//


import SwiftUI

// MARK: - Constants

private enum CarouselConfig {
    static let itemBaseWidth: CGFloat = 200
    static let itemFrameExtraWidth: CGFloat = 20
    static let itemSpacing: CGFloat = -10
    static let maxSizeIncrease: CGFloat = 60
    static let cornerRadius: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
    static let defaultZIndexBase: Double = 1000
    
    static var itemFrameWidth: CGFloat {
        itemBaseWidth + itemFrameExtraWidth
    }
    
    static var horizontalContentMargin: CGFloat {
        (UIScreen.main.bounds.width - itemFrameWidth) / 2
    }
    
    static let imageUrls: [String] = [
        "https://picsum.photos/id/237/400/400",
        "https://picsum.photos/id/1025/400/400",
        "https://picsum.photos/id/1005/400/400",
        "https://picsum.photos/id/1011/400/400",
        "https://picsum.photos/id/1012/400/400",
        "https://picsum.photos/id/1015/400/400",
        "https://picsum.photos/id/1024/400/400",
        "https://picsum.photos/id/1035/400/400",
        "https://picsum.photos/id/1041/400/400",
        "https://picsum.photos/id/1050/400/400"
    ]
}

// MARK: - Preference Key

private struct ScrollDistancePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = CarouselConfig.defaultZIndexBase
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Carousel View
struct CarouselView: View {
    
    // MARK: Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            carouselContent
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, CarouselConfig.horizontalContentMargin, for: .scrollContent)
    }
    
    // MARK: Subviews
    
    private var carouselContent: some View {
        HStack(spacing: CarouselConfig.itemSpacing) {
            ForEach(CarouselConfig.imageUrls.indices, id: \.self) { index in
                CarouselItemView(
                    imageUrl: CarouselConfig.imageUrls[index],
                    baseWidth: CarouselConfig.itemBaseWidth
                )
                .frame(width: CarouselConfig.itemFrameWidth)
                .scrollTransition { content, _ in
                    content
                }
            }
        }
        .scrollTargetLayout()
        .padding(.horizontal, CarouselConfig.horizontalPadding)
    }
}

// MARK: - Carousel Item View
private struct CarouselItemView: View {
    
    let imageUrl: String
    let baseWidth: CGFloat
    
    @State private var distanceFromScreenCenter: CGFloat = CarouselConfig.defaultZIndexBase
    
    // MARK: Body
    
    var body: some View {
        GeometryReader { geometry in
            scaledImageContent(in: geometry)
        }
        .onPreferenceChange(ScrollDistancePreferenceKey.self) { distance in
            distanceFromScreenCenter = distance
        }
        .zIndex(CarouselConfig.defaultZIndexBase - Double(distanceFromScreenCenter))
    }
    
    // MARK: Subviews
    
    private func scaledImageContent(in geometry: GeometryProxy) -> some View {
        let metrics = calculateScaleMetrics(in: geometry)
        
        return asyncImageView
            .frame(width: metrics.scaledSize, height: metrics.scaledSize)
            .clipShape(RoundedRectangle(cornerRadius: CarouselConfig.cornerRadius))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .preference(key: ScrollDistancePreferenceKey.self, value: metrics.rawDistance)
    }
    
    private var asyncImageView: some View {
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
                case .empty:
                    loadingPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    errorPlaceholder
                @unknown default:
                    EmptyView()
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: CarouselConfig.cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .overlay(ProgressView())
    }
    
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: CarouselConfig.cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            )
    }
    
    // MARK: Scale Calculations
    
    private struct ScaleMetrics {
        let scaledSize: CGFloat
        let rawDistance: CGFloat
    }
    
    private func calculateScaleMetrics(in geometry: GeometryProxy) -> ScaleMetrics {
        let itemMidX = geometry.frame(in: .global).midX
        let screenMidX = UIScreen.main.bounds.midX
        
        let rawDistanceFromCenter = abs(itemMidX - screenMidX)
        let maxEffectDistance = baseWidth / 2
        let clampedDistance = min(rawDistanceFromCenter, maxEffectDistance)
        
        // scaleProgress: 1.0 when centered, 0.0 when at max distance
        let scaleProgress = 1 - (clampedDistance / maxEffectDistance)
        let scaledSize = baseWidth + (scaleProgress * CarouselConfig.maxSizeIncrease)
        
        return ScaleMetrics(scaledSize: scaledSize, rawDistance: rawDistanceFromCenter)
    }
}

// MARK: - Preview

#Preview {
    CarouselView()
}
