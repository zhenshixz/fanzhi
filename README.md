# 繁殖防线

一个用 Godot 4 制作的地下魔王放置防守原型。

方向是“地下生态 + 入侵勇者 + 魔物巢穴经营”。灵感来自复古掌机地牢管理游戏的反英雄气质，但角色、美术、音乐和规则都是原创实现。

## 运行

1. 双击 `play_game.bat` 可以直接运行游戏。
2. 双击 `open_godot.bat` 可以打开 Godot 编辑器继续开发。
3. 点击地图上的发光巢位放置魔物巢穴。
4. 点击已放置的巢穴可以选中并升级。

也可以手动运行：

```bat
tools\godot\Godot_v4.7-stable_win64.exe --path .
```

## 当前玩法

- 勇者沿地下通道入侵魔王房间。
- 点击空巢位花费魔力孵化魔物巢穴。
- 巢穴会自动向最靠近终点的勇者发射诅咒。
- 击退勇者获得魔力。
- 点击已建巢穴可以升级，提高伤害、范围和攻速。
- 支持 x1/x2 速度切换和背景音乐开关。

## 已配置

- Godot 4.7 stable 放在 `tools/godot/`。
- PNG 美术资源已经通过 Godot 导入，`.import` 文件保留在资源目录。
- `.godot/` 是本地缓存，会由 Godot 自动生成。
- 当前音乐和音效来源见 `assets/audio/ATTRIBUTION.md`。

## 目录

- `scenes/`：Godot 场景。
- `scripts/`：GDScript 逻辑。
- `assets/images/`：生成美术资源。
- `data/`：塔和波次配置。
