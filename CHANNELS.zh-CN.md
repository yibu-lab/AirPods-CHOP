# AirPods CHOP

这是可拖入 TouchDesigner 的 .tox 组件，不是独立驱动。需要配套 Mac 原生采集助手。

## 开始
1. 停止旧 AirPodsMotion 助手，打开app/AirPodsBridge.app。
2. 戴上已连接 Mac 的 AirPods，点击 Start sensor，按系统提示允许运动数据访问。
3. 将 AirPods_CHOP.tox 拖入 TD 网络，时间轴保持播放。端口默认 9010。
4. 从组件右侧 CHOP 输出接 Select CHOP。在 Channel Names 中输入需要的名字。
5. live=1 代表最近有新数据；extended_data=1 代表新版额外字段已收到。

每个端口只放一个接收组件；其他位置使用 Select CHOP 引用同一个输出。

## 通道
|名称|含义|单位|
|---|---|---|
|ax ay az|去除重力的耳机自身坐标系加速度|g|
|vertical|沿重力反方向投影的加速度|g|
|accel_magnitude|三轴用户加速度合成强度|g|
|pitch roll yaw|原始欧拉角|弧度|
|pitch_deg roll_deg yaw_deg|便于 TD 参数使用的欧拉角|度|
|pitch_relative_deg roll_relative_deg yaw_relative_deg|相对回中值的各轴角度差，范围 [-180,180)|度|
|pitch_control roll_control yaw_control|相对角度乘角度增益|度 × 增益|
|vertical_control|竖直加速度乘运动增益|g × 增益|
|gx gy gz|重力在耳机坐标系的分量|g|
|rx ry rz|角速度，注意不是旋转角|弧度/秒|
|qx qy qz qw|姿态四元数|无单位|
|source|Core Motion 的传感器来源枚举原始值|整数|
|tick|运动时间戳对 10000 取余，检查更新用途|秒|
|live|最近有新数据为 1，否则 0|0/1|
|age_seconds|距上次新时间戳的时间，上限 999|秒|
|extended_data|新版额外数据已收到|0/1|

## 参数
- Active：接收开关。
- Port：默认 9010。配套助手固定发送到本机 9010。
- Timeout：多久没有新时间戳判定过期，默认 1 秒。
- Recenter：开启一次，在有数据时把当前三个欧拉角设为零点并自动关闭；不修改原始姿态或四元数，不是四元数空间重定位。
- Anglegain / Motiongain：只影响 *_control 通道，保留原始测量。
- Zeroonloss：默认开启，数据过期时清零原始运动字段（四元数设为单位姿态）。关闭时原始字段保持最后值；派生控制通道仍归零。务必以 live 为准。

## 例子
AirPods_CHOP → Select CHOP（roll_deg）→ Lag CHOP → 导出到 Transform TOP 的 Rotate。
AirPods_CHOP → Select CHOP（vertical_control）→ Math CHOP → 导出到物体 Y 轴位置。

角度映射并非真实位置追踪。欧拉角存在 ±180° 跳变，复杂三维姿态可改用四元数。
耳机一次只有一个数据源，左右耳不能当两个独立手柄。每项数值是当前最新值，按 TD 帧采样，非无损传感器记录。

助手只通过本机 UDP 发送，不上传数据。停止或取下耳机后可能停止采集，组件用 live 标记过期。
