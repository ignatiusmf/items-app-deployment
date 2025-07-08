import os
import sqlite3
from typing import Literal
from flask import Flask, request, jsonify
from flask.wrappers import Response

app = Flask(__name__)

# --- Database Configuration ---
# SQLite database file path - can be configured via environment variable
# Configure the database however you see fit, you are welcome to use a config file or environment variable
DB_PATH = os.environ.get("DB_PATH", "./items_db.sqlite")

def init_database() -> None:
    """Initialize the SQLite database with the required schema and seed data."""
    # Ensure the directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create the items table if it doesn't exist
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Insert seed data if the table is empty
    cursor.execute("SELECT COUNT(*) FROM items")
    if cursor.fetchone()[0] == 0:
        cursor.execute(
            "INSERT INTO items (id, name, description) VALUES (1, ?, ?)",
            ("My First Item", "This is a sample item in the database."),
        )

    conn.commit()
    conn.close()


if __name__ != "__main__" and not os.path.exists(os.environ.get("DB_PATH", "items_db.sqlite")):
    print("Initializing database with the required schema and seed data.")
    init_database()

def get_db_connection() -> sqlite3.Connection | None:
    """Establishes and returns a database connection."""
    try:
        conn = sqlite3.connect(DB_PATH)
        # Enable row factory to get dict-like access to rows
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as err:
        print(f"Database connection error: {err}")
        return None


@app.route("/items", methods=["POST"])
def add_item() -> (
    tuple[Response, Literal[400]]
    | tuple[Response, Literal[500]]
    | tuple[Response, Literal[201]]
):
    """
    Adds a new item to the database.
    Expects a JSON payload like: {"name": "New Item", "description": "Details here"}
    """
    data = request.get_json()

    if not data:
        return jsonify({"error": "Request body is missing"}), 400

    if "name" not in data:
        return jsonify({"error": "Missing 'name' in request body"}), 400

    name = data["name"]
    description = data.get("description", None)  # Description is optional

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    cursor = conn.cursor()

    query = "INSERT INTO items (name, description) VALUES (?, ?)"
    cursor.execute(query, (name, description))
    new_id = cursor.lastrowid  # Get the ID of the new record

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Item created successfully", "id": new_id}), 201


@app.route("/items/<int:item_id>", methods=["GET"])
def get_item(
    item_id: int,
) -> (
    tuple[Response, Literal[500]]
    | tuple[Response, Literal[200]]
    | tuple[Response, Literal[404]]
):
    """Retrieves a single item from the database by its ID."""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    cursor = conn.cursor()

    query = "SELECT id, name, description, created_at FROM items WHERE id = ?"
    cursor.execute(query, (item_id,))

    item = cursor.fetchone()

    cursor.close()
    conn.close()

    if item:
        item_dict = dict(item)
        return jsonify(item_dict), 200
    else:
        return jsonify({"error": "Item not found"}), 404


if __name__ == "__main__":
    # Initialize the database on startup
    init_database()
    app.run(host="0.0.0.0", port=3000, debug=True)
