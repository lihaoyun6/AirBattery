# 
<p align="center">
<img src="./DockBattery/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">DockBattery</h1>
<h3 align="center">在 Mac 上获取你所有设备的电量信息并显示在Dock栏上!<br><a href="./README_en.md">[English Version]</a></h3> 
</p>

## 运行截图
<p align="center">
<img src="./img/Preview.png" width="699"/> 
</p>

## 安装与使用
### 安装:
可[点此前往](../../releases/latest)下载最新版安装文件. 或使用homebrew安装:  

```bash
brew install lihaoyun6/tap/dockbattery
```

### 使用:
- DockBattery启动后会常驻Dock栏, 使用过程中不再产生其他窗口.  
- 无需任何配置, DockBattery启动后会自动搜索所有支持隔空电量获取的设备,  
- 您可以右键单击Dock图标来显示有线, 附近或同一局域网中您其他设备的电量.  
- 在偏好设置中, 您还可以切换Dock图标主题, 以显示更多符合您需求的信息.  
- 展开右键菜单后, 按住 <kbd>Option</kbd> 键可以显示每个设备最后一次更新电量的时间.

## 常见问题
**1. 为什么我的 iPhone/iPad 并没有显示?**  
> 请确保 iPhone/iPad 已信任此 Mac 且开启 WiFi 同步. 并确保其与 Mac 处于同一局域网中.  

**2. 我的 Apple Watch 也需要进行预连接吗?**  
> 不需要, 一旦 DockBattery 检测到您的 iPhone, 将会自动读取与其配对的 Apple Watch 的电量信息.

**3. 为什么某些设备名称前有一个⚠️符号?**
> 出现这个符号, 说明此设备已经超过十分钟以上没有更新过电量信息, 可能已离线或关闭.

**4. 可以读取没有连接到 WiFi 的 iPhone吗?**  
> 理论上可以, 将在后续版本中加入相关功能, 敬请期待.  

**5. 为什么 DockBattery 需要使用蓝牙权限?**  
> DockBattery 需要使用蓝牙来获取周边设备的数据包以解析其电量信息.

**6. 为什么 DockBattery 需要使用定位权限?**  
> 在 DockBattery 的"仪表盘"视图模式中支持显示当地天气, 此功能需要获取用户位置以正常工作.  

## 致谢
[libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) @libimobiledevice  
> 注: 本项目使用基于`73b6fd1`版本编译的 libimobiledevice 可执行文件及运行库. 如有疑虑可自行编译替换  

[comptest](https://gist.github.com/nikias/ebc6e975dc908f3741af0f789c5b1088) @nikias  
> 注: 本项目使用基于此源代码编译的 comptest 可执行文件. 如有疑虑可自行编译替换  

[ChatGPT](https://chat.openai.com) @OpenAI  
> 注: 本项目部分代码使用 ChatGPT 生成或重构整理

## 赞助
<img src="./img/donate.png" width="352"/>
