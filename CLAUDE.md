# 香港海域 Delft3D-FM 水动力模型 - 1205 运行案例

## 项目概述

这是一个基于 Delft3D-FM (D-Flow Flexible Mesh) 的三维水动力模型项目，用于模拟香港及周边海域的水动力、盐度和温度传输过程。

### 基本信息

| 项目 | 内容 |
|------|------|
| 模型软件 | Deltares D-Flow FM 1.2.184 |
| 安装路径 | `C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ` |
| 模型维度 | 3D (20 个垂直 sigma 层) |
| 坐标系统 | WGS84 地理坐标系 |
| 模拟时间 | 2022-01-01 ~ 2022-02-01 (1 个月) |
| 并行计算 | 20 核 MPI 并行 |

## 目录结构

```
1205/
├── run_dflowfm.bat              # 主运行脚本（20核并行）
├── dimr.xml                     # DIMR 并行配置文件（根目录）
├── dimr_config.xml              # DIMR 配置文件（备用）
├── run_parallel.bat             # 备用并行运行脚本
├── hydra_service.exe            # Intel MPI 服务程序
│
└── dflowfm/                     # 模型输入文件目录
    ├── HK-DFM11.mdu             # 主配置文件
    ├── dimr.xml                 # DIMR 配置（工作目录版本）
    ├── HK_grid_net.nc           # 计算网格文件
    │
    ├── 边界条件文件/
    │   ├── east_bnd_20251126.pli/bc    # 东边界（位置+潮位）
    │   ├── south_bnd_20251126.pli/bc   # 南边界
    │   ├── west_bnd_20251126.pli/bc    # 西边界
    │   ├── OB_sal_*.bc                 # 盐度边界条件
    │   └── OB_temp_*.bc                # 温度边界条件
    │
    ├── 外部强迫文件/
    │   ├── HK-FM_nowind.ext            # 旧格式外部强迫
    │   └── HK-FM_bnd_new.ext           # 新格式外部强迫
    │
    ├── 地形与结构/
    │   ├── HK-FM_dryPoints_75m_*.xyz   # 干点数据
    │   ├── 3RunWayDryArea_dry.pol      # 三跑道干区
    │   ├── landboundary_*.ldb_thd.pli  # 薄坝（陆地边界）
    │   ├── Hzm_bridge.pliz             # 港珠澳大桥桥墩
    │   ├── cbl_JB.pliz                 # JB 桥桥墩
    │   └── Deepbay_bridge.pliz         # 深圳湾大桥桥墩
    │
    ├── 观测与剖面/
    │   ├── HK-FM_20210802_obs.xyn      # 观测站位置
    │   └── HK-FM_20210629_crs.pli      # 剖面线
    │
    ├── 河流输入/
    │   └── WQ_Input/PRD/               # 珠江三角洲河流
    │       ├── Humen.pli/tim           # 虎门
    │       ├── Jiaomen.pli/tim         # 蕉门
    │       └── ...                     # 其他入海口
    │
    └── output/                         # 输出目录
        └── HK-DFM11.dia                # 诊断文件
```

## 模型配置

### 时间设置

| 参数 | 值 | 说明 |
|------|------|------|
| RefDate | 20220101 | 参考日期 |
| StartDateTime | 20220101000000 | 开始时间 |
| StopDateTime | 20220201000000 | 结束时间 |
| DtMax | 300 s | 最大时间步 |
| DtInit | 30 s | 初始时间步 |
| DtUser | 3600 s | 外部强迫更新间隔 |
| CFLMax | 0.8 | 最大 Courant 数 |

### 垂直分层

| 参数 | 值 | 说明 |
|------|------|------|
| Kmx | 20 | 垂直层数 |
| Layertype | 1 | sigma 坐标 |
| DzTop | 1 m | 表层厚度 |
| DzTopUniAboveZ | -5 m | 均匀层分界高程 |
| SigmaGrowthFactor | 1.2 | 底层增长因子 |

### 物理参数

| 参数 | 值 | 说明 |
|------|------|------|
| UnifFrictType | 1 | Manning 公式 |
| UnifFrictCoef | 0.025 | 底摩擦系数 |
| Vicouv | 0.1 m²/s | 水平涡粘系数 |
| Vicoww | 5E-05 m²/s | 垂直涡粘系数 |
| Turbulencemodel | 3 | k-epsilon 湍流模型 |
| Smagorinsky | 0.15 | Smagorinsky 因子 |
| Ag | 9.813 m/s² | 重力加速度 |

### 盐度与温度

| 参数 | 值 | 说明 |
|------|------|------|
| Salinity | 1 | 包含盐度计算 |
| InitialSalinity | 30 psu | 初始盐度 |
| Backgroundsalinity | 34.5 psu | 背景盐度 |
| Temperature | 1 | 包含温度计算 |
| InitialTemperature | 20°C | 初始温度 |
| Secchidepth | 4 m | 透明度 |

### 输出设置

| 参数 | 值 | 说明 |
|------|------|------|
| HisInterval | 86400 s | 历史输出间隔 (24h) |
| MapInterval | 43200 s | 地图输出间隔 (12h) |
| RstInterval | 864000 s | 重启文件间隔 (10d) |
| WaqInterval | 43200 s | DELWAQ 输出间隔 |
| OutputDir | output | 输出目录 |

## 运行模型

### 并行运行（20核）

双击运行：
```
run_dflowfm.bat
```

该脚本执行三个步骤：
1. **分区** - 将模型分成 20 个子域
2. **并行计算** - 使用 20 个 MPI 进程运行
3. **合并输出** - 合并分区的 map 文件

### 首次运行准备

如果是首次在此机器上使用 Intel MPI，需要以管理员身份运行：
```batch
cd "C:\Program Files\Deltares\Delft3D FM Suite 2025.01 HMWQ\plugins\DeltaShell.Dimr\kernels\x64\share\bin"
hydra_service.exe -install
```

### 并行配置文件

**dimr.xml** (dflowfm 目录下):
```xml
<component name="HK-DFM11">
  <library>dflowfm</library>
  <process>0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19</process>
  <mpiCommunicator>DFM_COMM_DFMWORLD</mpiCommunicator>
  <workingDir>.</workingDir>
  <inputFile>HK-DFM11.mdu</inputFile>
</component>
```

## 常见警告说明

### "Horizontal transport flux was limited for X links"

这是正常的警告，表示模型在某些网格连接上对水平物质输运通量进行了限制以保证数值稳定性。

**产生原因**：
- 局部 Courant 数较大
- 盐度/温度梯度较大（如珠江口区域）
- 网格分辨率不均匀

**处理方式**：
- 如果模型持续运行且警告数量稳定，可以忽略
- 如果警告数量不断增加，考虑减小 DtMax 或 CFLMax

## 输出文件

运行完成后，输出文件位于 `dflowfm/output/` 目录：

| 文件类型 | 说明 |
|----------|------|
| *_map.nc | 空间场输出（水位、流速、盐度、温度等） |
| *_his.nc | 观测站时间序列 |
| *_rst.nc | 重启文件 |
| *.dia | 诊断日志文件 |

## 修改核心数

如需修改并行核心数（例如改为 16 核）：

1. 修改 `dflowfm/dimr.xml`:
   ```xml
   <process>0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15</process>
   ```

2. 修改 `run_dflowfm.bat`:
   - 分区命令: `--partition:ndomains=16:icgsolver=6`
   - MPI 进程数: `run_dimr_parallel.bat 16 dimr.xml`

## 技术支持

- Deltares D-Flow FM 文档: https://www.deltares.nl/en/software/delft3d-fm-suite/
- 项目创建日期: 2025-12-05
