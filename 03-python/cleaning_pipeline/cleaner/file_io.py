import logging
import os

import pandas as pd
import requests

logger = logging.getLogger(__name__)


def read_file(path):
    # pick the pandas reader based on the file extension
    path = str(path)
    if path.endswith(".csv"):
        df = pd.read_csv(path)
    elif path.endswith(".json"):
        df = pd.read_json(path)
    elif path.endswith(".parquet"):
        df = pd.read_parquet(path)
    else:
        raise ValueError(f"File type not supported: {path}")

    logger.info(f"Read {len(df)} rows from {path}")
    return df


def write_file(df, path):
    path = str(path)
    # create the output folder if it doesn't exist
    folder = os.path.dirname(path)
    if folder:
        os.makedirs(folder, exist_ok=True)

    if path.endswith(".csv"):
        df.to_csv(path, index=False)
    elif path.endswith(".json"):
        df.to_json(path, orient="records", indent=2, date_format="iso")
    elif path.endswith(".parquet"):
        df.to_parquet(path, index=False)
    else:
        raise ValueError(f"File type not supported: {path}")

    logger.info(f"Wrote {len(df)} rows to {path}")


def read_api(url):
    # get JSON from an API and turn it into a table
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    df = pd.json_normalize(response.json())
    logger.info(f"Got {len(df)} rows from {url}")
    return df
