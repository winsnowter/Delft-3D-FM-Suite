# Hong Kong Delft3D-FM Hydrodynamic Model

香港海域 Delft3D-FM 三维水动力模型 (1205 运行案例)

## 项目概述

这是一个基于 Delft3D-FM (D-Flow Flexible Mesh) 的三维水动力模型，用于模拟香港及周边海域（包括珠江口、深圳湾等）的水动力、盐度和温度传输过程。

### 模型特点

- **三维模型**: 20 层 sigma 垂直坐标
- **非结构网格**: 变分辨率（精细区域 ~75m）
- **物理过程**: 水动力 + 盐度 + 温度 + k-epsilon 湍流
- **并行计算**: 支持 20 核 MPI 并行
- **模拟时间**: 2022-01-01 至 2022-02-01

## 快速开始

### 系统要求

- Windows 10/11 (64-bit)
- Delft3D FM Suite 2025.01 HMWQ
- 内存: ≥32 GB (推荐)
- 磁盘: ≥50 GB 可用空间
- CPU: 16-32 核心 (推荐 20 核)

### 运行模型

1. **首次运行** - 安装 Intel MPI 服务（以管理员身份）：
   ```batch
   cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
   hydra_service.exe -install
   ```

2. **启动模拟** - 双击运行：
   ```
   run_dflowfm.bat
   ```

3. **等待完成** - 20 核并行约需 2-3 小时

### 输出结果

模拟完成后，结果文件位于 `dflowfm/output/`:
- `HK-DFM11_merged_map.nc` - 空间场数据（水位、流速、盐度、温度）
- `HK-DFM11_his.nc` - 观测站时间序列
- `HK-DFM11_rst.nc` - 重启文件

## 文档

- [**CLAUDE.md**](CLAUDE.md) - 详细的模型配置和参数说明
- [**PARALLEL_COMPUTING_GUIDE.md**](PARALLEL_COMPUTING_GUIDE.md) - 并行计算配置指南

## 目录结构

```
1205/
├── README.md                    # 本文件
├── CLAUDE.md                    # 模型详细文档
├── PARALLEL_COMPUTING_GUIDE.md  # 并行计算指南
├── run_dflowfm.bat              # 主运行脚本（20核并行）
├── dimr.xml                     # DIMR 并行配置
├── dimr_config.xml              # DIMR 配置（备用）
│
└── dflowfm/                     # 模型输入文件
    ├── HK-DFM11.mdu             # 主配置文件
    ├── HK_grid_net.nc           # 计算网格
    │
    ├── 边界条件/
    │   ├── east_bnd_20251126.*   # 东边界
    │   ├── south_bnd_20251126.*  # 南边界
    │   ├── west_bnd_20251126.*   # 西边界
    │   └── OB_*_20251126.bc      # 盐度/温度边界
    │
    ├── 结构物/
    │   ├── Hzm_bridge.pliz       # 港珠澳大桥
    │   ├── cbl_JB.pliz           # JB 桥
    │   └── Deepbay_bridge.pliz   # 深圳湾大桥
    │
    └── WQ_Input/PRD/             # 珠江河流输入
        ├── Humen.pli/tim         # 虎门
        ├── Jiaomen.pli/tim       # 蕉门
        └── ...                   # 其他入海口
```

## 模型配置

### 基本参数

| 参数 | 值 |
|------|------|
| 参考日期 | 2022-01-01 |
| 模拟时长 | 31 天 |
| 最大时间步 | 300 s |
| 垂直层数 | 20 层 sigma |
| 底摩擦 | Manning 0.025 |
| 湍流模型 | k-epsilon |

### 边界条件

- **开边界**: 东、南、西三个边界
  - 潮位: 天文潮（FES2014）
  - 盐度: 时间序列
  - 温度: 时间序列

- **河流输入**: 珠江三角洲 11 个入海口
  - 虎门、蕉门、洪奇沥、横门、磨刀门等

### 物理过程

- 水动力计算
- 盐度输运（初始值 30 psu）
- 温度输运（初始值 20°C）
- k-epsilon 湍流模型
- 桥墩阻力效应

## 并行计算

模型配置为 20 核 MPI 并行：

- **分区方法**: K-Way 分区
- **求解器**: PETSc (icgsolver=6)
- **进程数**: 20 个 MPI 进程
- **通信器**: DFM_COMM_DFMWORLD

详细配置请参考 [PARALLEL_COMPUTING_GUIDE.md](PARALLEL_COMPUTING_GUIDE.md)

### 修改核心数

如需修改并行核心数（例如改为 16 核）：

1. 修改 `dimr.xml` 中的 `<process>` 列表
2. 修改 `run_dflowfm.bat` 中的 `ndomains=16`
3. 修改 `run_dflowfm.bat` 中的 MPI 进程数为 16

## 常见问题

### 1. "Horizontal transport flux was limited"

这是正常警告，表示模型对输运通量进行了限制以保证稳定性。如果模型持续运行且警告数量稳定，可以忽略。

### 2. MPI 服务未启动

确保已安装 Intel MPI 服务：
```batch
cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
hydra_service.exe -install
```

### 3. 内存不足

- 减少核心数（例如从 20 核降到 16 核）
- 增加物理内存
- 减少输出频率

## 结果后处理

推荐使用以下工具分析结果：

- **Python**: `xarray`, `netCDF4`, `matplotlib`
- **MATLAB**: 使用 Deltares 提供的工具箱
- **DeltaShell**: Deltares 官方后处理界面

## 许可证

本模型基于 Deltares Delft3D-FM Suite 构建。使用前请确保拥有相应的软件许可。

## 致谢

- 模型软件: Deltares Delft3D FM Suite 2025.01 HMWQ
- 潮汐数据: FES2014
- 气象数据: ERA5

## 联系方式

- GitHub: [@winsnowter](https://github.com/winsnowter)
- 项目仓库: [Delft-3D-FM-Suite](https://github.com/winsnowter/Delft-3D-FM-Suite)

---

**创建日期**: 2025-12-05
**模型版本**: HK-DFM11 (1205 case)
**软件版本**: Delft3D FM 1.2.184
