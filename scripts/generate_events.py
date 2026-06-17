import argparse
import json
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path


EVENT_TYPES = [
    "view_product",
    "add_to_cart",
    "purchase",
    "login",
    "logout",
    "search",
]

COUNTRIES = ["IL", "US", "GB", "DE", "FR", "ES"]
DEVICES = ["ios", "android", "web"]
PRODUCT_IDS = [f"product_{i}" for i in range(1, 101)]

BAD_ROW_TYPES = [
    "missing_event_id",
    "missing_user_id",
    "invalid_event_type",
    "invalid_device",
    "invalid_country",
    "purchase_missing_price",
    "purchase_invalid_price",
    "product_event_missing_product_id",
    "duplicate_event_id",
]


def random_timestamp_for_date(date_str: str) -> str:
    """
    Create a random timestamp inside one specific date.

    Example:
    date_str = "2026-06-14"
    output = "2026-06-14T13:42:10"
    """
    base_date = datetime.strptime(date_str, "%Y-%m-%d")
    seconds_to_add = random.randint(0, 24 * 60 * 60 - 1)
    event_time = base_date + timedelta(seconds=seconds_to_add)
    return event_time.isoformat()


def generate_valid_event(date_str: str) -> dict:
    """
    Generate one valid product event.
    """
    event_type = random.choices(
        EVENT_TYPES,
        weights=[45, 15, 8, 12, 10, 10],
        k=1,
    )[0]

    product_id = None
    price = None

    if event_type in ["view_product", "add_to_cart", "purchase"]:
        product_id = random.choice(PRODUCT_IDS)

    if event_type == "purchase":
        price = round(random.uniform(10, 300), 2)

    return {
        "event_id": str(uuid.uuid4()),
        "user_id": f"user_{random.randint(1, 5000)}",
        "session_id": str(uuid.uuid4()),
        "event_type": event_type,
        "event_timestamp": random_timestamp_for_date(date_str),
        "country": random.choice(COUNTRIES),
        "device": random.choice(DEVICES),
        "product_id": product_id,
        "price": price,
    }


def inject_bad_data(event: dict, existing_event_ids: list[str]) -> tuple[dict, str]:
    """
    Mutate a valid event into an intentionally bad event.

    Returns:
        mutated event
        bad row type
    """
    bad_row_type = random.choice(BAD_ROW_TYPES)

    if bad_row_type == "missing_event_id":
        event["event_id"] = None

    elif bad_row_type == "missing_user_id":
        event["user_id"] = None

    elif bad_row_type == "invalid_event_type":
        event["event_type"] = "product_clicked"

    elif bad_row_type == "invalid_device":
        event["device"] = "smart_tv"

    elif bad_row_type == "invalid_country":
        event["country"] = "XX"

    elif bad_row_type == "purchase_missing_price":
        event["event_type"] = "purchase"
        event["product_id"] = random.choice(PRODUCT_IDS)
        event["price"] = None

    elif bad_row_type == "purchase_invalid_price":
        event["event_type"] = "purchase"
        event["product_id"] = random.choice(PRODUCT_IDS)
        event["price"] = -10.00

    elif bad_row_type == "product_event_missing_product_id":
        event["event_type"] = random.choice(["view_product", "add_to_cart", "purchase"])
        event["product_id"] = None
        if event["event_type"] == "purchase":
            event["price"] = round(random.uniform(10, 300), 2)
        else:
            event["price"] = None

    elif bad_row_type == "duplicate_event_id":
        if existing_event_ids:
            event["event_id"] = random.choice(existing_event_ids)
        else:
            # If this is the first row and no previous ID exists,
            # fall back to another bad data type.
            event["event_id"] = None
            bad_row_type = "missing_event_id"

    return event, bad_row_type


def generate_events(
    date_str: str,
    num_events: int,
    output_dir: str,
    bad_row_rate: float,
) -> Path:
    """
    Generate many events and save them as JSONL.

    JSONL means:
    one JSON object per line.

    bad_row_rate controls the percent of intentionally invalid rows.
    Example:
    bad_row_rate = 0.02 means about 2% bad rows.
    """
    output_path = Path(output_dir) / f"events_{date_str}.jsonl"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    existing_event_ids: list[str] = []
    bad_row_counts: dict[str, int] = {}

    with output_path.open("w", encoding="utf-8") as file:
        for _ in range(num_events):
            event = generate_valid_event(date_str)

            should_inject_bad_data = random.random() < bad_row_rate

            if should_inject_bad_data:
                event, bad_row_type = inject_bad_data(event, existing_event_ids)
                bad_row_counts[bad_row_type] = bad_row_counts.get(bad_row_type, 0) + 1

            if event["event_id"] is not None:
                existing_event_ids.append(event["event_id"])

            file.write(json.dumps(event) + "\n")

    print(f"Generated {num_events} events")
    print(f"Output file: {output_path}")
    print(f"Bad row rate: {bad_row_rate}")

    if bad_row_counts:
        print("Injected bad rows:")
        for bad_row_type, count in sorted(bad_row_counts.items()):
            print(f"  {bad_row_type}: {count}")
    else:
        print("Injected bad rows: 0")

    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate fake raw event data as JSONL files."
    )

    parser.add_argument(
        "--date",
        required=True,
        help="Date in YYYY-MM-DD format",
    )

    parser.add_argument(
        "--num-events",
        type=int,
        default=10000,
        help="Number of events to generate",
    )

    parser.add_argument(
        "--output-dir",
        default="data/raw",
        help="Output directory",
    )

    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducible data",
    )

    parser.add_argument(
        "--bad-row-rate",
        type=float,
        default=0.0,
        help="Percent of rows to intentionally corrupt. Example: 0.02 means 2%.",
    )

    args = parser.parse_args()

    if not 0 <= args.bad_row_rate <= 1:
        raise ValueError("--bad-row-rate must be between 0 and 1")

    random.seed(args.seed)

    generate_events(
        date_str=args.date,
        num_events=args.num_events,
        output_dir=args.output_dir,
        bad_row_rate=args.bad_row_rate,
    )


if __name__ == "__main__":
    main()