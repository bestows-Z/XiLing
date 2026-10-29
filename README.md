<p align="center"><img src="assets/icons/xiling.svg" width="90" alt="汐灵原创海浪图标"></p>
<h1 align="center">汐灵 XiLing</h1>
<p align="center"><strong>把一点海风，留在你的桌面。</strong></p>
<p align="center">免费开源的 Godot 2D 桌宠 · 小汐 · 本地行为与情绪 · 可替换角色动画</p>
<p align="center">
  <a href="https://github.com/bestows-Z/XiLing/releases"><img src="https://img.shields.io/badge/Release-候选构建阶段-168aad" alt="当前没有稳定安装包"></a>
  <img src="https://img.shields.io/badge/Source-0.3.0--dev-478cbf" alt="源码开发版本">
  <a href="https://github.com/bestows-Z/XiLing/actions/workflows/checks.yml"><img src="https://github.com/bestows-Z/XiLing/actions/workflows/checks.yml/badge.svg" alt="Godot检查"></a>
  <a href="https://github.com/bestows-Z/XiLing/stargazers"><img src="https://img.shields.io/github/stars/bestows-Z/XiLing?color=f4b942" alt="Stars"></a>
  <a href="https://github.com/bestows-Z/XiLing/issues"><img src="https://img.shields.io/github/issues/bestows-Z/XiLing?color=8b80c7" alt="Issues"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4f86c6" alt="MIT"></a>
  <img src="https://img.shields.io/badge/Targets-Windows%20%7C%20macOS%20%7C%20Linux-7c8a97" alt="目标平台，不代表全部验收">
</p>
<p align="center"><a href="#开始陪伴">开始陪伴</a> · <a href="#操作与玩法">操作与玩法</a> · <a href="#平台状态">平台状态</a> · <a href="CONTRIBUTING.md">参与贡献</a> · <a href="https://github.com/bestows-Z/XiLing/issues">反馈问题</a></p>

小汐是非官方原创海洋主题角色。汐灵使用 Godot 4.7.2 与 GDScript，实现透明桌面窗口、本地行为评分、情绪与互动，不包含聊天、LLM、语音或联网 Agent，也不使用 Flutter。

**本机有原始 `assets/pet/xiaoxi.png` 时默认显示你的鲸鱼娘立绘。** 原画保留眨眼、呼吸、漂浮和整体互动反馈，不会自动变成有肢体动画的人物。精绘立绘的抬手、弯腿仍需要对应动画素材。开源仓库不发布原始 AI PNG；缺少它们时启动可交互的程序绘制兼容演示角色。

## 能玩到什么

| 系统 | 已实现内容 |
| --- | --- |
| 桌面窗口 | 透明、无边框、置顶开关、拖动、屏幕边界恢复、窗口位置记忆和 60%–150% 缩放 |
| 互动 | 单击、双击、右键菜单、鼠标来回抚摸、连续点击惊讶、拖动反馈、喂食 |
| 趣味玩法 | 20 秒泡泡小游戏：点击得分、自动补充目标、到时结束，也可随时主动退出；爱心反馈 |
| 行为 | 按精力、心情、无聊、好奇心、性格和时间段评分；动作历史/冷却避免重复；长时间无人互动时降低频率 |
| 情绪 | 心情、精力、无聊、亲密度与好奇心均限制在 0–100；不累计离线惩罚，亲密度不因离开而下降 |
| 设置 | 缩放、置顶、动画播放、最大帧率、自主活动、主动提示、夜间安静、角色配置及恢复默认 |
| 存档 | 保存设置、位置、情绪和互动计数；原子替换、有效备份、损坏回退；保存失败可继续运行 |
| 控制入口 | macOS/Windows 状态图标菜单；窗口内菜单常驻退出入口；不支持托盘时只能隐藏 10 秒，随后自动显示 |
| 角色接口 | `Resource` 配置角色名称、可选图片/动画路径、表情映射、性格、动画参数；提供两个可加载示例，尚非插件系统 |

### 动画的实际范围

独立的 `PetAnimationController` 支持三种表现来源：本地原画两帧、Godot 绘制的关节演示、用户有权使用的 `SpriteFrames`。多帧皮肤按相对帧时长、循环设置和行为时长播放。

兼容演示实现 22 类姿态状态：待机、挥手、跳跃、跳舞、睡眠、好奇、拖动、进食、抚摸、张望、开心、生气表情、惊讶、害羞、下蹲、起跳、落地、原地行走、转身示意、坐下、打哈欠、苏醒；另外保留随机眨眼和独立呼吸。抬臂、肘与膝盖的位置会独立变化。转身目前是正面身体朝向示意，没有背面精绘素材。

这些动作**不等于原始鲸鱼娘已拥有精绘肢体动画**。原画模式下的行为仍会改变内部情绪、显示文字并产生玩法/互动反馈，肢体姿态需通过合法动画皮肤补齐。兼容演示用于验证动作和接口，不替代精致人物美术。

## 真实界面预览

<p align="center"><img src="assets/screenshots/settings.png" width="300" alt="Godot实际运行的设置界面"></p>
<p align="center"><sub>本机 Godot GPU 实际渲染的设置界面；截图不包含仅限本地保留的原始人物图片。</sub></p>

## 开始陪伴

当前以源码和候选构建为主，没有已验收的稳定安装包。可以[下载源码 ZIP](https://github.com/bestows-Z/XiLing/archive/refs/heads/main.zip)，或：

```bash
git clone https://github.com/bestows-Z/XiLing.git
cd XiLing
godot --path .
```

安装 [Godot 4.7.2 标准版](https://godotengine.org/download/)，在项目管理器导入 `project.godot`，按 **F5** 运行即可。无需 .NET。macOS 若没有命令行别名，可运行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

使用本地原画时，将你有权使用的睁眼和闭眼图片分别放在 `assets/pet/xiaoxi.png`、`assets/pet/xiaoxi_blink.png`；这些文件不会提交仓库，也不会被公开导出预设打包。无需这些图片也能启动。

## 操作与玩法

| 操作 | 效果 |
| --- | --- |
| 左键轻点角色 | 短暂等待双击判定后摸摸 |
| 双击角色 | 挥手反馈 |
| 左键按住并移动 | 拖动窗口，优先于其他动作 |
| 在角色上来回移动鼠标 | 达到抚摸距离和换向阈值后摸摸，有冷却 |
| 连续快速点击 | 惊讶反馈，不扣亲密度 |
| 右键 / `M` | 互动与设置菜单 |
| `Space` | 跳跃；原画为整体反馈，演示/合法多帧皮肤可有真实关节动作 |
| `F` / `D` / `S` | 投喂 / 跳舞 / 睡或醒 |
| `B` | 开始或结束 20 秒泡泡游戏，左键点泡泡得分 |
| `A` | 开关自主行为 |
| `Esc` | 优先结束玩法，其次关闭菜单；无玩法/菜单时打开控制入口 |
| `H` | 操作提示 |

快捷键需要桌宠窗口获得焦点。macOS 菜单栏或 Windows 状态图标提供显示、隐藏、设置及退出；X11 等无可用状态图标时，隐藏按钮会明确显示“隐藏10秒”。Wayland 禁用该按钮，请使用系统窗口控制或 XWayland。没有音效，因此没有无效音量控件。

## 平台状态

| 环境 | 实际状态 |
| --- | --- |
| macOS Apple Silicon | Godot 4.7.2 导入、解析、核心测试和 GPU 界面渲染通过；原生 API 确认透明、无边框、置顶标志、状态图标矩形、越界恢复、125% 缩放及无托盘隐藏/自动恢复。完整真实鼠标/下层应用穿透验收仍需补齐 |
| macOS Intel | 共享源码；未实机运行。未签名、未公证，不能当作已获苹果认证 |
| Windows x64 | 已在 macOS 使用官方 Windows 模板导出候选程序；未在 Windows 运行，不代表透明、拖动、托盘或穿透已通过 |
| Linux X11 x64 | 目标平台；尚无本地 Linux 桌面实机结果，合成器与显卡驱动会影响透明窗口 |
| Linux Wayland | 已知降级：程序定位、置顶与轮廓穿透不能保证；使用支持的原生拖动入口。隐藏按钮禁用，使用系统窗口控制或 XWayland |

Wayland 用户可在提供 XWayland 的环境尝试：

```bash
godot --display-driver x11 --path .
```

API 支持边界参考 [Godot DisplayServer](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)、[Window](https://docs.godotengine.org/en/stable/classes/class_window.html) 与 [StatusIndicator](https://docs.godotengine.org/en/stable/classes/class_statusindicator.html) 官方文档；Linux 状态图标当前没有实现。源码逻辑的坐标/缩放测试不等于跨 DPI 多显示器设备验收，该项仍未覆盖真实多显示器组合。

### 鼠标穿透边界

图片模式使用当前帧 Alpha 命中和 BitMap 轮廓；演示角色使用绘制几何命中。隐藏采用停止绘制并设置窗外输入区域，不调用 Godot 主窗口不支持的 `hide()`；无托盘时 10 秒后恢复已在本机实际等待验证。系统只接收一个外包轮廓，因此肢体、发丝间的少量透明空隙仍可能拦截鼠标。提示与泡泡会扩大输入轮廓，菜单打开及拖动期间整窗接收输入。Windows 会裁掉系统轮廓外的绘制内容，特效目标均纳入轮廓。不是逐像素无限精度的系统穿透。

## 存档与角色资源

状态在 Godot `user://pet_state.cfg`，备份为 `.bak`。保存情绪、互动计数、角色/皮肤选择、设置和窗口坐标；首次运行或损坏且无有效备份时使用默认值。没有账号、密钥或云端同步依赖。

`characters/xiaoxi.tres` 是原画优先配置，`characters/demo.tres` 是不依赖图片的性格示例。核心行为只消费角色性格和动作状态，不直接引用小汐的 PNG 路径。

自定义逐帧皮肤可保存到 `assets/local/skin.tres`，至少有非空 `idle` 动画。可追加与动作状态同名的动画；缺少/空的可选动作回退 `idle`。菜单选择“本地动画皮肤”启用，该目录不提交；也可以在角色资源中指定其他合法素材路径。只有两张睁眼/闭眼图无法补出抬手、弯腿帧。

## 开发与测试

```text
scenes/main.tscn                  Main → Pet
characters/*.tres                可配置角色示例
scripts/pet_idle.gd               场景协调
scripts/pet_animation_controller.gd  表现播放与眨眼
scripts/pose_library.gd           22 类演示姿态
scripts/pet_visual.gd             关节演示绘制与几何命中
scripts/local_skin.gd             原画/多帧皮肤与 Alpha 命中
scripts/pet_brain.gd              评分、状态、优先级、冷却
scripts/pet_mood.gd               情绪数值与互动变化
scripts/pet_interaction.gd        点击/抚摸手势
scripts/pet_effects.gd            泡泡玩法和爱心
scripts/desktop_window.gd        窗口、拖动、边界、穿透
scripts/desktop_controls.gd      托盘与显示/隐藏恢复
scripts/pet_settings.gd          设置校验
scripts/pet_runtime.gd           角色、统计及状态组合
scripts/save_manager.gd          存档、备份与损坏恢复
tests/                           可重复运行的测试
tools/                           检查入口与仓库审计
```

```bash
python3 tools/check.py
python3 tools/repository_check.py
```

也可手动运行 Godot `--headless --path . --editor --quit`，再逐个运行 `--script tests/*_tests.gd`。统一检查会检查错误输出，避免引擎退出码为零却漏掉解析/运行错误。

2026-10-29 本机实测：动画控制 7 项、行为 26 项、本机皮肤 21 项 / 干净仓库 23 项、本机场景 34 项 / 干净仓库 33 项、设置/存储/互动/玩法 30 项，以及 22 × 21 组姿态检查通过。Headless 无法证明桌面鼠标穿透、系统拖动和不同操作系统 UI 兼容，范围以上表为准。

## 候选构建与发布

- `Godot checks` 在推送/PR 时验证干净源码的导入、解析、测试及提交文件边界。
- `Candidate builds` 手动执行，使用官方 Godot 4.7.2 引擎和模板，导出 Windows x64、Linux x64、macOS universal 未签名候选产物，附 `SHA256SUMS.txt`。
- 默认只保存 Actions artifact。只有维护者明确填写 `v0.3.0-rc.N` 才创建 **prerelease**；不自动发布稳定版。CI 导出成功也不等于该平台桌面验收通过。
- 本机只安装了 Windows 模板；Linux/macOS 候选依赖 CI 的官方模板下载。工作流首次结果应查看 [Actions](https://github.com/bestows-Z/XiLing/actions)，不要把“已配置”误认为“已成功运行”。

候选没有 Developer ID 签名、苹果公证或 Windows 代码签名。请核对来源与 SHA256，遵循系统提供的正常安全提示，不通过清除隔离属性绕过来源校验。

## 素材与许可

汐灵与任何模型厂商、DeepSeek 官方品牌没有关联，不使用官方 Logo 或未经授权的商标素材。

产品源码、场景、原创海浪 SVG 和正式项目文档使用 [MIT](LICENSE)。内置 Noto Sans SC 字体来自 [Noto CJK](https://github.com/notofonts/noto-cjk)，保留 [SIL OFL 1.1](assets/fonts/OFL.txt) 和[来源说明](assets/fonts/NOTICE.txt)，字体不适用 MIT。

本地原始 AI PNG 不进入公开仓库，不自动纳入 MIT，也不出现在公开预览截图或导出候选中。新增美术请先确认再分发权利；代码与美术分别管理授权。

## 参与贡献与项目链接

欢迎补充精致且可合法再分发的动作素材、改善体验、修复问题或提供目标系统实测。提交前阅读[贡献指南](CONTRIBUTING.md)，版本变化见[更新记录](CHANGELOG.md)。

[GitHub 源码](https://github.com/bestows-Z/XiLing) · [问题反馈](https://github.com/bestows-Z/XiLing/issues) · [提交 PR](https://github.com/bestows-Z/XiLing/pulls) · [候选与发布](https://github.com/bestows-Z/XiLing/releases)
