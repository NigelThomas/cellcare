# cellcare

* [Introduction](#introduction)
* [Demo description](#demo-description)
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
* [Visualization](#visualization)
* [Stepping through a demo](#stepping-through-a-demo)

### Streaming LISTAGG in SQLstream

* Read from MME input file(s)
* Generate subscriber list per cell, per minute (done)
* write to Postgres (TO DO)

### Test data generation

* add location to each cell/subscriber record, so we can watch then
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
  -h, --help            					show this help message and exit
  -c SUBSCRIBER_COUNT, --subscriber_count SUBSCRIBER_COUNT	number of subscribers to be created (defualt 250)
  -m OUTPUT_MINUTES, --output_minutes OUTPUT_MINUTES		minutes of data (default 30)
  -s SIZE, --size SIZE  					size of grid (default 5 square)
  -a ACTIVE_PROB, --active_prob ACTIVE_PROB 			integer pct probability of activity (default 10%)
  -w WALK_PROB, --walk_prob WALK_PROB 				integer pct probability of movement (default 20%)
  -f MME_FILE_PREFIX, --mme_file_prefix MME_FILE_PREFIX         prefix for filename (default MME_gen_) - suffix always .csv
```

### Visualization

* Show the input data on a map dashboard
* If we make the color map to each minute, and retain all icons, we can distinguish new and old pins (each minute we see a new colour)

### Stepping through a demo

* Create a data file for each minute sing the data generator
  * Include a dummy entry for the next minute to act as a rowrime bound
* For each minute, drop test data file into the input directory
* You can see icons moving on the grid; you can see the new lists of subscribers in a tabular dashboard
  * You can check that icons showing on the display are shown in the table until they age out
* Demonstrate queries from Postgres for historical data
  * Use get_subscribers(period, cell, intervalmins)


## SQLstream schema

* created by `cellcare.sql`
* or imported to StreamLab from `cellcare.slab`

## Postgres schema

* created by cellcare.psql
* tested by pgtests.psql

Includes a function "get_subscribers" which returns a list of subscribers for a given cell, over a range of minutes



