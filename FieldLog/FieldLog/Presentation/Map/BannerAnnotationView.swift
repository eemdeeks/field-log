
//  BannerAnnotationView.swift
//  FieldLog

import SwiftUI

/// 지도 위 배너 위치를 나타내는 Annotation 뷰.
/// thumbnailData: 저장 시 생성된 다운샘플 이미지.
/// count: 이 위치에 묶인 배너 수. 1보다 크면 배지 표시. (클러스터링 준비용)
struct BannerAnnotationView: View {
    let thumbnailData: Data
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailImage
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
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
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // 썸네일 디코딩 실패 시 fallback
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .padding(8)
                .foregroundStyle(.secondary)
                .background(.thinMaterial)
        }
    }
}

#Preview {
    BannerAnnotationView(thumbnailData: Data(), count: 1)
}
