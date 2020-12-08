import random
import argparse
import csv
import math
from datetime import date, time, datetime, timedelta

parser = argparse.ArgumentParser()
parser.add_argument("-c","--subscriber_count", type=int, default=250, help="number of subscribers to be created")
parser.add_argument("-m","--output_minutes", type=int, default=30, help="minutes of data")
parser.add_argument("-s","--size", type=int, default=5, help="size of grid")
parser.add_argument("-a","--active_prob", type=int, default=10, help="integer pct probability of activity")
parser.add_argument("-w","--walk_prob", type=int, default=20, help="integer pct probability of movement")
parser.add_argument("-x","--base_longitude", type=float, default=-0.157, help="Longitude bottom left")
parser.add_argument("-y","--base_latitude", type=float, default=51.523, help="Latitude bottom left")
parser.add_argument( "-k", "--trickle", default=True, action='store_true', help="Trickle one second of data each second")
parser.add_argument( "-n", "--no_trickle", default=False, dest='trickle', action='store_false', help="No trickling - emit data immediately")

parser.add_argument('-f', '--mme_file_prefix', default='MME_gen', help='output: generated file of MME data')

args = parser.parse_args()

# MME format - we are only interested in datetime,insi, lkey
# seq,datetime,imsi,lkey,mme_1.deactivation_trigger,mme_1.deconnect_pdn_type,mme_1.event_id,mme_1.event_result,mme_1.l_cause_prot_type,mme_1.mmei,mme_1.originating_cause_code,mme_1.originating_cause_prot_type,mme_1.pdn_connect_request_type,mme_1.rat,mme_1.sgw,mme_1.ue_requested_apn,postcode

# we will also add lat-lon coordinates and color at the end for demo purposes

trailing_fields = 'hlr_or_hss,mme_initiated,deactivate,ignore,nas,65532-80,undefined,undefined,handover,wcdma,172.26.52.177,mobile.o2.co.uk,HA9 0WS'

subscribers = []
recno = 0

# number of subdivisions x,y in each grid square to display subscribers
subsize = math.ceil(math.sqrt(args.subscriber_count))
# bottom left of display (London West End)
baseLat = args.base_latitude
baseLon = args.base_longitude
# size of grid squares
gridDeltaLon = 0.006
gridDeltaLat = 0.004
# size of sub-cells within each grid cell
subDeltaLon = gridDeltaLon/subsize
subDeltaLat = gridDeltaLat/subsize

for s in range(0,args.subscriber_count):
    sub = { 'no':s \
          , 'name': 'sub-'+str(s) \
          , 'x': random.randint(0,args.size - 1) \
          , 'y': random.randint(0,args.size - 1) 
          , 'sx': (s % subsize) * subDeltaLon
          , 'sy': int(s / subsize) * subDeltaLat
        }

    subscribers.append(sub)

# set starting time
current_ts = datetime(year=2020, month=12, day=1, hour=0, minute=0, second=0)  
ts_format = '%d/%m/%Y %H:%M'
color = 0

for m in range(0,args.output_minutes):
    # start a new file for each minute
    # TODO get the name sorted
    fname = args.mme_file_prefix + '{0:0>4}'.format(m) + '.csv'
    
    mf = open(fname, "w")
    mf.write("seq,datetime,imsi,lkey,mme_1.deactivation_trigger,mme_1.deconnect_pdn_type,mme_1.event_id,mme_1.event_result,mme_1.l_cause_prot_type,mme_1.mmei,mme_1.originating_cause_code,mme_1.originating_cause_prot_type,mme_1.pdn_connect_request_type,mme_1.rat,mme_1.sgw,mme_1.ue_requested_apn,postcode,lat,lon,color\n")

    # change colour each minute in rotation
    color = (color + 1) % 10

    # write a record (or not) for each subscriber and decide where they go next
    
    for sub in subscribers:

        # is the subscriber active? 
        if (random.randint(0,99) < args.active_prob):
            # write out the record and current location
            # TODO add trailing fields
            lat = baseLat + sub['y'] * gridDeltaLat + sub['sy']
            lon = baseLon + sub['x'] * gridDeltaLon + sub['sx']
            mf.write('%d,%s,%s,cell-%d-%d,%s,%f,%f,%d\n' % (recno,current_ts.strftime(ts_format),sub['name'],sub['y'],sub['x'],trailing_fields,lat,lon,color))
            recno += 1
        # should the subscriber move?

        if (random.randint(0,99) < args.walk_prob):
            # 2 directional random work zero or +/- one step each
            # So there is a 1/9 chance of not moving even when a move is selected
            sub['x'] = (sub['x'] + random.randint(0,2) - 1) % args.size;
            sub['y'] = (sub['y'] + random.randint(0,2) - 1) % args.size;

    # increment the time by one minute
    current_ts = current_ts + timedelta(minutes=1)

    # and write a rowtime bound record - no subscriber or cell for demo progression
    mf.write('%d,%s,XX,XX,%s,0.0,0.0,0\n' % (recno,current_ts.strftime(ts_format),trailing_fields))

    mf.close()
