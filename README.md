# 📦 Staxa

**Staxa** is a lightweight UIKit SDK that brings **declarative**, **composable**, and **builder-pattern-inspired** view construction to iOS development. Think of it as UIKit with a touch of SwiftUI’s elegance — powered by stacked views, block-based APIs, and clean layout composition.

## ✨ Features

- ✅ Declarative UIKit syntax with builder-style chaining  
- 📐 Auto layout-friendly, with built-in safe area handling  
- 🧱 Modular view composition using `BuildableView`  
- 💡 SwiftUI-inspired layout with `VStack`, `HStack`, `ZStack` equivalents  
- 🔄 Built-in Combine support for event-driven views  

## 📸 Preview

```swift
let view = UIView()
    .backgroundColor(.red)
    .alpha(0.5)
    .cornerRadius(16)
    .onTapGesture {
        print("Tapped!")
    }
```

## 🚀 Installation

📦 **Manual**
1. Add package dependencies to your xcodeproj using SPM.
2. import Staxa
3. Done!

Note: Carthage and CocoaPods support coming soon.

## 🧱 Core Concepts

🧩 **StaxaView**

A protocol that unlocks a builder-style API for UIKit views.

```swift
extension UIView: BuildableView {}

let button = UIButton()
    .attributedTitle(NSAttributedString(string: "Tap Me"))
    .cornerRadius(8)
```

🧱 **StaxaViewController**

A base UIViewController with a body property for clean declarative layout.

```swift
class ProfileVC: StaxaViewController {
    override var body: UIView {
        VStackView {
            UIImageView()
                .image(UIImage(named: "avatar"))
            UILabel()
                .text("Welcome")
                .font(.boldSystemFont(ofSize: 24))
        }
        .padding(20)
    }
}
```

## 📐 Layout Building DSL

VStackView, HStackView, ZStackView

These are custom stack views that mimic SwiftUI:

```swift
VStackView(spacing: 8) {
    UILabel()
      .text("Line 1")
    UILabel()
      .text("Line 2")
}
.padding(16)
```

## 💡 Example
```swift
class HomeViewController: StaxaViewController {
    override var body: UIView {
        VStackView {
            ToolbarView(title: "Home")
            CountdownView()
            UIButton(title: "Get Started") {
                print("Tapped Start")
            }
        }
        .spacing(16)
        .padding(24)
    }
}
```

## 🛠 Requirements
• iOS 13+
• Swift 5.5+
• Xcode 13+

## 👨‍💻 Author

Built with ❤️ by Jacob, Vicky & Irvan.
Inspired by SwiftUI, powered by UIKit.

## 📄 License

Let me know if you want:
  
- A "Contributing" section for open source projects  

Happy shipping with **Staxa**!
