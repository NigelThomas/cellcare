!set force on
ALTER PUMP "StreamLab_Output_cellcare".* STOP;
ALTER STREAM "StreamLab_Output_cellcare".* RESET;
DROP SCHEMA "StreamLab_Output_cellcare" CASCADE;
!set force off

CREATE OR REPLACE SCHEMA "StreamLab_Output_cellcare";
ALTER PUMP "StreamLab_Output_cellcare".* STOP;
ALTER STREAM "StreamLab_Output_cellcare".* RESET;

--  StreamApp start


--  PostgreSQL server

CREATE OR REPLACE SERVER "PostgreSQL_DB_1_cellcare"
    FOREIGN DATA WRAPPER "SYS_JDBC"
    OPTIONS (
        "URL" 'jdbc:postgresql://localhost/demo',
        "USER_NAME" 'demo',
        "PASSWORD" 'demodemo',
        "SCHEMA_NAME" 'cellcare',
        "DIALECT" 'PostgreSQL',
        "JNDI_WRITEBACK" 'true',
        "pollingInterval" '1000',
        "txInterval" '1000',

        "DRIVER_CLASS" 'org.postgresql.Driver'
    );

--  ECDA reading adapter/agent with Discovery support


--  Throttling is disabled globally in the project settings

CREATE OR REPLACE FOREIGN STREAM "StreamLab_Output_cellcare"."data_1_fs"
(
    "seq" INTEGER,
    "datetime" VARCHAR(16),
    "imsi" VARCHAR(8),
    "lkey" VARCHAR(8),
    "mme_1.deactivation_trigger" VARCHAR(16),
    "mme_1.deconnect_pdn_type" VARCHAR(16),
    "mme_1.event_id" VARCHAR(16),
    "mme_1.event_result" VARCHAR(8),
    "mme_1.l_cause_prot_type" VARCHAR(4),
    "mme_1.mmei" VARCHAR(8),
    "mme_1.originating_cause_code" VARCHAR(16),
    "mme_1.originating_cause_prot_type" VARCHAR(16),
    "mme_1.pdn_connect_request_type" VARCHAR(8),
    "mme_1.rat" VARCHAR(8),
    "mme_1.sgw" VARCHAR(16),
    "mme_1.ue_requested_apn" VARCHAR(16),
    "postcode" VARCHAR(8),
    "lat" DOUBLE,
    "lon" DOUBLE,
    "color" TINYINT
)

    SERVER "FILE_SERVER"

OPTIONS (
"PARSER" 'CSV',
        "CHARACTER_ENCODING" 'UTF-8',
        "SEPARATOR" ',',
        "SKIP_HEADER" 'true',

        "DIRECTORY" '/home/sqlstream/input',
        "FILENAME_PATTERN" 'MME_gen.*\.csv'

);
CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."data_1" AS
SELECT STREAM * FROM "StreamLab_Output_cellcare"."data_1_fs";

--  External table

CREATE OR REPLACE FOREIGN TABLE "StreamLab_Output_cellcare"."period_cell_subscribers_packed" ("lkey" VARCHAR(16),
    "period" TIMESTAMP,
    "occurrences" INTEGER,
    "subscribers" VARCHAR(1024))
SERVER "PostgreSQL_DB_1_cellcare"
OPTIONS (
    "SCHEMA_NAME" 'cellcare',
    "TABLE_NAME" 'period_cell_subscribers_packed',

    "TRANSACTION_ROW_LIMIT" '0',
    "TRANSACTION_ROWTIME_LIMIT" '1000'
);

--  Filter Operation

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_1" AS
    SELECT STREAM *
    FROM "StreamLab_Output_cellcare"."data_1" AS "input"
    WHERE NOT ("lat" = 0);

--  Timestamp Operation

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_2" AS
    SELECT STREAM CHAR_TO_TIMESTAMP('dd/MM/yyy HH:mm', CAST("datetime" AS VARCHAR(64))) AS "ROWTIME","seq","imsi","lkey","mme_1.deactivation_trigger","mme_1.deconnect_pdn_type","mme_1.event_id","mme_1.event_result","mme_1.l_cause_prot_type","mme_1.mmei","mme_1.originating_cause_code","mme_1.originating_cause_prot_type","mme_1.pdn_connect_request_type","mme_1.rat","mme_1.sgw","mme_1.ue_requested_apn","postcode","lat","lon","color"
    FROM "StreamLab_Output_cellcare"."pipeline_1_step_1" AS "input";

--  Drop Operation

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_3" AS
    SELECT STREAM "seq","imsi","lkey","lat","lon","color"
    FROM "StreamLab_Output_cellcare"."pipeline_1_step_2" AS "input";

--  New Column Operation

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_4" AS
    SELECT STREAM
           1 AS "size", *
    FROM "StreamLab_Output_cellcare"."pipeline_1_step_3" AS "input";

--  Map and Table Dashboard

CREATE OR REPLACE STREAM "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_5"(
"size" INTEGER NOT NULL, "seq" INTEGER, "imsi" VARCHAR(8), "lkey" VARCHAR(8), "lat" DOUBLE, "lon" DOUBLE, "color" TINYINT);
CREATE OR REPLACE PUMP "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_5-Pump" STOPPED AS
INSERT INTO "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_5" 
SELECT STREAM * FROM "StreamLab_Output_cellcare"."pipeline_1_step_4" AS "input";

--  Custom SQL view

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_6" AS

    select stream "lkey",count(*) as "occurrences",listagg("imsi",',') as "subscribers" from "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_5" s group by floor(s.rowtime to minute),"lkey";

--  New Column Operation

CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_step_7" AS
    SELECT STREAM
           "input"."ROWTIME" AS "period", *
    FROM "StreamLab_Output_cellcare"."pipeline_1_step_6" AS "input";

CREATE OR REPLACE STREAM "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_8"(
"period" TIMESTAMP NOT NULL, "lkey" VARCHAR(8), "occurrences" BIGINT NOT NULL, "subscribers" VARCHAR(4096) NOT NULL);

CREATE OR REPLACE PUMP "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_8-Pump" STOPPED AS
INSERT INTO "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_8" 
SELECT STREAM * FROM "StreamLab_Output_cellcare"."pipeline_1_step_7" AS "input";

--  External table

CREATE OR REPLACE FOREIGN TABLE "StreamLab_Output_cellcare"."period_cell_subscribers_packed" ("lkey" VARCHAR(16),
    "period" TIMESTAMP,
    "occurrences" INTEGER,
    "subscribers" VARCHAR(1024))
SERVER "PostgreSQL_DB_1_cellcare"
OPTIONS (
    "SCHEMA_NAME" 'cellcare',
    "TABLE_NAME" 'period_cell_subscribers_packed',

    "TRANSACTION_ROW_LIMIT" '0',
    "TRANSACTION_ROWTIME_LIMIT" '1000'
);

--  Define the pump

CREATE OR REPLACE PUMP "StreamLab_Output_cellcare"."pipeline_1_step_9-to-period_cell_subscribers_packed-Pump" STOPPED AS
MERGE INTO "StreamLab_Output_cellcare"."period_cell_subscribers_packed"  AS "sink"
    USING (SELECT STREAM CAST("lkey" AS VARCHAR(16)) AS "lkey", CAST("period" AS TIMESTAMP) AS "period", CAST("occurrences" AS INTEGER) AS "occurrences", CAST("subscribers" AS VARCHAR(1024)) AS "subscribers" FROM "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_8") AS "input"
    ON ("sink"."lkey" = "input"."lkey") AND ("sink"."period" = "input"."period")
WHEN MATCHED THEN
    UPDATE SET "occurrences" = "input"."occurrences", "subscribers" = "input"."subscribers"
WHEN NOT MATCHED THEN
    INSERT ("lkey", "period", "occurrences", "subscribers")
    VALUES ("lkey", "period", "occurrences", "subscribers");
CREATE OR REPLACE VIEW "StreamLab_Output_cellcare"."pipeline_1_out" AS 
SELECT STREAM * FROM "StreamLab_Output_cellcare"."dashboard_pipeline_1_step_8";

--  StreamApp end

ALTER PUMP "StreamLab_Output_cellcare".* START;

