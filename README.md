# 轻听 Light Music

一个轻量、离线优先的本地音乐播放器，目标平台为 Windows、macOS 和 Android。

## 当前版本

- 本地音乐导入与列表展示
- MP3、FLAC、M4A、OGG、WAV 等普通格式播放
- 搜索歌曲、歌手和专辑
- 播放 / 暂停 / 上一首 / 下一首
- 播放进度、音量、收藏入口
- `.mgg2.flac`、`.mflac0.flac` 等特殊格式识别提示
- GitHub Actions 自动构建 Android APK、Windows ZIP、macOS ZIP

## 本地运行

需要 Flutter stable 3.24 或更高版本：

```bash
flutter pub get
flutter run
```

## 构建

```bash
flutter build apk --release
flutter build windows --release
flutter build macos --release
```

推送到 `main` 后，GitHub Actions 会自动生成三端构建产物。

## 后续计划

1. 接入后台播放和锁屏控制
2. 增加文件夹扫描和播放记录
3. 接入 QMC 解密，支持 `.mgg2.flac` / `.mflac0.flac`
4. 加入歌词和 M3U 歌单
