import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedUIImage: UIImage?
    @State private var selectedImage: Image?
    @State private var showSheet = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var isNavigatingToFilterView = false

    var body: some View {
        NavigationStack {
            VStack {
                if let image = selectedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .overlay(Text("사진을 선택하세요"))
                }

                Button("사진 선택") {
                    showSheet = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onChange(of: selectedUIImage) {
                if selectedUIImage != nil {
                    isNavigatingToFilterView = true
                }
            }
            .navigationDestination(isPresented: $isNavigatingToFilterView) {
                if let image = selectedUIImage {
                    FilterView(image: image)
                }
            }
            // Sheet: 사진 선택 or 카메라
            .sheet(isPresented: $showSheet) {
                photoOrCameraSheet
            }
            // PhotoPicker Sheet
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedUIImage: $selectedUIImage, selectedImage: $selectedImage)
            }
            // CameraPicker Sheet
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(selectedUIImage: $selectedUIImage, selectedImage: $selectedImage)
            }
        }
    }

    // MARK: - 원하는 방식을 고르는 Sheet
    var photoOrCameraSheet: some View {
        VStack {
            Text("사진 불러오기")
                .font(.headline)
                .padding()

            Button("앨범에서 선택") {
                showSheet = false
                showPhotoPicker = true
            }
            .padding()

            Button("카메라 촬영") {
                showSheet = false
                showCameraPicker = true
            }
            .padding()

            Button("취소", role: .cancel) {
                showSheet = false
            }
            .padding()
        }
        .presentationDetents([.fraction(0.3)])
    }
}
