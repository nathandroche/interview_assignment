

import sys
import s3fs
import pandas as pd
from awsglue.utils import getResolvedOptions


METERS_TO_FEET = 3.28084

args = getResolvedOptions(sys.argv, ["BUCKET_NAME","input_file", "output_file", "key", "secret_key"])
s3 = s3fs.S3FileSystem(anon=False, key=args["key"], secret=args["secret_key"])

with s3.open(f'{args["BUCKET_NAME"]}/{args["input_file"]}', mode="r") as f:
    df = pd.read_json(f)


def transform(pokedex_entry_list):
    pokedex_entry = pokedex_entry_list["pokemon"]
    if "height" in pokedex_entry.keys():
        height_str = pokedex_entry["height"].split()[0]
        height_in_ft = round(float(height_str)*METERS_TO_FEET, 2)
        pokedex_entry["height"] = str(height_in_ft) + " ft"
    else:
        Warning.warn(f'could not find height in pokedex entry: {pokedex_entry}')
    return pokedex_entry

df.apply(transform, axis=1)

with s3.open(f'{args["BUCKET_NAME"]}/{args["output_file"]}', mode="w") as f:
    df.to_json(f)


