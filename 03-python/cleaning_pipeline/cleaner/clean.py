import logging

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


def standardize_columns(df):
    # " Order ID " -> "order_id"
    df = df.copy()
    df.columns = (
        df.columns.str.strip()
        .str.lower()
        .str.replace(r"[^a-z0-9]+", "_", regex=True)
        .str.strip("_")
    )
    logger.info(f"Column names: {list(df.columns)}")
    return df


def strip_text(df):
    # remove extra spaces in text columns, empty text becomes NaN
    df = df.copy()
    for col in df.columns:
        if pd.api.types.is_string_dtype(df[col].dtype):
            df[col] = df[col].str.strip().replace("", np.nan)
    logger.info("Removed extra spaces from text columns")
    return df


def drop_duplicates(df):
    before = len(df)
    df = df.drop_duplicates().reset_index(drop=True)
    logger.info(f"Removed {before - len(df)} duplicate rows")
    return df


def convert_types(df, date_cols=None, numeric_cols=None):
    # values that can't be converted become NaT / NaN instead of crashing
    df = df.copy()
    if date_cols:
        for col in date_cols:
            df[col] = pd.to_datetime(df[col], errors="coerce")
            logger.info(f"{col} -> datetime, {df[col].isna().sum()} invalid")
    if numeric_cols:
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors="coerce")
            logger.info(f"{col} -> number, {df[col].isna().sum()} invalid")
    return df


def fill_missing(df, fill_values=None):
    # fill_values example: {"status": "pending"}
    if not fill_values:
        return df
    df = df.fillna(value=fill_values)
    logger.info(f"Filled missing values: {fill_values}")
    return df


def drop_missing(df, required_cols=None):
    # drop rows where an important column is empty
    if not required_cols:
        return df
    before = len(df)
    df = df.dropna(subset=required_cols).reset_index(drop=True)
    logger.info(f"Dropped {before - len(df)} rows with missing {required_cols}")
    return df
