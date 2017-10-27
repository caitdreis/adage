'''
This code is used to collect datasets from the ArrayExpress database. We only focused on 
one pseudomonas array platform by Affymetirx "A-AFFY-30". It will print the url of the zip
file of raw data for all experiments measured on this platform. 
'''
urllib.request and urllib.error
from urllib.request import urlopen #have to do this with python version 3
import json

json_uh = urlopen("http://www.ebi.ac.uk/arrayexpress/json/v2/files?array=A-AFFY-30")
data_jsonstr = json_uh.read()
json_uh.close()
data = json.loads(data_jsonstr)

for experiment in data['files']['experiment']:
    files = experiment['file']
    for fobj in files:
        if fobj['kind'] == 'raw':
            print(fobj['url'])
