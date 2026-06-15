import argparse
import json
from collections import Counter
from pathlib import Path


def inspect_file(file_path: str) -> None:
    path = Path(file_path)

    if not path.exists():
        raise FileNotFoundError(f"File does not exist: {file_path}")

    total_rows = 0
    event_types = Counter()
    countries = Counter()
    devices = Counter()
    missing_product_id = 0
    missing_price = 0
    purchase_revenue = 0.0

    with path.open("r", encoding="utf-8") as file:
        for line in file:
            total_rows += 1
            event = json.loads(line)

            event_types[event["event_type"]] += 1
            countries[event["country"]] += 1
            devices[event["device"]] += 1

            if event["product_id"] is None:
                missing_product_id += 1

            if event["price"] is None:
                missing_price += 1
            else:
                purchase_revenue += event["price"]

    print(f"File: {file_path}")
    print(f"Total rows: {total_rows}")
    print()
    print("Event types:")
    for event_type, count in event_types.most_common():
        print(f"  {event_type}: {count}")

    print()
    print("Countries:")
    for country, count in countries.most_common():
        print(f"  {country}: {count}")

    print()
    print("Devices:")
    for device, count in devices.most_common():
        print(f"  {device}: {count}")

    print()
    print(f"Rows with missing product_id: {missing_product_id}")
    print(f"Rows with missing price: {missing_price}")
    print(f"Total purchase revenue: {purchase_revenue:.2f}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspect generated event JSONL files."
    )

    parser.add_argument(
        "--file",
        required=True,
        help="Path to JSONL file",
    )

    args = parser.parse_args()
    inspect_file(args.file)


if __name__ == "__main__":
    main()