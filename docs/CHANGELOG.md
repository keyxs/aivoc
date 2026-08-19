# 更新说明

## 版本：v2.1 — 零依赖启动 + 思考模型提速

更新日期：2026-08-19

---

## 一、零依赖启动（PowerShell 替代 Python）

### 背景

v2.0 的 `start.bat` 依赖 `python -m http.server` 启动本地服务器。实际部署中发现：

- 部分机器未安装 Python，双击 `start.bat` 直接闪退
- bat 脚本含中文，在 GBK 默认的 cmd 下出现乱码（如 `'腑...' 不是内部或外部命令`）
- 直接双击 `index.html`（`file://` 协议）会触发 CORS，报 `Failed to fetch`

### 改动

| 文件 | 改动 |
|------|------|
| `start.ps1`（新增） | 基于 `System.Net.HttpListener` 的 PowerShell 静态 HTTP 服务器，等价于 `python -m http.server` |
| `start.bat`（重写） | 改为调用 `start.ps1`，**全英文输出**避免 GBK 乱码，零 Python 依赖 |

- 启动器现在只依赖 Windows 自带的 PowerShell，无需安装任何运行时
- 端口检测、错误兜底、自动开浏览器逻辑保留
- 通过 `http://localhost:12580` 访问，规避 `file://` 的 CORS 问题

---

## 二、思考模型提速（think 参数）

### 背景

实测 `qwen3.5:2b` 等思考模型：默认会先长篇思考再输出正式内容。100 token 耗时 **11.2 秒**，且 `content` 全空（被思考过程吃光）。而 v2.0 的 `thinkingMode` 开关只控制 `temperature`，**未传 `think` 参数**，导致即使关闭「思考模式」模型照样思考。

### 改动

请求体新增 `think` 字段，由「思考模式」开关控制：

```js
think: thinkingMode   // 开启 → think:true（先分析再输出，更准但慢）
                      // 关闭 → think:false（直接输出，跳过思考）
```

### 实测数据（qwen3.5:2b，100 token）

| 模式 | 耗时 | content |
|------|------|---------|
| 默认（思考） | 11197 ms | 空（全被思考占用） |
| `think:false` | 581 ms | 正常输出 |

**关闭思考模式时提速约 19 倍。**

---

## 三、流式渲染性能优化

### 背景

v2.0 的流式渲染每 80ms 对**整个累积内容**跑一次 `marked.parse()` + `DOMPurify.sanitize()`，复杂度 O(n²)，长文本下明显卡顿。

### 改动

| 阶段 | v2.0 | v2.1 |
|------|------|------|
| 流式中 | `innerHTML = DOMPurify.sanitize(marked.parse(snapshot))` | `textContent = snapshot`（纯文本，O(n)） |
| 完成后 | 同上 | 一次性 `marked.parse` + `DOMPurify.sanitize` |
| 中断后 | 同上 | 一次性渲染，并清理流式阶段样式 |

流式阶段用 `textContent` 实时显示纯文本（带 `white-space: pre-wrap`），完成后一次性渲染 Markdown，消除全量解析卡顿。

---

## 四、生成长度兜底

请求 `options` 新增 `num_predict: 2048`（约覆盖 3000 中文字），防止模型发散输出导致等待过久，润色场景通常足够。

---

## 五、离线运行确认

对 `index.html` 全量审计外部依赖：

- JS 库：`lib/marked.min.js`、`lib/purify.min.js`（本地）
- 网络：仅 `fetch` Ollama 的 `/api/tags`、`/api/chat`
- 无 `@font-face`、无 CDN、无外链图片、无 WebSocket、无 `@import`

**结论：除连接 Ollama 外，断网可完整运行。**

---

## 六、启动脚本健壮性

- `start.bat` 全英文输出，彻底避免 GBK 乱码
- HTTP 服务器启动失败时显示错误码与可能原因，不再闪退
- 端口占用检测保留，支持 `start.bat <端口号>` 自定义

---

## 七、文件清单变更

```
aivoc/
├── index.html          # 主程序（含 think 参数、textContent 流式、num_predict）
├── start.bat           # 重写：调用 start.ps1，全英文，零 Python 依赖
├── start.ps1           # 新增：PowerShell 静态 HTTP 服务器
├── README.md           # 更新：去 Python 依赖、加目录、GitHub 规范结构
├── docs/CHANGELOG.md   # 本文件
├── LICENSE
├── .gitignore
└── lib/
    ├── marked.min.js
    └── purify.min.js
```

---

## 版本：v2.0 — 界面紧凑化 + 全面优化

更新日期：2026-08-17

---

## 一、界面布局重构

### 双列布局（核心改动）

从 4 个卡片垂直堆叠改为左右双列布局，一屏可见所有功能：

```
┌──────────────┬──────────────┐
│ 模型配置     │ 一键润色     │
│ 文本输入     │ 处理结果     │
│              │ 复制/停止    │
└──────────────┴──────────────┘
```

### CSS 全面压缩

| 属性 | 修改前 | 修改后 |
|------|--------|--------|
| body padding | 20px | 10px |
| header h1 | 2.8em | 1.6em |
| card padding | 28px | 12px |
| btn padding | 14px 28px | 7px 16px |
| textarea min-height | 160px | 70px |
| style-btn padding | 22px | 8px 6px |
| result-box max-height | 600px | 200px |
| style-grid gap | 16px | 6px |

---

## 二、P0 — 流式渲染性能优化

### 流式输出节流

- **修改前**：每个数据块都全量 `marked.parse()` + 重设 innerHTML，频繁 `smooth` 滚动导致卡顿
- **修改后**：80ms 时间节流 + `requestAnimationFrame` 合帧，`scrollTop` 直接定位替代 smooth 动画

### 复制取值修复

- **修改前**：`document.getElementById('polishedResult').textContent` 取渲染后 DOM 文本，丢失 Markdown 格式
- **修改后**：新增全局变量 `currentPolishedText` 保存原始响应，复制时直接使用

---

## 三、P1 — 安全与中断

### XSS 净化

- 引入 DOMPurify（本地化 `lib/purify.min.js`）
- 所有模型输出经 `DOMPurify.sanitize(marked.parse(...))` 净化后才渲染

### 请求可中断

- 新增"停止生成"按钮（生成中显示）
- 使用 `AbortController` 中断 fetch/reader
- 中断后保存已接收的部分结果，用户可复制

---

## 四、P2 — 体验增强

### 配置持久化

- API 地址、模型选择、Ollama 开关、思考模式自动保存到 `localStorage`
- 刷新页面不丢失配置
- 模型列表加载后自动恢复上次选中的模型

### 润色风格选中状态

- 点击风格按钮后高亮显示（`.style-btn.active` 紫色渐变）
- 点击其他按钮自动切换高亮
- 清空时重置选中状态

---

## 五、P3 — 代码质量

| 问题 | 修复 |
|------|------|
| 7 处 `alert()` | 全部替换为 `showToast`（非阻塞通知） |
| 注释与代码不符 | "10 条对话" 修正为 "10 条消息（5 轮对话）" |
| handlePolish 魔法字符串 | 移除三层 fallback，直接从 `inputText` 取值 |
| 错误信息 innerHTML 未净化 | 新增 `escapeHtml()` 函数，错误模板中转义 |
| apiType 死代码 | 删除"自定义 API"下拉框及相关逻辑 |
| cleanText 正则注入 | `new RegExp(word)` 改为 `replaceAll(word)` |
| console.log 冗余 | 清理 8 条 log + 1 条 debug，保留 error/warn |
| body 背景动画失效 | 添加 `background-size: 200% 200%` |

---

## 六、断网运行支持

- `marked.min.js` 和 `purify.min.js` 下载到 `lib/` 目录
- HTML 引用从 CDN 改为本地路径
- 只要 Ollama 本地可用，断网也能正常工作

---

## 七、启动脚本改进

- 增加 Python 环境检测（未安装则提示并退出）
- 启动 2 秒后自动打开浏览器
- `chcp 65001` 防止中文乱码

---

## 八、文件清单

```
d:\tarepj\aivoc\
├── index.html          # 主程序（55KB，界面+逻辑）
├── lib/
│   ├── marked.min.js   # Markdown 解析库（39KB，本地化）
│   └── purify.min.js   # XSS 净化库（29KB，本地化）
├── 启动系统.bat         # 一键启动脚本（改进后）
└── 使用说明.md          # 使用说明
```

---

## 九、升级方法

1. 确保已安装 Ollama 并拉取模型（`ollama pull llama3`）
2. 双击 `启动系统.bat`
3. 浏览器自动打开 `http://localhost:12580`
4. 点击"测试"验证 Ollama 连接
5. 选择模型，输入文本，选择润色风格
