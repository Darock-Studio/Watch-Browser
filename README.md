# 暗礁浏览器
这里是暗礁浏览器开源项目，App Store 版本直接由此源代码编译。

## 代码注意事项
即使能够通过 `Dynamic` 库调用任何私有 API，也不应该使用其来调用私有 API。

在通过 `Dynamic` 引入任何一个新 API 前，请检查：
1. 此 API 能够在 [Apple 开发者网页](https://developer.apple.com) 上找到相应文档。
2. 此 API 所属的 Framework 应处于 OS 运行时资源库目录的 `Frameworks` 而不是 `PrivateFrameworks` 文件夹下。

另外，App 必须遵守 **App 审核指南**
