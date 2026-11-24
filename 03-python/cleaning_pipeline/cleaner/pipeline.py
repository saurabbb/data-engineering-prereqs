import argparse
import logging

from cleaner.clean import (
    standardize_columns,
    strip_text,
    drop_duplicates,
    convert_types,
    fill_missing,
    drop_missing,
)
from cleaner.file_io import read_file, write_file

logger = logging.getLogger(__name__)


def run_pipeline(input_path, output_path, date_cols=None, numeric_cols=None,
                 required_cols=None, fill_values=None):
    logger.info(f"Starting pipeline: {input_path} -> {output_path}")

    df = read_file(input_path)
    df = standardize_columns(df)
    df = strip_text(df)
    df = drop_duplicates(df)
    df = convert_types(df, date_cols, numeric_cols)
    df = fill_missing(df, fill_values)
    df = drop_missing(df, required_cols)
    write_file(df, output_path)

    logger.info(f"Done. {len(df)} rows saved")
    return df


def to_list(text):
    # "a,b,c" -> ["a", "b", "c"]
    if not text:
        return []
    return [x.strip() for x in text.split(",")]


def to_dict(text):
    # "status=pending" -> {"status": "pending"}
    result = {}
    for item in to_list(text):
        key, value = item.split("=")
        result[key] = value
    return result


def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s - %(message)s",
    )

    parser = argparse.ArgumentParser(description="Clean a CSV/JSON/Parquet file")
    parser.add_argument("input", help="input file")
    parser.add_argument("output", help="output file")
    parser.add_argument("--dates", default="", help="date columns, comma separated")
    parser.add_argument("--numbers", default="", help="number columns, comma separated")
    parser.add_argument("--required", default="", help="drop rows missing these columns")
    parser.add_argument("--fill", default="", help="fill values, e.g. status=pending")
    args = parser.parse_args()

    run_pipeline(
        args.input,
        args.output,
        date_cols=to_list(args.dates),
        numeric_cols=to_list(args.numbers),
        required_cols=to_list(args.required),
        fill_values=to_dict(args.fill),
    )


if __name__ == "__main__":
    main()
