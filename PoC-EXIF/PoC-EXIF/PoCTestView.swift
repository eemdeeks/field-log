struct POCTestView: View {
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Text("사진 선택")
            }.onChange(of: selectedItems) { _, newItems in
                loadImages(newItems)
            }
        }
        .padding()

    }

    private func loadImages(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data, let image = UIImage(data: data) {
                        // 이미지는 잘 나온다
                        print("이미지 로드 성공: \(image.size)")
                    }
                case .failure(let error):
                    print("실패: \(error)")
                }
            }
        }
    }

}