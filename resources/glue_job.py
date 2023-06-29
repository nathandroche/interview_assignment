import pandas as pd

METERS_TO_FEET = 3.28084

df = pd.read_json("source_data.json")


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

df.to_json("output_data.json")


