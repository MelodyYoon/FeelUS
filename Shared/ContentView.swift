//
//  ContentView.swift
//  FeelUS (iOS)
//
//  Created by Alice Yoon on 09/02/22.
//

import SwiftUI
import Photos
import CoreHaptics

struct ContentView: View {
    // MARK: Picker Properties
    @State var showPicker: Bool = false
    @StateObject var imageTouchModel: ImageTouchViewModel = .init()
    @StateObject var hapticManager = HapticManager()
    @GestureState var isDetectingLongPress = false
    @State var dragStartTime = Date(timeIntervalSinceReferenceDate: 0)
    @State var showAlert = false
    @State var alertType = 0;
    @State var volumeAlerted = false;
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        //NavigationView{
            GeometryReader{ proxy in
                let size = proxy.size
                if #available(iOS 15.0, *) {
                    Image(uiImage: imageTouchModel.displayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width, height: size.height)
                        .background(Color.black)
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .inactive {
                                print("Inactive")
                                hapticManager.stopHapticPlayer()
                                imageTouchModel.stopSpeak()
                            }
                        }
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged {value in
                                //                            print("*****onChanged", pickedColor)
                                if (dragStartTime == Date(timeIntervalSinceReferenceDate: 0)) { dragStartTime = value.time }
                                if (!imageTouchModel.mainMenu) {
                                    let edgeDensity = imageTouchModel.getRGBColorOfThePixel(at: value.location, within: size, radius: 10)
                                    if (edgeDensity>0.01) {
                                        print("Edge detected", value.location, edgeDensity)
                                        hapticManager.startHapticPlayer(density: Float(edgeDensity))
                                        //let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                                        //impactHeavy.impactOccurred()
                                    } else {
                                        hapticManager.stopHapticPlayer()
                                    }
                                }
                                //self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                            }   // 4.
                            .onEnded {value in
                                hapticManager.stopHapticPlayer()
                                if ((value.time.timeIntervalSinceReferenceDate - dragStartTime.timeIntervalSinceReferenceDate) < 1) {
                                    let swipeThreshold = size.width/5
                                    if (value.startLocation.x < 30 && (value.location.x - value.startLocation.x) > swipeThreshold/3) {
                                        print("edge");
                                        imageTouchModel.gotoMainMenu()
                                    } else if ((value.location.x - value.startLocation.x) > swipeThreshold) {
                                        alertType = imageTouchModel.nextImage()
                                        if (alertType < 0) {
                                            showAlert = true
                                        } else if (alertType > 0 && !volumeAlerted) {
                                            showAlert = true
                                            volumeAlerted = true
                                        }
                                    }
                                    else if ((value.location.x - value.startLocation.x) < -swipeThreshold) {
                                        alertType = imageTouchModel.prevImage()
                                        if (alertType < 0) {
                                            showAlert = true
                                        } else if (alertType > 0 && !volumeAlerted) {
                                            showAlert = true
                                            volumeAlerted = true
                                        }

                                    }
                                    else if ((value.location.y - value.startLocation.y) < -swipeThreshold) {
                                        imageTouchModel.imageInfo()
                                    }
                                    else if ((value.location.y - value.startLocation.y) > swipeThreshold) {
                                        imageTouchModel.toggleImage()
                                    }
                                }
                                //currentImage = imagePickerModel.pickedImages[currentImageIndex]
                                dragStartTime = Date(timeIntervalSinceReferenceDate: 0)
                                //self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                                //print(self.newPosition.width)
                                //self.newPosition = self.currentPosition
                            }
                        )
                } else {
                    // Fallback on earlier versions
                }
                    
                /*ForEach(pickedImages,id: \.self){image in
                    GeometryReader{proxy in
                        let size = proxy.size
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .cornerRadius(15)
                    }
                    .padding()
                }*/
            }
            .alert(isPresented: $showAlert) {
                if self.alertType == -1 {
                    return Alert(title: Text("No Photo"),message: Text("Please allow photo access in FeelUS setting."))
                } else if self.alertType == -2 {
                    return Alert(title: Text("No Photo"),message: Text("Please take photos or add selected photos in FeelUS setting."))
                } else if self.alertType == 1 {
                    return Alert(title: Text("Low Volume"),message: Text("You can increase volume to listen voice navigation."))
                } else {
                    return Alert(title: Text("Low Volume"),message: Text("You can increase volume to listen voice navigation and touch sound."))
                }
            }
            /*.frame(height: 450)
            // MARK: SwiftUI Bug
            // If You Dont Have Any Views Inside Tabview
            // It's Crashing, But not in Never
            .tabViewStyle(.page(indexDisplayMode: $imagePickerModel.pickedImages.isEmpty ? .never : .always))
            .navigationTitle("Popup Image Picker")
            .toolbar {
                Button {
                    showPicker.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }*/
        //}
/*        .popupImagePicker(show: $showPicker) { assets in
            // MARK: Do Your Operation With PHAsset
            // I'm Simply Extracting Image
            // .init() Means Exact Size of the Image
            let manager = PHCachingImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            DispatchQueue.global(qos: .userInteractive).async {
                assets.forEach { asset in
                    manager.requestImage(for: asset, targetSize: .init(), contentMode: .default, options: options) { image, _ in
                        guard let image = image else {return}
                        DispatchQueue.main.async {
                            //self.pickedImages.append(image)
                        }
                    }
                }
            }
        }*/
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
