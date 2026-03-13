# AWRCRT (AWR Chart Report Tool)

[中文](#中文) | [English](#english) | [日本語](#日本語) | [한국어](#한국어) | [Tiếng Việt](#tiếng-việt) | [ไทย](#ไทย)

---

<a name="中文"></a>
## 中文

**AWRCRT** 是一个用于生成可视化 Oracle AWR 报告的工具。它通过 SQL*Plus 读取 Oracle AWR 历史数据 (`dba_hist_*` 视图)，并生成包含交互式图表 (基于 Chart.js) 的 HTML 报告。它是比较老的项目，现在通过vibe coding更新后，发布在github。

相比传统的文本版 AWR 报告，AWRCRT 提供了更加直观的性能趋势分析，涵盖了 CPU、IO、Wait Events、Latch、Top SQL 等多个维度的可视化展示。
它应该在11.2之上的non-CDB环境工作正常，有一个forpdb版本，稍后更新。目前发现使用新版本的chart.js后，加载速度比以前慢，需要耐心等待浏览器响应。

### 主要功能

- **可视化图表**：使用 Chart.js 生成动态折线图和柱状图，支持缩放和鼠标悬停查看详情。
- **全面覆盖**：包含 Time Model, Wait Events, Latch, Mutex, OS Stats, Top SQL 等关键性能指标。
- **多实例支持**：支持指定实例号生成报告。
- **静默执行**：支持命令行参数传入，方便脚本自动化调度。
- **最新特性 (v2.2beta)**：
    - 升级至 **Chart.js 4.x**，提供更现代的 UI 和交互体验。
    - **负值处理**：自动修复因实例重启导致的计数器负值问题。
    - **异常处理**：增强 PL/SQL 异常捕获，防止 ORA- 错误导致报告截断或 JS 语法错误。
    - **唯一文件名**：生成的报告文件名包含时间戳，避免覆盖。

### 运行环境要求

- Oracle Database Client (`sqlplus`)
- 连接到目标数据库的用户需要有访问 `dba_hist_*` 视图的权限 (通常为 `SYSDBA` 或拥有 `SELECT_CATALOG_ROLE` 的用户)。
- 生成的 HTML 报告需要浏览器支持 JavaScript，且需要能够访问互联网以加载 CDN 资源 (Chart.js)。
  - *注：脚本默认使用 `https://cdn.jsdelivr.net/npm/chart.js`。*

### 使用方法

#### 1. 交互式模式

直接在 SQL*Plus 中运行脚本，按照提示输入参数：

```bash
sqlplus / as sysdba @awrcrt.sql
```

**执行流程**：
1.  脚本会列出当前实例信息。
2.  提示输入查看最近几天的快照 (`days`)。
3.  列出符合条件的快照列表。
4.  提示输入 **Begin Snap ID**。
5.  提示输入 **End Snap ID**。
6.  提示输入 **Instance Number**。
7.  提示是否检查 **Top SQL** (输入 `1` 为是，`0` 为否)。

#### 2. 命令行静默模式 (推荐用于脚本)

可以通过命令行直接传入 5 个参数，无需人工交互：

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**参数说明**：
1.  **days**：列出最近多少天的快照 (用于内部查询范围，即使静默执行也建议设置足够大的范围以包含目标快照)。建议的范围不要超过7天（1小时间隔的snapshot），否则导致运行缓慢。
2.  **begin_snap**：开始快照 ID。
3.  **end_snap**：结束快照 ID。
4.  **inst_num**：实例号 (例如 `1`)。
5.  **check_sql**：是否生成 Top SQL 统计 (`1`=生成, `0`=跳过)。 统计TopSQL会运行变慢。

**示例**：
生成最近 7 天内，快照 ID 从 100 到 110，实例 1 的报告，并包含 Top SQL 分析：
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### 输出文件

脚本执行完成后，会在当前目录下生成一个 HTML 文件，命名格式如下：
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

例如：
`awrcrt_ORCL_1_100_110_20240313103000.html`

直接使用浏览器打开该文件即可查看报告。

### 常见问题

- **报告图表不显示**：
    - 请检查浏览器是否禁用了 JavaScript。
    - 请检查网络是否连通，因为图表库依赖 CDN 加载。你也可以把chart.js下载到本地。但需要修改html中的引用，如果你希望长期使用本地文件，建议修改awrcrt.sql相应代码为本地chart.js路径。
    - 如果使用的是旧版浏览器 (如 IE)，建议使用 Chrome, Firefox, Edge 等现代浏览器。
    - 检查html中，是否记录了发生的ORA-错误，对应进行分析。ORA-错误可能破坏JS语法，导致图表无法显示。

- **部分图表数据为空**：
    - 可能是对应时间段内该指标没有数据 (如无相关等待事件)。
    - 如果遇到 `ORA-` 错误提示，脚本会自动捕获并记录在 HTML 源码注释中，通常不会影响其他图表的显示。

### 许可证

MIT License

---

<a name="english"></a>
## English

**AWRCRT** is a tool for generating visual Oracle AWR reports. It reads Oracle AWR historical data (`dba_hist_*` views) via SQL*Plus and generates HTML reports containing interactive charts (based on Chart.js).

Compared to traditional text-based AWR reports, AWRCRT provides more intuitive performance trend analysis, covering multiple dimensions such as CPU, IO, Wait Events, Latch, Top SQL, and more.

### Key Features

- **Visual Charts**: Generates dynamic line and bar charts using Chart.js, supporting zooming and hover details.
- **Comprehensive Coverage**: Includes key performance indicators such as Time Model, Wait Events, Latch, Mutex, OS Stats, Top SQL, etc.
- **Multi-Instance Support**: Supports generating reports for a specified instance number.
- **Silent Execution**: Supports command-line arguments for easy script automation scheduling.
- **Latest Features (v2.2beta)**:
    - Upgraded to **Chart.js 4.x**, providing a more modern UI and interactive experience.
    - **Negative Value Handling**: Automatically fixes negative counter values caused by instance reboots.
    - **Exception Handling**: Enhanced PL/SQL exception capturing to prevent ORA- errors from truncating reports or causing JS syntax errors.
    - **Unique Filenames**: Generated report filenames include timestamps to avoid overwriting.

### Requirements

- Oracle Database Client (`sqlplus`)
- The user connecting to the target database needs permission to access `dba_hist_*` views (usually `SYSDBA` or a user with `SELECT_CATALOG_ROLE`).
- The generated HTML report requires a browser with JavaScript support and internet access to load CDN resources (Chart.js).
  - *Note: The script uses `https://cdn.jsdelivr.net/npm/chart.js` by default.*

### Usage

#### 1. Interactive Mode

Run the script directly in SQL*Plus and follow the prompts to enter parameters:

```bash
sqlplus / as sysdba @awrcrt.sql
```

**Execution Flow**:
1.  The script lists current instance information.
2.  Prompts to enter the number of days for snapshots (`days`).
3.  Lists matching snapshots.
4.  Prompts for **Begin Snap ID**.
5.  Prompts for **End Snap ID**.
6.  Prompts for **Instance Number**.
7.  Prompts whether to check **Top SQL** (Enter `1` for Yes, `0` for No).

#### 2. Command Line Silent Mode (Recommended for Scripts)

You can pass 5 parameters directly via the command line without manual interaction:

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**Parameter Description**:
1.  **days**: List snapshots from the last N days (used for internal query scope; it is recommended to set a large enough range to include target snapshots even in silent execution). Recommended range not to exceed 7 days (1-hour snapshot interval), otherwise it may run slowly.
2.  **begin_snap**: Begin Snapshot ID.
3.  **end_snap**: End Snapshot ID.
4.  **inst_num**: Instance Number (e.g., `1`).
5.  **check_sql**: Whether to generate Top SQL statistics (`1`=Generate, `0`=Skip). Statistics TopSQL will run slower.

**Example**:
Generate a report for instance 1, snapshot IDs 100 to 110 within the last 7 days, including Top SQL analysis:
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### Output File

After execution, an HTML file will be generated in the current directory with the following naming format:
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

Example:
`awrcrt_ORCL_1_100_110_20240313103000.html`

Open this file directly in a browser to view the report.

### FAQ

- **Charts do not display**:
    - Check if JavaScript is disabled in the browser.
    - Check network connectivity, as the chart library relies on CDN loading. You can also download chart.js locally. But you need to modify the reference in html, if you want to use local files for a long time, it is recommended to modify the corresponding code of awrcrt.sql to the local chart.js path.
    - If using an old browser (like IE), it is recommended to use modern browsers like Chrome, Firefox, Edge.
    - Check the html to see if there are any ORA- errors recorded, and analyze them accordingly. ORA- errors may break JS syntax, causing charts not to display.

- **Some charts have empty data**:
    - There may be no data for that metric in the corresponding time period (e.g., no relevant wait events).
    - If an `ORA-` error is encountered, the script automatically captures and records it in HTML source comments, usually not affecting the display of other charts.

### License

MIT License

---

<a name="日本語"></a>
## 日本語

**AWRCRT**は、Oracle AWRレポートを視覚化するためのツールです。SQL*Plusを介してOracle AWR履歴データ（`dba_hist_*`ビュー）を読み取り、インタラクティブなチャート（Chart.jsベース）を含むHTMLレポートを生成します。

従来のテキストベースのAWRレポートと比較して、AWRCRTはCPU、IO、待機イベント、ラッチ、Top SQLなど、複数の次元をカバーするより直感的なパフォーマンス傾向分析を提供します。

### 主な機能

- **視覚的なチャート**: Chart.jsを使用して動的な折れ線グラフと棒グラフを生成し、ズームやホバーによる詳細表示をサポートします。
- **包括的なカバレッジ**: Time Model、待機イベント、ラッチ、Mutex、OS統計、Top SQLなどの主要なパフォーマンス指標を含みます。
- **マルチインスタンスサポート**: 指定されたインスタンス番号のレポート生成をサポートします。
- **サイレント実行**: コマンドライン引数をサポートし、スクリプトによる自動化スケジューリングに便利です。
- **最新機能 (v2.2beta)**:
    - **Chart.js 4.x**へのアップグレードにより、よりモダンなUIとインタラクティブな体験を提供します。
    - **負の値の処理**: インスタンスの再起動によって引き起こされるカウンターの負の値を自動的に修正します。
    - **例外処理**: PL/SQLの例外キャプチャを強化し、ORA-エラーによるレポートの切断やJS構文エラーを防止します。
    - **ユニークなファイル名**: 生成されたレポートファイル名にタイムスタンプを含め、上書きを回避します。

### 動作環境

- Oracle Database Client (`sqlplus`)
- ターゲットデータベースに接続するユーザーは、`dba_hist_*`ビューへのアクセス権限が必要です（通常は`SYSDBA`または`SELECT_CATALOG_ROLE`を持つユーザー）。
- 生成されたHTMLレポートには、JavaScriptをサポートするブラウザと、CDNリソース（Chart.js）をロードするためのインターネットアクセスが必要です。
  - *注：スクリプトはデフォルトで`https://cdn.jsdelivr.net/npm/chart.js`を使用します。*

### 使用方法

#### 1. インタラクティブモード

SQL*Plusでスクリプトを直接実行し、プロンプトに従ってパラメータを入力します：

```bash
sqlplus / as sysdba @awrcrt.sql
```

**実行フロー**:
1.  スクリプトは現在のインスタンス情報をリストします。
2.  スナップショットの対象日数（`days`）を入力するよう求められます。
3.  条件に一致するスナップショットをリストします。
4.  **Begin Snap ID**の入力を求められます。
5.  **End Snap ID**の入力を求められます。
6.  **Instance Number**の入力を求められます。
7.  **Top SQL**をチェックするかどうか尋ねられます（`1`ははい、`0`はいいえ）。

#### 2. コマンドラインサイレントモード（スクリプトに推奨）

手動操作なしで、コマンドラインから直接5つのパラメータを渡すことができます：

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**パラメータ説明**:
1.  **days**: 最近N日間のスナップショットをリストします（内部クエリ範囲用。サイレント実行でも、ターゲットスナップショットを含めるために十分な範囲を設定することをお勧めします）。推奨範囲は7日を超えないようにしてください（1時間間隔のスナップショット）、そうしないと実行が遅くなる原因となります。
2.  **begin_snap**: 開始スナップショットID。
3.  **end_snap**: 終了スナップショットID。
4.  **inst_num**: インスタンス番号（例：`1`）。
5.  **check_sql**: Top SQL統計を生成するかどうか（`1`=生成、`0`=スキップ）。TopSQLの統計は実行が遅くなります。

**例**:
最近7日間、スナップショットID 100から110、インスタンス1のレポートを生成し、Top SQL分析を含める場合：
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### 出力ファイル

実行完了後、現在のディレクトリに以下の命名形式でHTMLファイルが生成されます：
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

例：
`awrcrt_ORCL_1_100_110_20240313103000.html`

このファイルをブラウザで直接開いてレポートを表示します。

### よくある質問

- **チャートが表示されない**:
    - ブラウザでJavaScriptが無効になっていないか確認してください。
    - チャートライブラリはCDNのロードに依存しているため、ネットワーク接続を確認してください。chart.jsをローカルにダウンロードすることもできます。ただし、html内の参照を変更する必要があります。ローカルファイルを長期間使用したい場合は、awrcrt.sqlの対応するコードをローカルのchart.jsパスに変更することをお勧めします。
    - 古いブラウザ（IEなど）を使用している場合は、Chrome、Firefox、Edgeなどの最新のブラウザを使用することをお勧めします。
    - htmlを確認して、発生したORA-エラーが記録されているかどうかを確認し、それに応じて分析してください。ORA-エラーはJS構文を破壊し、チャートが表示されない原因となる可能性があります。

- **一部のチャートデータが空**:
    - 対応する期間内にその指標のデータがない可能性があります（例：関連する待機イベントがない）。
    - `ORA-`エラーが発生した場合、スクリプトは自動的にそれをキャプチャしてHTMLソースのコメントに記録しますが、通常は他のチャートの表示には影響しません。

### ライセンス

MIT License

---

<a name="한국어"></a>
## 한국어

**AWRCRT**는 Oracle AWR 보고서를 시각화하기 위한 도구입니다. SQL*Plus를 통해 Oracle AWR 기록 데이터(`dba_hist_*` 뷰)를 읽고 대화형 차트(Chart.js 기반)가 포함된 HTML 보고서를 생성합니다.

기존의 텍스트 기반 AWR 보고서와 비교하여 AWRCRT는 CPU, IO, 대기 이벤트(Wait Events), 래치(Latch), Top SQL 등 여러 차원을 다루는 보다 직관적인 성능 추세 분석을 제공합니다.

### 주요 기능

- **시각적 차트**: Chart.js를 사용하여 동적 꺾은선형 차트와 막대 차트를 생성하며, 확대/축소 및 마우스 오버 상세 보기를 지원합니다.
- **포괄적인 커버리지**: Time Model, Wait Events, Latch, Mutex, OS 통계, Top SQL 등 주요 성능 지표를 포함합니다.
- **다중 인스턴스 지원**: 지정된 인스턴스 번호에 대한 보고서 생성을 지원합니다.
- **자동 실행 (Silent Execution)**: 스크립트 자동화 스케줄링을 위한 명령줄 인수를 지원합니다.
- **최신 기능 (v2.2beta)**:
    - **Chart.js 4.x**로 업그레이드되어 보다 현대적인 UI와 대화형 경험을 제공합니다.
    - **음수 값 처리**: 인스턴스 재부팅으로 인한 카운터 음수 값을 자동으로 수정합니다.
    - **예외 처리**: PL/SQL 예외 캡처를 강화하여 ORA- 오류로 인한 보고서 잘림이나 JS 구문 오류를 방지합니다.
    - **고유 파일 이름**: 생성된 보고서 파일 이름에 타임스탬프를 포함하여 덮어쓰기를 방지합니다.

### 실행 환경 요구 사항

- Oracle Database Client (`sqlplus`)
- 대상 데이터베이스에 연결하는 사용자는 `dba_hist_*` 뷰에 액세스할 수 있는 권한이 있어야 합니다(일반적으로 `SYSDBA` 또는 `SELECT_CATALOG_ROLE` 권한을 가진 사용자).
- 생성된 HTML 보고서는 JavaScript를 지원하는 브라우저와 CDN 리소스(Chart.js)를 로드할 수 있는 인터넷 액세스가 필요합니다.
  - *참고: 스크립트는 기본적으로 `https://cdn.jsdelivr.net/npm/chart.js`를 사용합니다.*

### 사용 방법

#### 1. 대화형 모드

SQL*Plus에서 스크립트를 직접 실행하고 프롬프트에 따라 매개변수를 입력합니다:

```bash
sqlplus / as sysdba @awrcrt.sql
```

**실행 흐름**:
1.  스크립트가 현재 인스턴스 정보를 나열합니다.
2.  최근 며칠간의 스냅샷을 볼 것인지 입력하라는 메시지가 표시됩니다 (`days`).
3.  조건에 맞는 스냅샷 목록을 나열합니다.
4.  **Begin Snap ID** 입력을 요청합니다.
5.  **End Snap ID** 입력을 요청합니다.
6.  **Instance Number** 입력을 요청합니다.
7.  **Top SQL** 확인 여부를 묻습니다 (`1`은 예, `0`은 아니요).

#### 2. 명령줄 자동 모드 (스크립트에 권장)

수동 상호 작용 없이 명령줄을 통해 5개의 매개변수를 직접 전달할 수 있습니다:

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**매개변수 설명**:
1.  **days**: 최근 N일간의 스냅샷 나열 (내부 쿼리 범위용; 자동 실행에서도 대상 스냅샷을 포함할 수 있도록 충분히 큰 범위를 설정하는 것이 좋습니다). 범위는 7일을 초과하지 않는 것이 좋습니다(1시간 간격 스냅샷), 그렇지 않으면 실행 속도가 느려질 수 있습니다.
2.  **begin_snap**: 시작 스냅샷 ID.
3.  **end_snap**: 종료 스냅샷 ID.
4.  **inst_num**: 인스턴스 번호 (예: `1`).
5.  **check_sql**: Top SQL 통계 생성 여부 (`1`=생성, `0`=건너뛰기). TopSQL 통계는 실행 속도가 느려집니다.

**예시**:
최근 7일 이내, 스냅샷 ID 100에서 110, 인스턴스 1에 대한 보고서를 생성하고 Top SQL 분석을 포함하는 경우:
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### 출력 파일

실행이 완료되면 현재 디렉터리에 다음 명명 형식으로 HTML 파일이 생성됩니다:
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

예:
`awrcrt_ORCL_1_100_110_20240313103000.html`

이 파일을 브라우저에서 직접 열어 보고서를 확인하십시오.

### 자주 묻는 질문 (FAQ)

- **차트가 표시되지 않음**:
    - 브라우저에서 JavaScript가 비활성화되어 있는지 확인하십시오.
    - 차트 라이브러리가 CDN 로드에 의존하므로 네트워크 연결을 확인하십시오. chart.js를 로컬에 다운로드할 수도 있습니다. 하지만 html의 참조를 수정해야 하며, 로컬 파일을 장기간 사용하려면 awrcrt.sql의 해당 코드를 로컬 chart.js 경로로 수정하는 것이 좋습니다.
    - 구형 브라우저(IE 등)를 사용하는 경우 Chrome, Firefox, Edge 등 최신 브라우저를 사용하는 것이 좋습니다.
    - html을 확인하여 발생한 ORA- 오류가 기록되어 있는지 확인하고 그에 따라 분석하십시오. ORA- 오류는 JS 구문을 파괴하여 차트가 표시되지 않게 할 수 있습니다.

- **일부 차트 데이터가 비어 있음**:
    - 해당 기간 내에 해당 지표에 대한 데이터가 없을 수 있습니다(예: 관련 대기 이벤트 없음).
    - `ORA-` 오류가 발생하면 스크립트가 자동으로 캡처하여 HTML 소스 주석에 기록하며, 일반적으로 다른 차트의 표시에는 영향을 미치지 않습니다.

### 라이선스

MIT License

---

<a name="tiếng-việt"></a>
## Tiếng Việt

**AWRCRT** là một công cụ để tạo báo cáo trực quan Oracle AWR. Nó đọc dữ liệu lịch sử Oracle AWR (`dba_hist_*` views) thông qua SQL*Plus và tạo báo cáo HTML chứa các biểu đồ tương tác (dựa trên Chart.js).

So với các báo cáo AWR dạng văn bản truyền thống, AWRCRT cung cấp phân tích xu hướng hiệu suất trực quan hơn, bao gồm nhiều khía cạnh như CPU, IO, Wait Events, Latch, Top SQL, v.v.

### Tính năng chính

- **Biểu đồ trực quan**: Tạo biểu đồ đường và biểu đồ cột động bằng Chart.js, hỗ trợ thu phóng và xem chi tiết khi di chuột.
- **Phạm vi toàn diện**: Bao gồm các chỉ số hiệu suất chính như Time Model, Wait Events, Latch, Mutex, Thống kê OS, Top SQL, v.v.
- **Hỗ trợ đa instance**: Hỗ trợ tạo báo cáo cho số instance được chỉ định.
- **Thực thi im lặng**: Hỗ trợ tham số dòng lệnh, thuận tiện cho việc lập lịch tự động hóa tập lệnh.
- **Tính năng mới nhất (v2.2beta)**:
    - Nâng cấp lên **Chart.js 4.x**, cung cấp giao diện người dùng hiện đại hơn và trải nghiệm tương tác tốt hơn.
    - **Xử lý giá trị âm**: Tự động sửa các giá trị bộ đếm âm do khởi động lại instance.
    - **Xử lý ngoại lệ**: Tăng cường bắt ngoại lệ PL/SQL để ngăn lỗi ORA- làm cắt ngắn báo cáo hoặc gây lỗi cú pháp JS.
    - **Tên tệp duy nhất**: Tên tệp báo cáo được tạo bao gồm dấu thời gian để tránh ghi đè.

### Yêu cầu môi trường

- Oracle Database Client (`sqlplus`)
- Người dùng kết nối với cơ sở dữ liệu đích cần có quyền truy cập các view `dba_hist_*` (thường là `SYSDBA` hoặc người dùng có quyền `SELECT_CATALOG_ROLE`).
- Báo cáo HTML được tạo yêu cầu trình duyệt hỗ trợ JavaScript và có quyền truy cập internet để tải tài nguyên CDN (Chart.js).
  - *Lưu ý: Tập lệnh mặc định sử dụng `https://cdn.jsdelivr.net/npm/chart.js`.*

### Cách sử dụng

#### 1. Chế độ tương tác

Chạy tập lệnh trực tiếp trong SQL*Plus và nhập tham số theo lời nhắc:

```bash
sqlplus / as sysdba @awrcrt.sql
```

**Quy trình thực thi**:
1.  Tập lệnh sẽ liệt kê thông tin instance hiện tại.
2.  Nhắc nhập số ngày xem ảnh chụp nhanh gần đây (`days`).
3.  Liệt kê danh sách ảnh chụp nhanh phù hợp.
4.  Nhắc nhập **Begin Snap ID**.
5.  Nhắc nhập **End Snap ID**.
6.  Nhắc nhập **Instance Number**.
7.  Nhắc xem có kiểm tra **Top SQL** hay không (Nhập `1` là có, `0` là không).

#### 2. Chế độ dòng lệnh im lặng (Khuyên dùng cho tập lệnh)

Bạn có thể truyền trực tiếp 5 tham số qua dòng lệnh mà không cần tương tác thủ công:

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**Mô tả tham số**:
1.  **days**: Liệt kê ảnh chụp nhanh trong N ngày gần đây (dùng cho phạm vi truy vấn nội bộ; ngay cả khi thực thi im lặng cũng nên đặt phạm vi đủ lớn để bao gồm ảnh chụp nhanh mục tiêu). Phạm vi khuyến nghị không quá 7 ngày (khoảng thời gian snapshot 1 giờ), nếu không sẽ dẫn đến chạy chậm.
2.  **begin_snap**: ID ảnh chụp nhanh bắt đầu.
3.  **end_snap**: ID ảnh chụp nhanh kết thúc.
4.  **inst_num**: Số instance (ví dụ: `1`).
5.  **check_sql**: Có tạo thống kê Top SQL hay không (`1`=Tạo, `0`=Bỏ qua). Thống kê TopSQL sẽ chạy chậm hơn.

**Ví dụ**:
Tạo báo cáo trong 7 ngày gần đây, ID ảnh chụp nhanh từ 100 đến 110, instance 1, và bao gồm phân tích Top SQL:
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### Tệp đầu ra

Sau khi thực thi xong, một tệp HTML sẽ được tạo trong thư mục hiện tại với định dạng tên như sau:
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

Ví dụ:
`awrcrt_ORCL_1_100_110_20240313103000.html`

Mở tệp này trực tiếp bằng trình duyệt để xem báo cáo.

### Câu hỏi thường gặp

- **Biểu đồ báo cáo không hiển thị**:
    - Vui lòng kiểm tra xem trình duyệt có tắt JavaScript hay không.
    - Vui lòng kiểm tra kết nối mạng, vì thư viện biểu đồ dựa vào tải CDN. Bạn cũng có thể tải chart.js về máy. Nhưng cần sửa đổi tham chiếu trong html, nếu bạn muốn sử dụng tệp cục bộ lâu dài, nên sửa đổi mã tương ứng trong awrcrt.sql thành đường dẫn chart.js cục bộ.
    - Nếu sử dụng trình duyệt cũ (như IE), nên sử dụng các trình duyệt hiện đại như Chrome, Firefox, Edge.
    - Kiểm tra html xem có ghi lại lỗi ORA- đã xảy ra hay không, và phân tích tương ứng. Lỗi ORA- có thể phá vỡ cú pháp JS, dẫn đến biểu đồ không hiển thị.

- **Một số dữ liệu biểu đồ bị trống**:
    - Có thể không có dữ liệu cho chỉ số đó trong khoảng thời gian tương ứng (ví dụ: không có sự kiện chờ liên quan).
    - Nếu gặp lỗi `ORA-`, tập lệnh sẽ tự động bắt và ghi vào chú thích nguồn HTML, thường không ảnh hưởng đến việc hiển thị các biểu đồ khác.

### Giấy phép

MIT License

---

<a name="ไทย"></a>
## ไทย

**AWRCRT** เป็นเครื่องมือสำหรับสร้างรายงาน Oracle AWR แบบภาพ (visual report) โดยจะอ่านข้อมูลประวัติ Oracle AWR (`dba_hist_*` views) ผ่าน SQL*Plus และสร้างรายงาน HTML ที่มีแผนภูมิแบบโต้ตอบ (Interactive charts) (โดยใช้ Chart.js)

เมื่อเทียบกับรายงาน AWR แบบข้อความดั้งเดิม AWRCRT ให้การวิเคราะห์แนวโน้มประสิทธิภาพที่เข้าใจง่ายกว่า ครอบคลุมหลายมิติ เช่น CPU, IO, Wait Events, Latch, Top SQL และอื่นๆ

### คุณสมบัติหลัก

- **แผนภูมิภาพ**: สร้างกราฟเส้นและกราฟแท่งแบบไดนามิกโดยใช้ Chart.js รองรับการซูมและการดูรายละเอียดเมื่อวางเมาส์
- **ครอบคลุม**: รวมตัวชี้วัดประสิทธิภาพหลัก เช่น Time Model, Wait Events, Latch, Mutex, สถิติ OS, Top SQL เป็นต้น
- **รองรับหลาย Instance**: รองรับการสร้างรายงานสำหรับหมายเลข Instance ที่ระบุ
- **การทำงานแบบเงียบ (Silent Execution)**: รองรับการส่งพารามิเตอร์ผ่านบรรทัดคำสั่ง สะดวกสำหรับการตั้งเวลาสคริปต์อัตโนมัติ
- **คุณสมบัติล่าสุด (v2.2beta)**:
    - อัปเกรดเป็น **Chart.js 4.x** ให้ UI ที่ทันสมัยยิ่งขึ้นและประสบการณ์การโต้ตอบที่ดีขึ้น
    - **การจัดการค่าลบ**: แก้ไขค่าตัวนับที่เป็นลบที่เกิดจากการรีบูต Instance โดยอัตโนมัติ
    - **การจัดการข้อยกเว้น**: ปรับปรุงการดักจับข้อยกเว้น PL/SQL เพื่อป้องกันข้อผิดพลาด ORA- ไม่ให้ตัดรายงานหรือทำให้เกิดข้อผิดพลาดทางไวยากรณ์ JS
    - **ชื่อไฟล์ที่ไม่ซ้ำกัน**: ชื่อไฟล์รายงานที่สร้างขึ้นจะรวมการประทับเวลา (timestamp) เพื่อหลีกเลี่ยงการเขียนทับ

### ข้อกำหนดสภาพแวดล้อม

- Oracle Database Client (`sqlplus`)
- ผู้ใช้ที่เชื่อมต่อกับฐานข้อมูลเป้าหมายต้องมีสิทธิ์เข้าถึงมุมมอง `dba_hist_*` (มักจะเป็น `SYSDBA` หรือผู้ใช้ที่มีสิทธิ์ `SELECT_CATALOG_ROLE`)
- รายงาน HTML ที่สร้างขึ้นต้องใช้เบราว์เซอร์ที่รองรับ JavaScript และต้องสามารถเข้าถึงอินเทอร์เน็ตเพื่อโหลดทรัพยากร CDN (Chart.js)
  - *หมายเหตุ: สคริปต์ใช้ `https://cdn.jsdelivr.net/npm/chart.js` เป็นค่าเริ่มต้น*

### วิธีใช้

#### 1. โหมดโต้ตอบ (Interactive Mode)

รันสคริปต์โดยตรงใน SQL*Plus และป้อนพารามิเตอร์ตามคำแนะนำ:

```bash
sqlplus / as sysdba @awrcrt.sql
```

**ขั้นตอนการทำงาน**:
1.  สคริปต์จะแสดงข้อมูล Instance ปัจจุบัน
2.  แจ้งให้ป้อนจำนวนวันย้อนหลังของสแน็ปช็อต (`days`)
3.  แสดงรายการสแน็ปช็อตที่ตรงตามเงื่อนไข
4.  แจ้งให้ป้อน **Begin Snap ID**
5.  แจ้งให้ป้อน **End Snap ID**
6.  แจ้งให้ป้อน **Instance Number**
7.  แจ้งว่าต้องการตรวจสอบ **Top SQL** หรือไม่ (ป้อน `1` คือใช่, `0` คือไม่)

#### 2. โหมดบรรทัดคำสั่งแบบเงียบ (แนะนำสำหรับสคริปต์)

คุณสามารถส่งพารามิเตอร์ 5 ตัวผ่านบรรทัดคำสั่งได้โดยตรงโดยไม่ต้องมีการโต้ตอบด้วยตนเอง:

```bash
sqlplus -S / as sysdba @awrcrt.sql <days> <begin_snap> <end_snap> <inst_num> <check_sql>
```

**คำอธิบายพารามิเตอร์**:
1.  **days**: แสดงรายการสแน็ปช็อตในช่วง N วันที่ผ่านมา (ใช้สำหรับขอบเขตการสืบค้นภายใน; แม้ในการทำงานแบบเงียบ แนะนำให้กำหนดขอบเขตให้กว้างพอที่จะรวมสแน็ปช็อตเป้าหมาย) แนะนำให้ช่วงไม่เกิน 7 วัน (snapshot ห่างกัน 1 ชั่วโมง) มิฉะนั้นจะทำให้การทำงานช้าลง
2.  **begin_snap**: ID สแน็ปช็อตเริ่มต้น
3.  **end_snap**: ID สแน็ปช็อตสิ้นสุด
4.  **inst_num**: หมายเลข Instance (เช่น `1`)
5.  **check_sql**: สร้างสถิติ Top SQL หรือไม่ (`1`=สร้าง, `0`=ข้าม) สถิติ TopSQL จะทำงานช้าลง

**ตัวอย่าง**:
สร้างรายงานในช่วง 7 วันที่ผ่านมา ID สแน็ปช็อตตั้งแต่ 100 ถึง 110, Instance 1 และรวมการวิเคราะห์ Top SQL:
```bash
sqlplus -S / as sysdba @awrcrt.sql 7 100 110 1 1
```

### ไฟล์เอาต์พุต

หลังจากดำเนินการเสร็จสิ้น ไฟล์ HTML จะถูกสร้างขึ้นในไดเร็กทอรีปัจจุบันด้วยรูปแบบชื่อดังนี้:
`awrcrt_<DBNAME>_<INST>_<BEGIN>_<END>_<TIMESTAMP>.html`

ตัวอย่าง:
`awrcrt_ORCL_1_100_110_20240313103000.html`

เปิดไฟล์นี้โดยตรงด้วยเบราว์เซอร์เพื่อดูรายงาน

### คำถามที่พบบ่อย (FAQ)

- **แผนภูมิรายงานไม่แสดง**:
    - โปรดตรวจสอบว่าเบราว์เซอร์ปิดการใช้งาน JavaScript หรือไม่
    - โปรดตรวจสอบการเชื่อมต่อเครือข่าย เนื่องจากไลบรารีแผนภูมิต้องโหลดผ่าน CDN คุณยังสามารถดาวน์โหลด chart.js มาไว้ที่เครื่องได้ แต่ต้องแก้ไขการอ้างอิงใน html หากคุณต้องการใช้ไฟล์ในเครื่องเป็นเวลานาน แนะนำให้แก้ไขโค้ดที่เกี่ยวข้องใน awrcrt.sql เป็นเส้นทาง chart.js ในเครื่อง
    - หากใช้เบราว์เซอร์รุ่นเก่า (เช่น IE) แนะนำให้ใช้เบราว์เซอร์สมัยใหม่ เช่น Chrome, Firefox, Edge
    - ตรวจสอบใน html ว่ามีการบันทึกข้อผิดพลาด ORA- ที่เกิดขึ้นหรือไม่ และวิเคราะห์ตามนั้น ข้อผิดพลาด ORA- อาจทำลายไวยากรณ์ JS ทำให้แผนภูมิไม่แสดง

- **ข้อมูลแผนภูมิบางส่วนว่างเปล่า**:
    - อาจไม่มีข้อมูลสำหรับตัวชี้วัดนั้นในช่วงเวลาที่เกี่ยวข้อง (เช่น ไม่มีเหตุการณ์การรอที่เกี่ยวข้อง)
    - หากพบข้อผิดพลาด `ORA-` สคริปต์จะจับและบันทึกไว้ในความคิดเห็นซอร์ส HTML โดยอัตโนมัติ ซึ่งมักจะไม่ส่งผลกระทบต่อการแสดงผลของแผนภูมิอื่นๆ

### ใบอนุญาต

MIT License
