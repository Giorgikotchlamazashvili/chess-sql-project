-- renaming columns in the chess table for consistency
exec sp_rename 'chess.dbo.chess_table.[white player]', 'white_player', 'column';
exec sp_rename 'chess.dbo.chess_table.[black player]', 'black_player', 'column';
exec sp_rename 'chess.dbo.chess_table.[white elo]', 'white_elo', 'column';
exec sp_rename 'chess.dbo.chess_table.[black elo]', 'black_elo', 'column';
exec sp_rename 'chess.dbo.chess_table.[white rating diff]', 'white_rating_diff', 'column';
exec sp_rename 'chess.dbo.chess_table.[black rating diff]', 'black_rating_diff', 'column';

-- creating a table to store player details
create table chess.dbo.players (
    player_id int identity(1,1) primary key,
    player_name nvarchar(255) not null unique
);

-- creating a table to store game details
create table chess.dbo.games (
    game_id int identity(1,1) primary key,
    event nvarchar(255),
    site nvarchar(255),
    date date,
    time time,
    result nvarchar(10),
    eco nvarchar(10),
    opening nvarchar(255),
    timecontrol nvarchar(50),
    termination nvarchar(50),
    moves nvarchar(max)
);

-- creating a table to store player-game relationships and ratings
create table chess.dbo.game_players (
    game_player_id int identity(1,1) primary key,
    game_id int not null foreign key references chess.dbo.games(game_id),
    player_id int not null foreign key references chess.dbo.players(player_id),
    role nvarchar(50) check (role in ('white', 'black')),
    elo_before int,
    elo_after int,
    rating_diff int
);

-- inserting unique player names into the players table from the chess table
insert into chess.dbo.players (player_name)
select distinct player_name
from (
    select white_player as player_name from chess.dbo.chess_table
    union
    select black_player as player_name from chess.dbo.chess_table
) as combined_players;

-- inserting game details into the games table
insert into chess.dbo.games (event, site, date, time, result, eco, opening, timecontrol, termination, moves)
select distinct 
    event, 
    site, 
    cast(date as date) as date, 
    cast(time as time) as time, 
    case 
        when trim(result) = '1-0' then 'white_won' 
        when trim(result) = '0-1' then 'black_won' 
        when trim(result) = '1/2-1/2' then 'draw' 
    end as result, 
    eco, 
    opening, 
    timecontrol, 
    termination, 
    moves
from chess.dbo.chess_table;

-- inserting player-specific data into the game_players table
insert into chess.dbo.game_players (game_id, player_id, role, elo_before, elo_after, rating_diff)
select 
    g.game_id, 
    p.player_id, 
    'white' as role, 
    ct.white_elo, 
    ct.white_elo + cast(ct.white_rating_diff as int) as elo_after, 
    cast(ct.white_rating_diff as int) as rating_diff
from chess.dbo.chess_table ct
join chess.dbo.players p on ct.white_player = p.player_name
join chess.dbo.games g on ct.event = g.event 
           and ct.site = g.site 
           and cast(ct.date as date) = g.date 
           and cast(ct.time as time) = g.time
union all
select 
    g.game_id, 
    p.player_id, 
    'black' as role, 
    ct.black_elo, 
    ct.black_elo + cast(ct.black_rating_diff as int) as elo_after, 
    cast(ct.black_rating_diff as int) as rating_diff
from chess.dbo.chess_table ct
join chess.dbo.players p on ct.black_player = p.player_name
join chess.dbo.games g on ct.event = g.event 
           and ct.site = g.site 
           and cast(ct.date as date) = g.date 
           and cast(ct.time as time) = g.time;

-- creating indexes to optimize queries on the game_players and games tables
create index idx_game_id on chess.dbo.game_players(game_id);
create index idx_player_id on chess.dbo.game_players(player_id);
create index idx_result on chess.dbo.games(result);
create index idx_event_site on chess.dbo.games(event, site);
create index idx_game_date_time on chess.dbo.games(date, time);
create index idx_player_name on chess.dbo.players(player_name);
