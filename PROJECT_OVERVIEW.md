# CoinConquer 项目概述

> 一款运行在 Android 系统上的本地记账 App，无广告，数据完全存储在本地，支持导入/导出备份文件。

---

## 一、基本信息

| 项目 | 内容 |
|------|------|
| **项目名称** | CoinConquer（硬币征服者） |
| **目标平台** | Android（小米澎湃OS） |
| **开发平台** | Windows 11 |
| **界面语言** | 简体中文 |
| **数据存储** | 完全本地 SQLite，无网络请求 |
| **广告** | 零广告 |

### 存储空间估算

SQLite 单条记录约 200 字节（含字段+索引），按使用强度估算年占用：

| 使用强度 | 日均记账 | 年记录数 | 数据库年增长 |
|---------|---------|---------|-------------|
| 轻度 | 3笔/天 | ~1,100条 | **≈ 0.25 MB** |
| 中度 | 5笔/天 | ~1,800条 | **≈ 0.4 MB** |
| 重度 | 10笔/天 | ~3,600条 | **≈ 0.8 MB** |

> **结论：十年重度使用约 8-10 MB，对现代手机可忽略。** 不提供按年/月删除旧记录功能，避免误删风险。

---

## 二、技术栈

| 层 | 技术 | 说明 |
|---|------|------|
| 框架 | Flutter 3.x + Dart | 跨平台，热重载，UI精美 |
| 状态管理 | Provider | 简单易学，适合新手 |
| 本地数据库 | sqflite | SQLite，数据完全本地 |
| 图表 | fl_chart | 饼图、折线图 |
| 文件操作 | path_provider + share_plus | 导出/导入备份文件 |
| 主题 | 亮色 / 暗色双模式 | 可在设置中切换 |

---

## 三、导航结构（3个Tab）

```
┌──────────────────────────────────────────────────────────┐
│  📅 日历                                                  │
│  月历(可左右滑动切换月份)                                   │
│  日期上显示小圆点标记(绿=有收入,红=有支出)                    │
│  点击日期 → 显示当日收支明细                                │
│  兼职区(可折叠展开)：选兼职 → 填工时 → 自动算收入            │
│  FAB[+]快速记账                                           │
├──────────────────────┬───────────────────────────────────┤
│  📊 统计              │  👤 我的                           │
│  分类饼图             │  兼职工作管理                       │
│  月度趋势折线图        │  预算设置                          │
│  月度总结报告          │  周期性账单                        │
│  ──────────────────   │  分类管理                          │
│  📥 导出图形报告       │  暗色模式切换                       │
│     (按月/年 → PDF/PNG)│  ──────────────────               │
│  💾 导出数据备份(JSON)  │  📂 导入数据恢复                   │
│                       │     (选JSON → 冲突检测 → 确认导入)  │
│                       │  ⏰ 定期提醒导出                    │
│                       │     (开关 + 周期选择)               │
│                       │  📖 导入恢复图文教程                 │
└──────────────────────┴───────────────────────────────────┘
```

---

## 四、核心功能清单

### 4.1 记账功能
- 记录**收入**和**支出**
- 选择预置分类（支出8类 + 收入4类）
- 收入支持**自定义来源名称**
- 填写金额、备注、日期

### 4.2 兼职模块
- 管理多份兼职工作（如：家教、外卖），每份设置**默认时薪**
- 工作结束后手动录入工时：
  - 选择兼职 → 输入工作时长(小时) → 时薪自动带出(可手动修改)
  - App 自动计算：**收入 = 工时 × 时薪**
  - 提交后自动生成一条兼职收入记录
- 查看历史工时记录

### 4.3 日历视图
- 月历可左右滑动切换月份
- 有收支记录的日期显示**小圆点标记**（绿色=有收入，红色=有支出）
- 点击日期查看该日收支明细
- 显示当日收支合计

### 4.4 统计与报告
- **分类饼图**：展示各分类支出/收入占比，支持按月筛选
- **月度趋势折线图**：展示最近6-12个月收支变化趋势
- **月度总结报告**：
  - 本月总收入、总支出、结余
  - 各类别收支金额及占比
  - 图形展示

### 4.5 图形报告导出（统计Tab内）
- 位置：**统计Tab**
- **月度报告**：选择月份 → 生成该月报告（含饼图+汇总数据）
- **年度报告**：选择年份 → 生成该年报告（含趋势图+汇总数据）
- 导出格式：**PDF** 或 **PNG**
- 用途：个人留存查看，不可导入

### 4.6 数据备份导出（统计Tab内）
- 位置：**统计Tab**
- 格式：**JSON**（完整数据库导出，含所有表数据）
- 用途：数据迁移，换手机后导入恢复
- **第一优先级功能**：从 v1.0 即必须可用，确保后续升级时数据无缝迁移

### 4.7 预算管理
- 按支出分类设置月度预算
- 日历页显示预算进度条
- 超支时**红色预警提示**

### 4.8 周期性账单
- 设置定期收支（如房租、订阅等）
- 支持周期：每月、每季度、每年
- 两种处理方式：
  1. **自动生成记录**：到期自动添加账单
  2. **提醒确认**：到期时提醒用户手动确认

### 4.9 数据导入恢复（我的Tab内）
- 位置：**我的Tab → 设置**
- 从手机存储选取 JSON 备份文件
- **冲突检测流程**：
  1. 解析备份文件，提取所有记录的日期范围
  2. 与本地数据库比对，找出重叠日期
  3. **无重叠** → 直接导入
  4. **有重叠** → 弹窗警告：
  ```
  ┌──────────────────────────────────────────┐
  │  ⚠️ 检测到数据冲突                        │
  │                                          │
  │  2026年06月：15条记录重叠                 │
  │  2026年07月：8条记录重叠                  │
  │                                          │
  │  建议先导出当前数据作为备份               │
  │                                          │
  │  [先备份再导入]  [直接覆盖]  [取消]       │
  └──────────────────────────────────────────┘
  ```
  5. 导入完成后刷新所有页面数据

### 4.10 定期提醒导出
- 位置：**我的Tab → 设置**
- 开关 + 提醒周期下拉选择（每月 / 每季度）
- 开关下方附带**图文教程**：如何导入恢复数据

### 4.11 暗色模式
- 亮色/暗色双主题
- 在"我的"页面中一键切换

---

## 五、分类体系

### 支出分类（8个预置）

| 分类名 | 图标参考 | 说明 |
|--------|---------|------|
| 食物 | 🍔 | 餐饮、外卖、零食 |
| 交通 | 🚇 | 地铁、公交、打车、加油 |
| 衣物 | 👕 | 服装、鞋帽、配饰 |
| 娱乐 | 🎮 | 游戏、电影、旅游、休闲 |
| 教育 | 📚 | 课程、书籍、培训 |
| 工作 | 💻 | 办公用品、设备、技能提升 |
| 医疗 | 💊 | 看病、药品、体检 |
| 人情 | 🎁 | 红包、礼品、聚餐AA |

### 收入分类（4个预置 + 自定义）

| 分类名 | 说明 |
|--------|------|
| 工资 | 正式工作收入 |
| 兼职 | 兼职工作收入 |
| 投资 | 理财、股票等收益 |
| 其他 | 未分类收入 |
| 自定义 | 用户可自行命名收入来源 |

---

## 六、数据库设计（5张表）

### 6.1 分类表 (categories)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 分类名称 |
| type | TEXT | 'income' 或 'expense' |
| icon | TEXT | 图标代码 |
| color | TEXT | 颜色值 |
| is_default | INTEGER | 0=用户自定义, 1=预置 |
| created_at | TEXT | 创建时间 |

### 6.2 收支记录表 (transactions)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| amount | REAL | 金额（正数） |
| type | TEXT | 'income' 或 'expense' |
| category_id | INTEGER FK | 关联分类 |
| custom_name | TEXT | 自定义收入来源名称（可空） |
| note | TEXT | 备注 |
| date | TEXT | 日期 YYYY-MM-DD |
| is_recurring | INTEGER | 0=否, 1=是 |
| recurring_interval | TEXT | 'monthly'/'quarterly'/'yearly' |
| created_at | TEXT | 创建时间 |

### 6.3 兼职工作表 (part_time_jobs)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 兼职名称 |
| default_hourly_rate | REAL | 默认时薪 |
| note | TEXT | 备注 |
| is_active | INTEGER | 0=停用, 1=启用 |

### 6.4 工时记录表 (work_sessions)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| job_id | INTEGER FK | 关联兼职 |
| hours_worked | REAL | 工时（小时） |
| hourly_rate | REAL | 实际时薪 |
| total_income | REAL | 本次收入（工时×时薪） |
| date | TEXT | 日期 YYYY-MM-DD |
| note | TEXT | 备注 |

### 6.5 预算表 (budgets)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| category_id | INTEGER FK | 关联支出分类 |
| amount | REAL | 预算金额 |
| month | TEXT | 月份 YYYY-MM |

### 6.6 周期性账单规则表 (recurring_rules)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| amount | REAL | 金额 |
| type | TEXT | 'income' 或 'expense' |
| category_id | INTEGER FK | 关联分类 |
| note | TEXT | 备注 |
| interval | TEXT | 'monthly'/'quarterly'/'yearly' |
| next_date | TEXT | 下次执行日期 |
| reminder_enabled | INTEGER | 0=自动生成, 1=提醒确认 |
| is_active | INTEGER | 0=停用, 1=启用 |

---

## 七、项目目录结构

```
CoinConquer/
├── lib/
│   ├── main.dart                      # 入口
│   ├── app.dart                       # MaterialApp + 主题
│   ├── theme/
│   │   ├── app_theme.dart             # 亮/暗主题定义
│   │   └── colors.dart                # 品牌色
│   ├── models/
│   │   ├── transaction.dart
│   │   ├── category.dart
│   │   ├── part_time_job.dart
│   │   ├── work_session.dart
│   │   ├── budget.dart
│   │   └── recurring_rule.dart
│   ├── database/
│   │   └── database_helper.dart       # SQLite 操作
│   ├── providers/
│   │   ├── transaction_provider.dart
│   │   ├── category_provider.dart
│   │   ├── balance_provider.dart
│   │   ├── budget_provider.dart
│   │   └── recurring_provider.dart
│   ├── screens/
│   │   ├── calendar/                   # 📅 日历Tab
│   │   │   └── calendar_screen.dart
│   │   ├── statistics/                 # 📊 统计Tab
│   │   │   ├── statistics_screen.dart
│   │   │   └── export_backup.dart      # 导出数据备份(JSON)
│   │   ├── mine/                       # 👤 我的Tab
│   │   │   ├── mine_screen.dart
│   │   │   ├── budget_setting.dart     # 预算设置
│   │   │   ├── recurring_bills.dart    # 周期性账单
│   │   │   ├── category_manage.dart    # 分类管理
│   │   │   ├── import_restore.dart     # 导入恢复(冲突检测)
│   │   │   └── remind_export.dart      # 定期提醒导出
│   │   └── add_transaction/           # FAB记账页面
│   │       └── add_transaction_screen.dart
│   ├── widgets/                        # 通用组件
│   │   ├── amount_input.dart           # 金额输入
│   │   ├── category_picker.dart        # 分类选择器
│   │   └── transaction_tile.dart       # 流水列表项
│   └── utils/
│       ├── formatters.dart             # 金额格式化
│       └── date_utils.dart             # 日期工具
│
├── pubspec.yaml                        # 依赖配置
├── PROJECT_OVERVIEW.md                 # 本文件
└── README.md
```

---

## 八、开发阶段

| 阶段 | 内容 | 状态 |
|------|------|------|
| **0. 环境搭建** | 安装 Flutter SDK + Android Studio，创建项目，配置依赖 | ✅ 完成 |
| **1. 骨架搭建** | 主题系统、3Tab导航、Provider架构、数据模型 | ✅ 完成 |
| **2. 数据库层** | 建表、CRUD操作、预置分类数据 | ✅ 完成 |
| **3. 记账核心** | 添加/编辑/删除交易、分类选择、流水显示 | ✅ 完成 |
| **4. 日历视图** | 月历组件、日期标记、点击查看当日流水 | ✅ 完成 |
| **5. 统计模块** | 饼图、折线图、月度总结报告、余额系统 | ✅ 完成 |
| **6. 数据导出** | 导出数据备份(JSON) | ✅ 完成 |
| **7. 数据导入** | 粘贴JSON备份、冲突检测、数据恢复 | ✅ 完成 |
| **8. 高级功能** | 预算设置、周期性账单、分类管理 | ✅ 完成 |
| **9. 设置完善** | 定期提醒导出、导入教程 | ✅ 完成 |
| **10. UI 重构** | iOS 纯白风格、余额系统、兼职集成到记账 | ✅ 完成 |
| **11. 打包发布** | 自定义图标、编译APK | ✅ 完成 |

---

## 九、变更记录

| 日期 | 变更内容 |
|------|---------|
| 2026-06-30 | 初始创建，确定全部需求和方案 |
| 2026-06-30 | 移除计时器功能，改为手动录入工时 |
| 2026-06-30 | 导航调整为：日历 / 统计 / 我的，3个Tab |
| 2026-06-30 | 重构数据管理模块：补充存储空间估算；拆分导出为图形报告和数据备份；增加导入冲突检测流程；增加定期提醒导出+导入恢复教程 |
| 2026-06-30 | UI全面重构为iOS纯白风格；取消暗色模式；取消兼职管理模块，兼职收入集成到记账页；新增余额系统；数字键盘支持小数点；中文名硬币征服者；自定义app图标 |

---

## 十、自定义 App 图标

### 10.1 修改步骤

1. **准备图标图片**：准备一张 1024×1024 像素的 PNG 图片，命名为 `icon.png`，放到项目根目录（`coin_conquer/` 同级目录，即 `WorkArea/icon.png`）。

2. **复制到 Android 资源目录**：运行以下 PowerShell 命令将图标复制到所有分辨率目录：

```powershell
$icon = "C:\Users\16023\WorkArea\icon.png"
$resDir = "C:\Users\16023\WorkArea\CoinConquer\coin_conquer\android\app\src\main\res"
$dirs = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")
foreach ($d in $dirs) {
    Copy-Item $icon -Destination "$resDir\$d\ic_launcher.png" -Force
}
```

3. **重新编译 APK**：

```powershell
cd C:\Users\16023\WorkArea\CoinConquer\coin_conquer
flutter build apk --debug
```

### 10.2 Android 各尺寸参考

| 目录 | 图标尺寸（像素） |
|------|----------------|
| `mipmap-mdpi` | 48 × 48 |
| `mipmap-hdpi` | 72 × 72 |
| `mipmap-xhdpi` | 96 × 96 |
| `mipmap-xxhdpi` | 144 × 144 |
| `mipmap-xxxhdpi` | 192 × 192 |

> Android 系统会自动缩放过大或过小的图标，直接使用高分辨率原图即可。

---

> 本文档为 CoinConquer（硬币征服者）项目唯一权威参考源。所有后续开发决策均需与此文档保持一致。需求变更时，需同步更新本文档。

---

## 十一、iOS 版本编译指南

### 11.1 前提条件

iOS 版本**必须在 macOS 上编译**（需要 Xcode），Windows 无法直接编译 iOS。

| 需要 | 说明 |
|------|------|
| Mac 电脑 | macOS 14+ (Sonoma) |
| Xcode 16+ | 从 Mac App Store 安装 |
| Flutter SDK | 在 Mac 上安装（同 Windows 步骤） |
| Apple ID | 免费账号即可真机调试（7天签名有效期） |

### 11.2 在 Mac 上编译步骤

1. **安装 Flutter**（macOS）：
```bash
# 下载 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
```

2. **拉取项目代码**（将当前项目文件夹复制到 Mac）：
```bash
# 将整个 CoinConquer 文件夹复制到 Mac 上
# 建议放到 ~/WorkArea/CoinConquer/
```

3. **安装依赖并编译**：
```bash
cd ~/WorkArea/CoinConquer/coin_conquer
flutter pub get
cd ios
pod install  # 安装 iOS 原生依赖
cd ..
flutter build ios --release
```

4. **使用 Xcode 打开项目**：
```bash
open ios/Runner.xcworkspace
```
   - 在 Xcode 中登录 Apple ID（Preferences → Accounts）
   - 选择 Runner target → Signing & Capabilities → 勾选 "Automatically manage signing"
   - 连接 iPhone，选择设备，点击 ▶ 运行

### 11.3 导出 IPA 安装包

```bash
flutter build ipa
```
生成的 IPA 文件在 `build/ios/ipa/` 目录下，可通过以下方式安装：
- **TestFlight**（需 Apple Developer 账号 $99/年）
- **蒲公英/fir.im**（企业分发）
- **Xcode 直连手机**安装（免费，7天签名有效）

### 11.4 iOS 已配置项

| 项目 | 状态 |
|------|------|
| App 图标 (icon.png) | ✅ 已复制所有尺寸到 Assets.xcassets |
| 开屏图案 (开屏图案.png) | ✅ 已配置 LaunchScreen.storyboard |
| 显示名称 "硬币征服者" | ✅ 已配置 CFBundleDisplayName |
| 包名 Bundle ID | `com.coinconquer.coinConquer`（如需修改在 Xcode 中改） |
