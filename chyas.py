# %%
from io import StringIO as strio
from pathlib import Path

import chess
import chess.engine
import chess.pgn
import kagglehub as kgl
import pandas as pd

# %%
remote = kgl.dataset_download("datasnaek/chess")
df = pd.read_csv(f"{remote}/games.csv")
df_moves = df.moves  # 데이터에서 필요한 것만 추출한다.
df_moves[0]


# %%
def anls(
    df: pandas.DataFrame,
    engine: chess.engine.SimpleEngine,
    limit: chess.eingine.Limit = chess.engine.Limit(time=1),
    model: str = "",
) -> pandas.DataFrame:

    cache = Path(f"./out/anly_{engine.id.get('name')}.csv")

    if cache.exists():
        df = pd.read_csv(cache)
    else:
        if model:
            engine.configure({"WeightsFile": model})
        for i in df.index:
            anal = engine.analyse(df.board.loc[i], limit=limit)
            df.loc[i, ["score"]] = anal["score"].relative.cp
            df.at[i, "pv"] = anal["pv"]

        df.to_csv(cache)

    return df


# %%
game = chess.pgn.read_game(strio(df_moves[0]))
board = game.board()
sfish = chess.engine.SimpleEngine.popen_uci("./engines/stockfish")
lczero = chess.engine.SimpleEngine.popen_uci("./engines/lc0")
# lczero 개체는 호출 시에 모델을 적용하도록 한다.

anal_df = pd.DataFrame(columns=["move", "board", "score", "pv"])

# %%
anal_df.move = df_moves[0].split(" ")
anal_df

# %%
for i, move in enumerate(game.mainline_moves()):
    board.push(move)
    anal_df.loc[i, ["board"]] = board.copy()

# %%
anal_df.board.loc[4]

# %%
# anal에서 필요한 거: score, pv
anal_df = anls(anal_df, sfish)
anal_df

# %%
anal_df2 = anal_df.copy()
model = "./model/model_heavy.pb.gz"
# lczero.configure({"WeightsFile": model})

anal_df2 = anls(
    df=anal_df2, engine=lczero, model=model, limit=chess.engine.Limit(time=5)
)
anal_df2

# %%
anly_df3 = anls(df=anal_df, engine=lczero, model="./model/model_2200.pb.gz")
anly_df3

# %%
import seaborn as sns
from matplotlib import pyplot as plt

# %%
plt.plot(anal_df.score)
# score 데이터가 양수면 백이, 음수면 흑이 유리함을 나타낸다.
# 즉 지그재그를 그리고 있으면 백과 흑 선수 서로 못 둔다고 봐야할까?

# %%
plt.plot(anal_df2.score)

# %%
plt.plot(anly_df3.score)
