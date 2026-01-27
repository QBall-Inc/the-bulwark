from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from typing import TypedDict

app = Flask(__name__)
CORS(app)


class HealthResponse(TypedDict):
    status: str
    timestamp: str


class Product(TypedDict):
    id: int
    name: str
    category: str
    price: float


products: list[Product] = [
    {"id": 1, "name": "Laptop", "category": "Electronics", "price": 999.99},
    {"id": 2, "name": "Keyboard", "category": "Electronics", "price": 79.99},
    {"id": 3, "name": "Mouse", "category": "Electronics", "price": 29.99},
]


@app.route("/health")
def health() -> tuple[HealthResponse, int]:
    response: HealthResponse = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
    }
    return response, 200


@app.route("/api/products")
def get_products() -> tuple[list[Product], int]:
    category = request.args.get("category")
    if category:
        filtered = [p for p in products if p["category"].lower() == category.lower()]
        return filtered, 200
    return products, 200


@app.route("/api/products/<int:product_id>")
def get_product(product_id: int) -> tuple[Product | dict[str, str], int]:
    for product in products:
        if product["id"] == product_id:
            return product, 200
    return {"error": "Product not found"}, 404


if __name__ == "__main__":
    app.run(debug=True, port=5000)
