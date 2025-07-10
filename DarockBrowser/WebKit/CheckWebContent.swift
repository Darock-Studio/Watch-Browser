//
//  CheckWebContent.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import SwiftSoup
import Alamofire
import Foundation
import SwiftUICore
import DarockFoundation

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
            // Optimize for specific websites
            // 10100011 music
            if currentUrl.contains(/music\..*\.com/) && currentUrl.contains(/(\?|&)id=[0-9]*($|&)/),
               let mid = currentUrl.split(separator: "id=")[from: 1]?.split(separator: "&").first {
                audioLinkLists = ["http://music.\(0b10100011).com/song/media/outer/url?id=\(mid).mp3"]
            }
            // TBH I really don't wanna do these things below, but users are gods😇.
            // dilidili
            if currentUrl.contains("bilibili.com/video/BV"),
               let _fbvid = currentUrl.split(separator: "bilibili.com/video/", maxSplits: 1).last,
               let bvid = _fbvid.split(separator: "/", maxSplits: 1).first {
                let headers: HTTPHeaders = [
                    "User-Agent": "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                ]
                requestJSON("https://api.bilibili.com/x/web-interface/view?bvid=\(bvid)", headers: headers) { respJson, isSuccess in
                    if isSuccess {
                        guard (respJson["code"].int ?? 0) == 0 else { return }
                        let cid = respJson["data"]["pages"][0]["cid"].int64!
                        requestJSON("https://api.bilibili.com/x/player/playurl?bvid=\(bvid)&cid=\(cid)&platform=html5", headers: headers) { respJson, isSuccess in
                            if isSuccess {
                                guard (respJson["code"].int ?? 0) == 0 else { return }
                                let videoLink = respJson["data"]["durl"][0]["url"].string!.replacingOccurrences(of: "\\u0026", with: "&")
                                videoLinkLists.insert(videoLink, at: 0)
                            }
                        }
                    }
                }
            }
        }
    })
}
