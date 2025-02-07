//
//  CheckWebContent.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftSoup
import Foundation
import SwiftUICore

func checkWebContent(for webView: WKWebView) {
    guard let currentUrl = webView.url?.absoluteString else {
        videoLinkLists.removeAll()
        imageLinkLists.removeAll()
        imageAltTextLists.removeAll()
        audioLinkLists.removeAll()
        return
    }
    webView.evaluateJavaScript("document.documentElement.outerHTML", completionHandler: { obj, error in
        DispatchQueue(label: "com.darock.WatchBrowser.wt.media-check", qos: .userInitiated).async {
            if let htmlStr = obj as? String {
                let webSuffixList = [".html", ".htm", ".php", ".xhtml"]
                do {
                    let doc = try SwiftSoup.parse(htmlStr)
                    videoLinkLists.removeAll()
                    let videos = try doc.body()?.select("video")
                    if let videos {
                        var srcs = [String]()
                        for video in videos {
                            var src = try video.attr("src")
                            if src.isEmpty, let tagSrc = try? video.select("source") {
                                src = try tagSrc.attr("src")
                            }
                            if !src.isEmpty {
                                if src.hasPrefix("/") {
                                    if currentUrl.split(separator: "/").count < 2 {
                                        continue
                                    }
                                    src = "http://" + currentUrl.split(separator: "/")[1] + src
                                } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                    var currentUrlCopy = currentUrl
                                    if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                        if currentUrlCopy.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                    }
                                    if !currentUrlCopy.hasSuffix("/") {
                                        currentUrlCopy += "/"
                                    }
                                    src = currentUrlCopy + src
                                }
                                srcs.append(src)
                            }
                        }
                        videoLinkLists = srcs
                    }
                    let iframeVideos = try doc.body()?.select("iframe")
                    if let iframeVideos {
                        var srcs = [String]()
                        for video in iframeVideos {
                            var src = try video.attr("src")
                            if src != "" && (src.hasSuffix(".mp4") || src.hasSuffix(".m3u8")) {
                                if src.split(separator: "://").count >= 2 && !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                    src = "https://" + src.split(separator: "://").last!
                                } else if src.hasPrefix("/") {
                                    if currentUrl.split(separator: "/").count < 2 {
                                        continue
                                    }
                                    src = "https://" + currentUrl.split(separator: "/")[1] + src
                                }
                                srcs.append(src)
                            }
                        }
                        videoLinkLists += srcs
                    }
                    let aLinks = try doc.body()?.select("a")
                    if let aLinks {
                        var srcs = [String]()
                        for video in aLinks {
                            var src = try video.attr("href")
                            if src != "" && (src.hasSuffix(".mp4") || src.hasSuffix(".m3u8")) {
                                if src.split(separator: "://").count >= 2 && !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                    src = "https://" + src.split(separator: "://").last!
                                } else if src.hasPrefix("/") {
                                    if currentUrl.split(separator: "/").count < 2 {
                                        continue
                                    }
                                    src = "https://" + currentUrl.split(separator: "/")[1] + src
                                }
                                srcs.append(src)
                            }
                        }
                        videoLinkLists += srcs
                    }
                    let images = try doc.body()?.select("img")
                    if let images {
                        var srcs = [String]()
                        var alts = [String]()
                        for image in images {
                            var src = try image.attr("src")
                            if src != "" {
                                if src.hasPrefix("/") {
                                    if currentUrl.split(separator: "/").count < 2 {
                                        continue
                                    }
                                    src = "http://" + currentUrl.split(separator: "/")[1] + src
                                } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                    var currentUrlCopy = currentUrl
                                    if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                        if currentUrlCopy.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                    }
                                    if !currentUrlCopy.hasSuffix("/") {
                                        currentUrlCopy += "/"
                                    }
                                    src = currentUrlCopy + src
                                }
                                srcs.append(src)
                            }
                            alts.append((try? image.attr("alt")) ?? "")
                        }
                        imageLinkLists = srcs
                        imageAltTextLists = alts
                    }
                    let audios = try doc.body()?.select("audio")
                    if let audios {
                        var srcs = [String]()
                        for audio in audios {
                            var src = try audio.attr("src")
                            if src != "" {
                                if src.hasPrefix("/") {
                                    if currentUrl.split(separator: "/").count < 2 {
                                        continue
                                    }
                                    src = "http://" + currentUrl.split(separator: "/")[1] + src
                                } else if !src.hasPrefix("http://") && !src.hasPrefix("https://") {
                                    var currentUrlCopy = currentUrl
                                    if webSuffixList.contains(where: { element in currentUrlCopy.hasSuffix(element) }) {
                                        if currentUrlCopy.split(separator: "/").count < 2 {
                                            continue
                                        }
                                        currentUrlCopy = currentUrlCopy.components(separatedBy: "/").dropLast().joined(separator: "/")
                                    }
                                    if !currentUrlCopy.hasSuffix("/") {
                                        currentUrlCopy += "/"
                                    }
                                    src = currentUrlCopy + src
                                }
                                srcs.append(src)
                            }
                        }
                        audioLinkLists = srcs
                    }
                } catch {
                    globalErrorHandler(error)
                }
            }
            if currentUrl.contains(/music\..*\.com/) && currentUrl.contains(/(\?|&)id=[0-9]*($|&)/),
               let mid = currentUrl.split(separator: "id=")[from: 1]?.split(separator: "&").first {
                audioLinkLists = ["http://music.\(0b10100011).com/song/media/outer/url?id=\(mid).mp3"]
            }
        }
    })
}
