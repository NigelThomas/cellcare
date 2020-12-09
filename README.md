# cellcare

* [Introduction](#introduction)
* [Demo description](#demo-description)
* [Running the demo](#running-the-demo)
* [SQLstream schema](#sqlstream-schema)
* [Postgres schema](#postgres-schema)

## Introduction

This is a demo application showing the use of the LISTAGG function.

Incoming 4G data includes the cell_id ("lkey") and subscriber_id ("imsi" in this data, would be "msisdn" in real life).

We perform a tumbling aggregation each minute to generate one row per cell per minute, with a list of the set of subscribers active in that cell in that minute.

If we want to see who was active over a longer period, we can merge the sets of cells. This will make a good case study for the new UDA framework when it is ready in early 2021. Until tthen we can perform that aggregation offline:

* The 1 minute data is saved into Postgres
* A Postgres view allows us to normalise ("unnest") the data set
* We can generate aggregates over any period required by unpivot, aggregate, re-pivot from Postgres.
* We can also combine multiple cells the same way (eg adjacent cells)


## Demo description

* [Streaming LISTAGG in SQLstream](#streaming-listagg-in-SQLstream)
* [Test Data Generation](#test-data-generation)
* [Locating the subscribers](#locating-the-subscribers)

### Streaming LISTAGG in SQLstream

This is implemented in the StreamLab pipeline

* Read from MME input file(s)
* Generate subscriber list per cell, per minute
* write to Postgres table

### Test data generation

* add location (lat,lon,color) to each cell/subscriber record, so we can watch them,
* generate relatively small amount of data for an X by Y grid with N subscribers
  * each subscriber moves randomly (fly walk, wraparound) or remains in place
  * each subscriber may be active or inactive in each cycle
  * for clarity, each subscriber has his own offset in each grid square
  * so each minute we work out where the subscriber is, and whether he is active
  * and we report the active subscribers
* We can centre the grid on a given city location with given size grid and then show cycles on a dashboard

By default `datagen.py` generates 30 1 minute files, with a 5x5 grid and 250 subscribers

```
usage: datagen.py [-h] [-c SUBSCRIBER_COUNT] [-m OUTPUT_MINUTES] [-s SIZE] [-a ACTIVE_PROB] [-w WALK_PROB] [-k] [-n] [-f MME_FILE_PREFIX]

optional arguments:
  -h, --help            					                          show this help message and exit
  -c SUBSCRIBER_COUNT, --subscriber_count SUBSCRIBER_COUNT	number of subscribers to be created (defualt 250)
  -m OUTPUT_MINUTES, --output_minutes OUTPUT_MINUTES	  	  minutes of data (default 30)
  -s SIZE, --size SIZE  					                          size of grid (default 5 square)
  -a ACTIVE_PROB, --active_prob ACTIVE_PROB 			          integer pct probability of activity (default 10%)
  -w WALK_PROB, --walk_prob WALK_PROB 				              integer pct probability of movement (default 20%)
  -x BASE_LONGITUDE, --base_longitude BASE_LONGITUDE        Longitude bottom left
  -y BASE_LATITUDE, --base_latitude BASE_LATITUDE           Latitude bottom left
 -f MME_FILE_PREFIX, --mme_file_prefix MME_FILE_PREFIX      prefix for filename (default MME_gen_) - suffix always .csv
```

#### Locating the subscribers

For London West End we can use a rectangle starting at the Grosvenor Hotel (W -0.156, N 51.510), Each grid rectangle is (W 0.006, N 0.005)

* We want to place subscribers in a grid square so they don't overlap. 
* We divide the grid into z * z = Z squares (where z = ceil(sqrt(N))
* Then place each subscriber into the square (p, q) where p = N mod Z and q = n % Z

* For 5 subscribers, z = 3; for 10 z = 4; for 20 z = 5; etc; for 100 subscribers, z =  10, Z=100; for 250 survivors z = 16

So the final location is:

(X,Y) = (cellx + dx/z * (S# mod Z), celly + dy * (S# % y))

All this is done in the datagen.

## Running the demo

* [Get the Repository](#get-the-repository)
* [Start the docker image](#start-the-docker-image)
* [Generate the test data](#generate-the-test-data)
* [Login to StreamLab](#login-to-streamlab)
* [Open the map and table dashboard](#open-the-map-and-table-dashboard)
* [Stepping through data](#stepping-through-data)
* [Postgres queries](#postgres-queries)

### Get the repository

* Pull this git repo
* change directory into the top of the git working set

### Start the docker image
```
./dockerrun.sh
```
* This will show the log of the image starting up, ending with something like:
```
 Request parallel scheduler with 2 threads, pid = 389                                               INFO [1 2020-12-08 16:07:41.222]: com.sqlstream.aspen.native.sched.internal <native>
 Scheduler starting with 2 execution threads                                                        INFO [1 2020-12-08 16:07:41.223]: com.sqlstream.aspen.native.sched.internal <native>
 Pump SYS_BOOT.MGMT.GLOBAL_TRACE_PUMP is running.                                                   INFO [1 2020-12-08 16:07:42.236]: com.sqlstream.aspen.pump.PumpManager start
 OCCT is turned off                                                                                 INFO [1 2020-12-08 16:07:42.317]: de.simplicit.vjdbc.server.command.CommandProcessor <init>
 Udx FarragoJavaUdxRel.#47:506(recordTraces) runnable 8% waiting for output 0%                      INFO [20 2020-12-08 16:10:00.012]: net.sf.farrago.runtime.FarragoTransformUdx$UdxMonitor logProbeStatisistics
```
* Now Ctrl-C out of the log and connect to the docker container
```
docker exec -it blaze bash
```
* Set up SQLstream environment
```
. /etc/sqlstream/environment
export PATH=$PATH:$SQLSTREAM_HOME/bin
```
### Generate the test data
```
cd /home/sqlstream/cellcare
python3 datagen.py
```
* Note: you could also run datagen from outside the docker container; and you could customize the options used. The /home/sqlstream/cellcare directory is mounted from your git working copy.

### Login to StreamLab
* Start StreamLab by going to http://localhost:5590
* Click on Projects, then click the upload icon next to "Create New Project"
* Drag and drop the `cellcare.slab` file from the got working copy on your host to the landing area
* Accept
* Now you can open the `cellcare` project and navigate to the pipeline
* No data will flow yet; the data in in `/home/sqlstream/cellcare` but the StreamLab project is monitoring `/home/sqlstream/input`

### Open the map and table dashboard
* Open the dashboard by clicking the red eye icon at step 5.
* Click on the URL at the top left of the dashboard
  * this opens a new browser tab with the dashboard only - this can run independently
* Go back to the StreamLab tab and close the dashboard
  * Now the dashboard should show you the end of the pipeline

### Stepping through data

* For each minute, copy a test data file into the `/home/sqlstream/input` directory using the `next` shell script:
```
next
```
  * In StreamLab, you should see a set of cells ("lkey") each with a list of subscribers
  * On the dashboard you can see icons for each subscriber showing his location
  * Icons showing on the display are shown in the table until the subscriber moves location

### Postgres queries
* Demonstrate queries from Postgres for historical data. We have a script for that; `showsubs`:
```
$ showsubs
   lkey   |       period        | occurrences |                     subscribers                     
----------+---------------------+-------------+-----------------------------------------------------
 cell-0-2 | 2020-12-01 00:01:00 |           2 | sub-140,sub-237
 cell-0-3 | 2020-12-01 00:01:00 |           2 | sub-85,sub-123
 cell-1-0 | 2020-12-01 00:01:00 |           1 | sub-150
 cell-1-2 | 2020-12-01 00:01:00 |           2 | sub-5,sub-169
 cell-1-3 | 2020-12-01 00:01:00 |           3 | sub-133,sub-203,sub-214
etc
```

* Using PostgreSQL this data can easily be "normalised" using `showsubnormal` to return one row per unique lkey/subscriber:
```
$ showsubsnormal
   lkey   |       period        | subscriber 
----------+---------------------+------------
 cell-4-3 | 2020-12-01 00:02:00 | sub-0
 cell-4-3 | 2020-12-01 00:02:00 | sub-157
 cell-3-2 | 2020-12-01 00:02:00 | sub-5
 cell-1-1 | 2020-12-01 00:02:00 | sub-25
 cell-2-0 | 2020-12-01 00:02:00 | sub-41
 cell-0-3 | 2020-12-01 00:02:00 | sub-50
 cell-0-3 | 2020-12-01 00:02:00 | sub-68
 cell-0-3 | 2020-12-01 00:02:00 | sub-162
 cell-1-0 | 2020-12-01 00:02:00 | sub-53
 cell-1-0 | 2020-12-01 00:02:00 | sub-75
 cell-1-0 | 2020-12-01 00:02:00 | sub-113
```
* Combine data from multiple time periods in a minute using `showcell`
  * This example combines 2 one-minute periods ending at 00:03 (so 00:02 to 00:03)
```
showcell cell-3-1 3 2
SET
 subs for cell-3-1 for 2 mins up to 00:03 inclusive 
----------------------------------------------------
 sub-184,sub-247,sub-125
(1 row)

```
* Similar functions could deal with combining data from neighbouring cells


## SQLstream schema

* created by `cellcare.sql`
* or imported to StreamLab from `cellcare.slab`

## Postgres schema

* created by cellcare.psql
* tested by pgtests.psql

Includes a function "get_subscribers" which returns a list of subscribers for a given cell, over a range of minutes



