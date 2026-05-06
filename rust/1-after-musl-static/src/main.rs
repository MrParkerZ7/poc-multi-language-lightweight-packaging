use chrono::Utc;
use serde_json::json;
use uuid::Uuid;

fn main() {
    let payload = json!({
        "hello": "world",
        "language": "rust",
        "uuid": Uuid::new_v4().to_string(),
        "timestamp": Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string(),
    });
    println!("{}", payload);
}
