# 更新说明

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
