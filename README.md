# 🚀 OpenMausBot 24/7 Cloud Deployment Pack

حزمة التشغيل السحابي المستمر لـ **OpenMausBot** مجاناً 100% وبدون الحاجة لترك الحاسوب مفتوحاً.

## 🌟 طرق التشغيل بنقرة واحدة (1-Click Deployment)

### الخيار 1: سيرفر سحابي مجاني بنقرة واحدة (سيرفر Ubuntu مجاني)
انسخ هذا السطر والصقه في شاشة الأوامر (Terminal) في أي سيرفر مجاني:
```bash
curl -fsSL https://raw.githubusercontent.com/eslambadeaa/openmausbot-cloud-247/master/deploy-cloud.sh | sudo bash
```

### الخيار 2: النشر المباشر عبر منصات السحابة المجانية
- **Koyeb Free Instance:** يمكنك ربط هذا المستودع مباشرة من خلال حسابك في GitHub لتشغيل حاوية Docker مجانية تعمل 24/7.
- **Render / Hugging Face Spaces:** تدعم تشغيل صور Docker مباشرة.

## 📱 الاتصال بالبوت بعد التشغيل
على السيرفر، نفذ الأمر التالي لإنشاء كود الاقتران:
```bash
cd /opt/openmausbot-247 && docker compose exec omb openmausbot pair --label "Mobile"
```
ثم امسح رمز الـ QR ضوئياً من هاتفك المحمول.
