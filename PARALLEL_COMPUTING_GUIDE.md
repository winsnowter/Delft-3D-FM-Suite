# Delft3D-FM 并行运算配置指南

## 概述

本指南介绍如何使用 20 核 MPI 并行运算来运行香港海域 Delft3D-FM 水动力模型。

## 关键文件

| 文件 | 作用 |
|------|------|
| `dimr.xml` | DIMR 并行配置文件，定义 MPI 进程分配 |
| `run_dflowfm.bat` | 主运行脚本，自动完成分区、运行、合并 |

## 一、并行运算原理

### MPI 并行计算流程

```
[原始网格]
    ↓ (分区)
[20个子域网格]
    ↓ (并行计算)
[20个进程同时运行]
    ↓ (合并输出)
[完整结果文件]
```

### 为什么需要并行计算？

| 方式 | 计算时间 | 适用场景 |
|------|----------|----------|
| 单核串行 | ~20-30 小时 | 测试运行 |
| 20核并行 | ~2-3 小时 | 生产运行 |

模拟 1 个月（2022-01-01 至 2022-02-01），20 核并行可节省约 **85-90% 的时间**。

## 二、dimr.xml 配置详解

### 文件位置

- 根目录: `E:\HK_model\HK_boudary_model\1205\dimr.xml`

### 核心配置项

```xml
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<dimrConfig xmlns="http://schemas.deltares.nl/dimr"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://schemas.deltares.nl/dimr https://content.oss.deltares.nl/schemas/dimr-1.2.xsd">

  <control>
    <start name="HK-DFM11" />
  </control>

  <component name="HK-DFM11">
    <library>dflowfm</library>

    <!-- 20核并行：进程 0-19 -->
    <process>0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19</process>

    <!-- MPI 通信器 -->
    <mpiCommunicator>DFM_COMM_DFMWORLD</mpiCommunicator>

    <!-- 工作目录（当前目录） -->
    <workingDir>.</workingDir>

    <!-- 输入文件 -->
    <inputFile>HK-DFM11.mdu</inputFile>
  </component>

</dimrConfig>
```

### 参数说明

#### 1. `<process>` - 进程列表

定义使用的 MPI 进程编号。

| 核心数 | 进程列表 |
|--------|----------|
| 10核 | `0 1 2 3 4 5 6 7 8 9` |
| 20核 | `0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19` |
| 16核 | `0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15` |

**注意**：
- 进程编号从 0 开始
- 进程数量必须与 `run_dflowfm.bat` 中的分区数一致

#### 2. `<mpiCommunicator>` - MPI 通信器

固定值: `DFM_COMM_DFMWORLD`

这是 Delft3D-FM 使用的 MPI 通信器名称，用于进程间通信。

#### 3. `<workingDir>` - 工作目录

| 值 | 说明 |
|----|------|
| `.` | 当前目录（推荐） |
| `dflowfm` | 切换到 dflowfm 子目录 |

**重要**：工作目录必须与 `run_dflowfm.bat` 中的路径一致。

#### 4. `<inputFile>` - 模型配置文件

指向主 MDU 文件: `HK-DFM11.mdu`

## 三、run_dflowfm.bat 脚本详解

### 完整脚本

```batch
@ echo off
title run_dflowfm_parallel_20cores

rem 设置 Delft3D 安装路径
set D3D_HOME=C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64

rem 切换到模型目录
cd /d "%CD%\dflowfm"

rem ============================================
rem 步骤 1: 网格分区（20 个子域）
rem ============================================
call "%D3D_HOME%\bin\run_dflowfm.bat" "--partition:ndomains=20:icgsolver=6" HK-DFM11.mdu

rem ============================================
rem 步骤 2: MPI 并行运行（20 个进程）
rem ============================================
call "%D3D_HOME%\bin\run_dimr_parallel.bat" 20 dimr.xml

rem ============================================
rem 步骤 3: 合并输出文件
rem ============================================
cd DFM_OUTPUT_HK-DFM11
dir /b *0*_map.nc > merge_filelist.txt
call "%D3D_HOME%\dflowfm\scripts\run_dfmoutput.bat" mapmerge --force --listfile "merge_filelist.txt"

pause
```

### 三个关键步骤

#### 步骤 1: 网格分区

```batch
call "%D3D_HOME%\bin\run_dflowfm.bat" "--partition:ndomains=20:icgsolver=6" HK-DFM11.mdu
```

**参数说明**：

| 参数 | 值 | 说明 |
|------|------|------|
| `ndomains` | 20 | 分成 20 个子域 |
| `icgsolver` | 6 | 使用 PETSc 并行求解器（推荐） |

**输出文件**：
- `HK_grid_0000_net.nc` ~ `HK_grid_0019_net.nc` - 20 个分区网格
- `HK-DFM11_0000.mdu` ~ `HK-DFM11_0019.mdu` - 20 个分区配置文件
- `DFM_interpreted_idomain_HK_grid_net.nc` - 分区信息

#### 步骤 2: 并行运行

```batch
call "%D3D_HOME%\bin\run_dimr_parallel.bat" 20 dimr.xml
```

**参数说明**：
- `20` - MPI 进程数（必须与 `ndomains` 一致）
- `dimr.xml` - DIMR 配置文件

**运行过程**：
- 启动 20 个 MPI 进程
- 每个进程负责一个子域
- 进程间通过 MPI 通信交换边界信息

#### 步骤 3: 合并输出

```batch
call "%D3D_HOME%\dflowfm\scripts\run_dfmoutput.bat" mapmerge --force --listfile "merge_filelist.txt"
```

将 20 个分区的 `*_map.nc` 文件合并为单个文件。

**输出**：
- `HK-DFM11_merged_map.nc` - 合并后的地图文件

## 四、如何修改核心数

### 示例：从 20 核改为 16 核

#### 1. 修改 dimr.xml

```xml
<process>0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15</process>
```

#### 2. 修改 run_dflowfm.bat

**步骤 1 - 分区**：
```batch
call "%D3D_HOME%\bin\run_dflowfm.bat" "--partition:ndomains=16:icgsolver=6" HK-DFM11.mdu
```

**步骤 2 - 运行**：
```batch
call "%D3D_HOME%\bin\run_dimr_parallel.bat" 16 dimr.xml
```

### 不同核心数的选择

| 核心数 | 适用场景 | 内存需求 |
|--------|----------|----------|
| 4-8 核 | 测试运行 | ~8-16 GB |
| 16 核 | 标准运行 | ~16-32 GB |
| 20 核 | 生产运行 | ~20-40 GB |
| 32+ 核 | 大规模模拟 | >40 GB |

**建议**：
- 核心数 = 物理 CPU 核心数（避免超线程）
- 确保有足够内存（每核心约 2 GB）

## 五、首次运行准备

### 安装 Intel MPI 服务

**仅需一次**，以管理员身份运行：

```batch
cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
hydra_service.exe -install
mpiexec.exe -register -username <用户名> -password <密码> -noprompt
```

### 检查安装

```batch
cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
mpiexec.exe -help
```

如果显示帮助信息，说明安装成功。

## 六、运行模型

### 方法 1：双击运行（推荐）

1. 打开文件资源管理器
2. 进入 `E:\HK_model\HK_boudary_model\1205`
3. 双击 `run_dflowfm.bat`

### 方法 2：命令行运行

```batch
cd /d E:\HK_model\HK_boudary_model\1205
run_dflowfm.bat
```

### 运行时间估算

| 模拟时长 | 20核并行 | 10核并行 |
|----------|----------|----------|
| 1 天 | ~5 分钟 | ~10 分钟 |
| 1 周 | ~30 分钟 | ~1 小时 |
| 1 个月 | ~2-3 小时 | ~4-6 小时 |
| 1 年 | ~24-36 小时 | ~48-72 小时 |

## 七、常见问题

### 1. 错误：MPI 服务未启动

**错误信息**：
```
Unable to connect to the hydra_pmi_proxy
```

**解决方法**：
安装 Intel MPI 服务（见第五节）。

### 2. 错误：分区数与进程数不匹配

**错误信息**：
```
Number of subdomains (20) does not match number of processes (16)
```

**解决方法**：
确保 `dimr.xml` 中的进程数与 `run_dflowfm.bat` 中的 `ndomains` 一致。

### 3. 警告：Horizontal transport flux was limited

这是正常的警告，表示模型在某些区域对物质输运进行了限制以保证数值稳定性。

**处理方式**：
- 如果模型持续运行，可以忽略
- 如果警告数量激增，考虑减小时间步长

### 4. 内存不足

**错误信息**：
```
Out of memory
```

**解决方法**：
- 减少核心数（例如从 20 核降到 16 核）
- 增加计算机内存
- 减少输出频率

### 5. 合并失败

**错误信息**：
```
Error merging map files
```

**解决方法**：
检查分区文件是否完整：
```batch
cd dflowfm\DFM_OUTPUT_HK-DFM11
dir *0*_map.nc
```

应该有 20 个文件（`_0000_map.nc` 到 `_0019_map.nc`）。

## 八、性能优化建议

### 1. 求解器选择

| icgsolver | 说明 | 性能 |
|-----------|------|------|
| 4 | sobekGS + Saadilud | 中等 |
| 6 | PETSc（推荐） | 最快 |
| 7 | parallel GS + CG | 较快 |

### 2. 时间步长优化

当前设置：
```
DtMax = 300 s
DtInit = 30 s
CFLMax = 0.8
```

如果模型不稳定：
- 减小 `DtMax` 到 240 s 或 180 s
- 减小 `CFLMax` 到 0.7 或 0.6

### 3. 输出频率优化

当前设置：
```
HisInterval = 86400 s  (24小时)
MapInterval = 43200 s  (12小时)
```

如果磁盘空间有限：
- 增加 `MapInterval` 到 86400 s（24小时）
- 减少输出变量（修改 `Wrimap_*` 参数）

### 4. 分区数选择

| 网格大小 | 推荐分区数 |
|----------|-----------|
| < 5万单元 | 4-8 |
| 5-10万单元 | 8-16 |
| 10-20万单元 | 16-32 |
| > 20万单元 | 32+ |

当前模型约 **12万单元**，20 核并行是合理的选择。

## 九、输出文件说明

### 分区文件（自动生成，可删除）

```
dflowfm/
├── HK_grid_0000_net.nc ~ HK_grid_0019_net.nc   (分区网格)
├── HK-DFM11_0000.mdu ~ HK-DFM11_0019.mdu       (分区配置)
├── HK-DFM11_0000.cache ~ HK-DFM11_0019.cache   (缓存文件)
└── DFM_interpreted_idomain_*.nc                 (分区信息)
```

这些文件在下次运行时会重新生成，可以安全删除以节省空间。

### 输出文件（保留）

```
dflowfm/output/
├── HK-DFM11_merged_map.nc    (合并后的地图文件)
├── HK-DFM11_his.nc           (历史输出)
├── HK-DFM11_rst.nc           (重启文件)
└── HK-DFM11.dia              (诊断日志)
```

## 十、检查清单

运行前检查：

- [ ] 已安装 Intel MPI 服务（`hydra_service.exe -install`）
- [ ] `dimr.xml` 中的进程数正确（20 个）
- [ ] `run_dflowfm.bat` 中的 `ndomains=20`
- [ ] `run_dflowfm.bat` 中的 MPI 进程数=20
- [ ] D3D_HOME 路径正确
- [ ] 有足够磁盘空间（建议 >50 GB）
- [ ] 有足够内存（建议 >32 GB）

运行后检查：

- [ ] 分区成功（生成 20 个 `*_net.nc` 文件）
- [ ] 并行运行成功（无 MPI 错误）
- [ ] 输出文件完整（20 个 `*_map.nc` 文件）
- [ ] 合并成功（生成 `*_merged_map.nc`）

## 十一、技术支持

### Deltares 官方资源

- D-Flow FM 用户手册: https://www.deltares.nl/en/software/delft3d-fm-suite/
- 并行计算指南: https://oss.deltares.nl/web/delft3dfm/parallel-computing

### 问题报告

如遇到问题，请提供：
1. 错误信息截图
2. `*.dia` 诊断日志文件
3. 计算机配置（CPU、内存）
4. Delft3D-FM 版本

---

**最后更新**: 2025-12-05
**模型版本**: HK-DFM11 (1205 case)
**并行配置**: 20 核 MPI + PETSc 求解器
