# AirPods 骰子 · 复古梦境版

打开方式：在空白 TD 工程拖入 examples/AirPods_Dice.tox
可复用模块：examples/AirPods_Dice.tox
实际画面：examples/preview.png

## 开始测试
1. 在空白 TD 工程拖入示例组件，时间线保持播放。
2. AirPods 连接 Mac，启动配套 AirPodsBridge.app，点击 Start sensor。
3. 画面底部 AIRPODS / LIVE 才代表最近收到新数据。WAITING 表示没有有效的新数据。
4. 握住耳机轻轻摇动，画面显示 ROLLING；停止约 0.6 秒，进入 SETTLING；约 1.4 秒后显示 RESULT 和点数。
5. 如果取下耳机后变 WAITING，先戴回耳朵验证连接。不能把离耳断流当作摇动检测正常。
6. 没有耳机时，在 AIRPODS_DICE 的 Dice Controls 页面开启 Demo。底部会明确显示 DEMO MODE；测试真实输入前关闭。

当前没有音效。主结果面是朝向观众的正面，不是上表面。

## 控制参数
- Demo：模拟摇动循环，默认关闭。
- Threshold：摇动加速度阈值，默认 0.18g。轻晃无反应可适当降低。
- Settlewait：确认停止的等待时间，默认 0.6 秒。
- Gain：翻滚速度倍率，默认 1。

## 教学节点走向
- AirPods_CHOP → 01_AIRPODS_INPUT：接收耳机通道。
- 02_SHAKE_AND_SETTLE：检测摇动，管理等待、翻滚、减速、结果四种状态。
- 03_SELECT_TRANSFORM → 04_POSE_OUT → 06_DICE：旋转和悬浮位置。
- 05_STATUS：live / demo / state / result / energy / rounds，可直接显示或另接可视化。
- DISPLAY_ANGLE：固定展示角度，使主结果面和另外两面容易辨认。
- 07_CHECKER_FLOOR、08_ABANDONED_ROOM：地面、旧墙与门洞。
- 09_CAMERA 和 LIGHT_KEY / LIGHT_FILL：固定镜头与灯光。
- 10_RENDER_320x240：低分辨率渲染，关闭抗锯齿。
- 11_RETRO_GRADE：轻微暗角、色阶与抖色。
- 12–14：标题、摇动状态、输入连接状态。
- 15_TEXT_OVER_SCENE → 16_PIXEL_UPSCALE → 17_FINAL：合成、最近邻放大、最终输出。

模型组件内部保留 Script SOP → Null SOP。几何和程序化旧化颜色已内嵌，不依赖外部图片、模型或在线素材。地面阴影是预先计算的简化阴影，不是实时光线追踪。

## 规则与边界
点数在停止摇动后由程序随机选择，再将对应骰面转向观众；不是物理碰撞模拟。相对面的点数和为 7。耳机控制摇动过程，不决定随机点数。

不要在同一 TD 进程内同时放多个使用 9010 端口的接收组件。需要多个画面时，复用同一个接收组件的通道。

## 验证
在本机 TouchDesigner 2025.33230 中完成实际渲染、模块错误检查和两轮模拟状态测试。完成时真实输入 live=0，已切回真实模式等待连接；本次未验证实际手持摇动。
