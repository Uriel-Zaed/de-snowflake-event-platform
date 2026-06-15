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


def generate_event(date_str: str) -> dict:
    """
    Generate one fake product event.

    Some events have product_id.
    Only purchase events have price.
    This creates realistic nulls in the data.
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


def generate_events(date_str: str, num_events: int, output_dir: str) -> Path:
    """
    Generate many events and save them as JSONL.

    JSONL means:
    one JSON object per line.
    """
    output_path = Path(output_dir) / f"events_{date_str}.jsonl"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as file:
        for _ in range(num_events):
            event = generate_event(date_str)
            file.write(json.dumps(event) + "\n")

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

    args = parser.parse_args()

    random.seed(args.seed)

    output_path = generate_events(
        date_str=args.date,
        num_events=args.num_events,
        output_dir=args.output_dir,
    )

    print(f"Generated {args.num_events} events")
    print(f"Output file: {output_path}")


if __name__ == "__main__":
    main()