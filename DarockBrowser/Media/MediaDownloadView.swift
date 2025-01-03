//
//  MediaDownloadView.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/25.
//

import SwiftUI
import Alamofire
import AVFoundation
import DarockFoundation

struct MediaDownloadView: View {
    @Binding var mediaLink: String
    var mediaTypeName: LocalizedStringResource
    var saveFolderName: String
    @Binding var saveFileName: String?
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("DLIsFeedbackWhenFinish") var isFeedbackWhenFinish = false
    @State var downloadProgress = ValuedProgress(completedUnitCount: 0, totalUnitCount: 0)
    @State var isFinishedDownload = false
    @State var isTerminateDownloadingAlertPresented = false
    @State var errorText = ""
    @State var m3u8DownloadObservation: NSKeyValueObservation?
    @State var m3u8DownloadTimer: Timer?
    @State var m3u8DownloadedSize = 0.0
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !isFinishedDownload {
                        VStack {
                            Text("正在下载...")
                                .font(.system(size: 20, weight: .bold))
                            if mediaLink.hasSuffix(".m3u8"), #available(watchOS 10, *) {
                                ProgressView()
                                Text("已下载 \(m3u8DownloadedSize ~ 2)MB")
                            } else {
                                ProgressView(value: Double(downloadProgress.completedUnitCount), total: Double(downloadProgress.totalUnitCount))
                                Text("\((Double(downloadProgress.completedUnitCount) / Double(downloadProgress.totalUnitCount) * 100) ~ 2)%")
                                Text("\((Double(downloadProgress.completedUnitCount) / 1024 / 1024) ~ 2)MB / \((Double(downloadProgress.totalUnitCount) / 1024 / 1024) ~ 2)MB")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                if let eta = downloadProgress.estimatedTimeRemaining {
                                    Text("预计时间：\(Int(eta))s")
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("下载已完成")
                            Spacer()
                        }
                    }
                }
                if mediaLink.hasSuffix(".m3u8") && !isFinishedDownload, #available(watchOS 10, *) {
                    Text("正在下载 M3U8 媒体，这可能需要较长时间，且暗礁浏览器无法报告进度。")
                    Text("如果下载大小长时间未变化，说明此 M3U8 视频无法被下载。")
                }
                if !errorText.isEmpty {
                    Section {
                        Text(errorText)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("下载\(String(localized: mediaTypeName))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if !isFinishedDownload {
                            isTerminateDownloadingAlertPresented = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
            }
            .alert("未完成的下载", isPresented: $isTerminateDownloadingAlertPresented, actions: {
                Button(role: .destructive, action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("退出")
                })
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("取消")
                })
            }, message: {
                Text("退出下载页将中断下载\n确定吗？")
            })
        }
        .onAppear {
            do {
                if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)") {
                    try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)", withIntermediateDirectories: true)
                }
                if mediaLink.hasSuffix(".m3u8"), #available(watchOS 10, *) {
                    let configuration = URLSessionConfiguration.background(withIdentifier: "com.darock.WatchBrowser.download.m3u8")
                    let session = AVAssetDownloadURLSession(
                        configuration: configuration,
                        assetDownloadDelegate: M3U8DownloadDelegate.shared,
                        delegateQueue: .main
                    )
                    let asset = AVURLAsset(url: URL(string: mediaLink)!)
                    let downloadTask = session.makeAssetDownloadTask(downloadConfiguration: .init(asset: asset, title: ""))
                    M3U8DownloadDelegate.shared.finishDownloadingHandler = { _, _, location in
                        print(location)
                        do {
                            if let saveFileName {
                                if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")) {
                                    try FileManager.default.moveItem(atPath: location.path, toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")
                                } else {
                                    var duplicateMarkNum = 1
                                    while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))") {
                                        duplicateMarkNum++
                                    }
                                    try FileManager.default.moveItem(atPath: location.path, toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName) (\(duplicateMarkNum))")
                                }
                            } else {
                                if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg")) {
                                    try FileManager.default.moveItem(
                                        atPath: location.path,
                                        toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])).movpkg"
                                    )
                                } else {
                                    var duplicateMarkNum = 1
                                    while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])) (\(duplicateMarkNum)).movpkg") {
                                        duplicateMarkNum++
                                    }
                                    try FileManager.default.moveItem(
                                        atPath: location.path,
                                        toPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: ".")[0])) (\(duplicateMarkNum)).movpkg"
                                    )
                                }
                            }
                            isFinishedDownload = true
                            if isFeedbackWhenFinish {
                                WKInterfaceDevice.current().play(.success)
                            }
                        } catch {
                            errorText = String(localized: "下载时出错：") + error.localizedDescription
                            if isFeedbackWhenFinish {
                                WKInterfaceDevice.current().play(.failure)
                            }
                            globalErrorHandler(error)
                        }
                    }
                    downloadTask.priority = 1.0
                    
                    let libFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library")
                    var libMediaFolderName = ""
                    for file in libFiles where file.hasPrefix("com.apple.UserManagedAssets.") {
                        libMediaFolderName = file
                        break
                    }
                    if !libMediaFolderName.isEmpty {
                        let previousFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)")
                        m3u8DownloadTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                            do {
                                let currentFiles = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)")
                                if _fastPath(currentFiles.count > previousFiles.count) {
                                    if let newFlie = currentFiles.filter({ !previousFiles.contains($0) }).first {
                                        let newFileSize = Double(try folderSize(
                                            atPath: NSHomeDirectory() + "/Library/\(libMediaFolderName)/\(newFlie)"
                                        ) ?? 0) / 1024.0 / 1024.0
                                        m3u8DownloadedSize = newFileSize
                                    }
                                }
                            } catch {
                                // Don't insert globalErrorHandler because it's in a timer.
                                print(error)
                            }
                        }
                    }
                    
                    downloadTask.resume()
                    m3u8DownloadObservation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                        downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                          totalUnitCount: progress.totalUnitCount,
                                                          estimatedTimeRemaining: progress.estimatedTimeRemaining)
                    }
                } else {
                    let destination: DownloadRequest.Destination = { _, _ in
                        if let saveFileName {
                            if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)")) {
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(saveFileName)"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            } else {
                                var duplicateMarkNum = 1
                                var desamedNames = saveFileName.split(separator: ".")
                                if let lastComponent = desamedNames[from: desamedNames.count - 2] {
                                    desamedNames[desamedNames.count - 2] = lastComponent + " (\(duplicateMarkNum))"
                                } else {
                                    desamedNames[desamedNames.count - 1] += " (\(duplicateMarkNum))"
                                }
                                while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(desamedNames.joined(separator: "."))") {
                                    duplicateMarkNum++
                                    if let lastComponent = desamedNames[from: desamedNames.count - 2] {
                                        desamedNames[desamedNames.count - 2] = lastComponent + " (\(duplicateMarkNum))"
                                    } else {
                                        desamedNames[desamedNames.count - 1] += " (\(duplicateMarkNum))"
                                    }
                                }
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(desamedNames.joined(separator: "."))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            }
                        } else {
                            if _fastPath(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0]))")) {
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(String(mediaLink.split(separator: "/").last!.split(separator: "?")[0]))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            } else {
                                var duplicateMarkNum = 1
                                var desamedNames = mediaLink.split(separator: "/").last!.split(separator: "?")[0].split(separator: ".")
                                if let lastComponent = desamedNames[from: desamedNames.count - 2] {
                                    desamedNames[desamedNames.count - 2] = lastComponent + " (\(duplicateMarkNum))"
                                } else {
                                    desamedNames[desamedNames.count - 1] += " (\(duplicateMarkNum))"
                                }
                                while FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(desamedNames.joined(separator: "."))") {
                                    duplicateMarkNum++
                                    if let lastComponent = desamedNames[from: desamedNames.count - 2] {
                                        desamedNames[desamedNames.count - 2] = lastComponent + " (\(duplicateMarkNum))"
                                    } else {
                                        desamedNames[desamedNames.count - 1] += " (\(duplicateMarkNum))"
                                    }
                                }
                                return (URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(saveFolderName)/\(desamedNames.joined(separator: "."))"),
                                        [.removePreviousFile, .createIntermediateDirectories])
                            }
                        }
                    }
                    AF.download(mediaLink, to: destination)
                        .downloadProgress { progress in
                            downloadProgress = ValuedProgress(completedUnitCount: progress.completedUnitCount,
                                                              totalUnitCount: progress.totalUnitCount,
                                                              estimatedTimeRemaining: progress.estimatedTimeRemaining)
                        }
                        .response { result in
                            if result.error == nil, let filePath = result.fileURL?.path {
                                debugPrint(filePath)
                                isFinishedDownload = true
                                if isFeedbackWhenFinish {
                                    WKInterfaceDevice.current().play(.success)
                                }
                            } else {
                                if let et = result.error?.localizedDescription {
                                    errorText = String(localized: "下载时出错：") + et
                                }
                                if isFeedbackWhenFinish {
                                    WKInterfaceDevice.current().play(.failure)
                                }
                            }
                        }
                }
            } catch {
                globalErrorHandler(error)
            }
        }
        .onDisappear {
            m3u8DownloadObservation?.invalidate()
            m3u8DownloadTimer?.invalidate()
        }
    }
    
    func folderSize(atPath path: String) throws -> UInt64? {
        let fileManager = FileManager.default
        guard let files = fileManager.enumerator(atPath: path) else {
            return nil
        }
        
        var totalSize: UInt64 = 0
        
        for case let file as String in files {
            let filePath = "\(path)/\(file)"
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? UInt64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}

struct ValuedProgress {
    var completedUnitCount: Int64
    var totalUnitCount: Int64
    var estimatedTimeRemaining: TimeInterval?
}

@available(watchOS 10.0, *)
private final class M3U8DownloadDelegate: NSObject, AVAssetDownloadDelegate {
    static let shared = M3U8DownloadDelegate(finishDownloadingHandler: { _, _, _ in })
    
    var finishDownloadingHandler: (URLSession, AVAssetDownloadTask, URL) -> Void
    
    init(finishDownloadingHandler: @escaping (URLSession, AVAssetDownloadTask, URL) -> Void) {
        self.finishDownloadingHandler = finishDownloadingHandler
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        finishDownloadingHandler(session, assetDownloadTask, location)
    }
}
