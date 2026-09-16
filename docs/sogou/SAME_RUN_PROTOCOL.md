# 搜狗九键丢字：证据审计与同轮实验协议

日期：2026-09-16。状态：根因尚未闭环；诊断分支，不是已验证修复版。

## 必须撤回或降级的结论

1. 另一个 App/另一次运行的 IME probe 收到完整文字，不能证明失败那次 RustDesk 也收到了同样的 commitText。固定坐标点击在不同帧率、候选变化和焦点条件下可能不等价。
2. 官方版 60/60、Final 59/60 是差异线索，不能单独证明 controller listener 是原因。必须比较同源、同 Flutter 工具链的实现和同轮输入记录。
3. 直接把 UTF-8 的 `我` 传给 libxdo 的 keysequence API，不等价于 RustDesk 实际调用。`libs/enigo/src/linux/xdo.rs` 的 `keysequence(Key::Layout(c))` 使用 `format!("U{:X}", c as u32)`，即 `U6211`。此前该负例不能证明真实 fallback 吞字。
4. Alacritty 中 raw PTY 捕获点仍在终端的 X11/输入法处理之后，不是 RustDesk 协议接收点。Chrome 偶尔通过也不能排除终端或共享 X11 注入问题。
5. `KeyEvent.seq` 保留字符串边界，但 Linux 最终仍需要注入/交付给应用；不能由此推导应用必然原子地收到整句。
6. 补丁第 87 行损坏属于构建错误；修复这个错误不代表修复输入丢字。

## 同一次失败必须保留的观测点

- A：RustDesk 自身的 Android InputConnection / Flutter 编辑状态，记录文本、selection、composing、候选提交，以及程序主动 reset。
- B：Dart 决策产生的插入串与删除次数，进入 FFI 的数据和顺序。
- C：客户端实际入发送队列的数据；远端解码完成的数据。区别“调用了 API”和“已入队/接收”。
- D：Linux 注入函数实际实参、返回值、X11 keymap 与 modifier/focus 状态。
- E：Chrome DOM input 事件和最终 value；Alacritty raw PTY 字节；最后单独验证 Codex 输入框，不自动回车提交任务。

只用同一轮 A→B→C→D→E 的第一次不一致定位责任层。跨轮探针用于对照，不填充缺失的观测点。

## 对抗性实验矩阵

固定 APK/hash、桌面版本、Sogou 版本、XKB 布局、IBus 状态和目标窗口。先测试 QWERTY，再单独测试 DVP，不在同轮更改多个因素。

| 对照 | 内容 | 判定 |
| --- | --- | --- |
| 单字/整词/整句 | 我；你好；我今天吃饺子 | 实际选择内容与 A～E 一致 |
| 连续提交 | 同句 100 次；单字和整句交替 | 字节/码点、顺序、次数均一致 |
| composition-only | 文本相同而 composing 从有效区间变为空 | 提交恰好一次，不依赖 onChanged 是否调用 |
| 编辑 | 删除、同长度替换、取消拼音、重新选词、隐藏重开键盘 | 不泄漏占位符，不误删已提交文字 |
| Unicode | BMP 汉字、补充平面字符、emoji、组合字符 | 区分 UTF-16、码点和字素；不损坏代理对 |
| 绕过 Android | 直接对隔离测试窗口注入同样的文本 | 判断故障是否仍存在于 Linux 接收之后 |
| libxdo 对照 | 正确 U6211 keysym 路径与 UTF-8 text 路径 | 记录调用参数；不能用错误实参负例代替真实调用 |
| 接收应用 | Chrome、Alacritty raw、Codex 未提交输入框 | 相同层次的数据分别核对，不只看截图 |

每轮确认焦点并记录实际候选；误点、断线、采集截断、焦点变化单列为无效轮，不能算传输丢字，也不能算通过。

## 当前新增验证

`sogou_callback_contract_test.dart` 在构建所用的 Flutter 3.24.5 上测试 106 次连续提交、仅 composing 变化的提交与 reset。它只验证框架/算法契约，不替代 Pixel→RustDesk→Linux 实测。

## 隐私与恢复边界

原版 RDC、系统代理、原版 RustDesk 不替换。诊断只记录合成测试文字，日志留在实验机，不上传真实输入、服务器密钥或完整桌面截图。设备离线时停止 GUI/ADB 实测，不能将 CI 等待算作设备测试。恢复 uan RDC 与 Pixel ADB 后才开始端到端采集。
