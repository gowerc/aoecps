
import support.api
import support
import pandas as pd
import datetime



def matches_to_pd(vars):
    HOLD = {}
    for i in vars:
        HOLD[i] = [x[i] for x in matches]
    return pd.DataFrame(HOLD)


def players_to_pd(vars_match = [], vars = []):
    HOLD = {}
    for i in vars_match:
        HOLD["m_" + i] = [y[i] for y in matches for x in y["players"]]
    for i in vars:
        HOLD["p_" + i] = [x[i] for y in matches for x in y["players"]]
    return pd.DataFrame(HOLD)


def meta_to_pd():
    HOLD = {"id":[], "string":[], "key" :[]}
    for i in meta.keys():
        if i == "language": 
            continue
        for j in meta[i]:
            HOLD["id"].append(j["id"])
            HOLD["string"].append(j["string"])
            HOLD["key"].append(i)
    return pd.DataFrame(HOLD)



pd.set_option("display.max_rows", None, "display.max_columns", None)


from shutil import get_terminal_size
pd.set_option('display.width', get_terminal_size()[0])

meta = support.api.get_meta()
dt_limit = support.as_seconds(datetime.datetime.now() - datetime.timedelta(hours=170))
matches = support.api.get_matches(dt_limit, 200)




meta_df = meta_to_pd()

meta.keys()

meta_df.query("key == 'game_type'")
meta_df.query("key == 'age'")
meta_df.query("key == 'leaderboard'")
meta_df.query("key == 'rating_type'")
meta_df.query("key == 'resources'")
meta_df.query("key == 'map_type'")
meta_df.query("key == 'speed'")
meta_df.query("key == 'visibility'")
meta_df.query("key == 'victory'")
meta_df.query("key == 'civ'")
meta_df.query("key == 'country'")

matches_df = matches_to_pd(
    ["leaderboard_id", "rating_type", "game_type",  "victory", "victory_time"]
)
matches_df.sample(300)

matches_df[matches_df["version"].isnull()]
matches_df[matches_df["version"].notnull()].sample(40)






matches_df.query("num_players != num_slots").sample(40)


matches_df = matches_to_pd(["victory", "leaderboard_id", "game_type",])
matches_df.sample(40)


for i in sorted(matches[1]["players"][1].keys()):
    print(i)




x = players_to_pd(
    ["treaty_length", "leaderboard_id", "rating_type", "name", "victory"],
    ["slot_type", "won", "slot", "team"]
)


x[x["m_name"] == "Salaif's Game"]
sample(40)




players_to_pd(
    [],
    ["civ", "name", "slot_type"]
)


1633629319 - 1633794072

(1633629424 - 1633794072)  / (60 * 60)


(1634240261 - 1634240526) / (60)
(1634238352 - 1634239599) / (60)
(1634240244 - 1634240974) / (60)