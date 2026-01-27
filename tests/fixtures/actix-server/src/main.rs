use actix_cors::Cors;
use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: String,
    timestamp: String,
}

struct AppState {
    users: Mutex<Vec<User>>,
}

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "healthy".to_string(),
        timestamp: Utc::now().to_rfc3339(),
    })
}

#[get("/api/users")]
async fn get_users(data: web::Data<AppState>) -> impl Responder {
    let users = data.users.lock().unwrap();
    HttpResponse::Ok().json(users.clone())
}

#[get("/api/users/{id}")]
async fn get_user(data: web::Data<AppState>, path: web::Path<u32>) -> impl Responder {
    let user_id = path.into_inner();
    let users = data.users.lock().unwrap();

    match users.iter().find(|u| u.id == user_id) {
        Some(user) => HttpResponse::Ok().json(user),
        None => HttpResponse::NotFound().json(serde_json::json!({"error": "User not found"})),
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let app_state = web::Data::new(AppState {
        users: Mutex::new(vec![
            User {
                id: 1,
                name: "Alice".to_string(),
                email: "alice@example.com".to_string(),
            },
            User {
                id: 2,
                name: "Bob".to_string(),
                email: "bob@example.com".to_string(),
            },
        ]),
    });

    println!("Starting server at http://127.0.0.1:8080");

    HttpServer::new(move || {
        App::new()
            .wrap(Cors::permissive())
            .app_data(app_state.clone())
            .service(health)
            .service(get_users)
            .service(get_user)
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}
