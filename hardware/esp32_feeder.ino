#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>

// --- KHUSUS WOKWI (JANGAN DIGANTI) ---
const char* ssid = "Wokwi-GUEST"; // WiFi Virtual Wokwi
const char* password = "";        // Password kosong

// --- KONFIGURASI MQTT ---
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883; 
const char* mqtt_topic = "ikan/pakan/perintah"; // Harus sama dengan Flutter
const char* clientID = "ESP32_Wokwi_Simulator"; // ID Unik

WiFiClient espClient;
PubSubClient client(espClient);
Servo myServo;

const int servoPin = 13; 

void setup() {
  Serial.begin(115200);
  
  // Setup Servo
  myServo.attach(servoPin);
  myServo.write(0); // Posisi awal (Tertutup)

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to WiFi...");
  
  // Wokwi connect ke Virtual WiFi
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi Connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  Serial.print("Pesan Masuk: ");
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  if (message == "FEED") {
    Serial.println("STATUS: MEMBERI MAKAN (SERVO 90 DERAJAT)");
    myServo.write(90); // Buka
    delay(1000);       
    
    Serial.println("STATUS: SELESAI (SERVO 0 DERAJAT)");
    myServo.write(0);  // Tutup
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Menghubungkan ke MQTT...");
    if (client.connect(clientID)) {
      Serial.println("Berhasil Terhubung!");
      client.subscribe(mqtt_topic);
    } else {
      Serial.print("Gagal, rc=");
      Serial.print(client.state());
      Serial.println(" coba lagi 5 detik...");
      delay(5000);
    }
  }
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}