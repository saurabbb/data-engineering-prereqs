import numpy as np
import pandas as pd
import pytest

from cleaner.clean import (
    standardize_columns,
    strip_text,
    drop_duplicates,
    convert_types,
    fill_missing,
    drop_missing,
)
from cleaner.file_io import read_file, write_file, read_api
from cleaner.pipeline import run_pipeline


def test_standardize_columns():
    df = pd.DataFrame(columns=[" Order ID ", "Customer Name", "Unit-Price"])
    result = standardize_columns(df)
    assert list(result.columns) == ["order_id", "customer_name", "unit_price"]


def test_strip_text():
    df = pd.DataFrame({"name": ["  Ram ", "Sita", "   "]})
    result = strip_text(df)
    assert result["name"][0] == "Ram"
    assert pd.isna(result["name"][2])   # only spaces -> empty


def test_drop_duplicates():
    df = pd.DataFrame({"id": [1, 1, 2], "name": ["Ram", "Ram", "Sita"]})
    result = drop_duplicates(df)
    assert len(result) == 2


def test_convert_types():
    df = pd.DataFrame({"date": ["2026-01-01", "not a date"], "qty": ["5", "abc"]})
    result = convert_types(df, date_cols=["date"], numeric_cols=["qty"])
    assert pd.isna(result["date"][1])
    assert result["qty"][0] == 5
    assert pd.isna(result["qty"][1])


def test_fill_missing():
    df = pd.DataFrame({"status": ["shipped", np.nan]})
    result = fill_missing(df, {"status": "pending"})
    assert result["status"].tolist() == ["shipped", "pending"]


def test_drop_missing():
    df = pd.DataFrame({"id": [1, 2], "email": ["ram@example.com", np.nan]})
    result = drop_missing(df, ["email"])
    assert result["id"].tolist() == [1]


def test_read_write_csv(tmp_path):
    df = pd.DataFrame({"id": [1, 2], "name": ["Ram", "Sita"]})
    path = tmp_path / "test.csv"
    write_file(df, path)
    result = read_file(path)
    assert result["name"].tolist() == ["Ram", "Sita"]


def test_read_write_parquet(tmp_path):
    df = pd.DataFrame({"id": [1, 2], "name": ["Ram", "Sita"]})
    path = tmp_path / "test.parquet"
    write_file(df, path)
    result = read_file(path)
    assert len(result) == 2


def test_wrong_file_type():
    with pytest.raises(ValueError):
        read_file("data.txt")


def test_read_api(monkeypatch):
    # fake API response so the test doesn't need internet
    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return [{"id": 1, "name": "Ram"}, {"id": 2, "name": "Sita"}]

    monkeypatch.setattr("cleaner.file_io.requests.get", lambda url, timeout: FakeResponse())
    df = read_api("https://example.com/api")
    assert len(df) == 2


def test_full_pipeline(tmp_path):
    output = tmp_path / "clean.csv"
    df = run_pipeline(
        "sample_data/orders_raw.csv",
        output,
        date_cols=["order_date"],
        numeric_cols=["quantity", "unit_price"],
        required_cols=["order_id", "customer_email"],
        fill_values={"status": "pending"},
    )
    assert output.exists()
    assert len(df) == 5
    assert df["order_id"].is_unique
    assert df["status"].isna().sum() == 0
