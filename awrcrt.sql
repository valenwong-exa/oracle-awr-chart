Rem awrcrt.sql
Rem
Rem Copyright WENJIE WANG from Oracle ACS.  
Rem Support email: valen.wang@oracle.com
Rem    NAME
Rem      awrcrt.sql
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid and instance number to that of the
Rem      current instance connected-to, then  produce
Rem      the Workload Repository CHART report.
Rem    VERSION
Rem      2.182 
Rem    MODIFIED   (MM/DD/YY)
Rem    Wang Wenjie      2015-06-12 - Created 0.1 version
Rem    Wang Wenjie      2016-03-26 - release 1.0 version
Rem    Wang Wenjie      2016-12-06 - Created 2.0 version
Rem    Ma Xuefeng       2016-01-10 - Modified, replaced sql to plsql, AMarkBro
Rem    Wang Wenjie      2016-01-16 - Modified, replaced sql to plsql 
Rem    Wang Wenjie      2016-01-18 - Fixed major bug
Rem    Wang Wenjie      2017-03-20 - Added IO request, IO wait time
Rem    Wang Wenjie      2017-06-09 - Removed top3 slowest datafile
Rem    Wang Wenjie      2017-06-09 - Added metric stats for logon, io, commit
Rem    Wang Wenjie      2017-07-01 - Added average IO wait time
Rem    Wang Wenjie      2017-08-15 - Set arraysize 5000
Rem    Wang Wenjie      2017-09-16 - Replaced chart js to new version , adjust chart contents,removed a parameter
Rem    Elliot           2017-11-03 - Reported bug of wrong order of logon and commit data, fixed
Rem    lijinguang       2018-02-02 - Reported misunderstanding about snap time between awrcrt and awrrpt
Rem    Wang Wenjie      2018-02-27 - Added Tablespace usage chart
Rem    Wang Wenjie      2018-03-15 - Added PGA,SGA stat chart, User calls chart
Rem    Gisela           2018-03-31 - Reported bug of memory chart, fixed
Rem    Wang Wenjie      2018-04-11 - Replace user io wait time to more types of wait time, handled reboot time for wait event list
Rem    Wang Wenjie      2018-06-21 - Added wait event severity color
Rem    Wang Wenjie      2018-10-16 - Modified exadata chart to show how much exadata feature be used, added multiple dbid support per Adam suggestion
Rem    Wang Wenjie      2018-12-20 - Added redo transfer chart
Rem    Wang Wenjie      2018-03-23 - Reported bug of ORA-01427, fixed
Rem    Wang Wenjie      2019-09-01 - Added Top 3 SQL list, added more wait event severity define,fixed bug which reported by stellar.hu
Rem    Wang Wenjie      2020-04-29 - Add cell physcial read event 
Rem    Wang Wenjie      2020-08-14 - Fixed duplicated Top SQL bug 
Rem    Wang Wenjie      2020-12-01 - Replace con_id to sql_id from Top SQL  
Rem    Wang Wenjie      2026-03-01 - Used vibe coding(Gemini) to adapt to new chart.js. Fixed bug of ORA-error effect chat. Fixed negative value bug.  
Rem    Peng Fu          2026-03-13 - Report topSQL charactor convert issue. Fixed by Gemini.  
set feedback off
set timing off
prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~
select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;
prompt
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
define days=&1
set linesize 999
select a.snap_id, to_char(a.END_INTERVAL_TIME,'yyyy-mm-dd hh24:mi:ss') snap_time from dba_hist_snapshot a
where a.instance_number=(select b.instance_number from v$instance b) 
and a.END_INTERVAL_TIME > sysdate-&days
order by 1;
/*****************************************
--parameter1 days (to list snapshots)
--parameter2 begin snap id
--parameter3 end snap id
--parameter4 instance number
--parameter5 check top sql (1/0)
Author: 
Date  : 2017-01
*****************************************/
set termout       on
set echo          off
set heading       on
prompt Specify the Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COLUMN spool_time NEW_VALUE _spool_time NOPRINT
SELECT TO_CHAR(SYSDATE,'YYYYMMDDhh24miss') spool_time FROM dual;
COLUMN iv NEW_VALUE _iv NOPRINT
select trunc(3600*24*(sysdate+snaP_interval-sysdate)) iv from dba_hist_wr_control;
COLUMN dbname NEW_VALUE _dbname NOPRINT
SELECT name dbname FROM v$database;
COLUMN cpucount NEW_VALUE _cpucount NOPRINT
select value cpucount from v$parameter where name ='cpu_count';
prompt begin snap id is
define bid=&2
prompt end snap id is
define eid=&3
prompt instance number is
define inid=&4
prompt do you want to check Top SQL list (1 YES, 0 NO) ?
define checksql=&5
set termout       on
set echo          off
set heading       on
set long 2000000
set pages 0
set linesize 999
set termout       off
set echo          off
set feedback      off
set heading       off
set verify        off
set wrap          on 
set trimspool     on
set serveroutput on size  unlimited
set escape        on
--set arraysize 5000
COLUMN vp NEW_VALUE _vp NOPRINT
SELECT case when &eid-&bid>500 then 6  when &eid-&bid>350 then 4 else 2 end vp FROM dual;
--spool awrcrt_&_dbname._&_spool_time..html
spool awrcrt_&_dbname._&inid._&bid._&eid._&_spool_time..html
prompt <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
prompt <html xmlns="http://www.w3.org/1999/xhtml">
prompt <head>
prompt <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
prompt <title>AWR Chart Report 2</title>
prompt <style type="text/css">
prompt body.awr {font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #333; background: #f9f9f9; padding: 20px;}
prompt pre.awr {font: 12px Consolas, Monaco, "Courier New", monospace; color: #333; background: #fff; padding: 10px; border-radius: 4px; border: 1px solid #ddd;}
prompt h1.awr {font-size: 24px; color: #0056b3; border-bottom: 2px solid #0056b3; padding-bottom: 10px; margin-bottom: 20px;}
prompt h2.awr {font-size: 20px; color: #0056b3; margin-top: 30px; margin-bottom: 15px;}
prompt h3.awr {font-size: 18px; color: #444; margin-top: 20px; margin-bottom: 10px;}
prompt h4.awr {font-size: 24px; color: #d9534f;}
prompt h5.awr {font-size: 14px; color: #d9534f; margin-top: 10px; font-weight: bold;}
prompt h6.awr {font-size: 14px; color: #0056b3; margin-top: 15px; font-weight: bold; border-left: 4px solid #0056b3; padding-left: 10px;}
prompt ul {list-style-type: none; padding-left: 0;}
prompt li.awr {font-size: 14px; margin-bottom: 5px;}
prompt table {border-collapse: collapse; width: 100%; margin-bottom: 20px; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1);}
prompt th.awrnobg {font-weight: bold; font-size: 12px; color: #333; padding: 8px; border: 1px solid #ddd;}
prompt th.awrbg {font-weight: bold; font-size: 12px; color: #fff; background: #0056b3; padding: 8px; border: 1px solid #0056b3;}
prompt td.awrnc {font-size: 12px; color: #333; padding: 8px; border: 1px solid #ddd;}
prompt td.awrc {font-size: 12px; color: #333; background: #fdfdfd; padding: 8px; border: 1px solid #ddd;}
prompt td.awrc2 {font-size: 12px; color: #d9534f; background: #fdfdfd; padding: 8px; border: 1px solid #ddd;}
prompt td.awrc3 {font-size: 14px; color: #d9534f; background: #fdfdfd; padding: 8px; border: 1px solid #ddd; font-weight: bold;}
prompt td.awrc4 {font-size: 16px; color: #d9534f; background: #fdfdfd; padding: 8px; border: 1px solid #ddd; font-weight: bold;}
prompt td.awrc5 {font-size: 14px; color: #fff; background: #d9534f; padding: 8px; border: 1px solid #d9534f; font-weight: bold;}
prompt a.awr {color: #0056b3; text-decoration: none;}
prompt a.awr:hover {text-decoration: underline;}
prompt a.awrred {color: #d9534f; font-weight: bold;}
prompt a1.awr {color: #0056b3; font-weight: bold; font-size: 12px;}
prompt div.chart-container {width: 100%; margin: 20px 0; background: #fff; padding: 15px; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);}
prompt </style>
prompt <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
set define off
prompt <script>
prompt window.awrColors = {
prompt     red1: 'rgb(255, 128, 128)',
prompt     red2: 'rgb(255, 0, 0)',
prompt     orange1: 'rgb(255, 159, 64)',
prompt     orange2: 'rgb(234, 117, 0)',
prompt     yellow1: 'rgb(255, 255, 0)',
prompt     green0: 'rgb(128, 255, 128)',
prompt     green1: 'rgb(0, 255, 0)',
prompt     green2: 'rgb(0, 128, 0)',
prompt     blue1: 'rgb(151, 203, 255)',
prompt     blue2: 'rgb(0, 0, 255)',
prompt     purple1: 'rgb(255, 0, 255)',
prompt     purple2: 'rgb(150, 0, 150)',
prompt     grey1: 'rgb(192, 192, 192)',
prompt     grey2: 'rgb(128, 128, 128)',
prompt     pink1: 'rgb(255, 164, 209)',
prompt     pink2: 'rgb(255, 111, 183)',
prompt     black1: 'rgb(0, 0, 0)'
prompt };
prompt // Adapter to convert Chart.js 2.x config to 4.x
prompt function upgradeChartConfig(config) {
prompt     if (!config || !config.options) return config;
prompt     var opts = config.options;
prompt     var newOpts = JSON.parse(JSON.stringify(opts)); 
prompt     
prompt     // Scales Adapter
prompt     if (newOpts.scales) {
prompt         if (newOpts.scales.xAxes) {
prompt             newOpts.scales.xAxes.forEach(function(axis) {
prompt                 // If axis has id, use it, else use 'x'
prompt                 var id = axis.id || 'x';
prompt                 newOpts.scales[id] = axis;
prompt                 // Chart.js 3+ renaming
prompt                 if (axis.scaleLabel) {
prompt                     newOpts.scales[id].title = axis.scaleLabel;
prompt                     newOpts.scales[id].title.display = axis.scaleLabel.display;
prompt                     newOpts.scales[id].title.text = axis.scaleLabel.labelString;
prompt                     delete newOpts.scales[id].scaleLabel;
prompt                 }
prompt             });
prompt             delete newOpts.scales.xAxes;
prompt         }
prompt         if (newOpts.scales.yAxes) {
prompt             newOpts.scales.yAxes.forEach(function(axis) {
prompt                 var id = axis.id || 'y';
prompt                 newOpts.scales[id] = axis;
prompt                  if (axis.scaleLabel) {
prompt                     newOpts.scales[id].title = axis.scaleLabel;
prompt                     newOpts.scales[id].title.display = axis.scaleLabel.display;
prompt                     newOpts.scales[id].title.text = axis.scaleLabel.labelString;
prompt                     delete newOpts.scales[id].scaleLabel;
prompt                 }
prompt             });
prompt             delete newOpts.scales.yAxes;
prompt         }
prompt     }
prompt     
prompt     // Plugins
prompt     newOpts.plugins = newOpts.plugins || {};
prompt     if (newOpts.title) {
prompt         newOpts.plugins.title = newOpts.title;
prompt         delete newOpts.title;
prompt     }
prompt     if (newOpts.legend) {
prompt         newOpts.plugins.legend = newOpts.legend;
prompt         delete newOpts.legend;
prompt     }
prompt     // Tooltips -> tooltip
prompt     if (newOpts.tooltips) {
prompt         newOpts.plugins.tooltip = newOpts.tooltips;
prompt         delete newOpts.tooltips;
prompt     }
prompt     
prompt     // Dataset adjustments
prompt     if (config.data \&\& config.data.datasets) {
prompt         config.data.datasets.forEach(function(ds) {
prompt             if (ds.lineTension !== undefined) {
prompt                 ds.tension = ds.lineTension;
prompt                 delete ds.lineTension;
prompt             }
prompt             // Colors: Chart.js 4 might need explicit colors if not provided
prompt         });
prompt     }
prompt     
prompt     config.options = newOpts;
prompt     return config;
prompt }
prompt </script>
set define on
prompt </head>
prompt <body class='awr'>
prompt <H1 class='awr'>
prompt WORKLOAD REPOSITORY CHART report for
prompt </H1>
prompt <p/>
prompt <TABLE BORDER=1 WIDTH=500>
prompt <tr><th class='awrbg'>DB Name</th><th class='awrbg'>DB Id</th><th class='awrbg'>Instance</th><th class='awrbg'>Inst num</th><th class='awrbg'>Release</th><th class='awrbg'>RAC</th><th class='awrbg'>Host</th></tr>
prompt <tr><TD class='awrnc'>
SELECT A.NAME||'</td><TD ALIGN=''right'' class=''awrnc''>'
||A.DBID||'</td><TD class=''awrnc''>'||(SELECT B.INSTANCE_NAME
||'</td><TD ALIGN=''right'' class=''awrnc''>'||&inid
||'</td><TD class=''awrnc''>'||B.VERSION 
|| '</td><TD class=''awrnc''>'
||(SELECT value FROM V$PARAMETER C WHERE C.NAME ='cluster_database')
||'</td><TD class=''awrnc''>'
||b.HOST_NAME FROM GV$INSTANCE B WHERE B.INSTANCE_NUMBER=&inid)
  FROM V$DATABASE A;
prompt </td></tr>
prompt </table>
prompt <p />
prompt <TABLE BORDER=1 WIDTH=500>
prompt <tr><th class='awrnobg'></th><th class='awrbg'>Snap Id</th><th class='awrbg'>Snap Time</th></tr>
prompt <tr><TD class='awrnc'>Begin Snap:</td><TD ALIGN='right' class='awrnc'>&bid</td><TD ALIGN='center' class='awrnc'>
select  
nvl((select to_char(a.END_INTERVAL_TIME,'yyyy-mm-dd hh24:mi:ss') from dba_hist_snapshot a where a.instance_number=&inid and a.snap_id=&bid),
'minimum snap time')
from dual;
prompt </td></tr>
prompt <tr><TD class='awrc'>End Snap:</td><TD ALIGN='right' class='awrc'>&eid</td><TD ALIGN='center' class='awrc'>
select  
nvl((select to_char(a.END_INTERVAL_TIME,'yyyy-mm-dd hh24:mi:ss') from dba_hist_snapshot a where a.instance_number=&inid and a.snap_id=&eid),
'maximum snap time')
from dual;
prompt </td></tr>
prompt </table>
prompt <p />
prompt <a class="awr" name="top"></a>
prompt <h2 class="awr">
prompt Main Report
prompt </h2>
prompt <ul>
prompt <h6 class="awr">Load Profile</h6>
prompt <li class="awr"><a class="awr" href="#1">CPU Utilization </a></li>
prompt <li class="awr"><a class="awr" href="#2">Time Model : DB TIME  DB CPU SQL EXEC TIME</a></li>
prompt <li class="awr"><a class="awr" href="#2_p">Time Model : Parse TIME</a></li>
prompt <li class="awr"><a class="awr" href="#31">User Calls</a></li>
prompt <li class="awr"><a class="awr" href="#3">SQL Execution Count and Average Execution Time </a></li>
prompt <li class="awr"><a class="awr" href="#2_1">Active Session History</a></li>
prompt <li class="awr"><a class="awr" href="#5">Session Logic Reads</a></li>
prompt <li class="awr"><a class="awr" href="#7">User Commits and Redo size </a></li>
prompt <li class="awr"><a class="awr" href="#71">User Commits(MAX) </a></li>
prompt <li class="awr"><a class="awr" href="#72">Redo Log Transport</a></li>
prompt <li class="awr"><a class="awr" href="#211">Parse Count</a></li>
prompt <li class="awr"><a class="awr" href="#721">Block Changes</a></li>
prompt <h6 class="awr">IO Profile</h6>
prompt <li class="awr"><a class="awr" href="#6">Physical writes and reads avg throughput</a></li>
prompt <li class="awr"><a class="awr" href="#61">Physical writes and reads avg requests</a></li>
prompt <li class="awr"><a class="awr" href="#62">Miscellaneous wait time</a></li>
prompt <li class="awr"><a class="awr" href="#64">Average IO wait time</a></li>
prompt <li class="awr"><a class="awr" href="#64_1">User IO wait times</a></li>
prompt <li class="awr"><a class="awr" href="#73">Tablespace Usage</a></li>
prompt <h6 class="awr">Connections</h6>
prompt <li class="awr"><a class="awr" href="#8">Connections</a></li>
prompt <li class="awr"><a class="awr" href="#81">User logon (MAX)</a></li>
prompt <h6 class="awr">Global Cache Statistics</h6>
prompt <li class="awr"><a class="awr" href="#10">Global cache transformation</a></li>
prompt <li class="awr"><a class="awr" href="#101">Global cache lost</a></li>
prompt <li class="awr"><a class="awr" href="#11">GCS/GES messages </a></li>
prompt <li class="awr"><a class="awr" href="#12">Global Cache Current and CR Block Time</a></li>
prompt <h6 class="awr">Memory Statistics</h6>
prompt <li class="awr"><a class="awr" href="#141">Memory Statistics</a></li>
prompt <li class="awr"><a class="awr" href="#142">Shared Pool Statistics</a></li>
prompt <li class="awr"><a class="awr" href="#14">Buffer Cache and PGA Hit POINT</a></li>
prompt <li class="awr"><a class="awr" href="#140">Library Hit POINT</a></li>
prompt <li class="awr"><a class="awr" href="#161">Latch Hit POINT</a></li>
prompt <li class="awr"><a class="awr" href="#16">Latch:shared pool</a></li>
prompt <li class="awr"><a class="awr" href="#17">Latch:row cache objects</a></li>
prompt <li class="awr"><a class="awr" href="#18">Latch:cache buffers chains</a></li>
prompt <li class="awr"><a class="awr" href="#19">Latch:cache buffers lru chain</a></li>
prompt <li class="awr"><a class="awr" href="#20">Latch:gc element</a></li>
prompt <li class="awr"><a class="awr" href="#21">Latch:DML lock allocation</a></li>
prompt <li class="awr"><a class="awr" href="#23">Table fetch continued row</a></li>
prompt <li class="awr"><a class="awr" href="#24">Dirty buffers inspected</a></li>
prompt <h5 class="awr">Exadata Smart IO Utilization</h5>
prompt <li class="awr"><a class="awr" href="#501">Exadata Total IO Chart 1</a></li>
prompt <li class="awr"><a class="awr" href="#502">Exadata Total IO Chart 2</a></li>
prompt <li class="awr"><a class="awr" href="#503">Cell Interconnect IO</a></li>
prompt <li class="awr"><a class="awr" href="#50">Cell physical IO bytes eligible for predicate offload</a></li>
prompt <li class="awr"><a class="awr" href="#51">Cell physical IO bytes saved by storage index</a></li>
prompt <li class="awr"><a class="awr" href="#52">Cell physical IO interconnect bytes returned by smart scan</a></li>
prompt <li class="awr"><a class="awr" href="#53">Smart Scan Saved IO Pct</a></li>
prompt <li class="awr"><a class="awr" href="#54">Flash Cache Hit Point Pct</a></li>
prompt <h6 class="awr">Wait Event</h6>
prompt <li class="awr"><a class="awr" href="#151">Top 5 Wait Event</a></li>
prompt <li class="awr"><a class="awr" href="#15">Top 5 Wait Event trends</a></li>
prompt <h6 class="awr">Top SQL</h6>
prompt <li class="awr"><a class="awr" href="#160">Top 3 workload SQL </a></li>
prompt <li class="awr"><a class="awr" href="#169">Complete List of SQL Text</a></li>
prompt </ul>
-----------------------------------------------------------------------
prompt <a class="awr" name="1"></a>
prompt <p><h3 class='awr'>Cpu Utilization</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt 	<div style="width:100%;">
prompt 		<canvas width="1800" height="600" id="canvas_cpu"></canvas>
prompt 	</div>
prompt 	<a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------
prompt <a class="awr" name="2"></a>
prompt <p><h3 class='awr'>Time Model : DB TIME DB CPU SQL EXEC TIME</h3></p>
prompt <a1 class="awr" href="#10">Comments: snap sample interval &_iv seconds, cpu count &_cpucount</a1>
prompt 	<div style="width:100%;">
prompt 		<canvas width="1800" height="600" id="canvas_dbtime"></canvas>
prompt 	</div>
prompt 	<a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------
prompt <a class="awr" name="2_p"></a>
prompt <p><h3 class='awr'>Time Model : Parse TIME</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt 	<div style="width:100%;">
prompt 		<canvas width="1800" height="600" id="canvas_parsetime"></canvas>
prompt 	</div>
prompt 	<a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------------
prompt <a class="awr" name="2_1"></a>
prompt <p><h3 class='awr'>Active Session History</h3> </p> 
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:450%">
prompt        <canvas width="3000px" height="200px" id="canvas_ash"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="31"></a>
prompt <p><h3 class='awr'>User Calls</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_usercall"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="3"></a>
prompt <p><h3 class='awr'>SQL Execution Count and Average Execution Time</h3></p>
prompt <a1 class="awr" href="#10">Comments: Unit of Time is micro second</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_sql"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------------------------
prompt <a class="awr" name="5"></a>
prompt <p><h3 class='awr'>Session Logic Read</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_logic"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------------------------
prompt <a class="awr" name="7"></a>
prompt <p><h3 class='awr'>User Commits and Redo size</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_commit"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------------------------
prompt <a class="awr" name="71"></a>
prompt <p><h3 class='awr'>User Commits (MAX)</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_maxcommit"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------------------------
prompt <a class="awr" name="72"></a>
prompt <p><h3 class='awr'>Redo Log Transport</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_redotrans"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------
prompt <a class="awr" name="211"></a>
prompt <p><h3 class='awr'>Parse count</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_parse"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="721"></a>
prompt <p><h3 class='awr'>Block Changes</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_bchange"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------
prompt <a class="awr" name="73"></a>
prompt <p><h3 class='awr'>Tablespace Usages</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_tbsusage"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-----------------------------------------------------------------
prompt <a class="awr" name="6"></a>
prompt <p><h3 class='awr'>Physical Read and Write</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_phy"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------------
prompt <a class="awr" name="61"></a>
prompt <p><h3 class='awr'>Physical Read Request and Write Request</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_phyreq"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------------
prompt <a class="awr" name="62"></a>
prompt <p><h3 class='awr'>Miscellaneous wait time</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_userio"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------------
prompt <a class="awr" name="64"></a>
prompt <p><h3 class='awr'>Average IO wait time</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas width="1800" height="600" id="canvas_avgio"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------------
prompt <a class="awr" name="64_1"></a>
prompt <p><h3 class='awr'>IO wait times</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:450%;">
prompt <canvas width="3000px" height="200px" id="canvas_iotimes"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------
prompt <a class="awr" name="8"></a>
prompt <p><h3 class='awr'>Connections</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_conn"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------
prompt <a class="awr" name="81"></a>
prompt <p><h3 class='awr'>User Logon</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_logon"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------------
prompt <a class="awr" name="10"></a>
prompt <p><h3 class='awr'>Global Cache Transformation</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_gckb"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------------
prompt <a class="awr" name="101"></a>
prompt <p><h3 class='awr'>Global Cache Lost</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_gclost"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------------
prompt <a class="awr" name="11"></a>
prompt <p><h3 class='awr'>GCS/GES Messages </h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_gcms"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="12"></a>
prompt <p><h3 class='awr'>Global Cache CR/Current Average Time</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_gcb"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="141"></a>
prompt <p><h3 class='awr'>Memory Statistics</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_memstats"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="142"></a>
prompt <p><h3 class='awr'>Shared Pool Statistics</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_sharedpool"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="14"></a>
prompt <p><h3 class='awr'>Buffer Cache and PGA Hit Point</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_bfpga"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="140"></a>
prompt <p><h3 class='awr'>Library Cache Hit Point</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_lib"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
----------------------------------------------------------
prompt <a class="awr" name="161"></a>
prompt <p><h3 class='awr'>Latch Hit Point</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latch"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------------------
prompt <a class="awr" name="16"></a>
prompt <p><h3 class='awr'>Latch Share Pool</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchsp"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------
prompt <a class="awr" name="17"></a>
prompt <p><h3 class='awr'>Latch:row cache objects</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchrco"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
---------------------------------------------------------
prompt <a class="awr" name="18"></a>
prompt <p><h3 class='awr'>Latch:cache buffers chains</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchcbc"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
--------------------------------------------------------------------------
prompt <a class="awr" name="19"></a>
prompt <p><h3 class='awr'>Latch:cache buffers lru chain</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchlru"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
--------------------------------------------------------------------------
prompt <a class="awr" name="20"></a>
prompt <p><h3 class='awr'>Latch:gc element</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchgc"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
--------------------------------------------------------------------------
prompt <a class="awr" name="21"></a>
prompt <p><h3 class='awr'>Latch:DML lock allocation</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_latchdml"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
--------------------------------------------------------------------------
prompt <a class="awr" name="23"></a>
prompt <p><h3 class='awr'>Table fetch continued row</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_fct"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="24"></a>
prompt <p><h3 class='awr'>Dirty buffers inspected</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_dirty"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="501"></a>
prompt <p><h3 class='awr'>Exadata Total IO 1</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_exaio"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="502"></a>
prompt <p><h3 class='awr'>Exadata Total IO 2</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_exaio2"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="503"></a>
prompt <p><h3 class='awr'>Cell Interconnect IO</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_exaio3"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="50"></a>
prompt <p><h3 class='awr'>Cell physical IO MB eligible for predicate offload</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_e1"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="51"></a>
prompt <p><h3 class='awr'>Cell physical IO MB saved by storage index</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_e2"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="52"></a>
prompt <p><h3 class='awr'>Cell physical IO interconnect MB returned by smart scan</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_e3"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="53"></a>
prompt <p><h3 class='awr'>Smart Scan Saved IO Pct</h3></p>
prompt <a1 class="awr" href="#10">Comments:Please ignore it when you see there is not zero in regular database machine. And it assumes redundancy of disk group is high </a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_e4"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="54"></a>
prompt <p><h3 class='awr'>Flash Cache Hit Point Pct</h3></p>
prompt <a1 class="awr" href="#10">Comments: </a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_e5"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
-------------------------------------------------------------------------
prompt <a class="awr" name="151"></a>
prompt <p><h3 class='awr'>Top5 Wait Event</h3></p>
prompt <a1 class="awr" href="#10">Comments:</a1>
prompt <div style="width:100%;">
prompt <canvas  width="1800" height="600" id="canvas_event"></canvas>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
------------------------------------------------
prompt <a class="awr" name="15"></a>
prompt <p><h3 class='awr'>Top 5 Wait Event trends </h3></p>
prompt <div style="width:75%">
prompt <div>

----------event 2018-6
declare
vevent varchar2(100);  
vtime number;
vavgtime number;
vpctwt number;
vwaits number;
vwaitclass varchar2(100);
vbid number ;
veid number ;
vinid number:=&inid;
startid number:=&bid;
endid number:=&eid;
vstarttime varchar2(200);
vendtime varchar2(200);
cursor c1 is
SELECT EVENT,
       WAITS,
       trunc(TIME,2),
       trunc(DECODE(WAITS,
              NULL,
              TO_NUMBER(NULL),
              0,
              TO_NUMBER(NULL),
              TIME / WAITS * 1000),2) AVGWT,
       trunc(PCTWTT,2) ,
       WAIT_CLASS
  FROM (SELECT EVENT, WAITS, TIME, PCTWTT, WAIT_CLASS
          FROM (SELECT E.EVENT_NAME EVENT,
                       E.TOTAL_WAITS_FG - NVL(B.TOTAL_WAITS_FG, 0) WAITS,
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       1000000 TIME,
                       100 *
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       E.WAIT_CLASS WAIT_CLASS
                  FROM DBA_HIST_SYSTEM_EVENT B, DBA_HIST_SYSTEM_EVENT E
                 WHERE B.SNAP_ID(+) = vbid
                   AND E.SNAP_ID = veid
                   AND B.INSTANCE_NUMBER(+) = vinid
                   AND E.INSTANCE_NUMBER = vinid
                   AND B.EVENT_ID(+) = E.EVENT_ID
                   AND E.TOTAL_WAITS > NVL(B.TOTAL_WAITS, 0)
                   AND E.WAIT_CLASS != 'Idle'
                UNION ALL
                SELECT 'CPU time' EVENT,
                       TO_NUMBER(NULL) WAITS,
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB CPU')) / 1000000 TIME,
                       100 * ((SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL e
                                WHERE e.SNAP_ID = veid
                                  AND e.INSTANCE_NUMBER = vinid
                                  AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL b
                                WHERE b.SNAP_ID = vbid
                                  AND b.INSTANCE_NUMBER = vinid
                                  AND b.STAT_NAME = 'DB CPU')) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       NULL WAIT_CLASS
                  from dual
                 WHERE ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = veid
                            AND e.INSTANCE_NUMBER = vinid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = vbid
                            AND b.INSTANCE_NUMBER = vinid
                            AND b.STAT_NAME = 'DB CPU')) > 0)
         ORDER BY TIME DESC, WAITS DESC)
 WHERE ROWNUM <= 5;
awr_string varchar2(20):='awrc';
cursor cs1 is
select a.EVENT,a.AVERAGE_WAIT avgwt,a.TOTAL_WAITS pct from v$system_event a;
TYPE event_list_type IS TABLE OF  cs1%rowtype -- Associative array type
INDEX BY VARCHAR2(64);
event_list event_list_type;
begin
  --log file sync
  event_list('log file sync').avgwt:=15;
  event_list('log file sync').pct:=10;
  --log file switch completion
  event_list('log file switch completion').avgwt:=1000;
  event_list('log file switch completion').pct:=10;
  --buffer deadlock
  event_list('buffer deadlock').avgwt:=99999;
  event_list('buffer deadlock').pct:=100;
  --buffer busy waits
  event_list('buffer busy waits').avgwt:=100;
  event_list('buffer busy waits').pct:=10;
  --read by other session
  event_list('read by other session').avgwt:=100;
  event_list('read by other session').pct:=10;
  --gc buffer busy release
  event_list('gc buffer busy release').avgwt:=100;
  event_list('gc buffer busy release').pct:=10;
  --gc buffer busy acquire
  event_list('gc buffer busy acquire').avgwt:=50;
  event_list('gc buffer busy acquire').pct:=10;
  --gc cr block busy
  event_list('gc cr block busy').avgwt:=100;
  event_list('gc cr block busy').pct:=20;
  --gc current block busy
  event_list('gc current block busy').avgwt:=100;
  event_list('gc current block busy').pct:=20;
  --control file sequential read
  event_list('control file sequential read').avgwt:=5;
  event_list('control file sequential read').pct:=10;
  --control file parallel write
  event_list('control file parallel write').avgwt:=5;
  event_list('control file parallel write').pct:=10;
  --cursor: mutex X  --cursor: mutex S
  event_list('cursor: mutex X').avgwt:=5;
  event_list('cursor: mutex X').pct:=10;
  event_list('cursor: mutex S').avgwt:=5;
  event_list('cursor: mutex S').pct:=10;
  event_list('cursor: pin X').avgwt:=5;
  event_list('cursor: pin X').pct:=10;
  event_list('cursor: pin S').avgwt:=5;
  event_list('cursor: pin S').pct:=10;
  event_list('cursor: pin S wait on X').avgwt:=5;
  event_list('cursor: pin S wait on X').pct:=10;
  --latch: shared pool
  event_list('latch: shared pool').avgwt:=5;
  event_list('latch: shared pool').pct:=10;
  --library cache lock
  event_list('library cache lock').avgwt:=120;
  event_list('library cache lock').pct:=15;
  --library cache: mutex X
  event_list('library cache: mutex X').avgwt:=5;
  event_list('library cache: mutex X').pct:=25;
  --latch: cache buffers chains
  event_list('latch: cache buffers chains').avgwt:=5;
  event_list('latch: cache buffers chains').pct:=25;
  --latch: undo global data
  event_list('latch: undo global data').avgwt:=20;
  event_list('latch: undo global data').pct:=5;
  --library cache load lock
  event_list('library cache load lock').avgwt:=115;
  event_list('library cache load lock').pct:=20;
  --library cache pin
  event_list('library cache pin').avgwt:=115;
  event_list('library cache pin').pct:=20;
  --Disk file operations I/O
   event_list('Disk file operations I/O').avgwt:=20;
   event_list('Disk file operations I/O').pct:=10;
   --db file sequential read
   --db file scattered read
   event_list('db file sequential read').avgwt:=20;
   event_list('db file sequential read').pct:=50;
   event_list('db file scattered read').avgwt:=20;
   event_list('db file scattered read').pct:=40;
   --db file parallel read
   event_list('db file parallel read').avgwt:=50;
   event_list('db file parallel read').pct:=20;
   --direct path read  
   event_list('direct path read').avgwt:=30;
   event_list('direct path read').pct:=20;
   event_list('direct path write').avgwt:=30;
   event_list('direct path write').pct:=10;
   --Sync ASM rebalance
   event_list('Sync ASM rebalance').avgwt:=99999;
   event_list('Sync ASM rebalance').pct:=100;
   --enq: TX - index contention
   event_list('enq: TX - index contention').avgwt:=100;
   event_list('enq: TX - index contention').pct:=10;
   --enq: TX - row lock contention
   event_list('enq: TX - row lock contention').avgwt:=10000;
   event_list('enq: TX - row lock contention').pct:=50;
--direct path read temp
   event_list('direct path read temp').avgwt:=100;
   event_list('direct path read temp').pct:=20;
--direct path write temp
   event_list('direct path write temp').avgwt:=100;
   event_list('direct path write temp').pct:=20;
   --control file sequential read
   event_list('control file sequential read').avgwt:=60;
   event_list('control file sequential read').pct:=20;
   --enq: RO - fast object reuse
   event_list('enq: RO - fast object reuse').avgwt:=99999;
   event_list('enq: RO - fast object reuse').pct:=100;
   --enq: SQ - contention
   event_list('enq: SQ - contention').avgwt:=50;
   event_list('enq: SQ - contention').pct:=15;
   --latch free
   event_list('latch free').avgwt:=5;
   event_list('latch free').pct:=6;
   --enq: TX - allocate ITL entry
    event_list('enq: TX - allocate ITL entry').avgwt:=20;
   event_list('enq: TX - allocate ITL entry').pct:=10;
   --enq: HW - contention
   event_list('enq: HW - contention').avgwt:=10;
   event_list('enq: HW - contention').pct:=10;
   --gc cr failure
   event_list('gc cr failure').avgwt:=99999;
   event_list('gc cr failure').pct:=100;
   --reliable message
   event_list('reliable message').avgwt:=99999;
   event_list('reliable message').pct:=100;
   --kfk: async disk IO
   event_list('kfk: async disk IO').avgwt:=99999;
   event_list('kfk: async disk IO').pct:=100;
  /*********define your event list end**********************/
  /*********define your event list end**********************/
  /*********define your event list end**********************/
  for i in startid..endid-1 loop
 begin 
  vbid:=i;
    veid:=i+1;
     select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi') into vstarttime from dba_hist_snapshot a where snap_id=vbid and instance_number=&inid;
     select to_char(a.end_interval_time,'yyyy-mm-dd hh24:mi') into vendtime from dba_hist_snapshot a where snap_id=veid and instance_number=&inid;
     dbms_output.put_line('<table border="1" width="50%" ><tr><th class="awrbg" scope="col" colspan="6">'||vstarttime||' to '||vendtime);
     dbms_output.put_line('</th></tr><tr><th class="awrbg" scope="col">Event</th><th class="awrbg" scope="col">Waits</th>');
     dbms_output.put_line('<th class="awrbg" scope="col">Time(s)</th><th class="awrbg" scope="col">Avg wait (ms)</th><th class="awrbg" scope="col">% DB time</th><th class="awrbg" scope="col">Wait Class</th></tr>');
  open c1;
  loop
  fetch c1 into vevent,vwaits,vtime,vavgtime,vpctwt,vwaitclass;
  exit when c1%notfound;
  ---------------check awrc-------------------------------------------
   awr_string:='awrc';
  if  event_list.exists(vevent) then
      if vavgtime >= event_list(vevent).avgwt and vpctwt>=event_list(vevent).pct then
        awr_string:='awrc4';
      elsif vavgtime >= event_list(vevent).avgwt and vpctwt<event_list(vevent).pct then
         awr_string:='awrc3';
      elsif vavgtime < event_list(vevent).avgwt and vpctwt>=event_list(vevent).pct then
           awr_string:='awrc3';
      elsif event_list(vevent).avgwt=99999 and  event_list(vevent).pct=100 then
           awr_string:='awrc2';
      else
           awr_string:='awrc';
      end if;
  else
     awr_string:='awrc';
  end if;
  --------------------------------------------
   dbms_output.put_line( '<tr>' );
  dbms_output.put_line('<td scope="row" class='''|| awr_string ||'''>'||vevent||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vwaits||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vtime||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vavgtime||'</td>' );
  dbms_output.put_line('<td align="right" class=''awrc''>'||vpctwt||'</td>' );
   dbms_output.put_line('<td class=''awrc''>'||vwaitclass||'</td>' );
  dbms_output.put_line('</tr>' );
  end loop;
  close c1;
   dbms_output.put_line('</table><p />');
exception when others then
null;
end; 
 end loop;
end;
/
-----------------------------top sql------------20190901---------------
prompt <a class="awr" name="160"></a>
prompt <p><h3 class='awr'>Top 3 workload SQL list </h3></p>
prompt <div style="width:75%">
prompt </div>
declare
vsnap_time varchar2(60);
vsql_id varchar2(60);
vELAPSED_TIME_DELTA number;
velapsed_order number;
vCPU_TIME_DELTA number;
vcpu_order number;
vphy_bytes number;
vphybytes_order number;
vEXECUTIONS_DELTA number;
vexe_order number;
vBUFFER_GETS_DELTA number;
vbuffer_order number;
vsql_text varchar2(160);
vformat varchar2(20):='awrnc';
vformat1 varchar2(20):='awrnc';
vformat2 varchar2(20):='awrnc';
vformat3 varchar2(20):='awrnc';
vformat4 varchar2(20):='awrnc';
vformat5 varchar2(20):='awrnc';
vlastsnatime varchar2(60);
vsqlfull clob;
cursor cur02 is
with b as (
select sql_id, sql_text from (
select   sql_id, sql_text, ROW_NUMBER() over( partition by sql_id order by sql_id ) rn from   dba_hist_sqltext  )
where rn=1 )
 select  a2.snap_time, a2.SQL_ID, 
 a2.ELAPSED_TIME_DELTA, a2.elapsed_order,
 a2.CPU_TIME_DELTA,a2.cpu_order,
 a2.phy_bytes,a2.phybytes_order ,
 a2.EXECUTIONS_DELTA,a2.exe_order ,
 a2.BUFFER_GETS_DELTA,a2.buffer_order,
 a2.sql_text
 from (
select * from (
select /*+ OPT_PARAM('_simple_view_merging' 'false')*/to_char(c.END_INTERVAL_TIME,'yyyy-mm-dd hh24:mi') snap_time,a.SNAP_ID,a.SQL_ID,
       a.ELAPSED_TIME_DELTA,
       rank() over(partition by a.SNAP_ID order by a.ELAPSED_TIME_DELTA desc nulls last) elapsed_order,
       a.CPU_TIME_DELTA,
       rank() over(partition by a.SNAP_ID order by a.CPU_TIME_DELTA desc nulls last) cpu_order,
       (a.PHYSICAL_WRITE_BYTES_DELTA + a.PHYSICAL_READ_BYTES_DELTA) phy_bytes,
       rank() over(partition by a.SNAP_ID order by (a.PHYSICAL_WRITE_BYTES_DELTA + a.PHYSICAL_READ_BYTES_DELTA) desc nulls last) phybytes_order,
       a.EXECUTIONS_DELTA,
       rank() over(partition by a.SNAP_ID order by a.EXECUTIONS_DELTA desc nulls last) exe_order,
       a.BUFFER_GETS_DELTA,
       rank() over(partition by a.SNAP_ID order by a.BUFFER_GETS_DELTA desc nulls last) buffer_order,
       substr(b.SQL_TEXT,1,50) sql_text
  from dba_hist_sqlstat a , b ,dba_hist_snapshot c where A.snap_id >= &bid and a.snap_id <=&eid  and &checksql=1
 and a.instance_number = &inid and
  a.SQL_ID=b.SQL_ID  and a.SNAP_ID=c.SNAP_ID and a.INSTANCE_NUMBER=c.INSTANCE_NUMBER  
    )a1
  where (elapsed_order <=3 or cpu_order<=3 or buffer_order<=3 or exe_order<=3 or phybytes_order <=3)
  )a2  order by a2.snap_id,a2.elapsed_order;
cursor cur03 is
with b as (
select sql_id, sql_text from (
select   sql_id, sql_text, ROW_NUMBER() over( partition by sql_id order by sql_id ) rn from   dba_hist_sqltext  )
where rn=1 )
 select  
 a2.SQL_ID,
 a2.sql_text
 from (
select * from (
select /*+ OPT_PARAM('_simple_view_merging' 'false')*/to_char(c.END_INTERVAL_TIME,'yyyy-mm-dd hh24:mi') snap_time,a.SNAP_ID,a.SQL_ID,
       a.ELAPSED_TIME_DELTA,
       rank() over(partition by a.SNAP_ID order by a.ELAPSED_TIME_DELTA desc nulls last) elapsed_order,
       a.CPU_TIME_DELTA,
       rank() over(partition by a.SNAP_ID order by a.CPU_TIME_DELTA desc nulls last) cpu_order,
       (a.PHYSICAL_WRITE_BYTES_DELTA + a.PHYSICAL_READ_BYTES_DELTA) phy_bytes,
       rank() over(partition by a.SNAP_ID order by (a.PHYSICAL_WRITE_BYTES_DELTA + a.PHYSICAL_READ_BYTES_DELTA) desc nulls last) phybytes_order,
       a.EXECUTIONS_DELTA,
       rank() over(partition by a.SNAP_ID order by a.EXECUTIONS_DELTA desc nulls last) exe_order,
       a.BUFFER_GETS_DELTA,
       rank() over(partition by a.SNAP_ID order by a.BUFFER_GETS_DELTA desc nulls last) buffer_order,
       b.sql_text
  from dba_hist_sqlstat a , b ,dba_hist_snapshot c where A.snap_id >= &bid and a.snap_id <=&eid  and &checksql=1
 and a.instance_number = &inid and
  a.SQL_ID=b.SQL_ID  and a.SNAP_ID=c.SNAP_ID and a.INSTANCE_NUMBER=c.INSTANCE_NUMBER  
      )a1
  where (elapsed_order <=3 or cpu_order<=3 or buffer_order<=3 or exe_order<=3 or phybytes_order <=3)
  )a2   ;
begin
dbms_output.put_line('<table border="0" class="tdiff" summary="This table displays top SQL">');
dbms_output.put_line('<tr><th class="awrbg" scope="col">Snap_time</th><th class="awrbg" scope="col">sql_id </th>');
dbms_output.put_line('<th class="awrbg" scope="col">ELAPSED_DELTA</th><th class="awrbg" scope="col">ELAPSED_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">CPU_DELTA</th><th class="awrbg" scope="col">CPU_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">PHY_DELTA</th><th class="awrbg" scope="col">PHY_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">EXE_DELTA</th><th class="awrbg" scope="col">EXE_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">BUFF_DELTA</th><th class="awrbg" scope="col">BUFF_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">SQL Text</th></tr>');
  open cur02;
  loop
    fetch cur02 into 
vsnap_time,
vsql_id,
vELAPSED_TIME_DELTA ,
velapsed_order,
vCPU_TIME_DELTA,
vcpu_order,
vphy_bytes,
vphybytes_order,
vEXECUTIONS_DELTA,
vexe_order,
vBUFFER_GETS_DELTA,
vbuffer_order,
vsql_text;
exit when cur02%notfound;

if(vsnap_time<>vlastsnatime) then
     dbms_output.put_line('<tr><th class="awrbg" scope="col">Snap_time</th><th class="awrbg" scope="col">sql_id </th>');
dbms_output.put_line('<th class="awrbg" scope="col">ELAPSED_DELTA</th><th class="awrbg" scope="col">ELAPSED_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">CPU_DELTA</th><th class="awrbg" scope="col">CPU_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">PHY_DELTA</th><th class="awrbg" scope="col">PHY_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">EXE_DELTA</th><th class="awrbg" scope="col">EXE_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">BUFF_DELTA</th><th class="awrbg" scope="col">BUFF_ORDER</th>');
dbms_output.put_line('<th class="awrbg" scope="col">SQL Text</th></tr>');
end if;

vlastsnatime:=vsnap_time;
  if vformat='awrnc' then
    vformat:='awrc';
    else
      vformat:='awrnc';
      end if;
      vformat1:=vformat;
      vformat2:=vformat;
      vformat3:=vformat;
      vformat4:=vformat;
      vformat5:=vformat;

   if velapsed_order<=3 then vformat1:='awrc5'; end if;
   if vcpu_order<=3 then vformat2:='awrc5'; end if;
   if vphybytes_order<=3 then vformat3:='awrc5'; end if;
   if vexe_order<=3 then vformat4:='awrc5'; end if;
   if vbuffer_order<=3 then vformat5:='awrc5'; end if;
  
   if mod(cur02%ROWCOUNT,15)=0 then
null;
   end if;

dbms_output.put_line('<tr><td align="right" class='''||vformat||'''>'||vsnap_time||'</td><td align="right" class='''||vformat||'''><a class="awr" href="#'||vsql_id||'">'||vsql_id||'</a></td>');
dbms_output.put_line('<td align="right" class='''||vformat||'''>'||vELAPSED_TIME_DELTA||'</td><td align="right" class='''||vformat1||'''>'||velapsed_order||'</td>');
dbms_output.put_line('<td align="right" class='''||vformat||'''>'||vCPU_TIME_DELTA||'</td><td align="right" class='''||vformat2||'''>'||vcpu_order||'</td>');
dbms_output.put_line('<td align="right" class='''||vformat||'''>'||vphy_bytes||'</td><td align="right" class='''||vformat3||'''>'||vphybytes_order||'</td>');
dbms_output.put_line('<td align="right" class='''||vformat||'''>'||vEXECUTIONS_DELTA||'</td><td align="right" class='''||vformat4||'''>'||vexe_order||'</td>');
dbms_output.put_line('<td align="right" class='''||vformat||'''>'||vBUFFER_GETS_DELTA||'</td><td align="right" class='''||vformat5||'''>'||vbuffer_order||'</td>');
dbms_output.put_line('<td class='''||vformat||'''>'||vsql_text||'</td></tr>');
  end loop;
  close cur02;

dbms_output.put_line('<a class="awr" name="169"></a>');
dbms_output.put_line('<div style="width:75%">');
dbms_output.put_line('</div>');
dbms_output.put_line('<table border="0" class="tdiff" summary="This table displays the text of the SQL statements which have been referred to in the report">');
dbms_output.put_line('<tr><th class="awrbg" scope="col">SQL Id</th><th class="awrbg" scope="col">SQL Text</th></tr>');
open cur03;
loop
    fetch cur03 into vsql_id, vsqlfull;
    exit when cur03%notfound;
    
    dbms_output.put_line('<tr><td scope="row" class=''awrc''><a class="awr" name="'|| vsql_id||'"></a>'||vsql_id||'</td><td class=''awrnc''>');
    
    DECLARE
        v_clob CLOB;
        v_len  NUMBER;
        v_off  NUMBER := 1;
        v_amount INTEGER := 8000;
        v_buffer VARCHAR2(32767);
    BEGIN
        IF vsqlfull IS NOT NULL AND dbms_lob.getlength(vsqlfull) > 0 THEN
            BEGIN
               v_clob := dbms_xmlgen.convert(vsqlfull, dbms_xmlgen.entity_encode);
            EXCEPTION WHEN OTHERS THEN
               v_clob := vsqlfull; 
            END;
            v_len := dbms_lob.getlength(v_clob);
            WHILE v_off <= v_len LOOP
                v_buffer := dbms_lob.substr(v_clob, v_amount, v_off);
                dbms_output.put(v_buffer);
                v_off := v_off + v_amount;
            END LOOP;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    
    dbms_output.put_line('</td></tr>');
end loop;
close cur03;

dbms_output.put_line('</table>');

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
prompt </p>
--------------------------------------top sql end------------------------

prompt </div>
prompt </div>
prompt <a class="awr" href="#top">Back to Top</a>
prompt 	<script>	
------------------------cpu---------------------------------------
prompt  
prompt  
declare
TYPE ValueList IS TABLE OF varchar2(200);
backdbcpu ValueList;
servercpu ValueList;
dbcpu ValueList;
snaptime ValueList;
cpu_cur SYS_REFCURSOR;
v_backdb_cpu varchar2(200);
v_server_cpu varchar2(200);
v_db_cpu varchar2(200);
v_snap_time varchar2(200);
begin
  dbms_output.put_line('var cpudata = { type: "line", data: { labels: [' );
open cpu_cur for
select  
       sum(case
   when e.metric_name = 'Background CPU Usage Per Sec' then
    e.pct
   else
    0
 end) backdb_cpu,
       sum(case
   when e.metric_name = 'Host CPU Utilization (%)' then
    e.pct
   else
    0
 end) server_cpu,
       sum(case
   when e.metric_name = 'CPU Usage Per Sec' then
    e.pct
   else
    0
 end) db_cpu, 
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
from dba_hist_snapshot f
         where f.snap_id = e.snap_id
 and f.instance_number = &inid) snap_time
  from (select a.snap_id,
     trunc(decode(a.METRIC_NAME,
        'Host CPU Utilization (%)',
        a.average,
        'CPU Usage Per Sec',
        a.average / 100 / (select value from v$parameter t where t.NAME = 'cpu_count' ) * 100, 
        a.average / 100 / (select value from v$parameter t where t.NAME = 'cpu_count' ) * 100,
        a.average),
 2) pct,
     a.METRIC_NAME,
     a.METRIC_UNIT
from dba_hist_sysmetric_summary a
         where A.snap_id >= &bid and a.snap_id <=&eid  
 and a.instance_number = &inid
 and a.METRIC_NAME in
     ('Host CPU Utilization (%)',
      'CPU Usage Per Sec',
      'Background CPU Usage Per Sec')
         order by 1, 3) e
 group by snap_id
 order by snap_id;
  FETCH cpu_cur BULK COLLECT INTO backdbcpu,servercpu,dbcpu,snaptime;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 backdbcpu.extend;
 backdbcpu(1):='0';
 servercpu.extend;
 servercpu(1):=0;
 dbcpu.extend;
 dbcpu(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "Backup CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(255, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(128, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');        
-----------------------------------------
FOR i IN backdbcpu.FIRST .. backdbcpu.LAST
LOOP
  if(i<backdbcpu.count) then
DBMS_OUTPUT.PUT_LINE (backdbcpu(i)||',');
elsif(i=backdbcpu.count) then
DBMS_OUTPUT.PUT_LINE (backdbcpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], }, {');
DBMS_OUTPUT.PUT_LINE ('label: "Database CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 0, 128)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbcpu.FIRST .. dbcpu.LAST
LOOP
  if(i<dbcpu.count) then
DBMS_OUTPUT.PUT_LINE (dbcpu(i)||',');
elsif(i=dbcpu.count) then
DBMS_OUTPUT.PUT_LINE (dbcpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Server CPU",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN servercpu.FIRST .. servercpu.LAST
LOOP
  if(i<servercpu.count) then
DBMS_OUTPUT.PUT_LINE (servercpu(i)||',');
elsif(i=servercpu.count) then
DBMS_OUTPUT.PUT_LINE (servercpu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('],},]},');
DBMS_OUTPUT.PUT_LINE('			options: {');
DBMS_OUTPUT.PUT_LINE('				responsive: true,');
DBMS_OUTPUT.PUT_LINE('				title:{');
DBMS_OUTPUT.PUT_LINE('					display:true,');
DBMS_OUTPUT.PUT_LINE('					text:"CPU Utilization"');
DBMS_OUTPUT.PUT_LINE('				},');
DBMS_OUTPUT.PUT_LINE('				tooltips: {');
DBMS_OUTPUT.PUT_LINE('					mode: "index",');
DBMS_OUTPUT.PUT_LINE('				},');
DBMS_OUTPUT.PUT_LINE('				hover: {');
DBMS_OUTPUT.PUT_LINE('					mode: "index"');
DBMS_OUTPUT.PUT_LINE('				},');
DBMS_OUTPUT.PUT_LINE('				scales: {');
DBMS_OUTPUT.PUT_LINE('					xAxes: [{');
DBMS_OUTPUT.PUT_LINE('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('							display: true,');
DBMS_OUTPUT.PUT_LINE('							labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE('						}');
DBMS_OUTPUT.PUT_LINE('					}],');
DBMS_OUTPUT.PUT_LINE('					yAxes: [{');
DBMS_OUTPUT.PUT_LINE('					 ticks: {min : 0,  max :100 },');
DBMS_OUTPUT.PUT_LINE('						stacked: false,');
DBMS_OUTPUT.PUT_LINE('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('							display: true,');
DBMS_OUTPUT.PUT_LINE('							labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('						}');
DBMS_OUTPUT.PUT_LINE('					}]');
DBMS_OUTPUT.PUT_LINE('				}');
DBMS_OUTPUT.PUT_LINE('			}');
DBMS_OUTPUT.PUT_LINE('		};');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
  /
---------------dbtime---------------------------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
dbtime ValueList;
cputime ValueList;
sqltime ValueList;
dbcpu ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
v_backdb_cpu varchar2(200);
v_server_cpu varchar2(200);
v_db_cpu varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var dbtimedata = { type: "line", data: { labels: [' );
open my_cur for
select 
  snap_time, db_time, db_cpu,sql_exec_time
 from (
select  a1.snap_id,
trunc((greatest(0, a1.dbtime - lag(a1.dbtime, 1, a1.dbtime) over(order by a1.snap_id)))/1000000) db_time,
trunc((greatest(0, a1.dbcpu - lag(a1.dbcpu, 1, a1.dbcpu) over(order by a1.snap_id)))/1000000) db_cpu,
trunc((greatest(0, a1.sql_time - lag(a1.sql_time, 1, a1.sql_time) over(order by a1.snap_id)))/1000000) sql_exec_time ,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = a1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a.snap_id,instance_number,
sum(case when a.stat_name='DB CPU' then  a.value else 0 end  )  dbcpu,
sum(case when a.stat_name='DB time' then  a.value else 0 end  )  dbtime,
sum(case when a.stat_name='hard parse elapsed time' then  a.value else 0 end  )  hardptime,
sum(case when a.stat_name='parse time elapsed' then  a.value else 0 end  )  ptime,
sum(case when a.stat_name='sql execute elapsed time' then  a.value else 0 end  )  sql_time,
(select b.value from DBA_HIST_SYSSTAT b where b.snap_id=a.snap_id and b.stat_name='execute count' and b.instance_number=&inid) exec_count
 from  dba_hist_sys_time_model a 
where a.stat_name in (   'DB time','DB CPU','parse time elapsed','hard parse elapsed time','sql execute elapsed time')
and A.snap_id >= &bid and A.snap_id <= &eid and a.instance_number=&inid 
group by a.snap_id,instance_number order by snap_id ) a1 ) a2 
where a2.db_time>0 and a2.db_cpu>0 and a2.sql_exec_time>0;
  FETCH my_cur BULK COLLECT INTO snaptime,dbtime,cputime,sqltime;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 dbtime.extend;
 dbtime(1):='0';
 cputime.extend;
 cputime(1):=0;
 sqltime.extend;
 sqltime(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "CPU Time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN cputime.FIRST .. cputime.LAST
LOOP
  if(i<cputime.count) then
DBMS_OUTPUT.PUT_LINE (cputime(i)||',');
elsif(i=cputime.count) then
DBMS_OUTPUT.PUT_LINE (cputime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "SQL time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(204, 102, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
FOR i IN sqltime.FIRST .. sqltime.LAST
LOOP
  if(i<sqltime.count) then
DBMS_OUTPUT.PUT_LINE (sqltime(i)||',');
elsif(i=sqltime.count) then
DBMS_OUTPUT.PUT_LINE (sqltime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "DB time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 128, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbtime.FIRST .. dbtime.LAST
LOOP
  if(i<dbtime.count) then
DBMS_OUTPUT.PUT_LINE (dbtime(i)||',');
elsif(i=dbtime.count) then
DBMS_OUTPUT.PUT_LINE (dbtime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('			options: {');
DBMS_OUTPUT.PUT_LINE ('				responsive: true,');
DBMS_OUTPUT.PUT_LINE ('				title:{');
DBMS_OUTPUT.PUT_LINE ('					display:true,');
DBMS_OUTPUT.PUT_LINE ('					text:"DB time"');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				tooltips: {');
DBMS_OUTPUT.PUT_LINE ('					mode: "index",');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				hover: {');
DBMS_OUTPUT.PUT_LINE ('					mode: "index"');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				scales: {');
DBMS_OUTPUT.PUT_LINE ('					xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('							display: true,');
DBMS_OUTPUT.PUT_LINE ('							labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('						}');
DBMS_OUTPUT.PUT_LINE ('					}],');
DBMS_OUTPUT.PUT_LINE ('					yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('						stacked: false,');
DBMS_OUTPUT.PUT_LINE ('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('							display: true,');
DBMS_OUTPUT.PUT_LINE ('							labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('						}}]}}};	');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------------dbtime end-------------------------
-------------------------------parsetime----------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
parsetime ValueList;
hparsetime ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
v_snap_time varchar2(200);
begin
dbms_output.put_line('var parsetimedata = { type: "line", data: { labels: [' );
open my_cur for
select 
  snap_time, ptime, hardptime
 from (
select  a1.snap_id,
trunc((greatest(0, a1.hardptime - lag(a1.hardptime, 1, a1.hardptime) over(order by a1.snap_id)))/1000000) hardptime,
trunc((greatest(0, a1.ptime - lag(a1.ptime, 1, a1.ptime) over(order by a1.snap_id)))/1000000) ptime,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = a1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a.snap_id,instance_number,
sum(case when a.stat_name='hard parse elapsed time' then  a.value else 0 end  )  hardptime,
sum(case when a.stat_name='parse time elapsed' then  a.value else 0 end  )  ptime
 from  dba_hist_sys_time_model a 
where a.stat_name in (  'parse time elapsed','hard parse elapsed time')
and A.snap_id >= &bid and A.snap_id <= &eid and a.instance_number=&inid 
group by a.snap_id,instance_number order by snap_id ) a1 ) a2 
where a2.ptime>0;
  FETCH my_cur BULK COLLECT INTO snaptime,parsetime,hparsetime;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 parsetime.extend;
 parsetime(1):='0';
 hparsetime.extend;
 hparsetime(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "Hard parse time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: window.awrColors.blue1 ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.blue2 ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN hparsetime.FIRST .. hparsetime.LAST
LOOP
  if(i<hparsetime.count) then
DBMS_OUTPUT.PUT_LINE (hparsetime(i)||',');
elsif(i=hparsetime.count) then
DBMS_OUTPUT.PUT_LINE (hparsetime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Parse time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(204, 102, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 128, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN parsetime.FIRST .. parsetime.LAST
LOOP
  if(i<parsetime.count) then
DBMS_OUTPUT.PUT_LINE (parsetime(i)||',');
elsif(i=parsetime.count) then
DBMS_OUTPUT.PUT_LINE (parsetime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('			options: {');
DBMS_OUTPUT.PUT_LINE ('				responsive: true,');
DBMS_OUTPUT.PUT_LINE ('				title:{');
DBMS_OUTPUT.PUT_LINE ('					display:true,');
DBMS_OUTPUT.PUT_LINE ('					text:"Parse time"');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				tooltips: {');
DBMS_OUTPUT.PUT_LINE ('					mode: "index",');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				hover: {');
DBMS_OUTPUT.PUT_LINE ('					mode: "index"');
DBMS_OUTPUT.PUT_LINE ('				},');
DBMS_OUTPUT.PUT_LINE ('				scales: {');
DBMS_OUTPUT.PUT_LINE ('					xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('							display: true,');
DBMS_OUTPUT.PUT_LINE ('							labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('						}');
DBMS_OUTPUT.PUT_LINE ('					}],');
DBMS_OUTPUT.PUT_LINE ('					yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('						stacked: false,');
DBMS_OUTPUT.PUT_LINE ('						scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('							display: true,');
DBMS_OUTPUT.PUT_LINE ('							labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('						}}]}}};	');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-------------------------------parsetime end------------------------
-------------------------------ash---------------------------------
set serveroutput on size unlimited
declare
cursor cur1 is
select to_char(time,'yyyy-mm-dd hh24:mi') time,
       sum(case activity
             when 'CPU' then
              1
             else
              0
           end) CPU,
       sum(case activity
             when 'Concurrency' then
              1
             else
              0
           end) Concurrency,
       sum(case activity
             when 'System I/O' then
              1
             else
              0
           end) Systemio,
       sum(case activity
             when 'User I/O' then
              1
             else
              0
           end) userio,
       sum(case activity
             when 'Administrative' then
              1
             else
              0
           end) Administrative,
       sum(case activity
             when 'Configuration' then
              1
             else
              0
           end) Configuration,
       sum(case activity
             when 'Application' then
              1
             else
              0
           end) Application,
       sum(case activity
             when 'Network' then
              1
             else
              0
           end) Network,
       sum(case activity
             when 'Commit' then
              1
             else
              0
           end) Commit,
       sum(case activity
             when 'Scheduler' then
              1
             else
              0
           end) Scheduler,
       sum(case activity
             when 'Cluster' then
              1
             else
              0
           end) Cluster1,
       sum(case activity
             when 'Queueing' then
              1
             else
              0
           end) Queueing,
       sum(case activity
             when 'Other' then
              1
             else
              0
           end) Other
  from (select to_date(substr(to_char(sample_time, 'yyyymmdd hh24:mi'),1,13)||'0','yyyymmdd hh24:mi') time,
               nvl(wait_class, 'CPU') activity
          from  dba_hist_active_sess_history a
         where session_type = 'FOREGROUND' 
         and a.snap_id >=&bid and snap_id <=&eid  and a.instance_number=&inid
         )
 group by time
 order by time;
 r1 cur1%rowtype;
 TYPE Roster IS TABLE OF cur1%rowtype;
 r2 Roster;
 i number:=1;
 m number;
begin
  r2:=Roster();
  OPEN cur1;
loop
FETCH cur1 INTO r1;
exit when cur1%notfound;
r2.extend;
r2(i):=r1;
i:=i+1;
END LOOP;
CLOSE cur1;
---
m:=r2.count();
DBMS_OUTPUT.PUT_LINE('var ashdata = {labels: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m   then
DBMS_OUTPUT.PUT_LINE('"'||r1.time||'",');
else
DBMS_OUTPUT.PUT_LINE('"'||r1.time||'"');
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('],datasets: [{');
DBMS_OUTPUT.PUT_LINE('label: "CPU time",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE('data: [');
----
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.CPU||',');
else
DBMS_OUTPUT.PUT_LINE(r1.CPU);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Concurrency",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
DBMS_OUTPUT.PUT_LINE('data: [');
--         
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Concurrency||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Concurrency);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "System io",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.yellow1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Systemio||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Systemio);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "User io",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.userio||',');
else
DBMS_OUTPUT.PUT_LINE(r1.userio);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Administrative",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.grey1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Administrative||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Administrative);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Configuration",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.orange1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Configuration||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Configuration);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Application",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Application||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Application);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Network",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.pink1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Network||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Network);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Commit",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.purple1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Commit||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Commit);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Scheduler",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.black1,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Scheduler||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Scheduler);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Cluster",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.orange2,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Cluster1||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Cluster1);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Queueing",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Queueing||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Queueing);
end if;
END LOOP;
---
DBMS_OUTPUT.PUT_LINE('] },  {');
DBMS_OUTPUT.PUT_LINE('label: "Other",');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.purple2,');
DBMS_OUTPUT.PUT_LINE('data: [');
FOR i IN r2.FIRST .. r2.LAST LOOP 
r1:=r2(i);
if i<m then
DBMS_OUTPUT.PUT_LINE(r1.Other||',');
else
DBMS_OUTPUT.PUT_LINE(r1.Other);
end if;
END LOOP;
DBMS_OUTPUT.PUT_LINE(' ]}] };');
---
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-------------------------ash end------------------------------------------------------
--------------------------sql----------------------------------------------------
----sqlcount 
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  snaptime ValueList;
  sqlcnt   ValueList;
  sqltime ValueList;
  sqlcnt_cur sys_refcursor;
begin
  dbms_output.put_line('var sqldata = {labels: [');
  open sqlcnt_cur for
    select snap_time,sql_exec_count,   trunc(sql_time/ sql_exec_count  )   avg_sql_time
      from (select 
                   a1.snap_time,
                  trunc( (greatest(0, a1.exec_count - lag(a1.exec_count, 1, a1.exec_count) over(order by a1.snap_id)))/&_iv) sql_exec_count,
                 trunc(( greatest(0, a1.sql_time - lag(a1.sql_time, 1, a1.sql_time) over(order by a1.snap_id)))/&_iv) sql_time
              from (select a.snap_id,
                           sum(case
                                 when a.stat_name = 'sql execute elapsed time' then
                                  a.value
                                 else
                                  0
                               end) sql_time,
                           (select b.value
                              from DBA_HIST_SYSSTAT b
                             where b.snap_id = a.snap_id
                               and b.stat_name = 'execute count'
                               and b.instance_number = &inid) exec_count,
                           (select '"' || to_char(f.END_INTERVAL_TIME,
                                                     'mm-dd hh24:mi') || '"'
                                 from dba_hist_snapshot f
                                where f.snap_id = a.snap_id
                                  and f.instance_number = &inid) snap_time
                      from dba_hist_sys_time_model a
                     where a.stat_name in
                           ('DB time',
                            'DB CPU',
                            'parse time elapsed',
                            'hard parse elapsed time',
                            'sql execute elapsed time')
                       and A.snap_id >= &bid
                       and A.snap_id <= &eid
                       and a.instance_number = &inid
                     group by a.snap_id
                     order by snap_id) a1)
     where sql_exec_count > 0;
  FETCH sqlcnt_cur BULK COLLECT
    INTO  snaptime, sqlcnt,sqltime;
  close sqlcnt_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 sqlcnt.extend;
 sqlcnt(1):='0';
 sqltime.extend;
 sqltime(1):='0';
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  -----------------------------------------
dbms_output.put_line('],datasets: [{');
dbms_output.put_line('label: "SQL Execution Count",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('borderColor: window.awrColors.red1,');
dbms_output.put_line('backgroundColor: window.awrColors.red2,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('data: [');
  -----------------------------------------
  FOR i IN sqlcnt.FIRST .. sqlcnt.LAST LOOP
    if (i < sqlcnt.count) then
      DBMS_OUTPUT.PUT_LINE(sqlcnt(i) || ',');
    elsif (i = sqlcnt.count) then
      DBMS_OUTPUT.PUT_LINE(sqlcnt(i));
    end if;
  END LOOP;
/*+copyright wangwenjie , do not copy this code to other business software*/
dbms_output.put_line('], yAxisID: "y-axis-1", }, {');
dbms_output.put_line('label: "SQL Execution Time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('borderColor: window.awrColors.blue1,');
dbms_output.put_line('backgroundColor: window.awrColors.blue2,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('data: [');
  -----------------------------------------
  FOR i IN sqltime.FIRST .. sqltime.LAST LOOP
    if (i < sqltime.count) then
      DBMS_OUTPUT.PUT_LINE(sqltime(i) || ',');
    elsif (i = sqltime.count) then
      DBMS_OUTPUT.PUT_LINE(sqltime(i));
    end if;
  END LOOP;
  -----------------------------------------        
dbms_output.put_line('],');
dbms_output.put_line('yAxisID: "y-axis-2"');
dbms_output.put_line(' }]};');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------------------sql end---------------------------------------------
--------------------------user call--------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
usercall ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var usercalldata = { type: "line", data: { labels: [');
open my_cur for
select 
  trunc(usercall / &_iv ) ,snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.usercall - lag(a2.usercall, 1, a2.usercall) over(order by a2.snap_id)) usercall,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='user calls' then  a1.value else 0 end  )  usercall  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'user calls' ) 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO usercall,snaptime;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 usercall.extend;
 usercall(1):='0';
end if;
-----------------------------------------   
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "User Calls",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green1,');
dbms_output.put_line('borderColor: window.awrColors.green2,');
dbms_output.put_line('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
 FOR i IN usercall.FIRST .. usercall.LAST
LOOP
  if(i<usercall.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (usercall(i)||',');
end if;
elsif(i=usercall.count) then
DBMS_OUTPUT.PUT_LINE (usercall(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:"User Calls Per Second"');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------user call end-----------------------------------
---------------------------------logic read----------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  snap_id  ValueList;
  CG       ValueList; ---consistent gets
  SL       ValueList; ---Session Logical Reads
  SNAPTIME ValueList;
  lg_cur sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var logicdata = { type: "line", data: { labels: [');
  OPEN LG_CUR FOR
    select  
          trunc( greatest(0, ( greatest(0, a2.csget - lag(a2.csget, 1, a2.csget) over(order by a2.snap_id))))/&_iv) cg,
         trunc( greatest(0, ( greatest(0, a2.slr - lag(a2.slr, 1, a2.slr) over(order by a2.snap_id))))/&_iv) sl,
          (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.snap_id,
                   sum(case
                         when a1.stat_name = 'consistent gets' then
                          a1.value
                         else
                          0
                       end) csget,
                   sum(case
                         when a1.stat_name = 'session logical reads' then
                          a1.value
                         else
                          0
                       end) slr
              from (select a.snap_id, a.stat_name, a.value
                      from dba_hist_sysstat a
                     where (a.stat_name = 'consistent gets' or
                           a.stat_name = 'session logical reads')
                       and snap_id >= &bid
                       and snap_id <= &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name) a1
             group by a1.snap_id
             order by a1.snap_id) a2;

  FETCH LG_CUR BULK COLLECT
    INTO  CG,  SL,   SNAPTIME;
  CLOSE LG_CUR;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 SL.extend;
 SL(1):='0';
 CG.extend;
 CG(1):=0;
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ], datasets: [');
  DBMS_OUTPUT.PUT_LINE('{label: "Consistent Gets",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2 ,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1 ,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN cg.FIRST .. cg.LAST LOOP
    if (i < cg.count) then
      DBMS_OUTPUT.PUT_LINE(cg(i) || ',');
    elsif (i = cg.count) then
      DBMS_OUTPUT.PUT_LINE(cg(i));
    end if;
  END LOOP;
DBMS_OUTPUT.PUT_LINE('],}, {label: "Session Logic Read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue1 ,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2 ,');
DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN SL.FIRST .. SL.LAST LOOP
    if (i < SL.count) then
      DBMS_OUTPUT.PUT_LINE(SL(i) || ',');
    elsif (i = SL.count) then
      DBMS_OUTPUT.PUT_LINE(SL(i));
    end if;
  END LOOP;
DBMS_OUTPUT.PUT_LINE('],},]}, ');
DBMS_OUTPUT.PUT_LINE('options: { ');
DBMS_OUTPUT.PUT_LINE('responsive: true, ');
DBMS_OUTPUT.PUT_LINE('title:{ ');
DBMS_OUTPUT.PUT_LINE('display:true, ');
DBMS_OUTPUT.PUT_LINE('text:"Logic read / Second" ');
DBMS_OUTPUT.PUT_LINE('}, ');
DBMS_OUTPUT.PUT_LINE('tooltips: { ');
DBMS_OUTPUT.PUT_LINE('mode: "index", ');
DBMS_OUTPUT.PUT_LINE('}, ');
DBMS_OUTPUT.PUT_LINE('hover: { ');
DBMS_OUTPUT.PUT_LINE('mode: "index" ');
DBMS_OUTPUT.PUT_LINE('}, ');
DBMS_OUTPUT.PUT_LINE('scales: { ');
DBMS_OUTPUT.PUT_LINE('xAxes: [{ ');
DBMS_OUTPUT.PUT_LINE('scaleLabel: { ');
DBMS_OUTPUT.PUT_LINE('display: true,');
DBMS_OUTPUT.PUT_LINE('labelString: "Snap Time" ');
DBMS_OUTPUT.PUT_LINE('} ');
DBMS_OUTPUT.PUT_LINE('}], ');
DBMS_OUTPUT.PUT_LINE('yAxes: [{ ');
DBMS_OUTPUT.PUT_LINE('stacked: false, ');
DBMS_OUTPUT.PUT_LINE('scaleLabel: { ');
DBMS_OUTPUT.PUT_LINE('display: true, ');
DBMS_OUTPUT.PUT_LINE('labelString: "Value" ');
DBMS_OUTPUT.PUT_LINE('}}]}}};'); 
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------logic read end------------------------------------------
-----------------------------commit and redo--------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  RD       ValueList; ---redo size
  UC       ValueList; ---User Commits
  SNAPTIME ValueList;
  uc_cur   sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var commitdata = {labels: [');
  open uc_cur for
    select  
        trunc(  ( greatest(0, a2.rd - lag(a2.rd, 1, a2.rd) over(order by a2.snap_id)))/&_iv/1024) rd,
       trunc(  (  greatest(0, a2.uc - lag(a2.uc, 1, a2.uc) over(order by a2.snap_id)))/&_iv) uc,
           (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.snap_id,
                   sum(case
                         when a1.stat_name = 'redo size' then
                          a1.value
                         else
                          0
                       end) rd,
                   sum(case
                         when a1.stat_name = 'user commits' then
                          a1.value
                         else
                          0
                       end) uc
              from (select a.snap_id, a.stat_name, a.value
                      from dba_hist_sysstat a
                     where (
                           a.stat_name = 'redo size' or
                           a.stat_name = 'user commits')
                       and snap_id >= &bid
                       and snap_id <= &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name) a1
             group by a1.snap_id
             order by a1.snap_id) a2;

  fetch uc_cur bulk collect
    into rd, uc, snaptime;
 close uc_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 uc.extend;
 uc(1):='0';
 end if;
-----------------------------------------  
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ],datasets: [{');
  DBMS_OUTPUT.PUT_LINE('label: "User Commit",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN uc.FIRST .. uc.LAST LOOP
    if (i < uc.count) then
      DBMS_OUTPUT.PUT_LINE(uc(i) || ',');
    elsif (i = uc.count) then
      DBMS_OUTPUT.PUT_LINE(uc(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], yAxisID: "y-axis-1", }, {');
  DBMS_OUTPUT.PUT_LINE('label: "Redo size(KB)",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor:window.awrColors.green0,');
  DBMS_OUTPUT.PUT_LINE('fill: true,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN rd.FIRST .. rd.LAST LOOP
    if (i < rd.count) then
      DBMS_OUTPUT.PUT_LINE(rd(i) || ',');
    elsif (i = rd.count) then
      DBMS_OUTPUT.PUT_LINE(rd(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('],yAxisID: "y-axis-2"}]};');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------------commit and redo end------------------------------------
----------------------------redo transport-------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
rf ValueList;
rfm ValueList;
pct ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
v_snap_time varchar2(200);
begin
dbms_output.put_line('var redotransdata  = {labels: [' );
open my_cur for
select '"'||(select to_char(BEGIN_INTERVAL_TIME, 'yyyy-mm-dd hh24:mi')
          from dba_hist_snapshot
         where snap_id = a3.snap_id
           and INSTANCE_NUMBER = 1)||'"' snap_time,
      trunc( a3.rf/&_iv) rf,
       trunc(a3.rfm/&_iv) rfm,
       case
         when a3.rf > 0 then
          trunc(a3.rfm * 100 / a3.rf, 2)  
         else
          0
       end pct
  from (select a2.snap_id,
               greatest(0, a2.rf - lag(a2.rf, 1, a2.rf) over(order by a2.snap_id)) rf,
               greatest(0, a2.rfm - lag(a2.rfm, 1, a2.rfm) over(order by a2.snap_id)) rfm
          from (select a1.snap_id,
                       sum(case
                             when a1.stat_name = 'redo KB read for transport' then
                              a1.value
                             else
                              0
                           end) rf,
                       sum(case
                             when a1.stat_name =
                                  'redo KB read (memory) for transport' then
                              a1.value
                             else
                              0
                           end) rfm
                  from (select snap_id, STAT_NAME, value
                          from dba_hist_sysstat
                         where STAT_NAME in
                               ('redo KB read for transport',
                                'redo KB read (memory) for transport')
                       and snap_id >= &bid
                       and snap_id <= &eid
                       and instance_number = &inid ) a1
                 group by a1.snap_id
                 order by a1.snap_id) a2) a3;
 FETCH my_cur BULK COLLECT INTO snaptime,rf,rfm,pct;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 rf.extend;
 rf(1):='0';
 rfm.extend;
 rfm(1):=0;
 pct.extend;
 pct(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "Pencentage",');
DBMS_OUTPUT.PUT_LINE ('borderColor: "#ff0000",');
DBMS_OUTPUT.PUT_LINE ('borderDash: [5, 5],');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "#ff0000",');
DBMS_OUTPUT.PUT_LINE ('fill: false,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN pct.FIRST .. pct.LAST
LOOP
  if(i<pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i)||',');
elsif(i=pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (' ], yAxisID: "y-axis-2" },{');
DBMS_OUTPUT.PUT_LINE ('label: "redo KB read (mem)for transport",');
DBMS_OUTPUT.PUT_LINE ('borderColor: "#ff6600",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "#ff6600",');
DBMS_OUTPUT.PUT_LINE ('fill: false,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN rfm.FIRST .. rfm.LAST
LOOP
  if(i<rfm.count) then
DBMS_OUTPUT.PUT_LINE (rfm(i)||',');
elsif(i=rfm.count) then
DBMS_OUTPUT.PUT_LINE (rfm(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (' ],yAxisID: "y-axis-1", }, {');
DBMS_OUTPUT.PUT_LINE ('label: "redo KB read  for transport",');
DBMS_OUTPUT.PUT_LINE ('borderColor: "#66cc66",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "#66ff00",');
DBMS_OUTPUT.PUT_LINE ('fill: true,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN rf.FIRST .. rf.LAST
LOOP
  if(i<rf.count) then
DBMS_OUTPUT.PUT_LINE (rf(i)||',');
elsif(i=rf.count) then
DBMS_OUTPUT.PUT_LINE (rf(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], yAxisID: "y-axis-1",}]};');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------------redo transport end---------------------------
-------------------------------phy wr-------------------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  PR       ValueList; ---Physical Reads bytes
  PW       ValueList; ---physical write bytes
  prmax ValueList;
  pwmax ValueList;
  SNAPTIME ValueList;
  pw_cur sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var phydata = { type: "line", data: { labels: [');
  open pw_cur for
   select    (select trunc(maxval/1024/1024) from dba_hist_sysmetric_summary b where b.METRIC_NAME='Physical Write Total Bytes Per Sec' and a2.snap_id=b.snap_id and b.INSTANCE_NUMBER=a2.instance_number) pwmax,
    (select trunc(maxval/1024/1024) from dba_hist_sysmetric_summary c where c.METRIC_NAME='Physical Read Total Bytes Per Sec' and a2.snap_id=c.snap_id and c.INSTANCE_NUMBER=a2.instance_number) prmax,
      trunc(  ( greatest(0, a2.pw - lag(a2.pw, 1, a2.pw) over(order by a2.snap_id)))/&_iv/1024/1024) pw,   
      trunc( ( greatest(0, a2.pr - lag(a2.pr, 1, a2.pr) over(order by a2.snap_id)))/&_iv/1024/1024) pr,
            (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.instance_number,a1.snap_id,
                   sum(case
                         when a1.stat_name = 'physical read total bytes' then
                          a1.value
                         else
                          0
                       end) pr,
                 
                   sum(case
                         when a1.stat_name = 'physical write total bytes' then
                          a1.value
                         else
                          0
                       end) pw
              from (select a.snap_id, a.stat_name, a.value,a.instance_number 
                      from dba_hist_sysstat a
                     where ( 
                           a.stat_name like 'physical write total bytes' or
                           a.stat_name = 'physical read total bytes' )
                       and snap_id >= &bid
                       and snap_id < &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name,a.instance_number) a1
             group by a1.snap_id,a1.instance_number
             order by a1.snap_id) a2;

  fetch pw_cur bulk collect into pwmax, prmax,  pw,  pr,    snaptime;
  close pw_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 pr.extend;
 pr(1):='0';
 pw.extend;
 pw(1):=0;
  prmax.extend;
 prmax(1):='0';
 pwmax.extend;
 pwmax(1):=0;
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ],  datasets: [{');
  DBMS_OUTPUT.PUT_LINE(' label: "Physical read",');
  DBMS_OUTPUT.PUT_LINE(' fill: false,');
  DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.blue1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE(' borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE(' data: [');
  FOR i IN pr.FIRST .. pr.LAST LOOP
    if (i < pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i) || ',');
    elsif (i = pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], }, {');
  DBMS_OUTPUT.PUT_LINE('label: "MAX Physical read",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN prmax.FIRST .. prmax.LAST LOOP
    if (i < prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i) || ',');
    elsif (i = prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], },{');
  DBMS_OUTPUT.PUT_LINE('label: "Physcial write",');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pw.FIRST .. pw.LAST LOOP
    if (i < pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i) || ',');
    elsif (i = pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('],  fill: false,}, {');
  DBMS_OUTPUT.PUT_LINE('label: "Max Physical write",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pwmax.FIRST .. pwmax.LAST LOOP
    if (i < pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i) || ',');
    elsif (i = pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('     ], }]},');
DBMS_OUTPUT.PUT_LINE('options: {');
DBMS_OUTPUT.PUT_LINE('    responsive: true,');
DBMS_OUTPUT.PUT_LINE('    title:{');
DBMS_OUTPUT.PUT_LINE('        display:true,');
DBMS_OUTPUT.PUT_LINE('        text:"Physical R/W (MB) per Second"');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    tooltips: {');
DBMS_OUTPUT.PUT_LINE('        mode: "index",');
DBMS_OUTPUT.PUT_LINE('        intersect: false,');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    hover: {');
DBMS_OUTPUT.PUT_LINE('        mode: "nearest",');
DBMS_OUTPUT.PUT_LINE('        intersect: true');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    scales: {');
DBMS_OUTPUT.PUT_LINE(' xAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Snap"');
DBMS_OUTPUT.PUT_LINE('     }');
DBMS_OUTPUT.PUT_LINE(' }],');
DBMS_OUTPUT.PUT_LINE(' yAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('     } }] } } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------------------------phy wr end---------------------------------------------
----------------------------------phy2---------------------------------------
-------------------------------phy wr-------------------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  PR       ValueList; ---Physical Reads bytes
  PW       ValueList; ---physical write bytes
  prmax ValueList;
  pwmax ValueList;
  SNAPTIME ValueList;
  pw_cur sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var phyreqdata = { type: "line", data: { labels: [');
  open pw_cur for
  select (select trunc(maxval ) from dba_hist_sysmetric_summary b where b.METRIC_NAME='Physical Write Total IO Requests Per Sec' and a2.snap_id=b.snap_id and b.INSTANCE_NUMBER=a2.instance_number) pwmax,
    (select trunc(maxval ) from dba_hist_sysmetric_summary c where c.METRIC_NAME='Physical Read Total IO Requests Per Sec' and a2.snap_id=c.snap_id and c.INSTANCE_NUMBER=a2.instance_number) prmax,
      trunc( greatest(0, ( greatest(0, a2.pw - lag(a2.pw, 1, a2.pw) over(order by a2.snap_id))))/&_iv ) pw,   
      trunc( greatest(0, ( greatest(0, a2.pr - lag(a2.pr, 1, a2.pr) over(order by a2.snap_id))))/&_iv ) pr,
            (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.instance_number,a1.snap_id,
                   sum(case
                         when a1.stat_name = 'physical read total IO requests' then
                          a1.value
                         else
                          0
                       end) pr,
                 
                   sum(case
                         when a1.stat_name = 'physical write total IO requests' then
                          a1.value
                         else
                          0
                       end) pw
              from (select a.snap_id, a.stat_name, a.value,a.instance_number 
                      from dba_hist_sysstat a
                     where ( 
                           a.stat_name like 'physical read total IO requests' or
                           a.stat_name = 'physical write total IO requests' )
                       and snap_id >= &bid
                       and snap_id < &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name,a.instance_number) a1
             group by a1.snap_id,a1.instance_number
             order by a1.snap_id) a2;
  fetch pw_cur bulk collect into pwmax, prmax,  pw,  pr,    snaptime;
  close pw_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 pr.extend;
 pr(1):='0';
 pw.extend;
 pw(1):=0;
  prmax.extend;
 prmax(1):='0';
 pwmax.extend;
 pwmax(1):=0;
 end if;
-----------------------------------------
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ],  datasets: [{');
  DBMS_OUTPUT.PUT_LINE(' label: "Physical read request",');
  DBMS_OUTPUT.PUT_LINE(' fill: false,');
  DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.blue1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE(' borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE(' data: [');
  FOR i IN pr.FIRST .. pr.LAST LOOP
    if (i < pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i) || ',');
    elsif (i = pr.count) then
      DBMS_OUTPUT.PUT_LINE(pr(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], }, {');
  DBMS_OUTPUT.PUT_LINE('label: "MAX Physical read request",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN prmax.FIRST .. prmax.LAST LOOP
    if (i < prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i) || ',');
    elsif (i = prmax.count) then
      DBMS_OUTPUT.PUT_LINE(prmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], },{');
  DBMS_OUTPUT.PUT_LINE('label: "Physcial write request",');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pw.FIRST .. pw.LAST LOOP
    if (i < pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i) || ',');
    elsif (i = pw.count) then
      DBMS_OUTPUT.PUT_LINE(pw(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('],  fill: false,}, {');
  DBMS_OUTPUT.PUT_LINE('label: "Max Physical write request",');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN pwmax.FIRST .. pwmax.LAST LOOP
    if (i < pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i) || ',');
    elsif (i = pwmax.count) then
      DBMS_OUTPUT.PUT_LINE(pwmax(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('     ], }]},');
DBMS_OUTPUT.PUT_LINE('options: {');
DBMS_OUTPUT.PUT_LINE('    responsive: true,');
DBMS_OUTPUT.PUT_LINE('    title:{');
DBMS_OUTPUT.PUT_LINE('        display:true,');
DBMS_OUTPUT.PUT_LINE('        text:"Physical R/W Request per Second"');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    tooltips: {');
DBMS_OUTPUT.PUT_LINE('        mode: "index",');
DBMS_OUTPUT.PUT_LINE('        intersect: false,');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    hover: {');
DBMS_OUTPUT.PUT_LINE('        mode: "nearest",');
DBMS_OUTPUT.PUT_LINE('        intersect: true');
DBMS_OUTPUT.PUT_LINE('    },');
DBMS_OUTPUT.PUT_LINE('    scales: {');
DBMS_OUTPUT.PUT_LINE(' xAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Snap"');
DBMS_OUTPUT.PUT_LINE('     }');
DBMS_OUTPUT.PUT_LINE(' }],');
DBMS_OUTPUT.PUT_LINE(' yAxes: [{');
DBMS_OUTPUT.PUT_LINE('     display: true,');
DBMS_OUTPUT.PUT_LINE('     scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('         display: true,');
DBMS_OUTPUT.PUT_LINE('         labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('     } }] } } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------------phy2 end------------------------------------------------------
------------------------avg io------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
control ValueList;
dbseq ValueList;
dbsca ValueList;
dbparaell ValueList;
logsync ValueList;
drtpath ValueList;
cellsing ValueList;
cellmulti ValueList;
cpu_cur SYS_REFCURSOR;
v_control varchar2(200);
v_dbseq varchar2(200);
v_dbsca varchar2(200);
v_dbparaell varchar2(200);
v_logsync varchar2(200);
v_drtpath varchar2(200);
v_snap_time varchar2(200);
vcells  varchar2(200);
vcellm varchar2(200);
begin
dbms_output.put_line('var avgiodata = {type: "line", data: { labels: [' );
open cpu_cur for
select a3.snap_time,
decode(controlfilewaits,0,1 ,ceil(controlfilewaitstimes/controlfilewaits/1000)) controlfilewaits,
decode(dbfileseqwaits,0,1 ,ceil(dbfileseqtimes/dbfileseqwaits/1000)) dbfileseqwaits,
decode(dbfilesctwaits,0,1 ,ceil(dbfilescttimes/dbfilesctwaits/1000)) dbfilesctwaits,
decode(cellsingtimes,0,1 ,ceil(cellsingtimes/cellsingtimes/1000)) cellsingtimes,
decode(cellmutiltimes,0,1 ,ceil(cellmutiltimes/cellmutiltimes/1000)) cellmutiltimes,
decode(drtwaits,0,1 ,ceil(drttimes/drtwaits/1000)) drtwaits,
decode(logwaits,0,1 ,ceil(logtimes/logwaits/1000)) logwaits,
decode(dbparallelwaits,0,1 ,ceil(dbparalleltimes/dbparallelwaits/1000)) dbparallelwaits
 from (
select a2.snap_id,
          trunc(( greatest(0, a2.controlfilewaitstimes - lag(a2.controlfilewaitstimes, 1, a2.controlfilewaitstimes) over(order by a2.snap_id)))) controlfilewaitstimes ,
            trunc(( greatest(0, a2.controlfilewaits - lag(a2.controlfilewaits, 1, a2.controlfilewaits) over(order by a2.snap_id))))  controlfilewaits,
              trunc(( greatest(0, a2.dbfileseqtimes - lag(a2.dbfileseqtimes, 1, a2.dbfileseqtimes) over(order by a2.snap_id)))) dbfileseqtimes ,
            trunc(( greatest(0, a2.dbfileseqwaits - lag(a2.dbfileseqwaits, 1, a2.dbfileseqwaits) over(order by a2.snap_id))))  dbfileseqwaits,
              trunc(( greatest(0, a2.dbfilescttimes - lag(a2.dbfilescttimes, 1, a2.dbfilescttimes) over(order by a2.snap_id)))) dbfilescttimes ,
            trunc(( greatest(0, a2.dbfilesctwaits - lag(a2.dbfilesctwaits, 1, a2.dbfilesctwaits) over(order by a2.snap_id))))  dbfilesctwaits,
              trunc(( greatest(0, a2.drttimes - lag(a2.drttimes, 1, a2.drttimes) over(order by a2.snap_id)))) drttimes ,
            trunc(( greatest(0, a2.drtwaits - lag(a2.drtwaits, 1, a2.drtwaits) over(order by a2.snap_id))))  drtwaits,
              trunc(( greatest(0, a2.logtimes - lag(a2.logtimes, 1, a2.logtimes) over(order by a2.snap_id)))) logtimes ,
            trunc(( greatest(0, a2.logwaits - lag(a2.logwaits, 1, a2.logwaits) over(order by a2.snap_id))))  logwaits, 
              trunc(( greatest(0, a2.dbparalleltimes - lag(a2.dbparalleltimes, 1, a2.dbparalleltimes) over(order by a2.snap_id)))) dbparalleltimes ,
            trunc(( greatest(0, a2.dbparallelwaits - lag(a2.dbparallelwaits, 1, a2.dbparallelwaits) over(order by a2.snap_id))))  dbparallelwaits,
             trunc(( greatest(0, a2.cellsingtimes - lag(a2.cellsingtimes, 1, a2.cellsingtimes) over(order by a2.snap_id)))) cellsingtimes ,
              trunc(( greatest(0, a2.cellmutiltimes - lag(a2.cellmutiltimes, 1, a2.cellmutiltimes) over(order by a2.snap_id)))) cellmutiltimes ,
           (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
           from (
select a1.snap_id,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.total_waits_fg
             else
              0
           end) controlfilewaits,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.time_waited_micro_fg
             else
              0
           end) controlfilewaitstimes,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.total_waits_fg
             else
              0
           end) dbfileseqwaits,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbfileseqtimes,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.total_waits_fg
             else
              0
           end) dbfilesctwaits,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbfilescttimes,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.total_waits_fg
             else
              0
           end) drtwaits,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.time_waited_micro_fg
             else
              0
           end) drttimes,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.total_waits_fg
             else
              0
           end) logwaits,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.time_waited_micro_fg
             else
              0
           end) logtimes,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.total_waits_fg
             else
              0
           end) dbparallelwaits,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.time_waited_micro_fg
             else
              0
           end) dbparalleltimes,
        sum(case
             when a1.event_name = 'cell single block physical read' then
              a1.time_waited_micro_fg
             else
              0
           end) cellsingtimes,
        sum(case
             when a1.event_name = 'cell multiblock physical read' then
              a1.time_waited_micro_fg
             else
              0
           end) cellmutiltimes
  from (select a.snap_id,
               a.event_name,
               a.time_waited_micro_fg,
               a.total_waits_fg
          from dba_hist_system_event a
         where event_name in ('control file sequential read',
                              'log file sync',
                              'db file sequential read',
                              'db file scattered read',
                              'db file parallel read',
                              'direct path read',
                              'cell single block physical read',
                              'cell multiblock physical read')
           and A.snap_id >= &bid and a.snap_id <=&eid  
 and a.instance_number = &inid) a1
 group by a1.snap_id
 order by a1.snap_id)a2)a3 order by snap_id;
   FETCH cpu_cur BULK COLLECT INTO snaptime,control,dbseq,dbsca,cellsing,cellmulti,drtpath,logsync, dbparaell;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 control.extend;
 control(1):='0';
 dbseq.extend;
 dbseq(1):=0;
 dbsca.extend;
 dbsca(1):=0;
  drtpath.extend;
 drtpath(1):=0;
  logsync.extend;
 logsync(1):=0;
  dbparaell.extend;
 dbparaell(1):=0;
 cellsing.extend;
 cellsing(1):=0;
cellmulti.extend;
cellmulti(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
/*+copyright wangwenjie , do not copy this code to other business software*/
DBMS_OUTPUT.PUT_LINE('], datasets: [{');
DBMS_OUTPUT.PUT_LINE('label: "db file sequential read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbseq.FIRST .. dbseq.LAST
LOOP
  if(i<dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i)||',');
elsif(i=dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
DBMS_OUTPUT.PUT_LINE('label: "direct path read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.pink1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.pink2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN drtpath.FIRST .. drtpath.LAST
LOOP
  if(i<drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i)||',');
elsif(i=drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "log file sync",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN logsync.FIRST .. logsync.LAST
LOOP
  if(i<logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i)||',');
elsif(i=logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "db file parallel read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.orange1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.orange2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbparaell.FIRST .. dbparaell.LAST
LOOP
  if(i<dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i)||',');
elsif(i=dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "cell single block read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: "rgba(0, 0, 255, 1)",');
DBMS_OUTPUT.PUT_LINE('borderColor: "rgba(0, 0, 255, 1)",');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN cellsing.FIRST .. cellsing.LAST
LOOP
  if(i<cellsing.count) then
DBMS_OUTPUT.PUT_LINE (cellsing(i)||',');
elsif(i=cellsing.count) then
DBMS_OUTPUT.PUT_LINE (cellsing(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "cell multiblock read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: "rgba(0, 255, 0, 1)",');  
DBMS_OUTPUT.PUT_LINE('borderColor: "rgba(0, 255, 0, 1)",');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN cellmulti.FIRST .. cellmulti.LAST
LOOP
  if(i<cellmulti.count) then
DBMS_OUTPUT.PUT_LINE (cellmulti(i)||',');
elsif(i=cellmulti.count) then
DBMS_OUTPUT.PUT_LINE (cellmulti(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "control file sequential read",');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.purple1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.purple2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN control.FIRST .. control.LAST
LOOP
  if(i<control.count) then
DBMS_OUTPUT.PUT_LINE (control(i)||',');
elsif(i=control.count) then
DBMS_OUTPUT.PUT_LINE (control(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "db file scatter read",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE(' backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN dbsca.FIRST .. dbsca.LAST
LOOP
  if(i<dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i)||',');
elsif(i=dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i));
end if;
END LOOP;
-----------------------------------------
dbms_output.put_line('        ], }]  },');
dbms_output.put_line('options: {');
dbms_output.put_line('    responsive: true,');
dbms_output.put_line('    title:{');
dbms_output.put_line('        display:true,');
dbms_output.put_line('        text:"Average IO Wait Time (ms)"');
dbms_output.put_line('    },');
dbms_output.put_line('    tooltips: {');
dbms_output.put_line('        mode: "index",');
dbms_output.put_line('        intersect: false,');
dbms_output.put_line('    },');
dbms_output.put_line('    hover: {');
dbms_output.put_line('        mode: "nearest",');
dbms_output.put_line('        intersect: true');
dbms_output.put_line('    },');
dbms_output.put_line('    scales: {');
dbms_output.put_line('        xAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Snap"');
dbms_output.put_line('            }');
dbms_output.put_line('        }],');
dbms_output.put_line('        yAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Value"');
dbms_output.put_line('            } }] } } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------avg io end ----------------------------------------
--------------------io wait times---------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
control ValueList;
dbseq ValueList;
dbsca ValueList;
dbparaell ValueList;
logsync ValueList;
drtpath ValueList;
cpu_cur SYS_REFCURSOR;
v_control varchar2(200);
v_dbseq varchar2(200);     
v_dbsca varchar2(200);
v_dbparaell varchar2(200);
v_logsync varchar2(200);
v_drtpath varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var iotimesdata = {labels: [' );
open cpu_cur for
select    trunc(( greatest(0, a2.controlfilewaits - lag(a2.controlfilewaits, 1, a2.controlfilewaits) over(order by a2.snap_id))))  controlfilewaits,
            trunc(( greatest(0, a2.drtwaits - lag(a2.drtwaits, 1, a2.drtwaits) over(order by a2.snap_id))))  drtwaits,
            trunc(( greatest(0, a2.logwaits - lag(a2.logwaits, 1, a2.logwaits) over(order by a2.snap_id))))  logwaits, 
            trunc(( greatest(0, a2.dbfileseqwaits - lag(a2.dbfileseqwaits, 1, a2.dbfileseqwaits) over(order by a2.snap_id))))  dbfileseqwaits,
            trunc(( greatest(0, a2.dbfilesctwaits - lag(a2.dbfilesctwaits, 1, a2.dbfilesctwaits) over(order by a2.snap_id))))  dbfilesctwaits,
            trunc(( greatest(0, a2.dbparallelwaits - lag(a2.dbparallelwaits, 1, a2.dbparallelwaits) over(order by a2.snap_id))))  dbparallelwaits,
            (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time  
           from (
select a1.snap_id,
       sum(case
             when a1.event_name = 'control file sequential read' then
              a1.total_waits_fg
             else
              0
           end) controlfilewaits,
       sum(case
             when a1.event_name = 'db file sequential read' then
              a1.total_waits_fg
             else
              0
           end) dbfileseqwaits,
       sum(case
             when a1.event_name = 'db file scattered read' then
              a1.total_waits_fg
             else
              0
           end) dbfilesctwaits,
       sum(case
             when a1.event_name = 'direct path read' then
              a1.total_waits_fg
             else
              0
           end) drtwaits,
       sum(case
             when a1.event_name = 'log file sync' then
              a1.total_waits_fg
             else
              0
           end) logwaits,
       sum(case
             when a1.event_name = 'db file parallel read' then
              a1.total_waits_fg
             else
              0
           end) dbparallelwaits
  from (select a.snap_id,
               a.event_name,
               a.total_waits_fg
          from dba_hist_system_event a
         where event_name in ('control file sequential read',
                              'log file sync',
                              'db file sequential read',
                              'db file scattered read',
                              'db file parallel read',
                              'direct path read')
           and A.snap_id >= &bid and a.snap_id <=&eid  
 and a.instance_number = &inid) a1
 group by a1.snap_id
 order by a1.snap_id)a2  order by snap_id;
   FETCH cpu_cur BULK COLLECT INTO  control,drtpath,logsync,dbseq,dbsca,dbparaell,snaptime;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 control.extend;
 control(1):='0';
 dbseq.extend;
 dbseq(1):=0;
 dbsca.extend;
 dbsca(1):=0;
 drtpath.extend;
 drtpath(1):=0;
 logsync.extend;
 logsync(1):=0;
 dbparaell.extend;
 dbparaell(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "db file sequential read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbseq.FIRST .. dbseq.LAST
LOOP
  if(i<dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i)||',');
elsif(i=dbseq.count) then
DBMS_OUTPUT.PUT_LINE (dbseq(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('] }, { label: "Direct path read",' );
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.pink2,' );
DBMS_OUTPUT.PUT_LINE ('data: [' );
-----------------------------------------
FOR i IN drtpath.FIRST .. drtpath.LAST
LOOP
  if(i<drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i)||',');
elsif(i=drtpath.count) then
DBMS_OUTPUT.PUT_LINE (drtpath(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('] }, {');
DBMS_OUTPUT.PUT_LINE ('label: "Log file sync",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN logsync.FIRST .. logsync.LAST
LOOP
  if(i<logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i)||',');
elsif(i=logsync.count) then
DBMS_OUTPUT.PUT_LINE (logsync(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Db file parallel read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.orange2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbparaell.FIRST .. dbparaell.LAST
LOOP
  if(i<dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i)||',');
elsif(i=dbparaell.count) then
DBMS_OUTPUT.PUT_LINE (dbparaell(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "control file sequential read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.purple2,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN control.FIRST .. control.LAST
LOOP
  if(i<control.count) then
DBMS_OUTPUT.PUT_LINE (control(i)||',');
elsif(i=control.count) then
DBMS_OUTPUT.PUT_LINE (control(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}, {');
DBMS_OUTPUT.PUT_LINE ('label: "Db file scatter read",');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN dbsca.FIRST .. dbsca.LAST
LOOP
  if(i<dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i)||',');
elsif(i=dbsca.count) then
DBMS_OUTPUT.PUT_LINE (dbsca(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE (']}]};');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
------------------------io wait times end----------------------------------
-----------------------max commit-----------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  max_com ValueList; ---max commit
  SNAP_ID      ValueList;
  cr_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var maxcommitdata = { type: "line", data: { labels: [');    
  OPEN CR_CUR FOR 
select sum(a1.maxcom),
       a1.snap_id,
      (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
             from dba_hist_snapshot f
            where f.snap_id = a1.snap_id
              and f.instance_number = &inid) snap_time
  from (select a.snap_id,
               case
                 when metric_name = 'User Commits Per Sec' then
                   trunc(a.maxval) 
                 else
                  0
               end maxcom
          from dba_hist_sysmetric_summary a
         where A.snap_id >= &bid
           and a.snap_id <= &eid
           and a.instance_number = &inid
         and a.metric_name in
               ('User Commits Per Sec'
                )) a1
 group by a1.snap_id order by a1.snap_id;
    FETCH CR_CUR     BULK COLLECT    INTO max_com,SNAP_ID,SNAPTIME;
    close CR_CUR;
  ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 max_com.extend;
 max_com(1):='0';
 end if;
-----------------------------------------     
    FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');  
dbms_output.put_line('label: "User Commits (MAX)",');  
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');  
dbms_output.put_line('borderColor: window.awrColors.blue2,');  
dbms_output.put_line('data: [');  
------------------------------
 FOR i IN max_com.FIRST .. max_com.LAST
LOOP
  if(i<max_com.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (max_com(i)||',');
end if;
elsif(i=max_com.count) then
DBMS_OUTPUT.PUT_LINE (max_com(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] }, ');
dbms_output.put_line('options: { ');
dbms_output.put_line('responsive: true, ');
dbms_output.put_line('title:{ ');
dbms_output.put_line('display:true, ');
dbms_output.put_line('text:"MAX User Commits per Second" ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Value"  ');
dbms_output.put_line('}  }] }  } };         ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-------------------------max commit end----------------------
---------------------------block change---------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
bchange ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var bchangedata = { type: "line", data: { labels: [');
open my_cur for
select 
  trunc(bc/&_iv) ,snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.bc - lag(a2.bc, 1, a2.bc) over(order by a2.snap_id)) bc,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
a1.value  bc  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'db block changes' ) 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO bchange,snaptime;
 close my_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 bchange.extend;
 bchange(1):='0';
 end if;
-----------------------------------------  

  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line(' ], datasets: [{');  
dbms_output.put_line('label: "Block changes ",');  
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.orange1,');  
dbms_output.put_line('borderColor: window.awrColors.black1,');  
dbms_output.put_line('data: [');  
------------------------------
 FOR i IN bchange.FIRST .. bchange.LAST
LOOP
  if(i<bchange.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (bchange(i)||',');
end if;
elsif(i=bchange.count) then
DBMS_OUTPUT.PUT_LINE (bchange(i));
end if;
END LOOP;
dbms_output.put_line('        ], fill: true, } ] },');
dbms_output.put_line('options: {');
dbms_output.put_line('    responsive: true,');
dbms_output.put_line('    title:{');
dbms_output.put_line('        display:true,');
dbms_output.put_line('        text:"Block Changes per Second"');
dbms_output.put_line('    },');
dbms_output.put_line('    tooltips: {');
dbms_output.put_line('        mode: "index",');
dbms_output.put_line('        intersect: false,');
dbms_output.put_line('    },');
dbms_output.put_line('    hover: {');
dbms_output.put_line('        mode: "nearest",');
dbms_output.put_line('        intersect: true');
dbms_output.put_line('    },');
dbms_output.put_line('    scales: {');
dbms_output.put_line('        xAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Snap"');
dbms_output.put_line('            }');
dbms_output.put_line('        }],');
dbms_output.put_line('        yAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Value"');
dbms_output.put_line('            }  }] }  } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------block changes end----------------------
----------------------------tbs usage-----------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
tbssize ValueList;
maxsize ValueList;
usedsize ValueList;
dbcpu ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var tbsusagedata = { type: "line", data: { labels: [' );
open my_cur for
select 
  snap_time, tbssize,maxsize,usedsize
 from (
select  a1.snap_id,
tbssize,maxsize,usedsize,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = a1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select snap_id,
       trunc(sum(tablespace_size)*(select value from v$parameter where name='db_block_size')/1024/1024/1024,2) tbssize,
       trunc(sum(tablespace_maxsize)*(select value from v$parameter where name='db_block_size')/1024/1024/1024,2) maxsize,
       trunc(sum(tablespace_usedsize)*(select value from v$parameter where name='db_block_size')/1024/1024/1024,2) usedsize
  from DBA_HIST_TBSPC_SPACE_USAGE
 where  snap_id >= &bid and  snap_id <= &eid  
 group by snap_id
 ) a1 ) a2 ;
  FETCH my_cur BULK COLLECT INTO snaptime,tbssize,maxsize,usedsize;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 tbssize.extend;
 tbssize(1):='0';
 maxsize.extend;
 maxsize(1):=0;
 usedsize.extend;
 usedsize(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "Used Size",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN usedsize.FIRST .. usedsize.LAST
LOOP
  if(i<usedsize.count) then
DBMS_OUTPUT.PUT_LINE (usedsize(i)||',');
elsif(i=usedsize.count) then
DBMS_OUTPUT.PUT_LINE (usedsize(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Tablespace Size",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(204, 102, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 128, 0, 0.3)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
FOR i IN tbssize.FIRST .. tbssize.LAST
LOOP
  if(i<tbssize.count) then
DBMS_OUTPUT.PUT_LINE (tbssize(i)||',');
elsif(i=tbssize.count) then
DBMS_OUTPUT.PUT_LINE (tbssize(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Max Size",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(255, 0, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 128, 255, 0)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN maxsize.FIRST .. maxsize.LAST
LOOP
  if(i<maxsize.count) then
DBMS_OUTPUT.PUT_LINE (maxsize(i)||',');
elsif(i=maxsize.count) then
DBMS_OUTPUT.PUT_LINE (maxsize(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('      options: {');
DBMS_OUTPUT.PUT_LINE ('        responsive: true,');
DBMS_OUTPUT.PUT_LINE ('        title:{');
DBMS_OUTPUT.PUT_LINE ('          display:true,');
DBMS_OUTPUT.PUT_LINE ('          text:"Tablespace Usage(MB)"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        tooltips: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index",');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        hover: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        scales: {');
DBMS_OUTPUT.PUT_LINE ('          xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('            }');
DBMS_OUTPUT.PUT_LINE ('          }],');
DBMS_OUTPUT.PUT_LINE ('          yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            stacked: false,');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('            }}]}}};  ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------tbs usage end--------------------------
--------------------conn-----------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  snap_id  ValueList;
  PROC     ValueList; ---Process
  SE       ValueList; ---Session  
  SNAPTIME ValueList;
  se_cur   sys_refcursor;
begin
  DBMS_OUTPUT.PUT_LINE('var conndata = { type: "line", data: { labels: [');
  OPEN SE_CUR FOR
    select pr,
           se,
          (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a1.snap_id
                  and f.instance_number = &inid) snap_time,
           snap_id
      from (select snap_id,
                   sum(case
                         when a.resource_name = 'processes' then
                          a.current_utilization
                         else
                          0
                       end) pr,
                   sum(case
                         when a.resource_name = 'sessions' then
                          a.current_utilization
                         else
                          0
                       end) se
              from dba_hist_resource_limit a
             where a.snap_id >= &bid
               and a.snap_id <= &eid
               and a.instance_number = &inid
               and (a.resource_name = 'sessions' or
                   a.resource_name = 'processes')
             group by snap_id
             order by snap_id) a1;

  Fetch se_cur bulk collect
    into PROC, SE, SNAPTIME, SNAP_ID;
close se_cur;
  ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 proc.extend;
 proc(1):='0';
 SE.extend;
 SE(1):='0';
end if;
-----------------------------------------  
  FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('  ], datasets: [{');
  DBMS_OUTPUT.PUT_LINE('label: "Processes",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
  DBMS_OUTPUT.PUT_LINE('data: [ ');
  FOR i IN proc.FIRST .. proc.LAST LOOP
    if (i < proc.count) then
      DBMS_OUTPUT.PUT_LINE(proc(i) || ',');
    elsif (i = proc.count) then
      DBMS_OUTPUT.PUT_LINE(proc(i));
    end if;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
  DBMS_OUTPUT.PUT_LINE('label: "Sessions",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('fill: false,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green1,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN SE.FIRST .. SE.LAST LOOP
    if (i < SE.count) then
      DBMS_OUTPUT.PUT_LINE(SE(i) || ',');
    elsif (i = SE.count) then
      DBMS_OUTPUT.PUT_LINE(SE(i));
    end if;
  END LOOP;
dbms_output.put_line(' ], }] },             ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"Connections"    ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------conn end-----------------------------------
----waittime------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
concu ValueList;
clust ValueList;
appw ValueList;
userio ValueList;
cpu_cur SYS_REFCURSOR;
v_concu varchar2(200);
v_clust varchar2(200);     
v_appw varchar2(200);
v_userio varchar2(200);
v_snap_time varchar2(200);
begin
dbms_output.put_line('var waittimedata = {type: "line", data: { labels: [' );
open cpu_cur for
select    trunc(( greatest(0, a2.concu - lag(a2.concu, 1, a2.concu) over(order by a2.snap_id))))  concu,
            trunc(( greatest(0, a2.clust - lag(a2.clust, 1, a2.clust) over(order by a2.snap_id))))  clust,
            trunc(( greatest(0, a2.appw - lag(a2.appw, 1, a2.appw) over(order by a2.snap_id))))  appw, 
            trunc(( greatest(0, a2.userio - lag(a2.userio, 1, a2.userio) over(order by a2.snap_id))))  userio,
            (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time  
           from (
select a1.snap_id,
       sum(case
             when a1.stat_name = 'concurrency wait time' then
              a1.value
             else
              0
           end) concu,
       sum(case
             when a1.stat_name = 'cluster wait time' then
              a1.value
             else
              0
           end) clust,
       sum(case
             when a1.stat_name = 'application wait time' then
              a1.value
             else
              0
           end) appw,
       sum(case
             when a1.stat_name = 'user I/O wait time' then
              a1.value
             else
              0
           end) userio
  from (select a.snap_id,stat_name, a.value
  from dba_hist_sysstat a
 where a.stat_name in ('concurrency wait time',
                       'cluster wait time',
                       'application wait time','user I/O wait time')
           and A.snap_id >= &bid and a.snap_id <=&eid  
 and a.instance_number = &inid) a1
 group by a1.snap_id
 order by a1.snap_id)a2  order by snap_id;
  FETCH cpu_cur BULK COLLECT INTO  concu,clust,appw,userio,snaptime;
 close cpu_cur;
 ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 concu.extend;
 concu(1):='0';
 clust.extend;
 clust(1):=0;
 appw.extend;
 appw(1):=0;
 userio.extend;
 userio(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], datasets: [{');
DBMS_OUTPUT.PUT_LINE ('label: "concurrency wait time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN concu.FIRST .. concu.LAST
LOOP
  if(i<concu.count) then
DBMS_OUTPUT.PUT_LINE (concu(i)||',');
elsif(i=concu.count) then
DBMS_OUTPUT.PUT_LINE (concu(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
DBMS_OUTPUT.PUT_LINE('label: "cluster wait time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.pink1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.pink2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN clust.FIRST .. clust.LAST
LOOP
  if(i<clust.count) then
DBMS_OUTPUT.PUT_LINE (clust(i)||',');
elsif(i=clust.count) then
DBMS_OUTPUT.PUT_LINE (clust(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "application wait time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN appw.FIRST .. appw.LAST
LOOP
  if(i<appw.count) then
DBMS_OUTPUT.PUT_LINE (appw(i)||',');
elsif(i=appw.count) then
DBMS_OUTPUT.PUT_LINE (appw(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE('], }, {');
DBMS_OUTPUT.PUT_LINE('label: "user I/O wait time",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE('fill: false,');
DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
DBMS_OUTPUT.PUT_LINE('data: [');
-----------------------------------------
FOR i IN userio.FIRST .. userio.LAST
LOOP
  if(i<userio.count) then
DBMS_OUTPUT.PUT_LINE (userio(i)||',');
elsif(i=userio.count) then
DBMS_OUTPUT.PUT_LINE (userio(i));
end if;
END LOOP;
-----------------------------------------
dbms_output.put_line('        ], }]  },');
dbms_output.put_line('options: {');
dbms_output.put_line('    responsive: true,');
dbms_output.put_line('    title:{');
dbms_output.put_line('        display:true,');
dbms_output.put_line('        text:"Miscellaneous Wait Time (ms)"');
dbms_output.put_line('    },');
dbms_output.put_line('    tooltips: {');
dbms_output.put_line('        mode: "index",');
dbms_output.put_line('        intersect: false,');
dbms_output.put_line('    },');
dbms_output.put_line('    hover: {');
dbms_output.put_line('        mode: "nearest",');
dbms_output.put_line('        intersect: true');
dbms_output.put_line('    },');
dbms_output.put_line('    scales: {');
dbms_output.put_line('        xAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Snap"');
dbms_output.put_line('            }');
dbms_output.put_line('        }],');
dbms_output.put_line('        yAxes: [{');
dbms_output.put_line('            display: true,');
dbms_output.put_line('            scaleLabel: {');
dbms_output.put_line('                display: true,');
dbms_output.put_line('                labelString: "Value"');
dbms_output.put_line('            } }] } } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-------------------------waittime end-------------------
----------------------------logon-----------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  max_logon ValueList; ---max logon
  avg_logon ValueList;
  cr_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var logondata = { type: "line", data: { labels: [');     
  OPEN CR_CUR FOR 
select sum(a1.maxlogon),sum(a1.avglogon),
        (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
             from dba_hist_snapshot f
            where f.snap_id = a1.snap_id
              and f.instance_number = &inid) snap_time
  from (select a.snap_id,
               case
                 when metric_name = 'Logons Per Sec' then
                   trunc(a.maxval) 
                 else
                  0
               end maxlogon,
               case
                 when metric_name = 'Logons Per Sec' then
                   trunc(a.average) 
                 else
                  0
               end avglogon
          from dba_hist_sysmetric_summary a
         where A.snap_id >= &bid
           and a.snap_id <= &eid
           and a.instance_number = &inid
         and a.metric_name in
               ('Logons Per Sec'
                )) a1
 group by a1.snap_id order by a1.snap_id;
    FETCH CR_CUR     BULK COLLECT    INTO max_logon,avg_logon,SNAPTIME;
    close CR_CUR;
  ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 max_logon.extend;
 max_logon(1):='0';
 avg_logon.extend;
 avg_logon(1):='0';
end if;
-----------------------------------------  
    FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{'); 
dbms_output.put_line('label: "Max Logon",'); 
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,'); 
dbms_output.put_line('borderColor: window.awrColors.red2,'); 
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN max_logon.FIRST .. max_logon.LAST
LOOP
  if(i<max_logon.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (max_logon(i)||',');
end if;
elsif(i=max_logon.count) then
DBMS_OUTPUT.PUT_LINE (max_logon(i));
end if;
END LOOP;
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "Average logon",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('borderDash: [5, 5],');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
dbms_output.put_line('data: [');
 FOR i IN avg_logon.FIRST .. avg_logon.LAST
LOOP
  if(i<avg_logon.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (avg_logon(i)||',');
end if;
elsif(i=avg_logon.count) then
DBMS_OUTPUT.PUT_LINE (avg_logon(i));
end if;
END LOOP;
dbms_output.put_line('], }] },                    ');
dbms_output.put_line('options: {                  ');
dbms_output.put_line('responsive: true,           ');
dbms_output.put_line('title:{                     ');
dbms_output.put_line('display:true,               ');
dbms_output.put_line('text:"User logon per Second"');
dbms_output.put_line('},                          ');
dbms_output.put_line('tooltips: {                 ');
dbms_output.put_line('mode: "index",              ');
dbms_output.put_line('intersect: false,           ');
dbms_output.put_line('},                          ');
dbms_output.put_line('hover: {                    ');
dbms_output.put_line('mode: "nearest",            ');
dbms_output.put_line('intersect: true             ');
dbms_output.put_line('},                          ');
dbms_output.put_line('scales: {                   ');
dbms_output.put_line('xAxes: [{                   ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('scaleLabel: {               ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('labelString: "Snap"         ');
dbms_output.put_line('}                           ');
dbms_output.put_line('}],                         ');
dbms_output.put_line('yAxes: [{                   ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('scaleLabel: {               ');
dbms_output.put_line('display: true,              ');
dbms_output.put_line('labelString:  "Value"       ');
dbms_output.put_line('} }] } } };                 ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------logon end-----------------------------
--------------------------gckb------------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  CR       ValueList; ---archive log size
  CR_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var gckbdata = { type: "line", data: { labels: [');
  OPEN CR_CUR FOR
      select
           trunc((greatest(0, a2.cr - lag(a2.cr, 1, a2.cr) over(order by a2.snap_id))) / &_iv) cr,
           (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid) snap_time
      from (select a1.snap_id,
                   sum(case
                         when a1.stat_name = 'gc cr blocks received' or
                              a1.stat_name = 'gc current blocks received' or
                              a1.stat_name = 'gc cr blocks served' or
                              a1.stat_name = 'gc current blocks served' then
                          a1.value
                         else
                          0
                       end) * (select value / 1024
                                 from v$parameter
                                where name = 'db_block_size') cr
              from (select a.snap_id, a.stat_name, a.value
                      from dba_hist_sysstat a
                     where (a.stat_name = 'gc cr blocks received' or
                           a.stat_name = 'gc current blocks received' or
                           a.stat_name = 'gc cr blocks served' or
                           a.stat_name = 'gc current blocks served')
                       and snap_id >= &bid
                       and snap_id <= &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name) a1
             group by a1.snap_id
             order by a1.snap_id) a2;

   FETCH CR_CUR BULK COLLECT INTO CR,SNAPTIME;
   CLOSE CR_CUR;
   ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 CR.extend;
 CR(1):='0';
end if;
/*+copyright wangwenjie , do not copy this code to other business software*/
   FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
   END LOOP;                               
  DBMS_OUTPUT.PUT_LINE('  ], datasets: [{');
  DBMS_OUTPUT.PUT_LINE('label: "Global Cache Transfer (KB)",');
  DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
  DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');
  DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');
  DBMS_OUTPUT.PUT_LINE('data: [');
  FOR i IN CR.FIRST .. CR.LAST LOOP
    if (i < CR.count) then
      DBMS_OUTPUT.PUT_LINE(CR(i) || ',');
    elsif (i = CR.count) then
      DBMS_OUTPUT.PUT_LINE(CR(i));
    end if;
   END LOOP;
dbms_output.put_line('], fill: true, } ] },                   ');
dbms_output.put_line('options: {                              ');
dbms_output.put_line('responsive: true,                       ');
dbms_output.put_line('title:{                                 ');
dbms_output.put_line('display:true,                           ');
dbms_output.put_line('text:"Global Cache Transfer per Second" ');
dbms_output.put_line('},                                      ');
dbms_output.put_line('tooltips: {                             ');
dbms_output.put_line('mode: "index",                          ');
dbms_output.put_line('intersect: false,                       ');
dbms_output.put_line('},                                      ');
dbms_output.put_line('hover: {                                ');
dbms_output.put_line('mode: "nearest",                        ');
dbms_output.put_line('intersect: true                         ');
dbms_output.put_line('},                                      ');
dbms_output.put_line('scales: {                               ');
dbms_output.put_line('xAxes: [{                               ');
dbms_output.put_line('display: true,                          ');
dbms_output.put_line('scaleLabel: {                           ');
dbms_output.put_line('display: true,                          ');
dbms_output.put_line('labelString: "Snap"                     ');
dbms_output.put_line('}                                       ');
dbms_output.put_line('}],                                     ');
dbms_output.put_line('yAxes: [{                               ');
dbms_output.put_line('display: true,                          ');
dbms_output.put_line('scaleLabel: {                           ');
dbms_output.put_line('display: true,                          ');
dbms_output.put_line('labelString: "Value"                    ');
dbms_output.put_line('}  }] }  } };                           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------gckb end-----------------------------------
----------------------------gclost-----------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
gclostdata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var gclostdata = { type: "line", data: { labels: [');
open my_cur for
select 
  trunc(gclost  ) ,snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.gclost - lag(a2.gclost, 1, a2.gclost) over(order by a2.snap_id)) gclost,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='gc blocks lost' then  a1.value else 0 end  )  gclost  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'gc blocks lost' ) 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO gclostdata,snaptime;
 close my_cur;
   ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 gclostdata.extend;
 gclostdata(1):='0';
end if;
-----------------------------------------   
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Global Cache Lost",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.black1,');
dbms_output.put_line('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
 FOR i IN gclostdata.FIRST .. gclostdata.LAST
LOOP
  if(i<gclostdata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (gclostdata(i)||',');
end if;
elsif(i=gclostdata.count) then
DBMS_OUTPUT.PUT_LINE (gclostdata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:"Global Cache Lost"');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------gclost end----------------------------
----------------------------gcms--------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  GCMessage       ValueList; ---archive log size
  GCMessage_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var gcmsdata = { type: "line", data: { labels: [');
  OPEN   GCMessage_cur FOR 
    select  
           trunc((greatest(0, a2.gm - lag(a2.gm, 1, a2.gm) over(order by a2.snap_id))) / &_iv) gm,
           (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid)  snap_time
      from (select a1.snap_id,
                   sum(case
                         when a1.stat_name = 'ges messages sent' or
                              a1.stat_name = 'gcs messages sent' then
                          a1.value
                         else
                          0
                       end) gm
              from (select a.snap_id, a.stat_name, a.value
                      from dba_hist_sysstat a
                     where (a.stat_name = 'ges messages sent' or
                           a.stat_name = 'gcs messages sent')
                       and snap_id >= &bid
                       and snap_id <= &eid
                       and a.instance_number = &inid
                     order by a.snap_id, a.stat_name) a1
             group by a1.snap_id
             order by a1.snap_id) a2;     
    FETCH  GCMessage_cur BULK COLLECT INTO GCMessage,SNAPTIME;
    CLOSE  GCMessage_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 GCMessage.extend;
 GCMessage(1):='0';
end if;
-----------------------------------------      
/*+copyright wangwenjie , do not copy this code to other business software*/
    FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
    if (i < snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
    elsif (i = snaptime.count) then
      DBMS_OUTPUT.PUT_LINE(snaptime(i));
    end if;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('], datasets: [{');
    DBMS_OUTPUT.PUT_LINE('label: "GCS/GES Messages ",');
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
    DBMS_OUTPUT.PUT_LINE('data: [');
    FOR i IN GCMessage.FIRST .. GCMessage.LAST LOOP
    if (i < GCMessage.count) then
      DBMS_OUTPUT.PUT_LINE(GCMessage(i) || ',');
    elsif (i = GCMessage.count) then
      DBMS_OUTPUT.PUT_LINE(GCMessage(i));
    end if;
    END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:"GCS/GES Messages  per Second"');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------------------gcmsend--------------------------------
--------------------------gcblocktime------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME ValueList;
  avg_cr       ValueList; ---avg Global Cache Average CR Get Time 
  max_cr       ValueList; ---max Global Cache Average CR Get Time
  avg_current  ValueList; ---avg Global Cache Average Current Get Time
  max_current  ValueList; ---max Global Cache Average Current Get Time
  cr_cur sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var gcbdata = { type: "line", data: { labels: [');    
  OPEN CR_CUR FOR 
          select   sum(maxval_cr) maxval_cr,sum(average_cr) average_cr,sum(maxval_cu) maxval_cu,sum(average_cu) average_cu,
          '"'||to_char(a2.begin_time,'mm-dd hh24:mi')||'"' begin_time
            from (select metric_name,  a.begin_time
                ,case when metric_name='Global Cache Average CR Get Time' then
                  sum(maxval) else
                  0 end maxval_cr
                   ,case when metric_name='Global Cache Average CR Get Time' then
                  sum(average) else
                  0 end average_cr
                   ,case when metric_name='Global Cache Average Current Get Time' then
                  sum(maxval) else
                  0 end maxval_cu
                   ,case when metric_name='Global Cache Average Current Get Time' then
                  sum(average) else
                  0 end average_cu
                from dba_hist_sysmetric_summary a
               where (a.metric_name like '%Global Cache Average CR Get Time%' or metric_name like '%Global Cache Average Current Get Time%')
                 and a.instance_number = &inid
                 and a.snap_id >= &bid
                 and a.snap_id <= &eid group by a.snap_id, a.metric_name,a.begin_time
               order by a.snap_id) a2  group by a2.begin_time order by a2.begin_time;
    FETCH CR_CUR     BULK COLLECT    INTO MAX_CR,AVG_CR,max_current,avg_current,SNAPTIME;
    close CR_CUR;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 AVG_CR.extend;
 AVG_CR(1):='0';
  MAX_CR.extend;
 MAX_CR(1):='0';
  avg_current.extend;
 avg_current(1):='0';
  max_current.extend;
 max_current(1):='0';
end if;
-----------------------------------------      
     FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
        if (i < snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
        elsif (i = snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i));
        end if;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('],  datasets: [{');
    DBMS_OUTPUT.PUT_LINE('label: "Global Cache Average CR Time",');
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('fill: false,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.pink1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.pink2,');
    DBMS_OUTPUT.PUT_LINE('data: [');
         FOR i IN avg_cr.FIRST .. avg_cr.LAST LOOP
        if (i < avg_cr.count) then
          DBMS_OUTPUT.PUT_LINE(avg_cr(i) || ',');
        elsif (i = avg_cr.count) then
          DBMS_OUTPUT.PUT_LINE(avg_cr(i));
        end if;
        END LOOP; 
    DBMS_OUTPUT.PUT_LINE('], }, {');  
    DBMS_OUTPUT.PUT_LINE('label: "Global Cache MAX CR Time",');  
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('fill: false,');  
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.red1,');  
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.red2,');  
    DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],');  
    DBMS_OUTPUT.PUT_LINE('data: [');  
     FOR i IN max_cr.FIRST .. max_cr.LAST LOOP
        if (i < max_cr.count) then
          DBMS_OUTPUT.PUT_LINE(max_cr(i) || ',');
        elsif (i = max_cr.count) then
          DBMS_OUTPUT.PUT_LINE(max_cr(i));
        end if;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('], },{'); 
    DBMS_OUTPUT.PUT_LINE('label: "Global Cache Average Current Get Time",'); 
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,'); 
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,'); 
    DBMS_OUTPUT.PUT_LINE('data: ['); 
 FOR i IN max_current.FIRST .. max_current.LAST LOOP
        if (i < max_current.count) then
          DBMS_OUTPUT.PUT_LINE(max_current(i) || ',');
        elsif (i = max_current.count) then
          DBMS_OUTPUT.PUT_LINE(max_current(i));
        end if;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('],  fill: false,}, {'); 
    DBMS_OUTPUT.PUT_LINE('label: "Global Cache MAX Current Get Time",'); 
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('fill: false,'); 
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,'); 
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,'); 
    DBMS_OUTPUT.PUT_LINE('borderDash: [5, 5],'); 
    DBMS_OUTPUT.PUT_LINE('data: ['); 
    FOR i IN avg_current.FIRST .. avg_current.LAST LOOP
        if (i < avg_current.count) then
          DBMS_OUTPUT.PUT_LINE(avg_current(i) || ',');
        elsif (i = avg_current.count) then
          DBMS_OUTPUT.PUT_LINE(avg_current(i));
        end if;
        END LOOP;
DBMS_OUTPUT.PUT_LINE('], }]},');
DBMS_OUTPUT.PUT_LINE('options: {');
DBMS_OUTPUT.PUT_LINE('responsive: true,');
DBMS_OUTPUT.PUT_LINE('title:{');
DBMS_OUTPUT.PUT_LINE('display:true,');
DBMS_OUTPUT.PUT_LINE('text:"GC CR/CURRENT BLOCK TIME"');
DBMS_OUTPUT.PUT_LINE('},');
DBMS_OUTPUT.PUT_LINE('tooltips: {');
DBMS_OUTPUT.PUT_LINE('mode: "index",');
DBMS_OUTPUT.PUT_LINE('intersect: false,');
DBMS_OUTPUT.PUT_LINE('},');
DBMS_OUTPUT.PUT_LINE('hover: {');
DBMS_OUTPUT.PUT_LINE('mode: "nearest",');
DBMS_OUTPUT.PUT_LINE('intersect: true');
DBMS_OUTPUT.PUT_LINE('},');
DBMS_OUTPUT.PUT_LINE('scales: {');
DBMS_OUTPUT.PUT_LINE('xAxes: [{');
DBMS_OUTPUT.PUT_LINE('display: true,');
DBMS_OUTPUT.PUT_LINE('scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('display: true,');
DBMS_OUTPUT.PUT_LINE('labelString: "Snap"');
DBMS_OUTPUT.PUT_LINE('}');
DBMS_OUTPUT.PUT_LINE('}],');
DBMS_OUTPUT.PUT_LINE('yAxes: [{');
DBMS_OUTPUT.PUT_LINE('display: true,');
DBMS_OUTPUT.PUT_LINE('scaleLabel: {');
DBMS_OUTPUT.PUT_LINE('display: true,');
DBMS_OUTPUT.PUT_LINE('labelString: "Value"');
DBMS_OUTPUT.PUT_LINE('} }] } } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----auther wangwenjie-----gcblocktime end--------------------
-----------------------------hit pga buffer----------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME         ValueList;
  Buffer_hit       ValueList; --- buffer hit %
  pga_hit          ValueList;
  BH_CUR           sys_refcursor;
  
BEGIN
  DBMS_OUTPUT.PUT_LINE('var bfpgadata = { type: "line", data: { labels: [');
  OPEN BH_CUR FOR   
   select
(select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = b1.snap_id
                  and f.instance_number = &inid)  snap_time,
   sum(case when hittype='pga' then hit else 0 end) pg ,sum(case when hittype='bf' then hit else 0 end) bf from (  
 select 'pga' hittype, (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a.snap_id
                  and f.instance_number = &inid) snap_time,
           snap_id,
           value hit
      from dba_hist_pgastat a
     where name = 'cache hit percentage'
       and a.instance_number = &inid
       and a.snap_id >= &bid
       and a.snap_id <= &eid
 union all
     select 'bf' hittype, (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid)  snap_time,
           a2.snap_id,
           trunc(a2.ph / a2.p * 100, 2) hit
      from (SELECT snap_id,
                   greatest(0, a1.ph - lag(a1.ph, 1, a1.ph) over(order by a1.snap_id)) ph,
                   greatest(0, a1.p - lag(a1.p, 1, a1.p) over(order by a1.snap_id)) p
              from (select snap_id, sum(pinhits) PH, sum(pins) P
                      from DBA_HIST_LIBRARYCACHE
                     WHERE SNAP_ID >= &bid
                       AND SNAP_ID <= &eid
                       and instance_number = &inid
                     group by snap_id
                     ORDER BY SNAP_ID) a1) a2
     where p > 0) b1 group by snap_id order by b1.snap_id;
               
    FETCH BH_CUR BULK COLLECT INTO SNAPTIME,pga_hit,Buffer_hit;
    CLOSE BH_CUR;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 Buffer_hit.extend;
 Buffer_hit(1):='0';
  pga_hit.extend;
 pga_hit(1):='0';
end if;
-----------------------------------------      
    FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
        if (i < snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
        elsif (i = snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i));
        end if;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(' ], datasets: [{'); 
    DBMS_OUTPUT.PUT_LINE('label: "Buffer Cache %",'); 
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue2,'); 
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,'); 
    DBMS_OUTPUT.PUT_LINE('data: [   '); 
     FOR i IN Buffer_hit.FIRST .. Buffer_hit.LAST LOOP
        if (i < Buffer_hit.count) then
          DBMS_OUTPUT.PUT_LINE(Buffer_hit(i) || ',');
        elsif (i = Buffer_hit.count) then
          DBMS_OUTPUT.PUT_LINE(Buffer_hit(i));
        end if;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('], fill: false, }, {');
    DBMS_OUTPUT.PUT_LINE('label: "PGA %",');
    DBMS_OUTPUT.PUT_LINE('fill: false,');
    DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green1,');
    DBMS_OUTPUT.PUT_LINE('data: [');
     FOR i IN pga_hit.FIRST .. pga_hit.LAST LOOP
        if (i < pga_hit.count) then
          DBMS_OUTPUT.PUT_LINE(pga_hit(i) || ',');
        elsif (i = pga_hit.count) then
          DBMS_OUTPUT.PUT_LINE(pga_hit(i));
        end if;
    END LOOP;
dbms_output.put_line('], }] },                ');     
dbms_output.put_line('options: {              ');
dbms_output.put_line('responsive: true,       ');
dbms_output.put_line('title:{                 ');
dbms_output.put_line('display:true,           ');
dbms_output.put_line('text:"Memory hit point" ');
dbms_output.put_line('},                      ');
dbms_output.put_line('tooltips: {             ');
dbms_output.put_line('mode: "index",          ');
dbms_output.put_line('intersect: false,       ');
dbms_output.put_line('},                      ');
dbms_output.put_line('hover: {                ');
dbms_output.put_line('mode: "nearest",        ');
dbms_output.put_line('intersect: true         ');
dbms_output.put_line('},                      ');
dbms_output.put_line('scales: {               ');
dbms_output.put_line('xAxes: [{               ');
dbms_output.put_line('display: true,          ');
dbms_output.put_line('scaleLabel: {           ');
dbms_output.put_line('display: true,          ');
dbms_output.put_line('labelString: "Snap"     ');
dbms_output.put_line('}                       ');
dbms_output.put_line('}],                     ');
dbms_output.put_line('yAxes: [{               ');
dbms_output.put_line('display: true,          ');
dbms_output.put_line('scaleLabel: {           ');
dbms_output.put_line('display: true,          ');
dbms_output.put_line('labelString:  "Value"   ');
dbms_output.put_line('} }] } } };             ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------hit pga buffer end-------------------------
--------------------mem stats---------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
sga ValueList;
hostm ValueList;
pga ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var memdata = { type: "line", data: { labels: [' );
open my_cur for
select 
  snap_time, pga,sga,hostm
 from (
select  b1.snap_id,
pga,sga,hostm,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = b1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.instance_number, pga, sga, hostm
  from (  
        select snap_id,
                instance_number,
                trunc(sum(dba_hist_sgastat.BYTES) / 1024 / 1024) sga
          from dba_hist_sgastat
         group by snap_id, instance_number) a1,
       (select snap_id,
               instance_number,
               trunc(sum(dba_hist_pgastat.VALUE) / 1024 / 1024) pga
          from dba_hist_pgastat  where name='total PGA allocated'
         group by snap_id, instance_number) a2,
       (select snap_id, instance_number, trunc(value / 1024 / 1024) hostm
          from dba_hist_osstat
         where stat_name = 'PHYSICAL_MEMORY_BYTES') a3
 where a1.snap_id = a2.snap_id
   and a1.snap_id = a3.snap_id(+)
   and a1.instance_number = a2.instance_number
   and a1.instance_number = a3.instance_number(+)
   and a1.snap_id >= &bid and a1.snap_id <= &eid   and a1.instance_number=&inid
 ) b1 ) b2 order by 1;
  FETCH my_cur BULK COLLECT INTO snaptime,pga,sga,hostm;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 pga.extend;
 pga(1):='0';
 sga.extend;
 sga(1):=0;
 hostm.extend;
 hostm(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "total PGA allocated",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 255, 0, 0)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN pga.FIRST .. pga.LAST
LOOP
  if(i<pga.count) then
DBMS_OUTPUT.PUT_LINE (pga(i)||',');
elsif(i=pga.count) then
DBMS_OUTPUT.PUT_LINE (pga(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "SGA (sum all values of sgastats)",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 128, 0, 0)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
FOR i IN sga.FIRST .. sga.LAST
LOOP
  if(i<sga.count) then
DBMS_OUTPUT.PUT_LINE (sga(i)||',');
elsif(i=sga.count) then
DBMS_OUTPUT.PUT_LINE (sga(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Host Memory",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(255, 0, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 128, 255, 0)" ,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN hostm.FIRST .. hostm.LAST
LOOP
  if(i<hostm.count) then
DBMS_OUTPUT.PUT_LINE (hostm(i)||',');
elsif(i=hostm.count) then
DBMS_OUTPUT.PUT_LINE (hostm(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('      options: {');
DBMS_OUTPUT.PUT_LINE ('        responsive: true,');
DBMS_OUTPUT.PUT_LINE ('        title:{');
DBMS_OUTPUT.PUT_LINE ('          display:true,');
DBMS_OUTPUT.PUT_LINE ('          text:"Memory Stats (MB)"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        tooltips: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index",');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        hover: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        scales: {');
DBMS_OUTPUT.PUT_LINE ('          xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('            }');
DBMS_OUTPUT.PUT_LINE ('          }],');
DBMS_OUTPUT.PUT_LINE ('          yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            stacked: false,');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('            }}]}}};  ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
------------------------------------mem stats end------------------------------------
-------------------------------shared pool start-----------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
freeml ValueList;
gesl ValueList;
gcsl ValueList;
restml ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var sharedpooldata = { type: "line", data: { labels: [');
open my_cur for
select 
freem,ges,gcs,restm,
 ( select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
           from (
select b.snap_id,
       trunc(sum(case when b.NAME='free memory' then b.BYTES else 0 end)/1024/1024) freem,
       trunc(sum(case when b.NAME like 'ges%' then b.BYTES  else 0 end)/1024/1024) ges,
       trunc(sum(case when b.NAME like 'gcs%' then b.BYTES  else 0 end)/1024/1024)  gcs,
        trunc(sum(case when (b.NAME<>'free memory'  and b.NAME not like 'ges%'  and b.NAME not like 'gcs%')
        then b.BYTES  else 0 end)/1024/1024)  restm
  FROM dba_hist_sgastat b 
where  (b.POOL='shared pool' )and b.instance_number=&inid
and b.snap_id>=&bid and b.snap_id<=&eid group by b.snap_id
order by b.snap_id
)a2;
 FETCH my_cur BULK COLLECT INTO freeml,gesl,gcsl,restml,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 freeml.extend;
 freeml(1):='0';
 gesl.extend;
 gesl(1):='0';
  gcsl.extend;
 gcsl(1):='0';
  restml.extend;
 freeml(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Free memory MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('backgroundColor: window.awrColors.orange2,');
dbms_output.put_line('borderColor: window.awrColors.orange1,');
dbms_output.put_line('data: [ ');
------------------------------
 FOR i IN freeml.FIRST .. freeml.LAST
LOOP
  if(i<freeml.count) then
DBMS_OUTPUT.PUT_LINE (freeml(i)||',');
elsif(i=freeml.count) then
DBMS_OUTPUT.PUT_LINE (freeml(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, }, {');
dbms_output.put_line('label: "Ges resource MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('backgroundColor: window.awrColors.green1,');
dbms_output.put_line('borderColor: window.awrColors.green2,');
dbms_output.put_line('data: [');
 FOR i IN gesl.FIRST .. gesl.LAST
LOOP
  if(i<gesl.count) then
DBMS_OUTPUT.PUT_LINE (gesl(i)||',');
elsif(i=gesl.count) then
DBMS_OUTPUT.PUT_LINE (gesl(i));
end if;
END LOOP;
------------
dbms_output.put_line('], fill: true, }, {');
dbms_output.put_line('label: "Gcs resource MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
dbms_output.put_line('data: [');
 FOR i IN gcsl.FIRST .. gcsl.LAST
LOOP
  if(i<gcsl.count) then
DBMS_OUTPUT.PUT_LINE (gcsl(i)||',');
elsif(i=gcsl.count) then
DBMS_OUTPUT.PUT_LINE (gcsl(i));
end if;
END LOOP;
------------
dbms_output.put_line('], fill: true, }, {');
dbms_output.put_line('label: "Other memory MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: true,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
dbms_output.put_line('data: [');
 FOR i IN restml.FIRST .. restml.LAST
LOOP
  if(i<restml.count) then
DBMS_OUTPUT.PUT_LINE (restml(i)||',');
elsif(i=restml.count) then
DBMS_OUTPUT.PUT_LINE (restml(i));
end if;
END LOOP;
-------------------
dbms_output.put_line('], }] },              ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"Shared Pool Stat"      ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('stacked: true,');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
------------------------shared pool end
---------------------------lib hit-----------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME         ValueList;
  LIBRARY_HIT       ValueList; --- Library hit %
  LIB_CUR           sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var libdata = { type: "line", data: { labels: [');
  OPEN LIB_CUR FOR   
    select  (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                 from dba_hist_snapshot f
                where f.snap_id = a2.snap_id
                  and f.instance_number = &inid)  snap_time,
           trunc(a2.ph / a2.p * 100, 2) hit
      from (SELECT snap_id,
                   greatest(0, a1.ph - lag(a1.ph, 1, a1.ph) over(order by a1.snap_id)) ph,
                   greatest(0, a1.p - lag(a1.p, 1, a1.p) over(order by a1.snap_id)) p
              from (select snap_id, sum(pinhits) PH, sum(pins) P
                      from DBA_HIST_LIBRARYCACHE
                     WHERE SNAP_ID >= &bid
                       AND SNAP_ID <= &eid
                       and instance_number = &inid
                     group by snap_id
                     ORDER BY SNAP_ID) a1) a2
     where p > 0;

   FETCH LIB_CUR BULK COLLECT INTO SNAPTIME ,LIBRARY_HIT;
   CLOSE LIB_CUR;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 LIBRARY_HIT.extend;
 LIBRARY_HIT(1):='0';
end if;
-----------------------------------------     
   FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
        if (i < snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
        elsif (i = snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i));
        end if;
    END LOOP;                                  
    DBMS_OUTPUT.PUT_LINE('], datasets: [{');
    DBMS_OUTPUT.PUT_LINE('label: "Library cache hit point",');
    DBMS_OUTPUT.PUT_LINE('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.blue1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.blue2,');
    DBMS_OUTPUT.PUT_LINE('data: [');
    FOR i IN LIBRARY_HIT.FIRST .. LIBRARY_HIT.LAST LOOP
        if (i < LIBRARY_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LIBRARY_HIT(i) || ',');
        elsif (i = LIBRARY_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LIBRARY_HIT(i));
        end if;
    END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------------lib hint end------------------------------------------------------
--------------------------latch hint--------------------------------
declare
  TYPE ValueList IS TABLE OF varchar2(200);
  SNAPTIME         ValueList;
  LATCH_HIT          ValueList; --- Latch hit %
  LATCH_CUR           sys_refcursor;
BEGIN
  DBMS_OUTPUT.PUT_LINE('var latchdata = { type: "line", data: { labels: [');
  OPEN LATCH_CUR FOR  
      select trunc(100 - (misses / gets * 100), 2) Get_rate,---change Miss_rate from Get_rate on 2016-12-30 by MaXuefeng
              (select '"' || to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi') || '"'
                   from dba_hist_snapshot f
                  where f.snap_id = a2.snap_id
                    and f.instance_number = &inid) snap_time
        from (select a1.snap_id,
                     greatest(0, a1.gets - lag(a1.gets, 1, a1.gets) over(order by a1.snap_id)) gets,
                     greatest(0, a1.misses - lag(a1.misses, 1, a1.misses) over(order by a1.snap_id)) misses
                from (select a.snap_id, sum(a.gets) gets, sum(a.misses) misses
                        from dba_hist_latch a
                       where a.instance_number = &inid
                         and a.snap_id >= &bid
                         and a.snap_id <= &eid
                       group by a.snap_id
                       order by a.snap_id) a1) a2
       where gets > 0;
   FETCH LATCH_CUR BULK COLLECT INTO LATCH_HIT,SNAPTIME;
   CLOSE LATCH_CUR;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 LATCH_HIT.extend;
 LATCH_HIT(1):='0';
end if;
-----------------------------------------      
   FOR i IN snaptime.FIRST .. snaptime.LAST LOOP
        if (i < snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i) || ',');
        elsif (i = snaptime.count) then
          DBMS_OUTPUT.PUT_LINE(snaptime(i));
        end if;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('], datasets: [{');
    DBMS_OUTPUT.PUT_LINE('label: "Latch hit point",');
    DBMS_OUTPUT.PUT_LINE('lineTension :0,');
    DBMS_OUTPUT.PUT_LINE('backgroundColor: window.awrColors.green1,');
    DBMS_OUTPUT.PUT_LINE('borderColor: window.awrColors.green2,');
    DBMS_OUTPUT.PUT_LINE('data: [');
    FOR i IN LATCH_HIT.FIRST .. LATCH_HIT.LAST LOOP
        if (i < LATCH_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LATCH_HIT(i) || ',');
        elsif (i = LATCH_HIT.count) then
          DBMS_OUTPUT.PUT_LINE(LATCH_HIT(i));
        end if;
    END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-------------------------------------latch hint end--------------------------------------
-----------------------------sp--------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
sharep ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchspdata = { type: "line", data: { labels: [');
open my_cur for
select 
sum(case when a2.latch_name='shared pool' then  a2.miss_rate else 0 end  ) shared_p,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
 and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
     a.latch_name,
     a.gets,
     a.misses,
     greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
     greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
from dba_hist_latch a 
         where latch_name in (
'shared pool') and a.instance_number=&inid and
a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id;
 FETCH my_cur BULK COLLECT INTO sharep,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 sharep.extend;
 sharep(1):='0';
end if;
----------------------------------------- 
 FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:shared pool - MISSES RATE N/10000 ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN sharep.FIRST .. sharep.LAST
LOOP
  if(i<sharep.count) then
DBMS_OUTPUT.PUT_LINE (sharep(i)||',');
elsif(i=sharep.count) then
DBMS_OUTPUT.PUT_LINE (sharep(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------------sp end------------------------------------
--------------------------------rco----------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
rowco ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchrcodata = { type: "line", data: { labels: ['); 
open my_cur for
select 
sum(case when a2.latch_name='row cache objects' then  a2.miss_rate else 0 end  ) row_co,
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid)  snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
               greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
          from dba_hist_latch a 
         where latch_name in ('row cache objects') and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id ;
 FETCH my_cur BULK COLLECT INTO rowco,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 rowco.extend;
 rowco(1):='0';
end if;
----------------------------------------- 
 FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:row cache objects - MISSES RATE N/10000 ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.orange1,');
dbms_output.put_line('borderColor: window.awrColors.orange2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN rowco.FIRST .. rowco.LAST
LOOP
  if(i<rowco.count) then
DBMS_OUTPUT.PUT_LINE (rowco(i)||',');
elsif(i=rowco.count) then
DBMS_OUTPUT.PUT_LINE (rowco(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------------rco------------------------------------------------
-------------------------cbc-------------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
latch_cbc ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchcbcdata = { type: "line", data: { labels: [');
open my_cur for
select
 cache_bc,snap_time
  from (
select 
a2.snap_id,
sum(case when a2.latch_name='cache buffers chains' then  a2.miss_rate else 0 end  ) cache_bc,
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
               greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
          from dba_hist_latch a 
         where latch_name in (
                              'cache buffers chains'
                             ) and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id )a3;
 FETCH my_cur BULK COLLECT INTO latch_cbc,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 latch_cbc.extend;
 latch_cbc(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:cache buffers chains - MISSES RATE N/10000  ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green0,');
dbms_output.put_line('borderColor: window.awrColors.green2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN latch_cbc.FIRST .. latch_cbc.LAST
LOOP
  if(i<latch_cbc.count) then
DBMS_OUTPUT.PUT_LINE (latch_cbc(i)||',');
elsif(i=latch_cbc.count) then
DBMS_OUTPUT.PUT_LINE (latch_cbc(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------------------------------------------
----------------------lru------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
lru_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchlrudata = { type: "line", data: { labels: [');
open my_cur for
select cache_lru,snap_time  
         from (
select 
a2.snap_id,
sum(case when a2.latch_name='cache buffers lru chain' then  a2.miss_rate else 0 end  ) cache_lru,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
               greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
          from dba_hist_latch a 
         where latch_name in (
                              'cache buffers lru chain') and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id )a3;
 FETCH my_cur BULK COLLECT INTO lru_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 lru_data.extend;
 lru_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');  
dbms_output.put_line('label: "Latch:cache buffers lru chain - MISSES RATE N/10000 ",');  
dbms_output.put_line('lineTension :0,');  
dbms_output.put_line('backgroundColor: window.awrColors.green0,');  
dbms_output.put_line('borderColor: window.awrColors.green2,');  
dbms_output.put_line('data: [');  
------------------------------
 FOR i IN lru_data.FIRST .. lru_data.LAST
LOOP
  if(i<lru_data.count) then
DBMS_OUTPUT.PUT_LINE (lru_data(i)||',');
elsif(i=lru_data.count) then
DBMS_OUTPUT.PUT_LINE (lru_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------lru end--------------------------------------------------
----------------------gc------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
gc_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchgcdata = { type: "line", data: { labels: [');
open my_cur for
select
gc_e,snap_time
         from (
select 
a2.snap_id,
sum(case when a2.latch_name='gc element' then  a2.miss_rate else 0 end  ) gc_e,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid)  snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
               greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
          from dba_hist_latch a 
         where latch_name in ('gc element') and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id )a3;
 FETCH my_cur BULK COLLECT INTO gc_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 gc_data.extend;
 gc_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');    
dbms_output.put_line('label: "Latch:gc element - MISSES RATE N/10000 ",');    
dbms_output.put_line('lineTension :0,');    
dbms_output.put_line('backgroundColor: window.awrColors.purple1,');    
dbms_output.put_line('borderColor: window.awrColors.purple2,');    
dbms_output.put_line('data: [');    
------------------------------
 FOR i IN gc_data.FIRST .. gc_data.LAST
LOOP
  if(i<gc_data.count) then
DBMS_OUTPUT.PUT_LINE (gc_data(i)||',');
elsif(i=gc_data.count) then
DBMS_OUTPUT.PUT_LINE (gc_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------gcend-------------------------
--------------------dml---------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
dml_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var latchdmldata = { type: "line", data: { labels: ['); 
open my_cur for
select
dml,snap_time
         from (
select 
a2.snap_id,
sum(case when a2.latch_name='DML lock allocation' then  a2.miss_rate else 0 end  ) dml,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id, a1.latch_name, trunc(a1.miss / a1.get * 10000 ) miss_rate
  from (select a.snap_id,
               a.latch_name,
               a.gets,
               a.misses,
               greatest(0, a.gets - lag(a.gets, 1, a.gets) over(partition by a.latch_name order by a.snap_id, a.latch_name)) get,
               greatest(0, a.misses - lag(a.misses, 1, a.misses) over(partition by a.latch_name order by a.snap_id, a.latch_name)) miss
          from dba_hist_latch a 
         where latch_name in (
                              'DML lock allocation'
                            ) and a.instance_number=&inid and
                              a.snap_id >=&bid and a.snap_id <=&eid
         order by snap_id, latch_name) a1
 where a1.get > 0 
  order by snap_id, latch_name )a2
group by a2.snap_id order by a2.snap_id )a3;
 FETCH my_cur BULK COLLECT INTO dml_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 dml_data.extend;
 dml_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Latch:DML lock allocation - MISSES RATE N/10000 ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.yellow1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN dml_data.FIRST .. dml_data.LAST
LOOP
  if(i<dml_data.count) then
DBMS_OUTPUT.PUT_LINE (dml_data(i)||',');
elsif(i=dml_data.count) then
DBMS_OUTPUT.PUT_LINE (dml_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "%"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------dml------------------------------------
----------------------fetch continue row----------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
tfetchdata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var fctdata = { type: "line", data: { labels: [');
open my_cur for
select 
  trunc(tfetch/&_iv  ) ,snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.tfetch - lag(a2.tfetch, 1, a2.tfetch) over(order by a2.snap_id)) tfetch,
greatest(0, a2.dirty - lag(a2.dirty, 1, a2.dirty) over(order by a2.snap_id)) dirty,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='table fetch continued row' then  a1.value else 0 end  )  tfetch ,
sum(case when a1.stat_name='dirty buffers inspected' then  a1.value else 0 end  )  dirty  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'dirty buffers inspected' or a.stat_name = 'table fetch continued row' ) 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO tfetchdata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 tfetchdata.extend;
 tfetchdata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Table fetch continued row / Second  ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green0,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN tfetchdata.FIRST .. tfetchdata.LAST
LOOP
  if(i<tfetchdata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (tfetchdata(i)||',');
end if;
elsif(i=tfetchdata.count) then
DBMS_OUTPUT.PUT_LINE (tfetchdata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------------fct end-------------------------------
----------------------------dirtydata-----------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
dirtydata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var dirtydata = { type: "line", data: { labels: [');
open my_cur for
select 
  trunc(dirty/&_iv  ) ,snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.tfetch - lag(a2.tfetch, 1, a2.tfetch) over(order by a2.snap_id)) tfetch,
greatest(0, a2.dirty - lag(a2.dirty, 1, a2.dirty) over(order by a2.snap_id)) dirty,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='table fetch continued row' then  a1.value else 0 end  )  tfetch ,
sum(case when a1.stat_name='dirty buffers inspected' then  a1.value else 0 end  )  dirty  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    ( a.stat_name = 'dirty buffers inspected' or a.stat_name = 'table fetch continued row' ) 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO dirtydata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 dirtydata.extend;
 dirtydata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Dirty buffers inspected / Second   ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.gray1,');
dbms_output.put_line('borderColor: window.awrColors.black1,');
dbms_output.put_line('data: [');
------------------------------
 FOR i IN dirtydata.FIRST .. dirtydata.LAST
LOOP
  if(i<dirtydata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (dirtydata(i)||',');
end if;
elsif(i=dirtydata.count) then
DBMS_OUTPUT.PUT_LINE (dirtydata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------dirty end--------------------------
-------------------exadata io toal-------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
totalio ValueList;
offloadio ValueList;
interio ValueList;
snaptime ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var exaio = { type: "line", data: { labels: [' );
open my_cur for
select 
  snap_time, totalio, offloadio,interio
 from (
select  a1.snap_id,
trunc((greatest(0, a1.totalio - lag(a1.totalio, 1, a1.totalio) over(order by a1.snap_id)))/1048576/&_iv,2) totalio,
trunc((greatest(0, a1.offloadio - lag(a1.offloadio, 1, a1.offloadio) over(order by a1.snap_id)))/1048576/&_iv,2) offloadio,
trunc((greatest(0, a1.interio - lag(a1.interio, 1, a1.interio) over(order by a1.snap_id)))/1048576/&_iv,2) interio ,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id = a1.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a.SNAP_ID,a.INSTANCE_NUMBER, sum(case when a.stat_name like 'physical%total bytes' then  a.value else 0 end  )  totalio,
sum(case when a.stat_name='cell physical IO bytes eligible for predicate offload' then  a.value else 0 end  )  offloadio,
sum(case when a.stat_name='cell physical IO interconnect bytes' then  a.value else 0 end  ) interio
  from dba_hist_sysstat a
 where a.STAT_NAME in
       ('physical read total bytes',
        'physical write total bytes',
        'cell physical IO bytes eligible for predicate offload',
        'cell physical IO interconnect bytes')
        and A.snap_id >= &bid and A.snap_id <= &eid and a.instance_number=&inid 
        group by a.SNAP_ID,a.INSTANCE_NUMBER ) a1 ) a2 ;
  FETCH my_cur BULK COLLECT INTO snaptime,totalio,offloadio,interio;
 close my_cur;
---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 totalio.extend;
 totalio(1):='0';
 offloadio.extend;
 offloadio(1):=0;
 interio.extend;
 interio(1):=0;
 end if;
-----------------------------------------
FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('], datasets: [');
DBMS_OUTPUT.PUT_LINE ('{label: "Cell physical IO interconnect",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 204, 102, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN interio.FIRST .. interio.LAST
LOOP
  if(i<interio.count) then
DBMS_OUTPUT.PUT_LINE (interio(i)||',');
elsif(i=interio.count) then
DBMS_OUTPUT.PUT_LINE (interio(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Predicate offload IO",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(255, 0, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(255, 0, 0, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
DBMS_OUTPUT.PUT_LINE ('data: [');
/*+copyright wangwenjie , do not copy this code to other business software*/
FOR i IN offloadio.FIRST .. offloadio.LAST
LOOP
  if(i<offloadio.count) then
DBMS_OUTPUT.PUT_LINE (offloadio(i)||',');
elsif(i=offloadio.count) then
DBMS_OUTPUT.PUT_LINE (offloadio(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],}, {label: "Physical read and write IO",');
DBMS_OUTPUT.PUT_LINE ('lineTension :0,');
DBMS_OUTPUT.PUT_LINE ('borderColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('backgroundColor: "rgba(0, 0, 255, 1)" ,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
DBMS_OUTPUT.PUT_LINE ('data: [');
-----------------------------------------
FOR i IN totalio.FIRST .. totalio.LAST
LOOP
  if(i<totalio.count) then
DBMS_OUTPUT.PUT_LINE (totalio(i)||',');
elsif(i=totalio.count) then
DBMS_OUTPUT.PUT_LINE (totalio(i));
end if;
END LOOP;
-----------------------------------------
DBMS_OUTPUT.PUT_LINE ('],},]},');
DBMS_OUTPUT.PUT_LINE ('      options: {');
DBMS_OUTPUT.PUT_LINE ('        responsive: true,');
DBMS_OUTPUT.PUT_LINE ('        title:{');
DBMS_OUTPUT.PUT_LINE ('          display:true,');
DBMS_OUTPUT.PUT_LINE ('          text:"Exadata IO MB Per Second"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        tooltips: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index",');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        hover: {');
DBMS_OUTPUT.PUT_LINE ('          mode: "index"');
DBMS_OUTPUT.PUT_LINE ('        },');
DBMS_OUTPUT.PUT_LINE ('        scales: {');
DBMS_OUTPUT.PUT_LINE ('          xAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Snap Time"');
DBMS_OUTPUT.PUT_LINE ('            }');
DBMS_OUTPUT.PUT_LINE ('          }],');
DBMS_OUTPUT.PUT_LINE ('          yAxes: [{');
DBMS_OUTPUT.PUT_LINE ('            stacked: false,');
DBMS_OUTPUT.PUT_LINE ('            scaleLabel: {');
DBMS_OUTPUT.PUT_LINE ('              display: true,');
DBMS_OUTPUT.PUT_LINE ('              labelString: "Value"');
DBMS_OUTPUT.PUT_LINE ('            }}]}}};  ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------------exadata io2------------------------------
-------------------------------------------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
p_data ValueList;
hp_data ValueList;
bp_data ValueList;
sp_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var exaio21 = { type: "line", data: { labels: [');
open my_cur for
select hp,p,bp,sp,snap_time 
 from (
select 
trunc( ( greatest(0, a2.hp - lag(a2.hp, 1, a2.hp) over(order by a2.snap_id)))/1048576/&_iv,2) hp,
trunc( (  greatest(0, a2.p - lag(a2.p, 1, a2.p) over(order by a2.snap_id)))/1048576/&_iv,2) p,
trunc( (  greatest(0, a2.bp - lag(a2.bp, 1, a2.bp) over(order by a2.snap_id)))/1048576/&_iv,2) bp,
trunc( (  greatest(0, a2.sp - lag(a2.sp, 1, a2.sp) over(order by a2.snap_id)))/1048576/&_iv,2) sp,
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
           from (
select b.snap_id,
       sum(case when b.STAT_NAME='cell physical IO bytes saved by storage index' then value else 0 end) p,
       sum(case when b.STAT_NAME='cell IO uncompressed bytes' then value else 0 end) hp,
       sum(case when b.STAT_NAME='physical read total bytes' then value else 0 end) bp,
        sum(case when b.STAT_NAME='cell physical IO interconnect bytes returned by smart scan' then value else 0 end) sp
  FROM DBA_HIST_SYSSTAT b 
where  b.STAT_NAME in ('cell physical IO bytes saved by storage index',
'cell IO uncompressed bytes',
'physical read total bytes',
'cell physical IO interconnect bytes returned by smart scan') and b.instance_number=&inid
and b.snap_id>=&bid and b.snap_id<=&eid group by b.snap_id
order by b.snap_id)a2
-- where hp>0
)a3;
 FETCH my_cur BULK COLLECT INTO hp_data,p_data,bp_data,sp_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 p_data.extend;
 p_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "cell IO uncompressed",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: "rgba( 0,255,0 , 1)",');
dbms_output.put_line('borderColor: "rgba( 0,255,0 , 1)",');
DBMS_OUTPUT.PUT_LINE('pointRadius: 0,');
dbms_output.put_line('data: [ ');
------------------------------
 FOR i IN hp_data.FIRST .. hp_data.LAST
LOOP
  if(i<hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i)||',');
elsif(i=hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "Cell physical IO MB saved by storage index",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('backgroundColor: "rgba(255, 0, 255, 1)",');
dbms_output.put_line('borderColor: "rgba(255, 0, 255, 1)",');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: [');
 FOR i IN p_data.FIRST .. p_data.LAST
LOOP
  if(i<p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i)||',');
elsif(i=p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i));
end if;
END LOOP;
------------
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "Physical read total MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: [');
 FOR i IN bp_data.FIRST .. bp_data.LAST
LOOP
  if(i<bp_data.count) then
DBMS_OUTPUT.PUT_LINE (bp_data(i)||',');
elsif(i=bp_data.count) then
DBMS_OUTPUT.PUT_LINE (bp_data(i));
end if;
END LOOP;
------------
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "cell physical IO returned by smart scan",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: [');
 FOR i IN sp_data.FIRST .. sp_data.LAST
LOOP
  if(i<sp_data.count) then
DBMS_OUTPUT.PUT_LINE (sp_data(i)||',');
elsif(i=sp_data.count) then
DBMS_OUTPUT.PUT_LINE (sp_data(i));
end if;
END LOOP;
-------------------
dbms_output.put_line('], }] },              ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"Exadata IO MB Per Second"      ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------------------exadata3----------------------------------
declare  --1048576
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
p_data ValueList;
hp_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var exaio3 = { type: "line", data: { labels: [');
open my_cur for
select hp,p,snap_time 
 from (
select 
trunc( ( greatest(0, a2.hp - lag(a2.hp, 1, a2.hp) over(order by a2.snap_id)))/1048576/&_iv,2) hp,
trunc( (  greatest(0, a2.p - lag(a2.p, 1, a2.p) over(order by a2.snap_id)))/1048576/&_iv,2) p,
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
           from (
select b.snap_id,
       sum(case when b.STAT_NAME='cell physical IO interconnect bytes' then value else 0 end) p,
       sum(case when b.STAT_NAME='cell physical IO interconnect bytes returned by smart scan' then value else 0 end) hp
  FROM DBA_HIST_SYSSTAT b 
where  b.STAT_NAME in ('cell physical IO interconnect bytes returned by smart scan','cell physical IO interconnect bytes') and b.instance_number=&inid
and b.snap_id>=&bid and b.snap_id<=&eid group by b.snap_id
order by b.snap_id)a2
-- where hp>0
)a3;
 FETCH my_cur BULK COLLECT INTO hp_data,p_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 p_data.extend;
 p_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "cell physical IO interconnect MB returned by smart scan",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green1,');
dbms_output.put_line('borderColor: window.awrColors.green1,');
DBMS_OUTPUT.PUT_LINE('pointRadius: 0,');
dbms_output.put_line('data: [ ');
------------------------------
 FOR i IN hp_data.FIRST .. hp_data.LAST
LOOP
  if(i<hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i)||',');
elsif(i=hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, }, {');
dbms_output.put_line('label: "cell physical IO interconnect MB",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('backgroundColor: window.awrColors.blue1,');
dbms_output.put_line('borderColor: window.awrColors.blue2,');
DBMS_OUTPUT.PUT_LINE('pointRadius: 0,');
dbms_output.put_line('data: [');
 FOR i IN p_data.FIRST .. p_data.LAST
LOOP
  if(i<p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i)||',');
elsif(i=p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, }] },              ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"Cell interconnect IO"      ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
--------------------------------exadata-----------------------------------


declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
cellpredicatedata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var e1data = { type: "line", data: { labels: ['); 
open my_cur for
select trunc(predicate/1048576/&_iv  ),  snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.predicate - lag(a2.predicate, 1, a2.predicate) over(order by a2.snap_id)) predicate,
greatest(0, a2.storageidx - lag(a2.storageidx, 1, a2.storageidx) over(order by a2.snap_id)) storageidx,
greatest(0, a2.uncom - lag(a2.uncom, 1, a2.uncom) over(order by a2.snap_id)) uncom,
greatest(0, a2.smart - lag(a2.smart, 1, a2.smart) over(order by a2.snap_id)) smart,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='cell physical IO bytes eligible for predicate offload' then  a1.value else 0 end )   predicate ,
sum(case when a1.stat_name='cell physical IO bytes saved by storage index' then  a1.value else 0 end )  storageidx  ,
sum(case when a1.stat_name='cell IO uncompressed bytes' then  a1.value else 0 end)    uncom  ,
sum(case when a1.stat_name='cell physical IO interconnect bytes returned by smart scan' then  a1.value else 0 end )    smart  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    
stat_name in ('cell physical IO bytes eligible for predicate offload',
            'cell physical IO bytes saved by storage index',
            'cell IO uncompressed bytes',
            'cell physical IO interconnect bytes returned by smart scan') 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO cellpredicatedata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 cellpredicatedata.extend;
 cellpredicatedata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Cell physical IO MB eligible for predicate offload / Second    ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.pink1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN cellpredicatedata.FIRST .. cellpredicatedata.LAST
LOOP
  if(i<cellpredicatedata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i)||',');
end if;
elsif(i=cellpredicatedata.count) then
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
cellpredicatedata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var e2data = { type: "line", data: { labels: ['); 
open my_cur for
select trunc(storageidx/1048576/&_iv  ),  snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.predicate - lag(a2.predicate, 1, a2.predicate) over(order by a2.snap_id)) predicate,
greatest(0, a2.storageidx - lag(a2.storageidx, 1, a2.storageidx) over(order by a2.snap_id)) storageidx,
greatest(0, a2.uncom - lag(a2.uncom, 1, a2.uncom) over(order by a2.snap_id)) uncom,
greatest(0, a2.smart - lag(a2.smart, 1, a2.smart) over(order by a2.snap_id)) smart,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='cell physical IO bytes eligible for predicate offload' then  a1.value else 0 end )   predicate ,
sum(case when a1.stat_name='cell physical IO bytes saved by storage index' then  a1.value else 0 end )  storageidx  ,
sum(case when a1.stat_name='cell IO uncompressed bytes' then  a1.value else 0 end)    uncom  ,
sum(case when a1.stat_name='cell physical IO interconnect bytes returned by smart scan' then  a1.value else 0 end )    smart  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    
stat_name in ('cell physical IO bytes eligible for predicate offload',
            'cell physical IO bytes saved by storage index',
            'cell IO uncompressed bytes',
            'cell physical IO interconnect bytes returned by smart scan') 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO cellpredicatedata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 cellpredicatedata.extend;
 cellpredicatedata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Cell physical IO MB saved by storage index / Second     ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.pink1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN cellpredicatedata.FIRST .. cellpredicatedata.LAST
LOOP
  if(i<cellpredicatedata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i)||',');
end if;
elsif(i=cellpredicatedata.count) then
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
cellpredicatedata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var e3data = { type: "line", data: { labels: ['); 
open my_cur for
select trunc(smart/1048576/&_iv  ),  snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.predicate - lag(a2.predicate, 1, a2.predicate) over(order by a2.snap_id)) predicate,
greatest(0, a2.storageidx - lag(a2.storageidx, 1, a2.storageidx) over(order by a2.snap_id)) storageidx,
greatest(0, a2.uncom - lag(a2.uncom, 1, a2.uncom) over(order by a2.snap_id)) uncom,
greatest(0, a2.smart - lag(a2.smart, 1, a2.smart) over(order by a2.snap_id)) smart,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='cell physical IO bytes eligible for predicate offload' then  a1.value else 0 end )   predicate ,
sum(case when a1.stat_name='cell physical IO bytes saved by storage index' then  a1.value else 0 end )  storageidx  ,
sum(case when a1.stat_name='cell IO uncompressed bytes' then  a1.value else 0 end)    uncom  ,
sum(case when a1.stat_name='cell physical IO interconnect bytes returned by smart scan' then  a1.value else 0 end )    smart  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    
stat_name in ('cell physical IO bytes eligible for predicate offload',
            'cell physical IO bytes saved by storage index',
            'cell IO uncompressed bytes',
            'cell physical IO interconnect bytes returned by smart scan') 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3;
 FETCH my_cur BULK COLLECT INTO cellpredicatedata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 cellpredicatedata.extend;
 cellpredicatedata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Cell physical IO interconnect MB returned by smart scan / Second     ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.pink1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN cellpredicatedata.FIRST .. cellpredicatedata.LAST
LOOP
  if(i<cellpredicatedata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i)||',');
end if;
elsif(i=cellpredicatedata.count) then
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
cellpredicatedata ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var e4data = { type: "line", data: { labels: ['); 
open my_cur for
select   (1-(iio/(wio*2+rio)))*100 iosavepct,  snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.iio - lag(a2.iio, 1, a2.iio) over(order by a2.snap_id)) iio,
greatest(0, a2.rio - lag(a2.rio, 1, a2.rio) over(order by a2.snap_id)) rio,
greatest(0, a2.wio - lag(a2.wio, 1, a2.wio) over(order by a2.snap_id)) wio,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='cell physical IO interconnect bytes' then  a1.value else 0 end )   iio ,
sum(case when a1.stat_name='physical read total bytes' then  a1.value else 0 end )  rio  ,
sum(case when a1.stat_name='physical write total bytes' then  a1.value else 0 end)    wio  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    
stat_name in ('cell physical IO interconnect bytes',
            'physical read total bytes',
            'physical write total bytes') 
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 
 where a2.rio>0
 ) a3 where rio>0;
 FETCH my_cur BULK COLLECT INTO cellpredicatedata,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 cellpredicatedata.extend;
 cellpredicatedata(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Saved IO Pct      ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.green1,');
dbms_output.put_line('borderColor: window.awrColors.blue1,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN cellpredicatedata.FIRST .. cellpredicatedata.LAST
LOOP
  if(i<cellpredicatedata.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i)||',');
end if;
elsif(i=cellpredicatedata.count) then
DBMS_OUTPUT.PUT_LINE (cellpredicatedata(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('ticks: {min : 0,  max :100 },          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------flash hit ----------------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
flashpctl ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var flashcachedata = { type: "line", data: { labels: ['); 
open my_cur for
select trunc(100*flash/phyrq,2) flashpct,  snap_time
 from (
select a2.snap_id  , 
greatest(0, a2.flash - lag(a2.flash, 1, a2.flash) over(order by a2.snap_id)) flash,
greatest(0, a2.phyrq - lag(a2.phyrq, 1, a2.phyrq) over(order by a2.snap_id)) phyrq,
(select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
 from (
select a1.snap_id,
sum(case when a1.stat_name='cell flash cache read hits' then  a1.value else 0 end )   flash ,
sum(case when a1.stat_name='physical read total IO requests' then  a1.value else 0 end )  phyrq  
from
(select a.snap_id,a.stat_name,a.value from dba_hist_sysstat a where    
stat_name in ('cell flash cache read hits','physical read total IO requests')
and snap_id >=&bid and snap_id<=&eid and a.instance_number=&inid
 order by a.snap_id,a.stat_name) a1 group by a1.snap_id order by a1.snap_id) a2 ) a3 where phyrq>0;
 FETCH my_cur BULK COLLECT INTO flashpctl,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 flashpctl.extend;
 flashpctl(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
  if i=1 then
   null;
  else
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
end if;
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Flash cache hit point PCT ",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.pink1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
DBMS_OUTPUT.PUT_LINE ('pointRadius: 0,');
dbms_output.put_line('data: ['); 
------------------------------
 FOR i IN flashpctl.FIRST .. flashpctl.LAST
LOOP
  if(i<flashpctl.count) then
   if i=1 then
    null;
  else
DBMS_OUTPUT.PUT_LINE (flashpctl(i)||',');
end if;
elsif(i=flashpctl.count) then
DBMS_OUTPUT.PUT_LINE (flashpctl(i));
end if;
END LOOP;
dbms_output.put_line('], fill: true, } ] },                  ');      
dbms_output.put_line('options: {                             ');
dbms_output.put_line('responsive: true,                      ');
dbms_output.put_line('title:{                                ');
dbms_output.put_line('display:true,                          ');
dbms_output.put_line('text:""');
dbms_output.put_line('},                                     ');
dbms_output.put_line('tooltips: {                            ');
dbms_output.put_line('mode: "index",                         ');
dbms_output.put_line('intersect: false,                      ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('hover: {                               ');
dbms_output.put_line('mode: "nearest",                       ');
dbms_output.put_line('intersect: true                        ');
dbms_output.put_line('},                                     ');
dbms_output.put_line('scales: {                              ');
dbms_output.put_line('xAxes: [{                              ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Snap"                    ');
dbms_output.put_line('}                                      ');
dbms_output.put_line('}],                                    ');
dbms_output.put_line('yAxes: [{                              ');
dbms_output.put_line('ticks: {min : 0,  max :100 },          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('scaleLabel: {                          ');
dbms_output.put_line('display: true,                         ');
dbms_output.put_line('labelString: "Value"                   ');
dbms_output.put_line('}  }] }  } };                          ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
---------------------flash hit end--------------------------------
---------------------------exadataend--------------------------------------

------------------------event---------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
pct ValueList;
event ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var eventdata = { type: "polarArea", data: { datasets: [{ data: ['); 
open my_cur for
select 
pct,event
 from
(
SELECT
        trunc(PCTWTT,2) pct , EVENT, rownum rn
  FROM (SELECT EVENT, WAITS, TIME, PCTWTT, WAIT_CLASS
          FROM (SELECT E.EVENT_NAME EVENT,
                       E.TOTAL_WAITS_FG - NVL(B.TOTAL_WAITS_FG, 0) WAITS,
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       1000000 TIME,
                       100 *
                       (E.TIME_WAITED_MICRO_FG - NVL(B.TIME_WAITED_MICRO_FG, 0)) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       E.WAIT_CLASS WAIT_CLASS
                  FROM DBA_HIST_SYSTEM_EVENT B, DBA_HIST_SYSTEM_EVENT E
                 WHERE B.SNAP_ID(+) = &bid
                   AND E.SNAP_ID = &eid
                   AND B.INSTANCE_NUMBER(+) = &inid
                   AND E.INSTANCE_NUMBER = &inid
                   AND B.EVENT_ID(+) = E.EVENT_ID
                   AND E.TOTAL_WAITS > NVL(B.TOTAL_WAITS, 0)
                   AND E.WAIT_CLASS != 'Idle'
                UNION ALL
                SELECT 'CPU time' EVENT,
                       TO_NUMBER(NULL) WAITS,
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB CPU')) / 1000000 TIME,
                       100 * ((SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL e
                                WHERE e.SNAP_ID = &eid
                                  AND e.INSTANCE_NUMBER = &inid
                                  AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                                 FROM DBA_HIST_SYS_TIME_MODEL b
                                WHERE b.SNAP_ID = &bid
                                  AND b.INSTANCE_NUMBER = &inid
                                  AND b.STAT_NAME = 'DB CPU')) /
                       ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB time') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB time')) PCTWTT,
                       NULL WAIT_CLASS
                  from dual
                 WHERE ((SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL e
                          WHERE e.SNAP_ID = &eid
                            AND e.INSTANCE_NUMBER = &inid
                            AND e.STAT_NAME = 'DB CPU') -
                       (SELECT sum(value)
                           FROM DBA_HIST_SYS_TIME_MODEL b
                          WHERE b.SNAP_ID = &bid
                            AND b.INSTANCE_NUMBER = &inid
                            AND b.STAT_NAME = 'DB CPU'))> 0)
         ORDER BY TIME DESC, WAITS DESC)
 WHERE ROWNUM <= 5) a1 order by rn;
 FETCH my_cur BULK COLLECT INTO pct,event;
 close my_cur;
 FOR i IN pct.FIRST .. pct.LAST
LOOP
  if(i<pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i)||',');
elsif(i=pct.count) then
DBMS_OUTPUT.PUT_LINE (pct(i));
end if;
END LOOP;
dbms_output.put_line('], backgroundColor: [');
dbms_output.put_line('window.awrColors.red2,');
dbms_output.put_line('window.awrColors.blue2,');
dbms_output.put_line('window.awrColors.green1,');
dbms_output.put_line('window.awrColors.yellow1,');
dbms_output.put_line('window.awrColors.orange1');
dbms_output.put_line('], label: "Event" }],');
dbms_output.put_line('labels: [');
FOR i IN event.FIRST .. event.LAST
LOOP
  if(i<event.count) then
DBMS_OUTPUT.PUT_LINE ('"'||event(i)||'",');
elsif(i=event.count) then
DBMS_OUTPUT.PUT_LINE ('"'||event(i)||'"');
end if;
END LOOP;
dbms_output.put_line('   ] },');
dbms_output.put_line('  options: {');
dbms_output.put_line('     responsive: true,');
dbms_output.put_line('   legend: {');
dbms_output.put_line('    position: "right",');
dbms_output.put_line(' },');
dbms_output.put_line(' title: {');
dbms_output.put_line('   display: true,');
dbms_output.put_line('  text: "event"');
dbms_output.put_line(' },');
dbms_output.put_line(' scale: {');
dbms_output.put_line(' ticks: {');
dbms_output.put_line(' beginAtZero: true');
dbms_output.put_line(' },');
dbms_output.put_line(' reverse: false');
dbms_output.put_line(' },');
dbms_output.put_line(' animation: {');
dbms_output.put_line(' animateRotate: false,');
dbms_output.put_line(' animateScale: true');
dbms_output.put_line('} } };');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
----------------------event end--------------------------------
-----------------pasrse count------------------------------
declare
TYPE ValueList IS TABLE OF varchar2(200);
snaptime ValueList;
p_data ValueList;
hp_data ValueList;
my_cur SYS_REFCURSOR;
begin
dbms_output.put_line('var parsedata = { type: "line", data: { labels: [');
open my_cur for
select hp,p,snap_time 
 from (
select 
trunc( greatest(0, ( greatest(0, a2.hp - lag(a2.hp, 1, a2.hp) over(order by a2.snap_id))))/&_iv) hp,
trunc( greatest(0, (  greatest(0, a2.p - lag(a2.p, 1, a2.p) over(order by a2.snap_id))))/&_iv) p,
 (select '"'||to_char(f.END_INTERVAL_TIME, 'mm-dd hh24:mi')||'"'
          from dba_hist_snapshot f
         where f.snap_id =a2.snap_id
           and f.instance_number = &inid) snap_time
           from (
select b.snap_id,
       sum(case when b.STAT_NAME='parse count (total)' then value else 0 end) p,
       sum(case when b.STAT_NAME='parse count (hard)' then value else 0 end) hp
  FROM DBA_HIST_SYSSTAT b 
where  b.STAT_NAME in ('parse count (total)','parse count (hard)') and b.instance_number=&inid
and b.snap_id>=&bid and b.snap_id<=&eid group by b.snap_id
order by b.snap_id)a2
 where hp>0
)a3;
 FETCH my_cur BULK COLLECT INTO hp_data,p_data,snaptime;
 close my_cur;
    ---handle null list---------------------
if(snaptime.count=0) then
snaptime.extend;
snaptime(1):='"1981-03-30 20:00:00"';
 p_data.extend;
 p_data(1):='0';
end if;
----------------------------------------- 
  FOR i IN snaptime.FIRST .. snaptime.LAST
LOOP
  if(i<snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i)||',');
elsif(i=snaptime.count) then
DBMS_OUTPUT.PUT_LINE (snaptime(i));
end if;
END LOOP;
------------------------------------
dbms_output.put_line('], datasets: [{');
dbms_output.put_line('label: "Hard Parse count",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('backgroundColor: window.awrColors.red1,');
dbms_output.put_line('borderColor: window.awrColors.red2,');
dbms_output.put_line('data: [ ');
------------------------------
 FOR i IN hp_data.FIRST .. hp_data.LAST
LOOP
  if(i<hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i)||',');
elsif(i=hp_data.count) then
DBMS_OUTPUT.PUT_LINE (hp_data(i));
end if;
END LOOP;
dbms_output.put_line('], fill: false, }, {');
dbms_output.put_line('label: "Parse count",');
dbms_output.put_line('lineTension :0,');
dbms_output.put_line('fill: false,');
dbms_output.put_line('backgroundColor: window.awrColors.orange1,');
dbms_output.put_line('borderColor: window.awrColors.orange2,');
dbms_output.put_line('data: [');
 FOR i IN p_data.FIRST .. p_data.LAST
LOOP
  if(i<p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i)||',');
elsif(i=p_data.count) then
DBMS_OUTPUT.PUT_LINE (p_data(i));
end if;
END LOOP;
dbms_output.put_line('], }] },              ');
dbms_output.put_line('options: {            ');
dbms_output.put_line('responsive: true,     ');
dbms_output.put_line('title:{               ');
dbms_output.put_line('display:true,         ');
dbms_output.put_line('text:"SQL Parse per second"      ');
dbms_output.put_line('},                    ');
dbms_output.put_line('tooltips: {           ');
dbms_output.put_line('mode: "index",        ');
dbms_output.put_line('intersect: false,     ');
dbms_output.put_line('},                    ');
dbms_output.put_line('hover: {              ');
dbms_output.put_line('mode: "nearest",      ');
dbms_output.put_line('intersect: true       ');
dbms_output.put_line('},                    ');
dbms_output.put_line('scales: {             ');
dbms_output.put_line('xAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString: "Snap"   ');
dbms_output.put_line('}                     ');
dbms_output.put_line('}],                   ');
dbms_output.put_line('yAxes: [{             ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('scaleLabel: {         ');
dbms_output.put_line('display: true,        ');
dbms_output.put_line('labelString:  "Value" ');
dbms_output.put_line('} }] } } };           ');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('/* Error: ' || replace(sqlerrm, '''', '''''') || ' */');
    DBMS_OUTPUT.PUT_LINE(']; } });');
end;
/
-----------------------parse count end----------------
prompt window.onload = function() {
--------------------------------
prompt var ctx = document.getElementById("canvas_cpu").getContext("2d");
prompt window.myLine = new Chart(ctx, upgradeChartConfig(cpudata));
prompt var ctx2 = document.getElementById("canvas_dbtime").getContext("2d");
prompt window.myLine = new Chart(ctx2, upgradeChartConfig(dbtimedata));
prompt var ctx2_p = document.getElementById("canvas_parsetime").getContext("2d");
prompt window.myLine = new Chart(ctx2_p, upgradeChartConfig(parsetimedata));
prompt var ctx6 = document.getElementById("canvas_ash").getContext("2d");
prompt  window.myBar = new Chart(ctx6, upgradeChartConfig({
prompt  type: "bar",
prompt  data: ashdata,
prompt  options: {
prompt  title:{
prompt  display:true,
prompt  text:"Active Session History"
prompt  },
prompt   tooltips: {
prompt  mode: "index",
prompt  intersect: false
prompt  },
prompt  responsive: true,
prompt  scales: {
prompt  xAxes: [{
prompt  stacked: true,
prompt  }],
prompt  yAxes: [{
prompt  stacked: true
prompt  }]}}}));
prompt var ctxusercall = document.getElementById("canvas_usercall").getContext("2d");
prompt window.myLine = new Chart(ctxusercall, upgradeChartConfig(usercalldata));
prompt var ctx3 = document.getElementById("canvas_sql").getContext("2d");
prompt window.myLine = new Chart(ctx3, upgradeChartConfig({ type: 'line',
prompt     data: sqldata,
prompt  options: {
prompt      responsive: true,
prompt      hoverMode: "index",
prompt      stacked: false,
prompt      title:{
prompt          display: true,
prompt          text:"SQL exe time and count"
prompt      },
prompt      scales: {
prompt  yAxes: [{
prompt      type: "linear", // only linear but allow scale type registration. This allows extensions to exist solely for log scale for instance
prompt      display: true,
prompt      position: "left",
prompt      id: "y-axis-1",
prompt  }, {
prompt      type: "linear", // only linear but allow scale type registration. This allows extensions to exist solely for log scale for instance
prompt      display: true,
prompt      position: "right",
prompt      id: "y-axis-2",
prompt      // grid line settings
prompt      gridLines: {
prompt          drawOnChartArea: false, // only want the grid lines for one axis to show up
prompt      }, }], }} })); 
prompt  var ctx5 = document.getElementById("canvas_logic").getContext("2d");
prompt  window.myLine = new Chart(ctx5, upgradeChartConfig(logicdata));
prompt var ctx7 = document.getElementById("canvas_commit").getContext("2d");
prompt window.myLine = new Chart(ctx7, upgradeChartConfig({ type: 'line',
prompt data: commitdata,
prompt options: {
prompt responsive: true,
prompt hoverMode: "index",
prompt stacked: false,
prompt title:{
prompt display: true,
prompt text:"Commits and Redo size per second"
prompt },
prompt scales: {
prompt yAxes: [{
prompt type: "linear",  
prompt display: true,
prompt position: "left",
prompt id: "y-axis-1",
prompt }, {
prompt type: "linear", 
prompt display: true,
prompt position: "right",
prompt id: "y-axis-2",
prompt // grid line settings
prompt gridLines: {
prompt drawOnChartArea: false,  
prompt }, }], }} }));
prompt var ctxphy = document.getElementById("canvas_phy").getContext("2d");
prompt window.myLine = new Chart(ctxphy, upgradeChartConfig(phydata));
prompt var ctxphy2 = document.getElementById("canvas_phyreq").getContext("2d");
prompt window.myLine = new Chart(ctxphy2, upgradeChartConfig(phyreqdata));
prompt var ctxuserio = document.getElementById("canvas_userio").getContext("2d");
prompt window.myLine = new Chart(ctxuserio, upgradeChartConfig(waittimedata));
prompt var ctxavgio = document.getElementById("canvas_avgio").getContext("2d");
prompt window.myLine = new Chart(ctxavgio, upgradeChartConfig(avgiodata));
prompt var ctxiotimes = document.getElementById("canvas_iotimes").getContext("2d");
prompt window.myBar = new Chart(ctxiotimes, upgradeChartConfig({
prompt     type: "bar",
prompt     data: iotimesdata,
prompt     options: {
prompt  title:{
prompt      display:true,
prompt      text:"Chart.js Bar Chart - Stacked"
prompt  },
prompt  tooltips: {
prompt      mode: "index",
prompt      intersect: false
prompt  },
prompt  responsive: true,
prompt  scales: {
prompt      xAxes: [{
prompt          stacked: true,
prompt      }],
prompt      yAxes: [{
prompt          stacked: true
prompt      }]
prompt         }
prompt     }
prompt }));
prompt var ctxmaxc = document.getElementById("canvas_maxcommit").getContext("2d");
prompt window.myLine = new Chart(ctxmaxc, upgradeChartConfig(maxcommitdata));
prompt  var ctx = document.getElementById("canvas_redotrans").getContext("2d");
prompt        window.myLine = new Chart(ctx, upgradeChartConfig({ type: 'line',
prompt            data: redotransdata,
prompt    options: {
prompt        responsive: true,
prompt        hoverMode: 'index',
prompt        stacked: false,
prompt        title:{
prompt            display: true,
prompt            text:'Redo transport'
prompt        },
prompt        scales: {
prompt       yAxes: [{
prompt           type: "linear",  
prompt           stacked: false,
prompt            ticks: {min : 0 },
prompt           display: true,
prompt           position: "left",
prompt           id: "y-axis-1",
prompt       }, {
prompt           type: "linear",  
prompt           display: true,
prompt           position: "right",
prompt            ticks: {min : 0,  max :100 },
prompt           id: "y-axis-2",
prompt           gridLines: {
prompt               drawOnChartArea: false, 
prompt           }, }], } }}));
prompt var ctxbchange = document.getElementById("canvas_bchange").getContext("2d");
prompt window.myLine = new Chart(ctxbchange, upgradeChartConfig(bchangedata));
prompt var ctxtbsusage = document.getElementById("canvas_tbsusage").getContext("2d");
prompt window.myLine = new Chart(ctxtbsusage, upgradeChartConfig(tbsusagedata));
prompt var ctxconn = document.getElementById("canvas_conn").getContext("2d");
prompt window.myLine = new Chart(ctxconn, upgradeChartConfig(conndata));
prompt var ctxlogon = document.getElementById("canvas_logon").getContext("2d");
prompt window.myLine = new Chart(ctxlogon, upgradeChartConfig(logondata));
prompt var ctxgckb = document.getElementById("canvas_gckb").getContext("2d");
prompt window.myLine = new Chart(ctxgckb, upgradeChartConfig(gckbdata));
prompt var ctxgclost = document.getElementById("canvas_gclost").getContext("2d");
prompt window.myLine = new Chart(ctxgclost, upgradeChartConfig(gclostdata));
prompt var ctxgcms = document.getElementById("canvas_gcms").getContext("2d");
prompt window.myLine = new Chart(ctxgcms, upgradeChartConfig(gcmsdata));
prompt var ctxeshared = document.getElementById("canvas_sharedpool").getContext("2d");
prompt window.myLine = new Chart(ctxeshared, upgradeChartConfig(sharedpooldata));
prompt var ctxgcb = document.getElementById("canvas_gcb").getContext("2d");
prompt window.myLine = new Chart(ctxgcb, upgradeChartConfig(gcbdata));
prompt var ctxmemstats = document.getElementById("canvas_memstats").getContext("2d");
prompt window.myLine = new Chart(ctxmemstats, upgradeChartConfig(memdata));
prompt var ctxbfpga = document.getElementById("canvas_bfpga").getContext("2d");
prompt window.myLine = new Chart(ctxbfpga, upgradeChartConfig(bfpgadata));
prompt var ctxlib = document.getElementById("canvas_lib").getContext("2d");
prompt window.myLine = new Chart(ctxlib, upgradeChartConfig(libdata));
prompt var ctxlatch = document.getElementById("canvas_latch").getContext("2d");
prompt window.myLine = new Chart(ctxlatch, upgradeChartConfig(latchdata));
prompt var ctxlatchsp = document.getElementById("canvas_latchsp").getContext("2d");
prompt window.myLine = new Chart(ctxlatchsp, upgradeChartConfig(latchspdata));
prompt var ctxlatchrco = document.getElementById("canvas_latchrco").getContext("2d");
prompt window.myLine = new Chart(ctxlatchrco, upgradeChartConfig(latchrcodata));
prompt var ctxlatchcbc = document.getElementById("canvas_latchcbc").getContext("2d");
prompt window.myLine = new Chart(ctxlatchcbc, upgradeChartConfig(latchcbcdata));
prompt var ctxlatchlru = document.getElementById("canvas_latchlru").getContext("2d");
prompt window.myLine = new Chart(ctxlatchlru, upgradeChartConfig(latchlrudata));
prompt var ctxlatchgc = document.getElementById("canvas_latchgc").getContext("2d");
prompt window.myLine = new Chart(ctxlatchgc, upgradeChartConfig(latchgcdata));
prompt var ctxlatchdml = document.getElementById("canvas_latchdml").getContext("2d");
prompt window.myLine = new Chart(ctxlatchdml, upgradeChartConfig(latchdmldata));
prompt var ctxfct = document.getElementById("canvas_fct").getContext("2d");
prompt window.myLine = new Chart(ctxfct, upgradeChartConfig(fctdata));
prompt var ctxdt = document.getElementById("canvas_dirty").getContext("2d");
prompt window.myLine = new Chart(ctxdt, upgradeChartConfig(dirtydata));
-------------------------------------
prompt var ctxe501 = document.getElementById("canvas_exaio").getContext("2d");
prompt window.myLine = new Chart(ctxe501, upgradeChartConfig(exaio));
prompt var ctxe502 = document.getElementById("canvas_exaio2").getContext("2d");
prompt window.myLine = new Chart(ctxe502, upgradeChartConfig(exaio21));
prompt var ctxe503 = document.getElementById("canvas_exaio3").getContext("2d");
prompt window.myLine = new Chart(ctxe503, upgradeChartConfig(exaio3));
prompt var ctxe1 = document.getElementById("canvas_e1").getContext("2d");
prompt window.myLine = new Chart(ctxe1, upgradeChartConfig(e1data));
prompt var ctxe2 = document.getElementById("canvas_e2").getContext("2d");
prompt window.myLine = new Chart(ctxe2, upgradeChartConfig(e2data));
prompt var ctxe3 = document.getElementById("canvas_e3").getContext("2d");
prompt window.myLine = new Chart(ctxe3, upgradeChartConfig(e3data));
prompt var ctxe4 = document.getElementById("canvas_e4").getContext("2d");
prompt window.myLine = new Chart(ctxe4, upgradeChartConfig(e4data));
prompt var ctxe599 = document.getElementById("canvas_e5").getContext("2d");
prompt window.myLine = new Chart(ctxe599, upgradeChartConfig(flashcachedata));
prompt var ctxevent = document.getElementById("canvas_event");
prompt window.myPolarArea = new Chart(ctxevent, upgradeChartConfig(eventdata));
prompt var ctxparse = document.getElementById("canvas_parse").getContext("2d")
prompt window.myLine = new Chart(ctxparse, upgradeChartConfig(parsedata))
------------------------------------
prompt };
prompt 	</script>	
prompt <hr>
prompt </p>
prompt The License of Awr Chart
prompt <br>
prompt The MIT License (MIT)
prompt <br>
prompt The copy right of Chart.js is an open source project (https://www.chartjs.org/) which
prompt <br>
prompt is under MIT license.
prompt <br>
prompt Awrcrt Author :
prompt <br>Wang,Wenjie | Valen Wang
prompt <br>From
prompt <H4 class='awr'>
prompt ONE SQL , BIG WORK , AWRCRT
prompt </H4>
prompt Version : 2.2beta
prompt <br>
prompt Date    : 2026-03-01
prompt </body>
prompt </html>
spool off
set termout       on
!cat awrcrt_&_dbname._&inid._&bid._&eid._&_spool_time..html|grep ORA-;
prompt report wrote to awrcrt_&_dbname._&inid._&bid._&eid._&_spool_time..html
exit