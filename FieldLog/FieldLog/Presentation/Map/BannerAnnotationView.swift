
//  BannerAnnotationView.swift
//  FieldLog

import SwiftUI

/// 지도 위 배너 위치를 나타내는 Annotation 뷰.
/// thumbnailData: 저장 시 생성된 다운샘플 이미지.
/// count: 이 위치에 묶인 배너 수. 1보다 크면 배지 표시. (클러스터링 준비용)
struct BannerAnnotationView: View {
    let thumbnailData: Data
    let count: Int

    @State private var cachedImage: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailImageView
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .shadow(radius: 3)

            if count > 1 {
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.red)
                    .clipShape(Circle())
                    .offset(x: 6, y: -6)
            }
        }
        .accessibilityLabel("배너")
        // id: thumbnailData — 데이터가 바뀌면 이전 Task를 취소하고 재실행.
        // byPreparingForDisplay: 백그라운드에서 미리 디코딩해 메인 스레드 부담을 줄인다.
        .task(id: thumbnailData) {
            cachedImage = await UIImage(data: thumbnailData)?.byPreparingForDisplay()
        }
    }

    @ViewBuilder
    private var thumbnailImageView: some View {
        if let image = cachedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .padding(8)
                .foregroundStyle(.secondary)
                .background(.thinMaterial)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    BannerAnnotationView(thumbnailData: Data(), count: 1)
}
