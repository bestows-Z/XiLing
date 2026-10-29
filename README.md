<h1 align="center">🌊 汐灵 XiLing</h1>

<p align="center">
  <strong>把一点海风，留在你的桌面。</strong>
</p>

<p align="center">
  用 Godot 4 与 GDScript 编写的开源 2D 桌宠。<br>
  蓝白鲸鱼主题 · 自主行为 · 可扩展动画 · 本地运行
</p>

<p align="center">
  <a href="https://github.com/bestows-Z/XiLing"><img src="https://img.shields.io/badge/Version-0.2.0-168aad" alt="源码版本 0.2.0"></a>
  <a href="https://github.com/bestows-Z/XiLing/archive/refs/heads/main.zip"><img src="https://img.shields.io/badge/Download-Source-52b788" alt="下载源码"></a>
  <a href="https://github.com/bestows-Z/XiLing/stargazers"><img src="https://img.shields.io/github/stars/bestows-Z/XiLing?style=flat&color=f4b942" alt="GitHub Stars"></a>
  <a href="https://github.com/bestows-Z/XiLing/issues"><img src="https://img.shields.io/github/issues/bestows-Z/XiLing?color=8b80c7" alt="GitHub Issues"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4f86c6" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Godot-4.7.2-478cbf" alt="Godot 4.7.2">
  <img src="https://img.shields.io/badge/Targets-macOS%20%7C%20Windows%20%7C%20Linux-7c8a97" alt="目标平台：macOS、Windows、Linux">
</p>

<p align="center">
  <a href="#-开始陪伴">🚀 开始陪伴</a>
  &nbsp;·&nbsp;
  <a href="#-怎么和汐灵玩">🎮 操作说明</a>
  &nbsp;·&nbsp;
  <a href="#-平台支持与限制">🖥️ 平台支持</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/bestows-Z/XiLing/issues">🐛 问题反馈</a>
</p>

汐灵希望成为有动作、有情绪、有一点自主性的桌宠。行为系统会随机选择挥手、张望、跳舞和休息；玩家的抚摸、喂食与陪玩会影响心情、精力和亲密度。肢体动作目前在兼容占位模式中展示，本机原画模式保留原有眨眼、漂浮、呼吸与整体反馈。

当前的“自主”由本地状态机、计时与情绪规则实现，不包含聊天、LLM、联网模型或语音服务。项目使用 Godot 原生功能，不依赖 Flutter。

## ✨ 这次能玩到什么

| 能力 | 当前实现 |
| --- | --- |
| 🐳 默认角色 | 兼容用的蓝白鲸鱼主题 Q 版拟人占位形象（Godot 绘制）；本机存在原始立绘时优先显示原始鲸鱼娘图片 |
| 🦵 占位动画能力 | 仅在兼容占位模式下，头部、手臂、肘关节、双腿和膝盖分别变化；跳跃含蓄力、抬臂和弯膝落地 |
| 🎭 动作状态 | 待机、挥手、跳跃、跳舞、睡眠、好奇、拖动、进食和抚摸反馈 |
| 🌱 自主行为 | 随机选择行为，结合精力安排休息；玩家互动优先于自主动作 |
| 💙 情绪与陪伴 | 心情、精力、亲密度随时间和互动变化，并保存在本地 |
| 🫧 桌面窗口 | 360 × 480 透明、无边框、置顶窗口；角色命中检测与轮廓鼠标穿透，实际效果受平台支持影响 |
| 🧩 可替换表现层 | 行为、情绪、姿态、绘制和窗口逻辑分离，便于接入有权使用的人物动画素材 |

**本机存在 `assets/pet/xiaoxi.png` 时，默认恢复原始鲸鱼娘立绘（原尺寸比例、眨眼、漂浮、呼吸与整体弹跳）；该静态立绘没有抬手、弯腿动画。** 干净的开源仓库不含这些本地图片，会使用程序绘制的兼容占位角色；只有占位角色提供连续多姿态关节动画。 仓库未提供精绘鲸鱼娘序列帧，也未把两张静态 PNG 的位移或缩放描述为人物肢体动画。若希望达到完整人物动画的美术效果，仍需要合法可发布的分层立绘、骨骼绑定或逐帧素材。

## 🚀 开始陪伴

### 下载与源码运行

当前提供源码，尚无预编译安装包或正式 Release。可[下载源码 ZIP](https://github.com/bestows-Z/XiLing/archive/refs/heads/main.zip)，或使用 Git：

```bash
git clone https://github.com/bestows-Z/XiLing.git
cd XiLing
```

1. 安装 [Godot 4.7.2 标准版](https://godotengine.org/download/)，无需 .NET 版。
2. 在 Godot 项目管理器中导入 `project.godot`。
3. 运行主场景 `scenes/main.tscn`，或按 **F6**；也可按 **F5** 运行项目。

已配置 Godot 命令行时，也可直接启动：

```bash
godot --path .
```

macOS 中如果没有 `godot` 命令，可使用应用内的可执行文件：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

### 🎮 怎么和汐灵玩

| 操作 | 效果 |
| --- | --- |
| 左键短按角色 | 抚摸 |
| 左键按住并移动 | 拖动桌宠窗口 |
| 双击角色 | 挥手 |
| 右键角色 / `Space` | 互动弹跳；原画模式为整体反馈，兼容占位模式为关节动作 |
| `Shift` + 右键 / `M` | 打开互动菜单 |
| `F` | 喂食 |
| `D` | 跳舞 |
| `S` | 睡觉或唤醒 |
| `A` | 开关自主行为 |
| `H` | 查看帮助 |
| `Esc` | 关闭已打开的菜单 |

Esc 在菜单关闭时会打开菜单，菜单已打开时关闭菜单。单击会短暂等待双击判定后触发抚摸。快捷键在桌宠窗口获得焦点后生效。退出可使用菜单中的退出按钮或系统的关闭应用操作。连续互动有冷却时间，避免动作被每次点击不停打断。

## 🖥️ 平台支持与限制

跨平台是项目目标，**源码可导入不等于所有桌面窗口特性已在三平台验收**。

| 环境 | 当前验证范围与注意事项 |
| --- | --- |
| macOS Apple Silicon | 当前开发环境；Godot 4.7.2。具体自动化检查与窗口验证结果见下方“开发与检查” |
| Windows | 尚未进行 Windows 实机验收；透明、置顶、拖动和穿透需要在目标系统验证。Godot 的轮廓穿透会裁掉轮廓外的绘制区域 |
| Linux X11 | 尚未进行 Linux 实机验收；透明效果还依赖窗口管理器、合成器及显卡驱动 |
| Linux Wayland | 降级环境。不能假设程序定位、置顶与轮廓穿透可用；拖动可用性取决于合成器和 Godot 的原生拖动支持 |

Wayland 通常不允许客户端自行设置全局窗口位置。Godot 的轮廓穿透 API 目前列出的平台为 macOS、Windows 和 Linux X11；置顶行为也可能受桌面环境限制。需要完整桌宠窗口体验时，可在安装了 XWayland 的桌面中尝试：

```bash
godot --display-driver x11 --path .
```

这需要当前 Godot 构建与桌面环境提供 X11 支持。无法使用相关能力时，角色动画与互动仍可运行，但透明区域可能接收鼠标事件。窗口能力依据 [Godot DisplayServer 官方文档](https://docs.godotengine.org/en/stable/classes/class_displayserver.html) 与 [Window 官方文档](https://docs.godotengine.org/en/stable/classes/class_window.html)，实际表现以目标系统验证为准。

兼容占位角色使用逐形状几何命中；系统鼠标穿透采用包含各肢体的外包轮廓，手臂之间等少量透明空隙仍可能拦截鼠标。原画/自定义贴图使用 Alpha 命中和 BitMap 轮廓。提示显示期间也会扩大系统输入轮廓，菜单打开时整窗接收输入。

## 🎨 角色、素材与本地数据

汐灵采用非官方原创的蓝白鲸鱼主题设定，与任何模型厂商或品牌无关，不使用 DeepSeek 官方 LOGO。

- 仓库内置的兼容占位角色由 GDScript 绘制，不依赖外部人物贴图；本机优先加载你已有的原始鲸鱼娘立绘。产品源码按 MIT 开源。
- 旧项目中的 `assets/pet/xiaoxi.png`、`xiaoxi_blink.png` 为本地原始 AI 生成素材，保留在用户电脑，并由 `.gitignore` 排除；它们及其导入描述不作为开源或发布资源。
- 本地原始图片保留原有整体运动和随机眨眼，不具备占位角色的独立关节动画。删除或不放置这两张图片，不影响默认模式启动。
- 替换人物素材前，请确认你拥有再分发和开源所需权利。仅有两张睁眼、闭眼 PNG 无法提供抬手和弯腿动作。
- 自定义逐帧皮肤：将有权使用的 `SpriteFrames` 保存到 `assets/local/skin.tres`，至少包含非空 `idle` 动画；可追加与动作同名的 `wave`、`jump`、`dance`、`sleep`、`curious`、`drag`、`feed`、`pet` 动画。菜单选择“本地动画皮肤”启用；缺少或空的动作回退 `idle`。循环动作按资源帧率播放，非循环动作按行为时长映射。此目录同样不提交。
- 情绪与偏好保存在 Godot `user://` 数据目录，不写入项目仓库。没有网络账号、API Key 或云端同步依赖。

## 🛠️ 开发与检查

### 代码结构

```text
scenes/main.tscn       主场景：Main → Pet
scripts/pet_idle.gd    桌宠协调与输入
scripts/pet_brain.gd   状态机、自主行为与互动优先级
scripts/pet_mood.gd    心情、精力和亲密度
scripts/pose_library.gd  动作姿态与关节变化
scripts/pet_visual.gd  兼容占位角色绘制与命中轮廓
scripts/desktop_window.gd  窗口、拖动与穿透
scripts/pet_menu.gd    互动菜单
scripts/local_skin.gd  可选本地贴图与 SpriteFrames 适配
tests/                可重复运行的行为、姿态和启动检查
```

### 本地检查

在项目目录执行：

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/brain_tests.gd
godot --headless --path . --script tests/visual_tests.gd
godot --headless --path . --script tests/skin_tests.gd
godot --headless --path . --script tests/smoke_tests.gd
```

这些命令分别检查资源导入和脚本解析、行为与情绪边界、动画姿态、主场景启动。**Headless 检查不能证明窗口透明、穿透、置顶或系统拖动有效**；这些能力必须启动实际窗口检查。

2026-10-29 在 macOS Apple Silicon、Godot 4.7.2 实际运行结果：

- 真实项目及不含原始 PNG、缓存的干净仓库均从零导入、解析通过，无脚本错误。
- 行为与情绪：26 项检查通过。
- 兼容占位动画：9 类动作 × 21 组姿态，以及呼吸、表情优先级检查通过。
- 本地皮肤：本机 21 项、干净仓库 23 项检查通过，覆盖缺失原画回退。
- 主场景：本机 29 项、干净仓库 28 项检查通过，含本地原画默认加载、切换、菜单边界、双击与右键竞争。
- 实际 GPU 窗口渲染通过；检查了原始立绘、两帧眨眼、0.25 缩放，以及中文菜单与兼容占位代表姿态。

系统级透明穿透、拖动与置顶尚未完成独立的桌面自动化验收；Windows/Linux 也未实机验证。三个导出预设排除了本地原画、测试和过程目录，尚未完成三平台打包、签名和发行验收。

### 🤝 参与贡献

欢迎修复问题、改进动画、提供可授权的角色素材，以及补充 Windows、Linux X11 和 Wayland 的实测结果。

1. 较大改动先通过 [Issue](https://github.com/bestows-Z/XiLing/issues) 说明问题和预期行为。
2. 保持模块职责清晰，新增动作时同时检查关节姿态、命中区域、动作结束和互动优先级。
3. 提交 PR 时写明 Godot 版本、操作系统、复现方式和实际测试范围。
4. 请勿提交 `doc/`、`.codex/`、AI 过程文件、计划草稿、生成缓存、机密或没有明确授权的素材；提交前检查暂存区文件清单。

## 📄 开源许可

项目产品源码与 README 使用 [MIT License](LICENSE)。内置的 Noto Sans SC 字体来自 [Noto CJK](https://github.com/notofonts/noto-cjk)，使用 [SIL Open Font License 1.1](assets/fonts/OFL.txt)，字体不适用 MIT。本机保留且未随仓库发布的原始图片不包含在此开源授权中。

## 🔗 项目链接

- [GitHub 仓库](https://github.com/bestows-Z/XiLing)
- [下载源码](https://github.com/bestows-Z/XiLing/archive/refs/heads/main.zip)
- [反馈问题与建议](https://github.com/bestows-Z/XiLing/issues)
- [参与代码贡献](https://github.com/bestows-Z/XiLing/pulls)

<p align="center">
  <strong>汐灵 XiLing · 把一点海风，留在你的桌面。</strong>
</p>
