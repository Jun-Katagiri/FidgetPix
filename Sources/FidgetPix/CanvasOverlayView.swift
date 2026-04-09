import SwiftUI
import AppKit

struct CanvasOverlayView: View {
    // 1. キーと画像名の対応表
    @State private var keyMap: [String: String] = [:]

    // 2. すべての描画が焼き付けられる、ベースとなる一枚の画像
    @State private var canvasImage: NSImage?

    // 3. 利用可能な画像セット（Assets.xcassetsの画像名 / フォールバックとして色付き矩形を使用）
    let availableImages = ["figure_a", "figure_b", "figure_c", "figure_d"]

    // キャンバスの初期サイズ
    let canvasSize = CGSize(width: 2000, height: 1500)
    let stampSize = CGSize(width: 150, height: 150)

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.white // 背景色

                // 4. キャンバス画像が存在すれば表示する
                if let image = canvasImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
        let key = press.characters
        if key.isEmpty { return }

        // 初回のみキーに画像をマップ
        if keyMap[key] == nil {
            keyMap[key] = availableImages.randomElement()
        }

        guard let imageName = keyMap[key],
              let stampImage = loadImage(named: imageName) else { return }

        // ランダムな座標を決定（スタンプがキャンバス内に収まるよう上下限を設定）
        let randomX = CGFloat.random(in: 0...(canvasSize.width - stampSize.width))
        let randomY = CGFloat.random(in: 0...(canvasSize.height - stampSize.height))
        let rect = CGRect(origin: CGPoint(x: randomX, y: randomY), size: stampSize)

        // 5. 現在のキャンバスに画像を焼き付ける
        if let currentCanvas = canvasImage {
            canvasImage = drawImageOnImage(baseImage: currentCanvas, imageToDraw: stampImage, inRect: rect)
        }
    }

    // 画像をAssets.xcassetsから読み込む。存在しない場合はプレースホルダーを生成する
    private func loadImage(named name: String) -> NSImage? {
        if let asset = NSImage(named: name) {
            return asset
        }
        // アセットが見つからない場合、識別しやすい色付き矩形をプレースホルダーとして使用する
        return makePlaceholderImage(name: name, size: stampSize)
    }

    // 真っ白なNSImageを作成するユーティリティ
    private func createEmptyImage(size: CGSize) -> NSImage? {
        guard let context = makeBitmapContext(size: size) else { return nil }
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }

    // プレースホルダー用の色付き矩形画像を生成する
    private func makePlaceholderImage(name: String, size: CGSize) -> NSImage? {
        let colors: [String: NSColor] = [
            "figure_a": .systemRed,
            "figure_b": .systemBlue,
            "figure_c": .systemGreen,
            "figure_d": .systemYellow
        ]
        let color = colors[name] ?? .systemGray
        guard let context = makeBitmapContext(size: size) else { return nil }

        // 背景色を塗りつぶす
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // 画像名のラベルをCGContextを通じてNSGraphicsContextで描画する
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        let label = name as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 24)
        ]
        let labelSize = label.size(withAttributes: attrs)
        let labelRect = CGRect(
            x: (size.width - labelSize.width) / 2,
            y: (size.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        label.draw(in: labelRect, withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()

        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }

    // 6. 画像に画像を上書き描画して、新しいNSImageを返す関数（ここが肝）
    private func drawImageOnImage(baseImage: NSImage, imageToDraw: NSImage, inRect rect: CGRect) -> NSImage {
        let size = baseImage.size
        guard let context = makeBitmapContext(size: size) else { return baseImage }

        // ベース画像を描画（変換失敗時はベース画像をそのまま返す）
        if let cgBase = baseImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgBase, in: CGRect(origin: .zero, size: size))
        } else {
            return baseImage
        }

        // スタンプ画像を指定位置に描画（上書き）。変換失敗時はベース画像をそのまま返す
        if let cgStamp = imageToDraw.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgStamp, in: rect)
        } else {
            return baseImage
        }

        guard let cgResult = context.makeImage() else { return baseImage }
        return NSImage(cgImage: cgResult, size: size)
    }

    // ビットマップCGContextを生成するユーティリティ
    private func makeBitmapContext(size: CGSize) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        return CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
}
