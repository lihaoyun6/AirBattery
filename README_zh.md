# 
<p align="center">
<img src="./AirBattery/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">AirBattery</h1>
<h3 align="center">在 Mac 上获取你所有设备的电量信息并显示在Dock栏、状态栏上或小组件上!<br><a href="./README.md">[English Version]</a><br><a href="https://lihaoyun6.github.io/airbattery/">[软件主页]</a></h3> 
</p>

## 运行截图
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview.png">
  <img alt="QuickRecorder Screenshots" src="./img/preview.png" width="840"/>
</picture>
</p>

## 安装与使用
### 系统版本要求:
- macOS 11.0 及更高版本  

### 安装:
可[点此前往](../../releases/latest)下载最新版安装文件. 或使用homebrew安装:  

```bash
brew install lihaoyun6/tap/airbattery
```

### 使用:
- AirBattery 启动后默认同时显示在 Dock 栏和状态栏上, 也可以只显示其中之一.  

- 无需任何手动配置, AirBattery 启动后会自动搜索所有支持隔空电量获取的设备. 
- 您可以单击 Dock 图标 / 状态栏图标、或添加小组件查随时看周边设备的电量信息. 
- 利用 `Nearcast` 功能还可以随时查看局域网中属于你的其他 Mac 及其外设的电量.
- 您还可以在偏好设置中将状态栏图标更改为实时电量显示, 就像系统自带图标的那样.  
- 如有需要, 可以在 Dock 栏菜单或状态栏菜单中隐藏某些设备, 亦可随时解除隐藏.  

## 常见问题
**1. 为什么我的 iPhone / iPad / Apple Watch 没有显示出来?**  
> 请确保 iPhone / iPad 已信任此 Mac ***(且至少在 AirBattery 运行状态下使用数据线连接 Mac 一次以进行配对)***. 之后只需确保其与 Mac 处于同一局域网中即可.  

**2. 我的 Apple Watch 也需要进行预连接吗?**  
> 不需要, 一旦 AirBattery 通过 WiFi 或 USB 发现任何已配对的 iPhone, 将会自动读取与其配对的 Apple Watch 的电量信息 **(通过蓝牙发现的 iPhone 不支持读取手表电量!)**

**3. 为什么某些设备名称前有一个⚠️符号?**
> 出现这个符号, 说明此设备已经超过十分钟以上没有更新过电量信息, 可能已离线或关闭.

**4. 我的 iPhone 没有连接到 WiFi, 可以读取电池信息吗?**  
> 请安装 AirBattery v1.1.2 或更高版本, 在设置面板中启用 `通过蓝牙发现 iPhone / iPad` 选项, 并保持设备蓝牙开启即可 ***(此功能仅支持 iPhone 或插卡版 iPad设备!)***  

**5. 为什么 AirBattery 需要使用蓝牙权限?**  
> AirBattery 需要使用蓝牙来获取周边设备的数据包以解析其电量信息.  

## 赞助
<img src="./img/donate.png" width="350"/>

## 致谢
[libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) @libimobiledevice  
> AirBattery 使用基于`73b6fd1`版本编译的 libimobiledevice 可执行文件及运行库. 如有疑虑可自行编译替换  

[comptest](https://gist.github.com/nikias/ebc6e975dc908f3741af0f789c5b1088) @nikias  
> AirBattery 使用基于此源代码编译的 comptest 可执行文件. 如有疑虑可自行编译替换  

[MultipeerKit](https://github.com/insidegui/MultipeerKit) @insidegui  
> AirBattery 使用 MultipeerKit 框架来进行局域网内的对称多端通信   

[ChatGPT](https://chat.openai.com) @OpenAI  
> 注: 本项目部分代码使用 ChatGPT 生成或重构整理
