// 使い方: swift Design/make_icon.swift <出力PNGパス>
// 墨藍の地に、徳利を円と角丸だけで描いた自作の幾何学アイコン（1024px、不透明）。
import AppKit

let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
let info = CGImageAlphaInfo.noneSkipLast.rawValue
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
ctx.setFillColor(color(0.122, 0.165, 0.227)); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
// 座標は上原点で書き、反転して描画する
ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)
let kinari = color(0.969, 0.949, 0.906)
ctx.setFillColor(kinari)
ctx.addPath(CGPath(roundedRect: CGRect(x: 432, y: 150, width: 160, height: 300), cornerWidth: 50, cornerHeight: 50, transform: nil))
ctx.addPath(CGPath(roundedRect: CGRect(x: 392, y: 118, width: 240, height: 64), cornerWidth: 32, cornerHeight: 32, transform: nil))
ctx.addEllipse(in: CGRect(x: 232, y: 340, width: 560, height: 560))
ctx.fillPath()
ctx.setFillColor(color(0.690, 0.235, 0.188))
ctx.fillEllipse(in: CGRect(x: 392, y: 520, width: 240, height: 240))
ctx.setFillColor(color(0.722, 0.592, 0.353))
ctx.fill(CGRect(x: 232, y: 676, width: 560, height: 20))
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
