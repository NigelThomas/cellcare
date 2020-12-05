# cellcare

This is a demo application showing the use of the LISTAGG function.

Incoming 4G data includes the cell_id ("lkey") and subscriber_id ("imsi" in this data, would be "msisdn" in real life).

We perform a tumbling aggregation each minute to generate one row per cell per minute, with a list of the set of subscribers active in that cell in that minute.

If we want to see who was active over a longer period, we can merge the sets of cells. This will make a good case study for the new UDA framework when it is ready in early 2021. Until tthen we can perform that aggregation offline:

* The 1 minute data is saved into Postgres
* A Postgres view allows us to normalise ("unnest") the data set
* We can generate aggregates over any period required by unpivot, aggregate, re-pivot from Postgres.
* We can also combine multiple cells the same way (eg adjacent cells)



