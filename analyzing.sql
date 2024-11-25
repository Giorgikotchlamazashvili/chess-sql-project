-- finding the top player's winning precentage
select 
    p.player_name,
    coalesce(sum(case 
        when gp.role = 'white' and g.result = 'white_won' then 1
        when gp.role = 'black' and g.result = 'black_won' then 1 
    end), 0) as wins,
    count(gp.game_id) as total_games,
    round(coalesce(sum(case 
        when gp.role = 'white' and g.result = 'white_won' then 1
        when gp.role = 'black' and g.result = 'black_won' then 1 
    end), 0) * 100.0 / 
    nullif(count(gp.game_id), 0), 2) as win_percentage
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
join chess.dbo.games g on gp.game_id = g.game_id
group by p.player_name
order by win_percentage desc, total_games desc;

--white winning precentage by opening
select 
    (sum(case when result = 'white_won' then 1 else 0 end) * 100.0) / count(result) as white_win_prec_by_opening,
    opening
from chess.dbo.games
group by opening
order by white_win_prec_by_opening desc;
--black winning precentage by openning
select 
    (sum(case when result = 'black_won' then 1 else 0 end) * 100.0) / count(result) as black_win_prec_by_opening,
    opening
from chess.dbo.games
group by opening
order by black_win_prec_by_opening desc;
-- draw precentage by openning
select 
    (sum(case when result = 'draw' then 1 else 0 end) * 100.0) / count(result) as draw_prec_by_opening,
    opening
from chess.dbo.games
group by opening
order by draw_prec_by_opening desc;
--a player's elo progression over time
select 
    g.date,
	g.time,
    p.player_name,
    gp.role,
    gp.elo_before,
    gp.elo_after
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
join chess.dbo.games g on gp.game_id = g.game_id
where p.player_name = 'Marzinkus'
order by g.date , g.time;
--top 10 players by total games played
select
    p.player_name,
    count(gp.game_id) as total_games
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
group by p.player_name
order by total_games desc
offset 0 rows fetch next 10 rows only;
--average elo vhange by player
select 
    p.player_name,
    avg(abs(gp.rating_diff)) as avg_elo_change
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
group by p.player_name
order by avg_elo_change desc;
--most played openings
select 
    g.opening,
    count(g.game_id) as games_played
from chess.dbo.games g
group by g.opening
order by games_played desc;
--elo gaps between players
select 
    g.date,
    g.opening,
    p1.player_name as white_player,
    p2.player_name as black_player,
    gp1.elo_before as white_elo,
    gp2.elo_before as black_elo,
    abs(gp1.elo_before - gp2.elo_before) as elo_gap,
    g.result
from chess.dbo.games g
join chess.dbo.game_players gp1 on g.game_id = gp1.game_id and gp1.role = 'white'
join chess.dbo.players p1 on gp1.player_id = p1.player_id
join chess.dbo.game_players gp2 on g.game_id = gp2.game_id and gp2.role = 'black'
join chess.dbo.players p2 on gp2.player_id = p2.player_id
order by elo_gap desc;
--players with the most draws
select 
    p.player_name,
    count(gp.game_id) as total_draws
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
join chess.dbo.games g on gp.game_id = g.game_id
where g.result = 'draw'
group by p.player_name
order by total_draws desc;
--players that played together the most 
select 
    p1.player_name as player_1,
    p2.player_name as player_2,
    count(*) as games_played_together
from chess.dbo.games g
join chess.dbo.game_players gp1 on g.game_id = gp1.game_id and gp1.role = 'white'
join chess.dbo.players p1 on gp1.player_id = p1.player_id
join chess.dbo.game_players gp2 on g.game_id = gp2.game_id and gp2.role = 'black'
join chess.dbo.players p2 on gp2.player_id = p2.player_id
group by p1.player_name, p2.player_name
order by games_played_together desc;
--longest games based on moves
select 
    g.game_id,
    g.opening,
    len(g.moves) - len(replace(g.moves, ' ', '')) + 1 as total_moves,
    g.date
from chess.dbo.games g
order by total_moves desc;
--longest winning streak by a player
with streaks as (
    select 
        p.player_name,
        g.date,
        case when gp.role = 'white' and g.result = 'white_won' then 1
             when gp.role = 'black' and g.result = 'black_won' then 1
             else 0 end as win_flag,
        row_number() over (partition by p.player_name order by g.date) - 
        sum(case when gp.role = 'white' and g.result = 'white_won' then 1
                 when gp.role = 'black' and g.result = 'black_won' then 1
                 else 0 end) over (partition by p.player_name order by g.date) as streak_id
    from chess.dbo.players p
    join chess.dbo.game_players gp on p.player_id = gp.player_id
    join chess.dbo.games g on gp.game_id = g.game_id
)
select 
    player_name,
    count(*) as longest_streak
from streaks
where win_flag = 1
group by player_name, streak_id
order by longest_streak desc;
--white and black elo averages 
select 
    avg(case when gp.role = 'white' then gp.elo_before else null end) as avg_white_elo,
    avg(case when gp.role = 'black' then gp.elo_before else null end) as avg_black_elo
from chess.dbo.game_players gp;
--best opponent against strong players
select 
    p.player_name,
    count(gp.game_id) as games_played,
    count(case when g.result = 'white_won' and gp.role = 'white' then 1 
               when g.result = 'black_won' and gp.role = 'black' then 1 end) as wins,
    avg(case when gp.role = 'white' then gp.elo_before else gp.elo_after end) as avg_opponent_elo
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
join chess.dbo.games g on gp.game_id = g.game_id
where gp.elo_before > 2400 
group by p.player_name
order by avg_opponent_elo desc, wins desc;
--correlation between average elo and win rate
select 
    p.player_name,
    avg(gp.elo_before) as avg_elo,
    (count(case when gp.role = 'white' and g.result = 'white_won' then 1 
                when gp.role = 'black' and g.result = 'black_won' then 1 end) * 100.0) /
    count(gp.game_id) as win_rate
from chess.dbo.players p
join chess.dbo.game_players gp on p.player_id = gp.player_id
join chess.dbo.games g on gp.game_id = g.game_id
group by p.player_name
order by avg_elo desc;
--win rate and draw rate by event
select 
    event,
    sum(case when result = 'white_won' then 1 else 0 end) * 100.0 / count(*) as white_win_rate,
    sum(case when result = 'black_won' then 1 else 0 end) * 100.0 / count(*) as black_win_rate,
    sum(case when result = 'draw' then 1 else 0 end) * 100.0 / count(*) as draw_rate,
    count(*) as total_games
from chess.dbo.games
group by event
order by total_games desc, white_win_rate desc;

