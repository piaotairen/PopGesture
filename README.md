# FullscreenPopGesture
侧滑手势返回，解决自定义导航栏无手势返回的问题。

# 使用
* Swift 4 中 `initialze` 方法被禁用，需在 `application(_:didFinishLaunchingWithOptions:)` 方法中调用 `FullscreenPopGesture.configuration()` 来启用 Method swizzling。

``` swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 启用
        FullscreenPopGesture.configuration()
        
        return true
    }
```

* 跳转至有 **UIScrollView** 的控制器时,需要在 **UIScrollView** 内部完成返回手势,只需如下设置:

``` swift
scrollView.scrollViewPopGestureRecognizerEnable = true
```

- 本库实现无代码全局设置侧滑返回，如需取消界面侧滑返回手势，则在该界面的视图控制器中添加如下代码：

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加以禁用侧滑返回 仅该界面有效
        interactivePopDisabled = true
    }
```

# CocoaPods 安装

``` ruby
pod 'FullscreenPopGesture'
```
