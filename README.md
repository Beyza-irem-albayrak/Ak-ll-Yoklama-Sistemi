Akıllı Yoklama Sistemi

Bitirme Projesi | Bilgisayar Mühendisliği 2025
Ondokuz Mayıs Üniversitesi

📌 Proje Hakkında

Bu proje, geleneksel yoklama yöntemlerinin zaman kaybı ve güvenlik açıkları gibi dezavantajlarını ortadan kaldırmak amacıyla geliştirilmiş modern bir Akıllı Yoklama Sistemidir. Mobil tabanlı bu uygulama, öğrenci yoklamalarını Face ID (yüz tanıma) ve QR kod yöntemleriyle otomatik ve güvenli bir şekilde almayı hedefler.

👨‍💻 Kullanılan Teknolojiler
	•	Flutter – Mobil uygulama geliştirme
	•	Firebase Firestore – Gerçek zamanlı veritabanı
	•	Firebase ML Kit – Yüz algılama
	•	RAG Sunucusu (Retrieval-Augmented Generation) – Vektörel yüz karşılaştırma
	•	Geolocator – Konum doğrulama (GPS)
	•	QR Flutter / Mobile Scanner – QR kod oluşturma ve tarama

⚙ Özellikler
	•	📸 Face ID ile Yoklama: Canlı kamera görüntüsü ile öğrencinin yüzü tanınır, Firebase Storage’daki referans görsellerle karşılaştırılır, eşleşme sağlanırsa otomatik olarak yoklama alınır.
	•	📲 QR Kod ile Yoklama: Öğretmen tarafından oluşturulan QR kod, öğrenci uygulamasıyla taratılarak yoklama gerçekleştirilir.
	•	🌍 Konum Doğrulama: Yoklama sırasında öğrencinin konumu kontrol edilerek sadece sınıfta olan öğrencilerin yoklaması alınır.
	•	📊 Gerçek Zamanlı Veri Yönetimi: Yoklama verileri anında Firebase Firestore’a kaydedilir ve öğretmen/öğrenci arayüzlerinde görüntülenebilir.
