import SwiftUI
import Photos
import UIKit

// 이미지저장
class ImageSaver: NSObject {
    static func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                print("사진 저장 권한 거부")
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if let error = error {
                    print("저장 실패: \(error.localizedDescription)")
                } else {
                    print("저장 성공!")
                }
            })
        }
    }
}

// 편집 , 공유
enum FilterStage {
    case editing
    case preview
}

// 필터
struct FilterView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    @State private var filters: [FilterModel] = []
    @State private var selectedFilterImage: UIImage?
    @State private var selectedIndex: Int = 0
    @State private var categories: [String] = ["ALL", "PREMIUM", "PORTRAIT"]
    @State private var selectedCategory: String = "ALL"

    @State private var stage: FilterStage = .editing
    @State private var showFilterName: Bool = false
    @State private var currentFilterName: String = ""
    @State private var isShowingOriginal: Bool = false
    @State private var isSharing: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Image(uiImage: isShowingOriginal ? image : (selectedFilterImage ?? image))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if showFilterName {
                        VStack {
                            Spacer()
                            Text(currentFilterName)
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                    }
                }
                .padding(.vertical, 8)

                if stage == .editing {
                    categoryTabView
                    filterTabView.frame(height: 0)
                    filterThumbnailBar(displayedFilters: filteredFilters)
                }

                bottomBar
            }

            VStack(alignment: .trailing, spacing: 12) {
                if stage == .preview {
                    Button {
                        isSharing = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }

                Image(systemName: "eye")
                    .font(.title2)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .offset(x: 4)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isShowingOriginal {
                                    isShowingOriginal = true
                                    currentFilterName = "원본"
                                    showFilterName = true
                                }
                            }
                            .onEnded { _ in
                                isShowingOriginal = false
                                showFilterName = false
                            }
                    )
            }
            .padding(.trailing, 20)
            .padding(.top, 20)
            .transition(.move(edge: .top))
        }
        .sheet(isPresented: $isSharing) {
            let final = selectedFilterImage ?? image
            ShareSheet(activityItems: [final])
        }
        .onAppear {
            self.filters = FilterManager.loadFilters()
            if !filters.isEmpty {
                apply(filters[0])
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut, value: stage)
    }

    var filteredFilters: [FilterModel] {
        filters.filter {
            $0.category == selectedCategory || selectedCategory == "ALL"
        }
    }

    var categoryTabView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat)
                        .foregroundColor(selectedCategory == cat ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == cat ? Color.white.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedCategory = cat
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    var filterTabView: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(filteredFilters.enumerated()), id: \.offset) { idx, filter in
                Color.clear
                    .tag(idx)
                    .onAppear {
                        apply(filter)
                        showFilterLabel(for: filter.name)
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    func filterThumbnailBar(displayedFilters: [FilterModel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(displayedFilters.enumerated()), id: \.offset) { idx, filter in
                    let thumb = applyFilter(filter, to: image.resized(to: 100))
                    VStack(spacing: 4) {
                        Image(uiImage: thumb)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedIndex == idx ? .white : .clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedIndex = idx
                                apply(filter)
                                showFilterLabel(for: filter.name)
                            }
                        Text(filter.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    var bottomBar: some View {
        HStack {
            Button {
                switch stage {
                case .editing:
                    dismiss()
                case .preview:
                    withAnimation {
                        stage = .editing
                    }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.white)
            }

            Spacer()

            Text("필터 효과")
                .font(.footnote)
                .foregroundColor(.white)

            Spacer()

            Button {
                switch stage {
                case .editing:
                    withAnimation {
                        stage = .preview
                    }
                case .preview:
                    let final = selectedFilterImage ?? image
                    ImageSaver.saveToPhotoLibrary(final)
                    dismiss()
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.white)
            }
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.95))
    }

    func apply(_ filter: FilterModel) {
        guard let settings = filter.settings else {
            self.selectedFilterImage = image
            return
        }
        self.selectedFilterImage = CustomFilter.applyFilters(image, settings: settings)
    }

    func applyFilter(_ filter: FilterModel, to image: UIImage) -> UIImage {
        guard let settings = filter.settings else {
            return image
        }

        var result = image

        let brightness  = CGFloat(settings.brightness)
        let contrast    = CGFloat(settings.contrast)
        let saturation  = CGFloat(settings.saturation)

        result = CustomFilter.applyBrightness(result, value: brightness)
        result = CustomFilter.applyContrast(result, value: contrast)
        result = CustomFilter.applySaturation(result, value: saturation)

        return result
    }

    func showFilterLabel(for name: String) {
        self.currentFilterName = name
        self.showFilterName = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !isShowingOriginal {
                self.showFilterName = false
            }
        }
    }
}

// 공유
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
