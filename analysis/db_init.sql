CREATE TABLE IF NOT EXISTS public.match_meta (
    match_id text,
    lobby_id text,
    match_uuid text,
    version text,
    name text,
    num_players integer,
    num_slots integer,
    average_rating integer,
    cheats boolean,
    full_tech_tree boolean,
    ending_age integer,
    expansion boolean,
    game_type integer,
    has_custom_content boolean,
    has_password boolean,
    lock_speed boolean,
    lock_teams boolean,
    map_size integer,
    map_type integer,
    pop integer,
    ranked boolean,
    leaderboard_id integer,
    rating_type integer,
    resources integer,
    rms text,
    scenario text,
    server text,
    shared_exploration boolean,
    speed integer,
    starting_age integer,
    team_together boolean,
    team_positions boolean,
    treaty_length integer,
    turbo boolean,
    victory integer,
    victory_time integer,
    visibility integer,
    opened integer,
    started integer,
    finished integer,
    PRIMARY KEY (match_id)
);

CREATE TABLE IF NOT EXISTS public.match_players (
    match_id text,
    profile_id integer,
    steam_id text,
    name text,
    clan boolean,
    country text,
    slot integer,
    slot_type integer,
    rating integer,
    rating_change integer,
    games boolean,
    wins boolean,
    streak boolean,
    drops boolean,
    color integer,
    team integer,
    civ integer,
    won boolean,
    PRIMARY KEY (match_id, profile_id),
    CONSTRAINT fk_matchid
      FOREIGN KEY(match_id) 
        REFERENCES match_meta(match_id)
);


CREATE TABLE IF NOT EXISTS public.game_meta (
    version text,
    type text,
    id integer,
    string text,
    PRIMARY KEY (version, type, id)
);

