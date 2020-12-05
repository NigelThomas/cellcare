CREATE OR REPLACE SCHEMA "StreamLab_Output_cellcare";

CREATE OR REPLACE FUNCTION "StreamLab_Output_cellcare"."source_1_throttlefunc"(
  INPUTROWS CURSOR,
  THROTTLESCALE INTEGER)
RETURNS TABLE (
   INPUTROWS.*
)
SPECIFIC "StreamLab_Output_cellcare"."source_1_throttlefunc"
LANGUAGE JAVA
PARAMETER STYLE SYSTEM DEFINED JAVA
NO SQL
NOT DETERMINISTIC
EXTERNAL NAME 'class:com.sqlstream.plugin.timesync.ThrottleStream.throttle';

CREATE OR REPLACE FOREIGN STREAM "StreamLab_Output_cellcare"."_StreamLab_Discovery" (
   "d_name" VARCHAR(1024),
   "d_path" VARCHAR(1024),
   "d_type" VARCHAR(1024),
   "d_precision" INTEGER,
   "d_scale" INTEGER,
   "d_nullable" BOOLEAN,
   "d_sample" VARCHAR(4096),
   "d_properties" VARCHAR(40960)
)
SERVER FILE_SERVER
OPTIONS (
  DIRECTORY '/home/sqlstream/nigel/Dropbox/github/cellcare',
  DISCOVERY_TIMEOUT '5000',
  FILENAME_PATTERN 'MME_.*\.csv',
  FORMAT_SUGGESTION 'UNKNOWN',
  MAX_EXAMPLE_BYTES '1048576',
  PARSER 'DISCOVERY',
  SKIP_HEADER 'false'
);

CREATE OR REPLACE FOREIGN STREAM "StreamLab_Output_cellcare"."source_1_fs" (
   "?seq" BIGINT,
   "datetime" VARCHAR(16),
   "imsi" VARCHAR(16),
   "lkey" VARCHAR(16),
   "mme_1.deactivation_trigger" VARCHAR(16),
   "mme_1.deconnect_pdn_type" VARCHAR(16),
   "mme_1.event_id" VARCHAR(16),
   "mme_1.event_result" VARCHAR(8),
   "mme_1.l_cause_prot_type" VARCHAR(8),
   "mme_1.mmei" VARCHAR(16),
   "mme_1.originating_cause_code" VARCHAR(16),
   "mme_1.originating_cause_prot_type" VARCHAR(16),
   "mme_1.pdn_connect_request_type" VARCHAR(8),
   "mme_1.rat" VARCHAR(8),
   "mme_1.sgw" VARCHAR(16),
   "mme_1.ue_requested_apn" VARCHAR(16),
   "postcode" VARCHAR(8)
)
SERVER FILE_SERVER
OPTIONS (
  CHARACTER_ENCODING 'UTF-8',
  DIRECTORY '/home/sqlstream/nigel/Dropbox/github/cellcare',
  FILENAME_PATTERN 'MME_.*\.csv',
  PARSER 'CSV',
  SEPARATOR ',',
  SKIP_HEADER 'true'
);

CREATE OR REPLACE STREAM "StreamLab_Output_cellcare"."source_1_ns" (
   "?seq" BIGINT,
   "datetime" VARCHAR(16),
   "imsi" VARCHAR(16),
   "lkey" VARCHAR(16),
   "mme_1.deactivation_trigger" VARCHAR(16),
   "mme_1.deconnect_pdn_type" VARCHAR(16),
   "mme_1.event_id" VARCHAR(16),
   "mme_1.event_result" VARCHAR(8),
   "mme_1.l_cause_prot_type" VARCHAR(8),
   "mme_1.mmei" VARCHAR(16),
   "mme_1.originating_cause_code" VARCHAR(16),
   "mme_1.originating_cause_prot_type" VARCHAR(16),
   "mme_1.pdn_connect_request_type" VARCHAR(8),
   "mme_1.rat" VARCHAR(8),
   "mme_1.sgw" VARCHAR(16),
   "mme_1.ue_requested_apn" VARCHAR(16),
   "postcode" VARCHAR(8)
);

SET SCHEMA '"StreamLab_Output_cellcare"';
CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_1" AS
SELECT STREAM CHAR_TO_TIMESTAMP('dd/MM/yyyy HH:mm', CAST("datetime" AS VARCHAR(64))) AS "ROWTIME","?seq","imsi","lkey","mme_1.deactivation_trigger","mme_1.deconnect_pdn_type","mme_1.event_id","mme_1.event_result","mme_1.l_cause_prot_type","mme_1.mmei","mme_1.originating_cause_code","mme_1.originating_cause_prot_type","mme_1.pdn_connect_request_type","mme_1.rat","mme_1.sgw","mme_1.ue_requested_apn","postcode"     FROM "StreamLab_Output_cellcare"."source_1_fs" AS "input";

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_2" AS
SELECT STREAM "imsi","lkey","postcode"     FROM "StreamLab_Output_cellcare"."pipeline_1_step_1" AS "input";

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_3" AS
select stream "lkey", listagg("imsi") as subscribers from "StreamLab_Output_cellcare"."pipeline_1_step_2" "input" group by floor("input".rowtime to minute), "lkey";

