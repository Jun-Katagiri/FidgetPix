//
//  ContentView.swift
//  FidgetPix
//
//  Created by Jun Katagiri on 2026/04/09.
//

import SwiftUI
import AppKit

struct CanvasOverlayView: View {
    // キーと画像名の対応表
    @State private var keyMap: [String: String] = [:]
    
    // すべての描画が焼き付けられる、ベースとなる一枚の画像
    @State private var canvasImage: NSImage?
    
    // 利用可能な画像セット（Assets.xcassetsの画像名）
    let availableImages = ["figure_a", "figure_b", "figure_c", "figure_d"]
    
    // キャンバスの初期サイズ（大きめに設定）
    let canvasSize = CGSize(width: 2000, height: 1500)
    let stampSize = CGSize(width: 150, height: 150)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white // 背景色

                // キャンバス画像が存在すれば表示する
                if let image = canvasImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .focusable()
            // macOS 14+ のキー入力キャプチャ
            .onKeyPress { press in
                handleKeyPress(press)
                return .handled
            }
            // 初期化時に真っ白なキャンバスを作成
            .onAppear {
                if canvasImage == nil {
                    canvasImage = createEmptyImage(size: canvasSize)
                }
            }
        }
        // ウィンドウの初期サイズ
        .frame(minWidth: 1000, minHeight: 800)
    }

    // --- ロジック部 ---

    private func handleKeyPress(_ press: KeyPress) {
        // Deleteキーでキャンバスをクリア
        if press.key == .delete || press.key == .deleteForward {
            canvasImage = createEmptyImage(size: canvasSize)
            return
        }

        let key = press.characters
        if key.isEmpty { return }

        // 初回のみキーに画像をマップ
        if keyMap[key] == nil {
            keyMap[key] = availableImages.randomElement()
        }
        
        guard let imageName = keyMap[key],
              let stampImage = NSImage(named: imageName) else { return }
        
        // ランダムな座標を決定（キャンバスサイズ内）
        let randomX = CGFloat.random(in: stampSize.width...(canvasSize.width - stampSize.width))
        let randomY = CGFloat.random(in: stampSize.height...(canvasSize.height - stampSize.height))
        let rect = CGRect(origin: CGPoint(x: randomX, y: randomY), size: stampSize)
        
        // 現在のキャンバスに画像を焼き付ける
        if let currentCanvas = canvasImage {
            canvasImage = drawImageOnImage(baseImage: currentCanvas, imageToDraw: stampImage, inRect: rect)
        }
    }

    // 真っ白なNSImageを作成するユーティリティ
    private func createEmptyImage(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.set()
        NSMakeRect(0, 0, size.width, size.height).fill()
        image.unlockFocus()
        return image
    }

    // 画像に画像を上書き描画して、新しいNSImageを返す関数
    private func drawImageOnImage(baseImage: NSImage, imageToDraw: NSImage, inRect rect: CGRect) -> NSImage {
        let newImage = baseImage.copy() as! NSImage
        
        newImage.lockFocus()
        
        if let context = NSGraphicsContext.current?.cgContext {
            context.setAlpha(0.8)
            imageToDraw.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        newImage.unlockFocus()
        
        return newImage
    }
}

#Preview {
    CanvasOverlayView()
}
