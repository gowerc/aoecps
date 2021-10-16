import requests
import json

VERSION = "C"


def api_get_meta(game="aoe2de", language="en"):
    params = {
        "game": game,
        "language": language
    }
    resp = requests.get("https://aoe2.net/api/strings", params)
    resp.raise_for_status()
    return resp.json()


meta = api_get_meta()

result = {
    "string": [],
    "id": [],
    "type": []
}

for i in meta.keys():
    if i == "language":
        continue
    for d in meta[i]:
        result["string"].append(d["string"])
        result["id"].append(d["id"])
        result["type"].append(i)


with open("./data-raw/db_meta.json", "r") as fi:
    final = json.load(fi)

final[VERSION] = result

with open("./data-raw/db_meta.json", "w") as fi:
    json.dump(final, fi, indent="    ", separators=(',', ":"))
