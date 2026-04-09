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
        let key = press.characters
        if key.isEmpty { return }

        // 初回のみキーに画像をマップ
        if keyMap[key] == nil {
            keyMap[key] = availableImages.randomElement()
        }

        guard let imageName = keyMap[key],
              let stampImage = loadImage(named: imageName) else { return }

        // ランダムな座標を決定（キャンバスサイズ内）
        let randomX = CGFloat.random(in: stampSize.width...(canvasSize.width - stampSize.width))
        let randomY = CGFloat.random(in: stampSize.height...(canvasSize.height - stampSize.height))
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
    private func createEmptyImage(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.set()
        NSMakeRect(0, 0, size.width, size.height).fill()
        image.unlockFocus()
        return image
    }

    // プレースホルダー用の色付き矩形画像を生成する
    private func makePlaceholderImage(name: String, size: CGSize) -> NSImage {
        let colors: [String: NSColor] = [
            "figure_a": .systemRed,
            "figure_b": .systemBlue,
            "figure_c": .systemGreen,
            "figure_d": .systemYellow
        ]
        let color = colors[name] ?? .systemGray
        let image = NSImage(size: size)
        image.lockFocus()
        color.withAlphaComponent(0.8).set()
        NSMakeRect(0, 0, size.width, size.height).fill()
        // 画像名のラベルを描画してどのキーに対応するかを判別しやすくする
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
        image.unlockFocus()
        return image
    }

    // 6. 画像に画像を上書き描画して、新しいNSImageを返す関数（ここが肝）
    private func drawImageOnImage(baseImage: NSImage, imageToDraw: NSImage, inRect rect: CGRect) -> NSImage {
        // ベース画像のコピーを作成（直接変更を避けるため推奨されるパターン）
        let newImage = baseImage.copy() as! NSImage

        newImage.lockFocus() // 描画フォーカスを開始

        // NSImageをCGImageに変換して描画
        imageToDraw.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        newImage.unlockFocus() // 描画フォーカスを終了

        return newImage // 新しい状態として返す
    }
}
