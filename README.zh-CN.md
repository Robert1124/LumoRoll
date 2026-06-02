# LumoRoll

LumoRoll 是一个 iPhone-first 的原生 SwiftUI App，用一张参考照片生成可复用 LUT，也可以把本地 `.cube` LUT 导入成用户自己的「Film Roll」，再用这卷 Film Roll 处理照片，并导出 `.cube` LUT 文件。

产品方向是轻盈、友好、有胶片感、local-first。它不是普通滤镜 App，也不是专业调色套件。

[加入 LumoRoll TestFlight](https://testflight.apple.com/join/bcH5zNCR)

## 当前状态

App 已在 2026-06-01 标记为功能完成。公开发布或 App Store 发布前剩余工作是 release QA、真机 profiling、打包和政策/文案 review，而不是功能实现。

- Xcode project：`LumoRoll.xcodeproj`
- Project definition：`project.yml`
- App target：`LumoRoll`
- Test target：`LumoRollTests`
- 最低系统：iOS 17
- UI：SwiftUI
- 图像处理：Core Image，优先使用 Metal-backed `CIContext`，并保留 fallback context
- 默认 LUT：`33x33x33`
- 媒体范围：仅照片

## 开源边界

这个公开仓库包含原生 App 源码、确定性的 Algorithm V2 LUT 生成路径、测试、设计文档和项目网页源码。

正式 App 可以携带一个私有的本地 Core ML base-LUT predictor。该模型实现、artifact 和 metadata 都不包含在公开仓库中。公开源码构建使用 Algorithm V2 创建 reference-image Film Roll。

## App 功能

- 用一张 reference image，或一个本地 `.cube` LUT 文件，创建一卷 Film Roll。
- 从 Photos 或 Files 导入 reference / target 照片。
- 在设备本地分析 reference image，或解析 `.cube` LUT。
- 在设备本地生成并存储 33x33x33 base LUT。公开源码构建使用确定性的 Algorithm V2；正式构建可以通过单独的私有 release overlay 加入本地 Core ML predictor，并在模型不可用或输出无效时回退到 Algorithm V2。
- reference image 创建的 Film Roll 会保存本地 sample analysis package，包括 sample quality、coverage/confidence、lighting、style 和 render profile seed metadata。
- 保存 Film Roll 前必须由用户命名。
- 在 App 内持久化 Film Roll、reference asset、LUT、处理结果、缩略图和 metadata。
- 首页展示横向反转片 Film Roll 滚轮。
- Film Roll Detail 先展示 reference sample，再展示 processed frames。
- Apply 页面采用先导入 target photo、再预览 intensity，并由用户明确点击 `Save` 或 `Cancel` 的流程。
- 保存输出时，先应用 base LUT，再运行可选的 App 内 adaptive post process，最后根据当前 intensity 混合原图和处理结果。
- 支持把处理结果保存回当前 Film Roll。
- Fullscreen viewer 支持通过系统 Share Sheet 分享 processed output；用户可以在系统分享面板里把渲染后的图片保存到 Photos。
- 支持通过系统文件导出流程导出 Film Roll 的 base LUT `.cube`。sample analysis、confidence、model 和 adaptive metadata 只留在 App 内，不写入 `.cube`。
- Fullscreen viewer 使用深色沉浸式浏览；processed frames 支持 Share、Edit 和 Remove。

当前 App 是 photo-only 和 local-first 的产品形态，不包含视频导入/导出、视频处理、HDR、Log、Display P3 高级流程、iCloud 同步、账号、云处理、联网 AI、搜索、复制 Film Roll，以及独立的 fullscreen Save to Photos 按钮。

## 架构

当前实现分层如下：

- `LumoRoll/App/`：App entry point、root navigation、dependency container、display image store。
- `LumoRoll/Domain/`：models、protocols、use cases。
- `LumoRoll/Processing/`：reference analysis、LUT generation、`.cube` import/export、Core Image rendering、thumbnail、JPEG encoding。
- `LumoRoll/Storage/`：file-backed Film Roll repository、manifest、asset store、asset writer。
- `LumoRoll/SystemIntegrations/`：App-owned path resolution、import staging、local image loading、add-only Photos writing。
- `LumoRoll/DesignSystem/`：SwiftUI theme 和复用视觉组件。
- `LumoRoll/Features/`：Library、Create、Detail、Apply、Fullscreen screens 和 feature models。
- `LumoRollTests/`：各层 unit / boundary tests。
- `web/`：Vite/React 项目网页，包含 GSAP 动效、Remotion teaser source、HyperFrames teaser HTML，以及复制出的网页可用视觉 assets。

Domain protocol 用来隔离 UI、PhotosUI、PhotoKit、storage、rendering 等具体依赖，避免核心 use case 直接绑定系统实现。

## 文档

文档是这个项目的实现契约，不是可选项。

- `doc/README.md`：开发文档索引。
- `design/README.md`：设计文档索引和 prototype 说明。
- `doc/qa/github-release-readiness.md`：公开发布准备和风险说明。

设计相关内容放在 `design/`。开发、架构、算法、组件、隐私和 QA 文档放在 `doc/`。

## 本地开发

修改 `project.yml` 或新增/删除 Swift 文件后，重新生成 Xcode project：

```sh
xcodegen generate
```

在预期模拟器上运行测试：

```sh
xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

构建 App：

```sh
xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

运行项目网页：

```sh
cd web
npm install
npm run dev
```

## 后续方向

后续 hardening 包括内存 profiling、display cache eviction review、崩溃恢复后的临时文件清理 review，以及可选本地模型的 public/private release packaging 检查。

未来候选方向包括 iCloud 同步、视频支持、HDR / Log / Display P3 流程、更高级的肤色和中性灰保护控制、更丰富的模型质量控制、更丰富的 LUT 控制，以及更多整理和分享能力。

## License

源码和文档使用 MIT License。LumoRoll 品牌资产、App icon 和产品图像不允许自由复用；详见 `NOTICE`。
